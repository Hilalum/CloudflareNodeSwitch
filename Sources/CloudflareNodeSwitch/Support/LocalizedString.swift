import Foundation

/// 集中管理所有 UI 文本的中英文翻译
enum LocalizedString {
    static var isChinese: Bool {
        let rawValue = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.system.rawValue
        switch AppLanguage(rawValue: rawValue) ?? .system {
        case .chineseSimplified:
            return true
        case .english:
            return false
        case .system:
            return Locale.preferredLanguages.first?.lowercased().hasPrefix("zh") == true
        }
    }

    // MARK: - App

    static var appTitle: String { localized("Cloudflare Node Switch", "Cloudflare 节点切换") }

    // MARK: - Sidebar

    static var running: String { localized("Running", "运行中") }
    static var stopped: String { localized("Stopped", "已停止") }
    static var autoSelect: String { localized("Auto Select", "自动选择") }
    static var nodes: String { localized("Nodes", "节点") }
    static var useThisNode: String { localized("Use This Node", "使用此节点") }
    static var active: String { localized("Active", "活跃") }

    // MARK: - Header

    static var refresh: String { localized("Refresh", "刷新") }
    static var test: String { localized("Test", "测试") }
    static var start: String { localized("Start", "启动") }
    static var stop: String { localized("Stop", "停止") }

    // MARK: - Status

    static var proxy: String { localized("Proxy", "代理") }
    static var mode: String { localized("Mode", "模式") }
    static var current: String { localized("Current", "当前") }
    static var nodeCount: String { localized("Node Count", "节点数") }
    static var system: String { localized("System", "系统") }
    static var developer: String { localized("Developer", "开发者") }
    static var on: String { localized("On", "开") }
    static var off: String { localized("Off", "关") }
    static var auto: String { localized("Auto", "自动") }
    static var manual: String { localized("Manual", "手动") }
    static var detecting: String { localized("Detecting", "检测中") }

    // MARK: - Settings

    static var settings: String { localized("Settings", "设置") }
    static var subscription: String { localized("Subscription", "订阅") }
    static var subscriptionURL: String { localized("Subscription URL", "订阅链接") }
    static var localPort: String { localized("Local Port", "本地端口") }
    static var language: String { localized("Language", "语言") }
    static var routing: String { localized("Routing", "路由") }
    static var integration: String { localized("Integration", "集成") }
    static var inbound: String { localized("Inbound", "入站") }
    static var blankUsesPath: String { localized("Blank uses PATH", "留空使用系统 PATH") }

    // MARK: - Inbound Mode

    static var mixedMode: String { localized("Mixed", "混合") }
    static var mixedDetail: String { localized("HTTP + SOCKS5 proxy", "HTTP + SOCKS5 代理") }
    static var tunMode: String { localized("TUN", "TUN") }
    static var tunDetail: String { localized("Full traffic tunnel (needs root)", "全流量隧道（需要管理员权限）") }

    // MARK: - Routing Modes

    static var globalTitle: String { localized("Global", "全局") }
    static var globalDetail: String { localized("Only LAN/private addresses are direct", "仅局域网/私有地址直连") }
    static var smartCNTitle: String { localized("Smart CN", "智能中国") }
    static var smartCNDetail: String { localized("CN/local traffic direct, others proxy", "国内/本地流量直连，其余代理") }
    static var aiStableTitle: String { localized("AI Stable", "AI 稳定") }
    static var aiStableDetail: String { localized("AI/GitHub/Google proxy first, CN direct", "AI/GitHub/Google 优先代理，国内直连") }

    // MARK: - Node Detail

    static var node: String { localized("Node", "节点") }
    static var use: String { localized("Use", "使用") }
    static var name: String { localized("Name", "名称") }
    static var endpoint: String { localized("Endpoint", "端点") }
    static var network: String { localized("Network", "网络") }
    static var tlsSNI: String { localized("TLS SNI", "TLS SNI") }
    static var host: String { localized("Host", "主机") }
    static var path: String { localized("Path", "路径") }
    static var country: String { localized("Country", "国家") }
    static var selectNodeHint: String { localized("Select a node in the sidebar to inspect it.", "在侧边栏选择一个节点查看详情。") }

    // MARK: - Log

    static var log: String { localized("Log", "日志") }
    static var folder: String { localized("Folder", "文件夹") }
    static var noSingBoxOutput: String { localized("No sing-box output yet.", "暂无 sing-box 输出。") }

    // MARK: - Menu Bar

    static var openWindow: String { localized("Open Window", "打开窗口") }
    static var startProxy: String { localized("Start Proxy", "启动代理") }
    static var stopProxy: String { localized("Stop Proxy", "停止代理") }
    static var refreshSubscription: String { localized("Refresh Subscription", "刷新订阅") }
    static var testLatency: String { localized("Test Latency", "测试延迟") }
    static var tcp: String { "TCP" }
    static var openProxied: String { localized("Open Proxied", "打开代理终端") }
    static var terminal: String { localized("Terminal", "终端") }
    static var quit: String { localized("Quit", "退出") }

    // MARK: - Status Messages

    static var pasteSubscriptionHint: String { localized("Paste a subscription URL, then refresh.", "粘贴订阅链接，然后刷新。") }
    static var subscriptionEmpty: String { localized("Subscription URL is empty.", "订阅链接为空。") }
    static var refreshingSubscription: String { localized("Refreshing subscription...", "正在刷新订阅...") }
    static var loadedNodes: String { localized("Loaded %d nodes.", "已加载 %d 个节点。") }
    static var refreshFailed: String { localized("Refresh failed: %@", "刷新失败：%@") }
    static var noNodesToTest: String { localized("No nodes to test.", "没有可测试的节点。") }
    static var testingTCPLatency: String { localized("Testing TCP latency...", "正在测试 TCP 延迟...") }
    static var bestTCPLatency: String { localized("Best TCP latency: %@", "最佳 TCP 延迟：%@") }
    static var latencyTestFinished: String { localized("Latency test finished; no reachable node found.", "延迟测试完成；未找到可达节点。") }
    static var modeSetToAuto: String { localized("Mode set to auto.", "已切换为自动模式。") }
    static var selectedNode: String { localized("Selected %@.", "已选择 %@。") }
    static var noNodesLoaded: String { localized("No nodes loaded.", "未加载节点。") }
    static var proxyStarted: String { localized("Proxy started.", "代理已启动。") }
    static var proxyRestarted: String { localized("Proxy restarted.", "代理已重启。") }
    static var proxyStopped: String { localized("Proxy stopped.", "代理已停止。") }
    static var startFailed: String { localized("Start failed: %@", "启动失败：%@") }
    static var restartFailed: String { localized("Restart failed: %@", "重启失败：%@") }
    static var startProxyFirst: String { localized("Start the proxy before enabling integration.", "请先启动代理再开启集成。") }
    static var integrationAutoOn: String { localized("Turns on automatically after Start", "启动后自动开启") }
    static var integrationWillStayOff: String { localized("Will stay off after Start", "启动后保持关闭") }
    static var integrationActive: String { localized("System and developer proxy are active", "系统和开发者代理已激活") }
    static var systemProxyOff: String { localized("System proxy is off", "系统代理已关闭") }
    static var developerProxyOff: String { localized("Developer proxy is off", "开发者代理已关闭") }
    static var integratedProxyEnabled: String { localized("Integrated proxy enabled for system apps and new shells.", "系统代理和新终端已启用。") }
    static var integratedProxyDisabled: String { localized("Integrated proxy disabled.", "已关闭集成代理。") }
    static var integrationFailed: String { localized("Integration failed: %@", "集成失败：%@") }
    static var systemProxyEnabled: String { localized("System proxy enabled.", "系统代理已开启。") }
    static var systemProxyDisabled: String { localized("System proxy disabled.", "系统代理已关闭。") }
    static var systemProxyFailed: String { localized("System proxy failed: %@", "系统代理失败：%@") }
    static var disableIntegrationFailed: String { localized("Disable integration failed: %@", "关闭集成失败：%@") }
    static var openTerminalFirst: String { localized("Start the proxy before opening a proxied terminal.", "请先启动代理再打开代理终端。") }
    static var openedProxiedTerminal: String { localized("Opened a proxied Terminal.", "已打开代理终端。") }
    static var openedCommandWithProxy: String { localized("Opened %@ with proxy.", "已打开 %@（代理）。") }
    static var openTerminalFailed: String { localized("Open terminal failed: %@", "打开终端失败：%@") }
    static var noNodesAvailable: String { localized("No nodes are available for sing-box config generation.", "没有可用节点来生成 sing-box 配置。") }
    static var selectedNodeMissing: String { localized("The selected node is no longer available.", "所选节点不再可用。") }
    static var noSupportedNodes: String { localized("No supported VLESS nodes were found in the subscription.", "订阅中未找到支持的 VLESS 节点。") }

    // MARK: - Country Filter

    static var allCountries: String { localized("All", "全部") }

    // MARK: - sing-box Manager

    static var singBoxNotFound: String { localized("sing-box was not found. Install it with: brew install sing-box", "未找到 sing-box。请运行: brew install sing-box") }
    static var singBoxExited: String { localized("sing-box exited with code %d.", "sing-box 已退出，状态码 %d。") }
    static var singBoxStarted: String { localized("Started sing-box: %@", "已启动 sing-box: %@") }
    static var nodeFallback: String { localized("Node %d", "节点 %d") }

    // MARK: - Developer Proxy

    static var failedOpenTerminal: String { localized("Failed to open Terminal.", "打开终端失败。") }
    static var proxyActiveInTerminal: String { localized("Cloudflare Node Switch proxy is active for this Terminal.", "Cloudflare Node Switch 代理已在此终端激活。") }
    static var commandNotFoundProxyActive: String { localized("%@ was not found in PATH. Proxy variables are active in this Terminal.", "未在 PATH 中找到 %@。代理变量已在此终端激活。") }
    static var launchctlFailed: String { localized("launchctl failed.", "launchctl 失败。") }

    // MARK: - Private

    private static func localized(_ en: String, _ zh: String) -> String {
        isChinese ? zh : en
    }
}
