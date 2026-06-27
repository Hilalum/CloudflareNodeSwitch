import SwiftUI

struct DetailView: View {
    @ObservedObject var state: AppState
    let selectedNodeID: ProxyNode.ID?

    private var selectedNode: ProxyNode? {
        guard let selectedNodeID else { return nil }
        return state.nodes.first(where: { $0.id == selectedNodeID })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeaderView(state: state)
                StatusStrip(state: state)
                SettingsPanel(state: state)
                NodeDetailPanel(state: state, node: selectedNode)
                LogPanel(state: state)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: 980, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Header

private struct HeaderView: View {
    @ObservedObject var state: AppState

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text(LocalizedString.appTitle)
                        .font(.title.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(1)

                    // 运行状态指示器
                    if state.isProxyRunning {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .fill(.green.opacity(0.4))
                                    .frame(width: 14, height: 14)
                            )
                    }
                }

                Text(state.statusMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
                    .animation(.easeInOut(duration: 0.3), value: state.statusMessage)
            }

            Spacer(minLength: 18)

            HStack(spacing: 10) {
                HeaderButton(
                    title: LocalizedString.refresh,
                    icon: "arrow.clockwise",
                    isLoading: state.isRefreshing
                ) {
                    state.refreshSubscription()
                }

                HeaderButton(
                    title: LocalizedString.test,
                    icon: "speedometer",
                    isLoading: state.isTesting
                ) {
                    state.testLatencies()
                }
                .disabled(state.isTesting || state.nodes.isEmpty)

                Button {
                    if state.isProxyRunning {
                        state.stopProxy()
                    } else {
                        state.startProxyFromUI()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: state.isProxyRunning ? "stop.fill" : "play.fill")
                        Text(state.isProxyRunning ? LocalizedString.stop : LocalizedString.start)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        state.isProxyRunning ?
                        AnyShapeStyle(.red.opacity(0.12)) :
                        AnyShapeStyle(.green.opacity(0.12))
                    )
                    .foregroundStyle(state.isProxyRunning ? .red : .green)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(state.nodes.isEmpty)
                .keyboardShortcut(.space, modifiers: [.command])
            }
        }
    }
}

private struct HeaderButton: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Status Strip

private struct StatusStrip: View {
    @ObservedObject var state: AppState

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 10)]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            StatusCard(
                title: LocalizedString.proxy,
                value: state.isProxyRunning ? LocalizedString.running : LocalizedString.stopped,
                symbol: state.isProxyRunning ? "bolt.horizontal.fill" : "bolt.horizontal",
                gradient: state.isProxyRunning ?
                    LinearGradient(colors: [.green.opacity(0.15), .green.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(colors: [.secondary.opacity(0.1), .secondary.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing),
                accentColor: state.isProxyRunning ? .green : .secondary
            )

            StatusCard(
                title: LocalizedString.mode,
                value: state.modeDisplayName,
                symbol: state.mode == .auto ? "wand.and.stars" : "scope",
                gradient: LinearGradient(colors: [.blue.opacity(0.12), .blue.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing),
                accentColor: .blue
            )

            StatusCard(
                title: LocalizedString.current,
                value: state.currentNodeName,
                symbol: "point.3.connected.trianglepath.dotted",
                gradient: state.activeNodeID != nil ?
                    LinearGradient(colors: [.green.opacity(0.12), .green.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(colors: [.secondary.opacity(0.1), .secondary.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing),
                accentColor: state.activeNodeID != nil ? .green : .secondary
            )

            StatusCard(
                title: LocalizedString.nodeCount,
                value: "\(state.nodes.count)",
                symbol: "server.rack",
                gradient: LinearGradient(colors: [.purple.opacity(0.12), .purple.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing),
                accentColor: .purple
            )

            StatusCard(
                title: LocalizedString.system,
                value: state.isSystemProxyEnabled ? LocalizedString.on : LocalizedString.off,
                symbol: "network",
                gradient: state.isSystemProxyEnabled ?
                    LinearGradient(colors: [.green.opacity(0.12), .green.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(colors: [.secondary.opacity(0.1), .secondary.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing),
                accentColor: state.isSystemProxyEnabled ? .green : .secondary
            )

            StatusCard(
                title: LocalizedString.developer,
                value: state.isDeveloperProxyEnabled ? LocalizedString.on : LocalizedString.off,
                symbol: "terminal",
                gradient: state.isDeveloperProxyEnabled ?
                    LinearGradient(colors: [.green.opacity(0.12), .green.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(colors: [.secondary.opacity(0.1), .secondary.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing),
                accentColor: state.isDeveloperProxyEnabled ? .green : .secondary
            )
        }
    }
}

private struct StatusCard: View {
    let title: String
    let value: String
    let symbol: String
    let gradient: LinearGradient
    let accentColor: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(gradient)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.secondary.opacity(0.06), lineWidth: 0.5)
        )
    }
}

// MARK: - Settings Panel

private struct SettingsPanel: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                Text(LocalizedString.settings)
                    .font(.title3.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 0) {
                SettingRow(label: LocalizedString.subscription) {
                    SecureField(LocalizedString.subscriptionURL, text: $state.subscriptionURL)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 260)

                    Button {
                        state.refreshSubscription()
                    } label: {
                        Label(LocalizedString.refresh, systemImage: "arrow.clockwise")
                    }
                    .disabled(state.isRefreshing)
                }

                Divider().padding(.leading, 108)

                SettingRow(label: LocalizedString.language) {
                    Picker(LocalizedString.language, selection: $state.appLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.title).tag(language)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 142, alignment: .leading)
                }

                Divider().padding(.leading, 108)

                SettingRow(label: "sing-box") {
                    TextField("/opt/homebrew/bin/sing-box", text: $state.singBoxPath)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 260)

                    Text(LocalizedString.blankUsesPath)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Divider().padding(.leading, 108)

                SettingRow(label: LocalizedString.localPort) {
                    TextField("7890", value: $state.localPort, formatter: NumberFormatter.plainPortFormatter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 92)
                        .monospacedDigit()

                    Stepper("", value: $state.localPort, in: 1024...65535)
                        .labelsHidden()
                }

                Divider().padding(.leading, 108)

                SettingRow(label: LocalizedString.inbound) {
                    Picker(LocalizedString.inbound, selection: $state.inboundMode) {
                        ForEach(InboundMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 100, alignment: .leading)

                    Text(state.inboundMode.detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Divider().padding(.leading, 108)

                SettingRow(label: LocalizedString.routing) {
                    Picker(LocalizedString.routing, selection: $state.routingMode) {
                        ForEach(RoutingMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 142, alignment: .leading)

                    Text(state.routingMode.detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Divider().padding(.leading, 108)

                SettingRow(label: LocalizedString.integration) {
                    Toggle(isOn: Binding(
                        get: { state.isProxyRunning ? state.isIntegratedProxyEnabled : state.shouldAutoEnableIntegration },
                        set: { state.setIntegratedProxyEnabled($0) }
                    )) {
                        Label(
                            (state.isProxyRunning ? state.isIntegratedProxyEnabled : state.shouldAutoEnableIntegration) ? LocalizedString.on : LocalizedString.off,
                            systemImage: "network"
                        )
                    }
                    .toggleStyle(.switch)

                    Text(integrationDescription)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Divider().padding(.leading, 108)

                SettingRow(label: LocalizedString.developer) {
                    HStack(spacing: 8) {
                        Text(state.isDeveloperProxyEnabled ? LocalizedString.integrationActive : LocalizedString.developerProxyOff)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        Button {
                            state.openProxiedTerminal(command: nil)
                        } label: {
                            Label(LocalizedString.terminal, systemImage: "terminal")
                                .font(.callout)
                        }
                        .disabled(!state.isProxyRunning)

                        Button {
                            state.openProxiedTerminal(command: "codex")
                        } label: {
                            Label("Codex", systemImage: "chevron.left.forwardslash.chevron.right")
                                .font(.callout)
                        }
                        .disabled(!state.isProxyRunning)

                        Button {
                            state.openProxiedTerminal(command: "claude")
                        } label: {
                            Label("Claude", systemImage: "sparkles")
                                .font(.callout)
                        }
                        .disabled(!state.isProxyRunning)
                    }
                }
            }
            .padding(14)
            .background(Color.secondary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.secondary.opacity(0.08), lineWidth: 0.5)
            )
        }
    }

    private var integrationDescription: String {
        if state.isProxyRunning {
            return state.isIntegratedProxyEnabled ? LocalizedString.integrationActive : LocalizedString.systemProxyOff
        }
        return state.shouldAutoEnableIntegration ? LocalizedString.integrationAutoOn : LocalizedString.integrationWillStayOff
    }
}

private struct SettingRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)

            HStack(spacing: 10) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Node Detail Panel

private struct NodeDetailPanel: View {
    @ObservedObject var state: AppState
    let node: ProxyNode?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                Text(LocalizedString.node)
                    .font(.title3.weight(.semibold))

                Spacer()

                if let node {
                    Button {
                        state.choose(node: node)
                    } label: {
                        Label(LocalizedString.use, systemImage: "checkmark.circle")
                            .font(.callout.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                }

                Button {
                    state.chooseAuto()
                } label: {
                    Label(LocalizedString.auto, systemImage: "wand.and.stars")
                        .font(.callout.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }

            if let node {
                VStack(spacing: 0) {
                    // 节点头部 - 国家信息
                    if let country = node.country {
                        HStack(spacing: 12) {
                            Text(node.countryFlag)
                                .font(.system(size: 32))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(node.countryName)
                                    .font(.headline)
                                Text(country)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.blue.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.bottom, 12)
                    }

                    // 节点详情
                    VStack(spacing: 0) {
                        DetailInfoRow(label: LocalizedString.name, value: node.displayName)
                        Divider().padding(.leading, 108)
                        DetailInfoRow(label: LocalizedString.endpoint, value: node.endpoint)
                        Divider().padding(.leading, 108)
                        DetailInfoRow(label: LocalizedString.network, value: node.network.uppercased())
                        Divider().padding(.leading, 108)
                        DetailInfoRow(label: LocalizedString.tlsSNI, value: node.sni ?? "-")
                        Divider().padding(.leading, 108)
                        DetailInfoRow(label: LocalizedString.host, value: node.host ?? "-")
                        Divider().padding(.leading, 108)
                        DetailInfoRow(label: LocalizedString.path, value: node.path ?? "-")
                    }
                    .textSelection(.enabled)
                    .padding(14)
                    .background(Color.secondary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.secondary.opacity(0.08), lineWidth: 0.5)
                    )
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "cursorarrow.click.2")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text(LocalizedString.selectNodeHint)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }
}

private struct DetailInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)
            Text(value)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Log Panel

private struct LogPanel: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                Text(LocalizedString.log)
                    .font(.title3.weight(.semibold))
                Spacer()
                Button {
                    state.openSupportFolder()
                } label: {
                    Label(LocalizedString.folder, systemImage: "folder")
                        .font(.callout)
                }
            }

            ScrollView([.horizontal, .vertical]) {
                Text(state.singBoxManager.logTail.isEmpty ? LocalizedString.noSingBoxOutput : state.singBoxManager.logTail)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(state.singBoxManager.logTail.isEmpty ? Color.secondary : Color.primary.opacity(0.7))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(minHeight: 140, maxHeight: 220)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .textBackgroundColor).opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 0.5)
            )
        }
    }
}

// MARK: - Number Formatter

private extension NumberFormatter {
    static var plainPortFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 1024
        formatter.maximum = 65535
        formatter.allowsFloats = false
        return formatter
    }
}
