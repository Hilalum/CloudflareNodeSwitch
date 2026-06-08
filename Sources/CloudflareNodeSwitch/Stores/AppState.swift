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
    @Published var mode: ProxyMode = .auto
    @Published var isRefreshing = false
    @Published var isTesting = false
    @Published var isSystemProxyEnabled = false
    @Published var isDeveloperProxyEnabled = false
    @Published var shouldAutoEnableIntegration: Bool {
        didSet { defaults.set(shouldAutoEnableIntegration, forKey: Keys.autoEnableIntegration) }
    }
    @Published var activeNodeID: UUID?
    @Published var statusMessage = "Paste a subscription URL, then refresh."

    let singBoxManager = SingBoxManager()

    private let defaults = UserDefaults.standard
    private let subscriptionService = SubscriptionService()
    private let systemProxyManager = SystemProxyManager()
    private let developerProxyManager = DeveloperProxyManager()
    private var cancellables: Set<AnyCancellable> = []
    private var didRefreshOnLaunch = false
    private var latencyTestTask: Task<Void, Never>?
    private var activeNodeTask: Task<Void, Never>?
    private let clashAPIPort = 19090

    init() {
        subscriptionURL = defaults.string(forKey: Keys.subscriptionURL) ?? ""
        singBoxPath = defaults.string(forKey: Keys.singBoxPath) ?? ""
        let storedPort = defaults.integer(forKey: Keys.localPort)
        localPort = storedPort == 0 ? 7890 : storedPort
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
        nodes.sorted {
            let lhs = latencies[$0.id, default: .unknown].sortValue
            let rhs = latencies[$1.id, default: .unknown].sortValue
            if lhs == rhs {
                return $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
            }
            return lhs < rhs
        }
    }

    var modeDisplayName: String {
        switch mode {
        case .auto:
            return "Auto"
        case .manual:
            return "Manual"
        }
    }

    var currentNodeName: String {
        if let activeNodeID,
           let activeNode = nodes.first(where: { $0.id == activeNodeID }) {
            return activeNode.displayName
        }

        switch mode {
        case .auto:
            return isProxyRunning ? "Detecting" : "-"
        case .manual(let id):
            return nodes.first(where: { $0.id == id })?.displayName ?? "Manual"
        }
    }

    func refreshSubscription() {
        guard !subscriptionURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "Subscription URL is empty."
            return
        }

        isRefreshing = true
        statusMessage = "Refreshing subscription..."

        Task {
            do {
                let fetchedNodes = try await subscriptionService.fetch(from: subscriptionURL)
                nodes = fetchedNodes
                latencies = Dictionary(uniqueKeysWithValues: fetchedNodes.map { ($0.id, NodeLatency.unknown) })
                activeNodeID = nil
                mode = .auto
                statusMessage = "Loaded \(fetchedNodes.count) nodes."
                testLatencies()
                if singBoxManager.isRunning {
                    try startProxy(restart: true)
                }
            } catch {
                statusMessage = "Refresh failed: \(error.localizedDescription)"
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
            statusMessage = "No nodes to test."
            return
        }

        latencyTestTask?.cancel()
        let nodesToTest = nodes
        isTesting = true
        statusMessage = "Testing TCP latency..."
        for node in nodesToTest {
            latencies[node.id] = .testing
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
                    latencies[id] = latency
                }
            }

            guard !Task.isCancelled else {
                return
            }
            if let best = sortedNodes.first, case .alive = latencies[best.id, default: .unknown] {
                statusMessage = "Best TCP latency: \(best.displayName)"
            } else {
                statusMessage = "Latency test finished; no reachable node found."
            }
            isTesting = false
            latencyTestTask = nil
        }
    }

    func chooseAuto() {
        mode = .auto
        statusMessage = "Mode set to auto."
        startActiveNodeMonitoring()
        restartIfRunning()
    }

    func choose(node: ProxyNode) {
        mode = .manual(node.id)
        activeNodeID = node.id
        statusMessage = "Selected \(node.displayName)."
        restartIfRunning()
    }

    func startProxy(restart: Bool = false) throws {
        guard !nodes.isEmpty else {
            statusMessage = "No nodes loaded."
            return
        }

        let data = try SingBoxConfigBuilder(localPort: localPort).build(nodes: nodes, mode: mode)
        try data.write(to: AppPaths.singBoxConfigURL, options: .atomic)
        singBoxManager.start(configURL: AppPaths.singBoxConfigURL, executablePath: singBoxPath)
        if singBoxManager.isRunning {
            startActiveNodeMonitoring()
            if shouldAutoEnableIntegration {
                applyIntegratedProxy()
            }
            statusMessage = restart ? "Proxy restarted." : "Proxy started."
        } else if let error = singBoxManager.lastError {
            statusMessage = error
        }
    }

    func startProxyFromUI() {
        do {
            try startProxy()
        } catch {
            statusMessage = "Start failed: \(error.localizedDescription)"
        }
    }

    func stopProxy() {
        stopActiveNodeMonitoring()
        latencyTestTask?.cancel()
        latencyTestTask = nil
        isTesting = false
        cleanupIntegratedProxy()
        singBoxManager.stop()
        statusMessage = "Proxy stopped."
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
            statusMessage = "Start the proxy before enabling integration."
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
                statusMessage = "Integration will turn on automatically after Start."
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
            statusMessage = "Start the proxy before opening a proxied terminal."
            return
        }

        do {
            if !isIntegratedProxyEnabled {
                shouldAutoEnableIntegration = true
                applyIntegratedProxy()
            }
            try developerProxyManager.openProxiedTerminal(host: "127.0.0.1", port: localPort, command: command)
            statusMessage = command == nil ? "Opened a proxied Terminal." : "Opened \(command!) with proxy."
        } catch {
            statusMessage = "Open terminal failed: \(error.localizedDescription)"
        }
    }

    func toggleSystemProxy() {
        Task.detached { [localPort] in
            do {
                if await self.isSystemProxyEnabled {
                    try self.systemProxyManager.disable()
                    await MainActor.run {
                        self.isSystemProxyEnabled = false
                        self.statusMessage = "System proxy disabled."
                    }
                } else {
                    try self.systemProxyManager.enable(host: "127.0.0.1", port: localPort)
                    await MainActor.run {
                        self.isSystemProxyEnabled = true
                        self.statusMessage = "System proxy enabled."
                    }
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = "System proxy failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func applyIntegratedProxy() {
        Task.detached { [localPort] in
            do {
                try self.systemProxyManager.enable(host: "127.0.0.1", port: localPort)
                try self.developerProxyManager.enable(host: "127.0.0.1", port: localPort)
                await MainActor.run {
                    self.isSystemProxyEnabled = true
                    self.isDeveloperProxyEnabled = true
                    self.statusMessage = "Integrated proxy enabled for system apps and new shells."
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = "Integration failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func disableIntegratedProxy() {
        Task.detached {
            do {
                try self.systemProxyManager.disable()
                try self.developerProxyManager.disable()
                await MainActor.run {
                    self.isSystemProxyEnabled = false
                    self.isDeveloperProxyEnabled = false
                    self.shouldAutoEnableIntegration = false
                    self.statusMessage = "Integrated proxy disabled."
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = "Disable integration failed: \(error.localizedDescription)"
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
            statusMessage = "Restart failed: \(error.localizedDescription)"
        }
    }

    private func startActiveNodeMonitoring() {
        activeNodeTask?.cancel()

        switch mode {
        case .manual(let id):
            activeNodeID = id
            activeNodeTask = nil
        case .auto:
            activeNodeID = nil
            let port = clashAPIPort
            activeNodeTask = Task {
                while !Task.isCancelled {
                    do {
                        if let tag = try await ClashAPIClient(port: port).currentOutboundTag(),
                           let id = nodeID(forOutboundTag: tag) {
                            activeNodeID = id
                        }
                    } catch {
                        activeNodeID = nil
                    }

                    try? await Task.sleep(for: .seconds(3))
                }
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
        static let autoEnableIntegration = "autoEnableIntegration"
    }
}
