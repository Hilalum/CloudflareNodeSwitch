import SwiftUI

struct SidebarView: View {
    @ObservedObject var state: AppState
    @Binding var selectedNodeID: ProxyNode.ID?

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: state.isProxyRunning ? "bolt.horizontal.fill" : "bolt.horizontal")
                        .foregroundStyle(state.isProxyRunning ? .green : .secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.isProxyRunning ? "Running" : "Stopped")
                            .font(.headline)
                        Text(state.isProxyRunning ? state.currentNodeName : state.modeDisplayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }

                Button {
                    state.chooseAuto()
                } label: {
                    Label("Auto Select", systemImage: state.mode == .auto ? "checkmark.circle.fill" : "circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Divider()

            List(selection: $selectedNodeID) {
                Section("Nodes") {
                    ForEach(state.sortedNodes) { node in
                        NodeRow(
                            node: node,
                            latency: state.latencies[node.id, default: .unknown],
                            isSelectedForProxy: isSelectedForProxy(node),
                            isActive: state.activeNodeID == node.id
                        )
                            .tag(node.id)
                            .contextMenu {
                                Button("Use This Node") {
                                    state.choose(node: node)
                                }
                            }
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .background(.bar)
    }

    private func isSelectedForProxy(_ node: ProxyNode) -> Bool {
        if case .manual(let id) = state.mode {
            return id == node.id
        }
        return false
    }
}

private struct NodeRow: View {
    let node: ProxyNode
    let latency: NodeLatency
    let isSelectedForProxy: Bool
    let isActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: leadingSymbol)
                .foregroundStyle(isActive || isSelectedForProxy ? .green : .secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(node.displayName)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                    if isActive {
                        Text("Active")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.green.opacity(0.13))
                            .clipShape(Capsule())
                    }
                }
                Text(node.endpoint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(latency.label)
                .font(.caption)
                .foregroundStyle(latencyColor)
                .monospacedDigit()
                .frame(width: 62, alignment: .trailing)
        }
        .padding(.vertical, 3)
    }

    private var leadingSymbol: String {
        if isActive {
            return "largecircle.fill.circle"
        }
        if isSelectedForProxy {
            return "checkmark.circle.fill"
        }
        return "server.rack"
    }

    private var latencyColor: Color {
        switch latency {
        case .alive(let milliseconds):
            return milliseconds < 300 ? .green : .orange
        case .failed:
            return .red
        case .testing:
            return .blue
        case .unknown:
            return .secondary
        }
    }
}
