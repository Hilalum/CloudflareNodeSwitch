import SwiftUI

struct SidebarView: View {
    @ObservedObject var state: AppState
    @Binding var selectedNodeID: ProxyNode.ID?

    var body: some View {
        VStack(spacing: 0) {
            // 顶部状态区
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(state.isProxyRunning ?
                                  LinearGradient(colors: [.green.opacity(0.2), .green.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [.secondary.opacity(0.15), .secondary.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 40, height: 40)

                        Image(systemName: state.isProxyRunning ? "bolt.horizontal.fill" : "bolt.horizontal")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(state.isProxyRunning ? .green : .secondary)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(state.isProxyRunning ? LocalizedString.running : LocalizedString.stopped)
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(state.isProxyRunning ? state.currentNodeName : state.modeDisplayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }

                // 自动选择按钮
                Button {
                    state.chooseAuto()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: state.mode == .auto ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                            .foregroundStyle(state.mode == .auto ? .blue : .secondary)
                        Text(LocalizedString.autoSelect)
                            .font(.body.weight(.medium))
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(state.mode == .auto ? Color.blue.opacity(0.08) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider()

            // 国家筛选器
            if !state.availableCountries.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        CountryTag(
                            label: LocalizedString.allCountries,
                            icon: "globe",
                            isSelected: state.selectedCountry == nil
                        ) {
                            state.selectedCountry = nil
                        }

                        ForEach(state.availableCountries, id: \.self) { code in
                            CountryTag(
                                label: "\(CountryUtils.flag(for: code)) \(code)",
                                icon: nil,
                                isSelected: state.selectedCountry == code
                            ) {
                                state.selectedCountry = code
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                Divider()
            }

            // 节点列表
            List(selection: $selectedNodeID) {
                Section {
                    ForEach(state.sortedNodes) { node in
                        NodeRow(
                            node: node,
                            pathLatency: state.latencies[node.id, default: .unknown],
                            tcpLatency: state.tcpLatencies[node.id, default: .unknown],
                            isSelectedForProxy: isSelectedForProxy(node),
                            isActive: state.activeNodeID == node.id
                        )
                        .tag(node.id)
                        .contextMenu {
                            Button(LocalizedString.useThisNode) {
                                state.choose(node: node)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(LocalizedString.nodes)
                        Spacer()
                        Text("\(state.filteredNodes.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.1))
                            .clipShape(Capsule())
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

// MARK: - Country Tag

private struct CountryTag: View {
    let label: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(label)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.08))
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Node Row

private struct NodeRow: View {
    let node: ProxyNode
    let pathLatency: NodeLatency
    let tcpLatency: NodeLatency
    let isSelectedForProxy: Bool
    let isActive: Bool

    var body: some View {
        HStack(spacing: 0) {
            // 左侧活跃指示条
            if isActive {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.green)
                    .frame(width: 3)
                    .padding(.trailing, 8)
            } else {
                Spacer().frame(width: 11)
            }

            // 状态图标
            Image(systemName: leadingSymbol)
                .font(.system(size: 13))
                .foregroundStyle(isActive ? .green : isSelectedForProxy ? .blue : .secondary)
                .frame(width: 20)

            // 节点信息
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    if !node.countryFlag.isEmpty {
                        Text(node.countryFlag)
                            .font(.system(size: 12))
                    }

                    Text(node.displayName)
                        .font(.body.weight(.medium))
                        .lineLimit(1)

                    if isActive {
                        Text(LocalizedString.active)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(.green)
                            )
                    }
                }

                HStack(spacing: 4) {
                    Text(node.endpoint)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if let country = node.country {
                        Text("·")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(CountryUtils.name(for: country))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                latencyLabel(LocalizedString.path, latency: pathLatency)
                latencyLabel(LocalizedString.tcp, latency: tcpLatency)
            }
            .frame(width: 92, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.green.opacity(0.06) : Color.clear)
        )
    }

    private var leadingSymbol: String {
        if isActive { return "largecircle.fill.circle" }
        if isSelectedForProxy { return "checkmark.circle.fill" }
        return "server.rack"
    }

    private func latencyColor(for latency: NodeLatency) -> Color {
        switch latency {
        case .alive(let ms):
            return ms < 150 ? .green : ms < 300 ? .orange : .red
        case .failed:
            return .red
        case .testing:
            return .blue
        case .unknown:
            return .secondary
        }
    }

    @ViewBuilder
    private func latencyLabel(_ title: String, latency: NodeLatency) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .foregroundStyle(.tertiary)
            Text(latency.label)
                .foregroundStyle(latencyColor(for: latency))
        }
        .font(.caption2.monospacedDigit())
    }
}
