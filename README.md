# Cloudflare Node Switch

[English](README.md) | [中文](README_CN.md)

A macOS SwiftUI application for managing VLESS subscription nodes with intelligent latency-based auto-selection.

![Screenshot](docs/screenshot.png)

## How It Works — Auto Selection Flow

The core feature is **automatic node optimization** — the app continuously tests all available Cloudflare edge nodes and routes your traffic through the fastest one in real-time.

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Cloudflare Node Switch                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐     ┌──────────────┐     ┌───────────────┐       │
│  │ Subscription  │────▶│  Parse VLESS │────▶│  Node Pool    │       │
│  │     URL       │     │    Links     │     │  (N nodes)    │       │
│  └──────────────┘     └──────────────┘     └───────┬───────┘       │
│                                                     │               │
│                                                     ▼               │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                     sing-box urltest                         │    │
│  │                                                              │    │
│  │  ┌────────┐  ┌────────┐  ┌────────┐         ┌────────┐     │    │
│  │  │ Node 1 │  │ Node 2 │  │ Node 3 │   ···   │ Node N │     │    │
│  │  │  55ms  │  │ 120ms  │  │  89ms  │         │ 200ms  │     │    │
│  │  │   ✓    │  │        │  │        │         │        │     │    │
│  │  └───┬────┘  └────────┘  └────────┘         └────────┘     │    │
│  │      │                                                      │    │
│  │      └──────────────────┬───────────────────────────────────┘    │
│  │                         ▼                                        │    │
│  │                 ┌───────────────┐                                │    │
│  │                 │   Pick Best   │◀── TCP latency test (1 min)   │    │
│  │                 │    Node       │◀── tolerance: 50ms            │    │
│  │                 └───────┬───────┘                                │    │
│  └─────────────────────────┼───────────────────────────────────────┘    │
│                            ▼                                            │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                    127.0.0.1:7890                                │    │
│  │              Mixed HTTP / SOCKS5 Proxy                           │    │
│  └─────────────────────────┬───────────────────────────────────────┘    │
│                            ▼                                            │
│                ┌───────────────────┐                                    │
│                │    System Proxy   │                                    │
│                │    + Developer    │                                    │
│                │    Terminals      │                                    │
│                └───────────────────┘                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### Selection Algorithm

1. **Fetch Subscription** — Decode Base64 subscription response containing `vless://` links
2. **Build Node Pool** — Parse all available Cloudflare edge nodes from the subscription
3. **Latency Testing** — TCP handshake to measure real connection time for each node
4. **Auto Selection** — sing-box `urltest` continuously monitors and picks the fastest node
5. **Failover** — If the current node fails, automatically switches to the next best option
6. **Real-time Monitoring** — Clash API tracks the active node, UI updates every 3 seconds

### Why This Works Well for Cloudflare

- **Edge Network** — Cloudflare has 300+ edge locations worldwide
- **Random Assignment** — Nodes are dynamically assigned, latency varies by time of day
- **Continuous Testing** — urltest runs every minute with 50ms tolerance threshold
- **Smart Routing** — Picks the optimal node based on your actual network conditions

## Features

- **VLESS Subscription Management**: Parse and manage VLESS subscription links
- **Intelligent Node Selection**: Automatic latency-based node selection using sing-box's urltest
- **Real-time Latency Testing**: TCP latency measurement for quick node sorting
- **System Integration**: Seamless macOS system proxy configuration
- **Developer Tools**: Proxy-aware terminal integration for development workflows
- **Clean UI**: Native SwiftUI interface with sidebar node list and detailed configuration

## Requirements

- macOS 14 or newer
- Swift toolchain / Xcode command line tools
- sing-box installed on the host

Install sing-box with Homebrew:

```sh
brew install sing-box
```

## Installation

### Build from Source

```sh
git clone https://github.com/hilalum/CloudflareNodeSwitch.git
cd CloudflareNodeSwitch
swift build
```

### Create App Bundle

```sh
script/package_app.sh
open "$HOME/Applications/Cloudflare Node Switch.app"
```

## Usage

1. Launch the application
2. Paste your VLESS subscription URL in the settings panel
3. Click "Refresh" to load available nodes
4. Click "Start" to launch the proxy service
5. Enable system proxy integration for automatic configuration

### Keyboard Shortcuts

- `Cmd+R`: Refresh subscription
- `Cmd+Shift+S`: Start/Stop proxy
- `Space`: Start/Stop proxy (when window is focused)

### Developer Integration

The application provides proxy-aware terminal integration for development tools:

- **Terminal**: Open a new terminal with proxy environment variables
- **Codex**: Launch Codex with proxy configuration
- **Claude**: Launch Claude Code with proxy settings

## Configuration

Generated configuration and logs are stored in:

```
~/Library/Application Support/CloudflareNodeSwitch/
```

### Proxy Settings

- **Default Port**: 7890 (configurable)
- **Protocol**: Mixed HTTP/HTTPS/SOCKS5 proxy
- **Auto-detection**: Interface auto-detection enabled

### Node Selection Modes

- **Auto Mode**: Automatic selection based on latency testing
- **Manual Mode**: Fixed node selection for specific requirements

## Architecture

The application follows a clean MVVM architecture:

- **AppState**: Central state management with Combine publishers
- **Views**: SwiftUI components for the user interface
- **Services**: Business logic for subscription parsing, config generation, and system integration
- **Models**: Data structures for proxy nodes and configuration

### Key Components

- `SubscriptionService`: Fetches and parses VLESS subscription data
- `SingBoxConfigBuilder`: Generates sing-box configuration from nodes
- `SystemProxyManager`: Manages macOS system proxy settings
- `DeveloperProxyManager`: Handles terminal proxy integration

## Development

### Prerequisites

- Xcode 15.0+
- macOS 14.0+ SDK

### Building

```sh
swift build
```

### Testing

```sh
swift test
```

### Creating Release

```sh
script/package_app.sh
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Disclaimer

This software is provided "as is", without warranty of any kind. The author is not responsible for any misuse of this software. Users are responsible for ensuring compliance with all applicable laws and regulations.

## Acknowledgments

- [sing-box](https://sing-box.sagernet.org/) - The universal proxy platform
- [VLESS Protocol](https://www.v2fly.org/en_US/v5/config/transport/vless.html) - The proxy protocol implementation
- SwiftUI - Apple's declarative UI framework
