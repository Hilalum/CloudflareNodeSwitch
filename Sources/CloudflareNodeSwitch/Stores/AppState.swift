import Combine
import Foundation
import AppKit

@MainActor
final class AppState: ObservableObject {
    @Published var subscriptionURL: String {
        didSet { defaults.set(subscriptionURL, forKey: Keys.subscriptionURL) }
    }
    @Published var singBoxPath: String {
        didSet { defaults.set(singBoxPath, forKey: Keys.singBoxPath) }
    }
    @Published var localPort: Int {
        didSet { defaults.set(localPort, forKey: Keys.localPort) }
    }
    @Published var nodes: [ProxyNode] = []
    @Published var latencies: [UUID: NodeLatency] = [:]
    @Published var tcpLatencies: [UUID: NodeLatency] = [:]
    @Published var mode: ProxyMode = .auto
    @Published var appLanguage: AppLanguage {
        didSet {
            defaults.set(appLanguage.rawValue, forKey: Keys.appLanguage)
            statusMessage = LocalizedString.pasteSubscriptionHint
        }
    }
    @Published var routingMode: RoutingMode {
        didSet {
            defaults.set(routingMode.rawValue, forKey: Keys.routingMode)
            restartIfRunning()
        }
    }
    @Published var inboundMode: InboundMode {
        didSet {
            defaults.set(inboundMode.rawValue, forKey: Keys.inboundMode)
            restartIfRunning()
        }
    }
    @Published var selectedCountry: String? = nil
    @Published var isRefreshing = false
    @Published var isTesting = false
    @Published var isSystemProxyEnabled = false
    @Published var isDeveloperProxyEnabled = false
    @Published var shouldAutoEnableIntegration: Bool {
        didSet { defaults.set(shouldAutoEnableIntegration, forKey: Keys.autoEnableIntegration) }
    }
    @Published var activeNodeID: UUID?
    @Published var statusMessage = LocalizedString.pasteSubscriptionHint

    let singBoxManager = SingBoxManager()

    private let defaults = UserDefaults.standard
    private let subscriptionService = SubscriptionService()
    private let countryLookupService = CountryLookupService()
    private let systemProxyManager = SystemProxyManager()
    private let developerProxyManager = DeveloperProxyManager()
    private var cancellables: Set<AnyCancellable> = []
    private var didRefreshOnLaunch = false
    private var latencyTestTask: Task<Void, Never>?
    private var activeNodeTask: Task<Void, Never>?
    private let clashAPIPort = SingBoxConfigBuilder.defaultClashAPIPort

    init() {
        subscriptionURL = defaults.string(forKey: Keys.subscriptionURL) ?? ""
        singBoxPath = defaults.string(forKey: Keys.singBoxPath) ?? ""
        let storedPort = defaults.integer(forKey: Keys.localPort)
        localPort = storedPort == 0 ? 7890 : storedPort
        let storedLanguage = defaults.string(forKey: Keys.appLanguage) ?? AppLanguage.system.rawValue
        appLanguage = AppLanguage(rawValue: storedLanguage) ?? .system
        let storedRouting = defaults.string(forKey: Keys.routingMode) ?? RoutingMode.aiStable.rawValue
        routingMode = RoutingMode(rawValue: storedRouting) ?? .aiStable
        let storedInbound = defaults.string(forKey: Keys.inboundMode) ?? InboundMode.mixed.rawValue
        inboundMode = InboundMode(rawValue: storedInbound) ?? .mixed
        if defaults.object(forKey: Keys.autoEnableIntegration) == nil {
            shouldAutoEnableIntegration = true
            defaults.set(true, forKey: Keys.autoEnableIntegration)
        } else {
            shouldAutoEnableIntegration = defaults.bool(forKey: Keys.autoEnableIntegration)
        }
        isDeveloperProxyEnabled = false

        singBoxManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var isProxyRunning: Bool {
        singBoxManager.isRunning
    }

    var isIntegratedProxyEnabled: Bool {
        isSystemProxyEnabled || isDeveloperProxyEnabled
    }

    var sortedNodes: [ProxyNode] {
        let sortLatencies = isProxyRunning ? latencies : tcpLatencies
        return filteredNodes.sorted {
            let lhs = sortLatencies[$0.id, default: .unknown].sortValue
            let rhs = sortLatencies[$1.id, default: .unknown].sortValue
            if lhs == rhs {
                return $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
            }
            return lhs < rhs
        }
    }

    var availableCountries: [String] {
        let codes = Set(nodes.compactMap { $0.country })
        return codes.sorted { a, b in
            let nameA = CountryUtils.name(for: a)
            let nameB = CountryUtils.name(for: b)
            return nameA.localizedStandardCompare(nameB) == .orderedAscending
        }
    }

    var filteredNodes: [ProxyNode] {
        guard let country = selectedCountry else { return nodes }
        return nodes.filter { $0.country == country }
    }

    var modeDisplayName: String {
        switch mode {
        case .auto:
            return LocalizedString.auto
        case .manual:
            return LocalizedString.manual
        }
    }

    var currentNodeName: String {
        if let activeNodeID,
           let activeNode = nodes.first(where: { $0.id == activeNodeID }) {
            return activeNode.displayName
        }

        switch mode {
        case .auto:
            return isProxyRunning ? LocalizedString.detecting : "-"
        case .manual(let id):
            return nodes.first(where: { $0.id == id })?.displayName ?? LocalizedString.manual
        }
    }

    func refreshSubscription() {
        guard !subscriptionURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = LocalizedString.subscriptionEmpty
            return
        }

        isRefreshing = true
        statusMessage = LocalizedString.refreshingSubscription

        Task {
            do {
                let fetchedNodes = try await subscriptionService.fetch(from: subscriptionURL)
                nodes = fetchedNodes
                latencies = Dictionary(uniqueKeysWithValues: fetchedNodes.map { ($0.id, NodeLatency.unknown) })
                tcpLatencies = Dictionary(uniqueKeysWithValues: fetchedNodes.map { ($0.id, NodeLatency.unknown) })
                activeNodeID = nil
                selectedCountry = nil
                mode = .auto
                statusMessage = String(format: LocalizedString.loadedNodes, fetchedNodes.count)
                testLatencies()
                if singBoxManager.isRunning {
                    try startProxy(restart: true)
                }
                let countryCodes = await countryLookupService.countryCodes(for: fetchedNodes)
                for index in nodes.indices {
                    nodes[index].countryCode = countryCodes[nodes[index].id]
                }
            } catch {
                statusMessage = String(format: LocalizedString.refreshFailed, error.localizedDescription)
                isTesting = false
            }
            isRefreshing = false
        }
    }

    func refreshOnLaunchIfNeeded() {
        guard !didRefreshOnLaunch else {
            return
        }
        didRefreshOnLaunch = true
        guard !subscriptionURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        refreshSubscription()
    }

    func testLatencies() {
        guard !nodes.isEmpty else {
            statusMessage = LocalizedString.noNodesToTest
            return
        }

        latencyTestTask?.cancel()
        let nodesToTest = nodes
        isTesting = true
        statusMessage = LocalizedString.testingTCPLatency
        for node in nodesToTest {
            tcpLatencies[node.id] = .testing
        }

        latencyTestTask = Task {
            await withTaskGroup(of: (UUID, NodeLatency).self) { group in
                for node in nodesToTest {
                    group.addTask {
                        guard !Task.isCancelled else {
                            return (node.id, NodeLatency.unknown)
                        }
                        let result = await LatencyTester().measure(node: node)
                        return (node.id, result)
                    }
                }

                for await (id, latency) in group {
                    guard !Task.isCancelled else {
                        group.cancelAll()
                        return
                    }
                    tcpLatencies[id] = latency
                }
            }

            guard !Task.isCancelled else {
                isTesting = false
                latencyTestTask = nil
                return
            }
            let best = filteredNodes.min {
                tcpLatencies[$0.id, default: .unknown].sortValue < tcpLatencies[$1.id, default: .unknown].sortValue
            }
            if let best, case .alive = tcpLatencies[best.id, default: .unknown] {
                statusMessage = String(format: LocalizedString.bestTCPLatency, best.displayName)
            } else {
                statusMessage = LocalizedString.latencyTestFinished
            }
            isTesting = false
            latencyTestTask = nil
        }
    }

    func chooseAuto() {
        mode = .auto
        statusMessage = LocalizedString.modeSetToAuto
        startActiveNodeMonitoring()
        restartIfRunning()
    }

    func choose(node: ProxyNode) {
        mode = .manual(node.id)
        activeNodeID = node.id
        statusMessage = String(format: LocalizedString.selectedNode, node.displayName)
        restartIfRunning()
    }

    func startProxy(restart: Bool = false) throws {
        guard !nodes.isEmpty else {
            statusMessage = LocalizedString.noNodesLoaded
            return
        }

        let data = try SingBoxConfigBuilder(localPort: localPort).build(nodes: nodes, mode: mode, routingMode: routingMode, inboundMode: inboundMode)
        try data.write(to: AppPaths.singBoxConfigURL, options: .atomic)
        singBoxManager.start(configURL: AppPaths.singBoxConfigURL, executablePath: singBoxPath)
        if singBoxManager.isRunning {
            startActiveNodeMonitoring()
            if shouldAutoEnableIntegration {
                applyIntegratedProxy()
            }
            statusMessage = restart ? LocalizedString.proxyRestarted : LocalizedString.proxyStarted
        } else if let error = singBoxManager.lastError {
            statusMessage = error
        }
    }

    func startProxyFromUI() {
        do {
            try startProxy()
        } catch {
            statusMessage = String(format: LocalizedString.startFailed, error.localizedDescription)
        }
    }

    func stopProxy() {
        stopActiveNodeMonitoring()
        latencies = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, NodeLatency.unknown) })
        latencyTestTask?.cancel()
        latencyTestTask = nil
        isTesting = false
        cleanupIntegratedProxy()
        singBoxManager.stop()
        statusMessage = LocalizedString.proxyStopped
    }

    func shutdown() {
        stopActiveNodeMonitoring()
        latencyTestTask?.cancel()
        latencyTestTask = nil
        isTesting = false
        cleanupIntegratedProxy()
        singBoxManager.stop()
    }

    func toggleIntegratedProxy() {
        guard isProxyRunning else {
            statusMessage = LocalizedString.startProxyFirst
            return
        }

        if isDeveloperProxyEnabled || isSystemProxyEnabled {
            disableIntegratedProxy()
        } else {
            shouldAutoEnableIntegration = true
            applyIntegratedProxy()
        }
    }

    func setIntegratedProxyEnabled(_ enabled: Bool) {
        shouldAutoEnableIntegration = enabled
        if enabled {
            guard isProxyRunning else {
                statusMessage = LocalizedString.integrationAutoOn
                return
            }
            if !isIntegratedProxyEnabled {
                applyIntegratedProxy()
            }
        } else if isIntegratedProxyEnabled {
            disableIntegratedProxy()
        }
    }

    func openProxiedTerminal(command: String?) {
        guard isProxyRunning else {
            statusMessage = LocalizedString.openTerminalFirst
            return
        }

        do {
            if !isIntegratedProxyEnabled {
                shouldAutoEnableIntegration = true
                applyIntegratedProxy()
            }
            try developerProxyManager.openProxiedTerminal(host: "127.0.0.1", port: localPort, command: command)
            statusMessage = command == nil ? LocalizedString.openedProxiedTerminal : String(format: LocalizedString.openedCommandWithProxy, command!)
        } catch {
            statusMessage = String(format: LocalizedString.openTerminalFailed, error.localizedDescription)
        }
    }

    func toggleSystemProxy() {
        Task.detached { [weak self, localPort] in
            guard let self else { return }
            do {
                if await self.isSystemProxyEnabled {
                    try self.systemProxyManager.disable()
                    await MainActor.run {
                        self.isSystemProxyEnabled = false
                        self.statusMessage = LocalizedString.systemProxyDisabled
                    }
                } else {
                    try self.systemProxyManager.enable(host: "127.0.0.1", port: localPort)
                    await MainActor.run {
                        self.isSystemProxyEnabled = true
                        self.statusMessage = LocalizedString.systemProxyEnabled
                    }
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = String(format: LocalizedString.systemProxyFailed, error.localizedDescription)
                }
            }
        }
    }

    private func applyIntegratedProxy() {
        Task.detached { [weak self, localPort] in
            guard let self else { return }
            do {
                try self.systemProxyManager.enable(host: "127.0.0.1", port: localPort)
                try self.developerProxyManager.enable(host: "127.0.0.1", port: localPort)
                await MainActor.run {
                    self.isSystemProxyEnabled = true
                    self.isDeveloperProxyEnabled = true
                    self.statusMessage = LocalizedString.integratedProxyEnabled
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = String(format: LocalizedString.integrationFailed, error.localizedDescription)
                }
            }
        }
    }

    private func disableIntegratedProxy() {
        Task.detached { [weak self] in
            guard let self else { return }
            do {
                try self.systemProxyManager.disable()
                try self.developerProxyManager.disable()
                await MainActor.run {
                    self.isSystemProxyEnabled = false
                    self.isDeveloperProxyEnabled = false
                    self.shouldAutoEnableIntegration = false
                    self.statusMessage = LocalizedString.integratedProxyDisabled
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = String(format: LocalizedString.disableIntegrationFailed, error.localizedDescription)
                }
            }
        }
    }

    private func cleanupIntegratedProxy() {
        if isSystemProxyEnabled {
            try? systemProxyManager.disable()
            isSystemProxyEnabled = false
        }

        if isDeveloperProxyEnabled {
            try? developerProxyManager.disable()
            isDeveloperProxyEnabled = false
        }
    }

    func openSupportFolder() {
        NSWorkspace.shared.open(AppPaths.applicationSupportDirectory)
    }

    private func restartIfRunning() {
        guard singBoxManager.isRunning else {
            return
        }
        do {
            try startProxy(restart: true)
        } catch {
            statusMessage = String(format: LocalizedString.restartFailed, error.localizedDescription)
        }
    }

    private func startActiveNodeMonitoring() {
        activeNodeTask?.cancel()
        if case .manual(let id) = mode {
            activeNodeID = id
        } else {
            activeNodeID = nil
        }

        let port = clashAPIPort
        activeNodeTask = Task {
            while !Task.isCancelled {
                do {
                    let snapshot = try await ClashAPIClient(port: port).snapshot()
                    if case .auto = mode,
                       let tag = snapshot.currentTag,
                       let id = nodeID(forOutboundTag: tag) {
                        activeNodeID = id
                    }
                    var proxyLatencies = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, NodeLatency.failed) })
                    for (tag, delay) in snapshot.delays {
                        if let id = nodeID(forOutboundTag: tag) {
                            proxyLatencies[id] = .alive(milliseconds: delay)
                        }
                    }
                    latencies = proxyLatencies
                } catch {
                    if case .auto = mode {
                        activeNodeID = nil
                    }
                }

                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    private func stopActiveNodeMonitoring() {
        activeNodeTask?.cancel()
        activeNodeTask = nil
        activeNodeID = nil
    }

    private func nodeID(forOutboundTag tag: String) -> UUID? {
        guard tag.hasPrefix("node-"),
              let number = Int(tag.dropFirst("node-".count)) else {
            return nil
        }

        let index = number - 1
        guard nodes.indices.contains(index) else {
            return nil
        }

        return nodes[index].id
    }

    private enum Keys {
        static let subscriptionURL = "subscriptionURL"
        static let singBoxPath = "singBoxPath"
        static let localPort = "localPort"
        static let appLanguage = "appLanguage"
        static let autoEnableIntegration = "autoEnableIntegration"
        static let routingMode = "routingMode"
        static let inboundMode = "inboundMode"
    }
}
