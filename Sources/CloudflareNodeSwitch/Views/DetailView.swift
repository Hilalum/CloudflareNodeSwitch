import SwiftUI

struct DetailView: View {
    @ObservedObject var state: AppState
    let selectedNodeID: ProxyNode.ID?

    private var selectedNode: ProxyNode? {
        guard let selectedNodeID else {
            return nil
        }
        return state.nodes.first(where: { $0.id == selectedNodeID })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
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

private struct HeaderView: View {
    @ObservedObject var state: AppState

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Cloudflare Node Switch")
                    .font(.largeTitle.weight(.semibold))
                    .lineLimit(1)
                Text(state.statusMessage)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 18)

            HStack(spacing: 8) {
                Button {
                    state.refreshSubscription()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(state.isRefreshing)

                Button {
                    state.testLatencies()
                } label: {
                    Label("Test", systemImage: "speedometer")
                }
                .disabled(state.isTesting || state.nodes.isEmpty)

                Button {
                    if state.isProxyRunning {
                        state.stopProxy()
                    } else {
                        state.startProxyFromUI()
                    }
                } label: {
                    Label(state.isProxyRunning ? "Stop" : "Start", systemImage: state.isProxyRunning ? "stop.fill" : "play.fill")
                }
                .disabled(state.nodes.isEmpty)
                .keyboardShortcut(.space, modifiers: [.command])
            }
            .labelStyle(.iconOnly)
            .controlSize(.large)
        }
    }
}

private struct StatusStrip: View {
    @ObservedObject var state: AppState

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 12)]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            MetricView(title: "Proxy", value: state.isProxyRunning ? "Running" : "Stopped", symbol: state.isProxyRunning ? "bolt.horizontal.fill" : "bolt.horizontal", color: state.isProxyRunning ? .green : .secondary)
            MetricView(title: "Mode", value: state.modeDisplayName, symbol: state.mode == .auto ? "wand.and.stars" : "scope", color: .blue)
            MetricView(title: "Current", value: state.currentNodeName, symbol: "point.3.connected.trianglepath.dotted", color: state.activeNodeID == nil ? .secondary : .green)
            MetricView(title: "Nodes", value: "\(state.nodes.count)", symbol: "server.rack", color: .blue)
            MetricView(title: "System", value: state.isSystemProxyEnabled ? "On" : "Off", symbol: "network", color: state.isSystemProxyEnabled ? .green : .secondary)
            MetricView(title: "Developer", value: state.isDeveloperProxyEnabled ? "On" : "Off", symbol: "terminal", color: state.isDeveloperProxyEnabled ? .green : .secondary)
        }
    }
}

private struct MetricView: View {
    let title: String
    let value: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct SettingsPanel: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 10) {
                SettingRow(label: "Subscription") {
                    SecureField("Subscription URL", text: $state.subscriptionURL)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 260)

                    Button {
                        state.refreshSubscription()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(state.isRefreshing)
                }

                SettingRow(label: "sing-box") {
                    TextField("/opt/homebrew/bin/sing-box", text: $state.singBoxPath)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 260)

                    Text("Blank uses PATH")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                SettingRow(label: "Local Port") {
                    TextField("7890", value: $state.localPort, formatter: NumberFormatter.plainPortFormatter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 92)
                        .monospacedDigit()

                    Stepper("", value: $state.localPort, in: 1024...65535)
                        .labelsHidden()
                }

                SettingRow(label: "Integration") {
                    Toggle(isOn: Binding(
                        get: { state.isProxyRunning ? state.isIntegratedProxyEnabled : state.shouldAutoEnableIntegration },
                        set: { state.setIntegratedProxyEnabled($0) }
                    )) {
                        Label((state.isProxyRunning ? state.isIntegratedProxyEnabled : state.shouldAutoEnableIntegration) ? "On" : "Off", systemImage: "network")
                    }
                    .toggleStyle(.switch)

                    Text(integrationDescription)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                SettingRow(label: "Developer") {
                    Text(state.isDeveloperProxyEnabled ? "New terminals inherit proxy automatically" : "Off for Codex and Claude Code shells")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Button {
                        state.openProxiedTerminal(command: nil)
                    } label: {
                        Label("Terminal", systemImage: "terminal")
                    }
                    .disabled(!state.isProxyRunning)

                    Button {
                        state.openProxiedTerminal(command: "codex")
                    } label: {
                        Label("Codex", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    .disabled(!state.isProxyRunning)

                    Button {
                        state.openProxiedTerminal(command: "claude")
                    } label: {
                        Label("Claude", systemImage: "sparkles")
                    }
                    .disabled(!state.isProxyRunning)
                }
            }
        }
    }

    private var integrationDescription: String {
        if state.isProxyRunning {
            return state.isIntegratedProxyEnabled ? "System and developer proxy are active" : "System proxy is off"
        }
        return state.shouldAutoEnableIntegration ? "Turns on automatically after Start" : "Will stay off after Start"
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
    }
}

private struct NodeDetailPanel: View {
    @ObservedObject var state: AppState
    let node: ProxyNode?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Node")
                    .font(.title3.weight(.semibold))
                Spacer()
                if let node {
                    Button {
                        state.choose(node: node)
                    } label: {
                        Label("Use", systemImage: "checkmark.circle")
                    }
                }
                Button {
                    state.chooseAuto()
                } label: {
                    Label("Auto", systemImage: "wand.and.stars")
                }
            }

            if let node {
                VStack(spacing: 8) {
                    InfoRow(label: "Name", value: node.displayName)
                    InfoRow(label: "Endpoint", value: node.endpoint)
                    InfoRow(label: "Network", value: node.network.uppercased())
                    InfoRow(label: "TLS SNI", value: node.sni ?? "-")
                    InfoRow(label: "Host", value: node.host ?? "-")
                    InfoRow(label: "Path", value: node.path ?? "-")
                }
                .textSelection(.enabled)
            } else {
                Text("Select a node in the sidebar to inspect it.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct InfoRow: View {
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
    }
}

private struct LogPanel: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Log")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button {
                    state.openSupportFolder()
                } label: {
                    Label("Folder", systemImage: "folder")
                }
            }

            ScrollView([.horizontal, .vertical]) {
                Text(state.singBoxManager.logTail.isEmpty ? "No sing-box output yet." : state.singBoxManager.logTail)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .frame(minHeight: 140, maxHeight: 220)
            .background(Color(nsColor: .textBackgroundColor).opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

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
