# Cloudflare Node Switch

A macOS SwiftUI application for intelligent network node management with automatic latency-based selection.

![Screenshot](docs/screenshot.png)

## How It Works — Auto Selection Flow

The core feature is **automatic node optimization** — the app continuously tests all available Cloudflare edge nodes and routes your traffic through the fastest one in real-time.

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Cloudflare Node Switch                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐     ┌──────────────┐     ┌───────────────┐       │
│  │   Remote     │────▶│   Parse &    │────▶│  Node Pool    │       │
│  │   Config     │     │   Decode     │     │  (N nodes)    │       │
│  └──────────────┘     └──────────────┘     └───────┬───────┘       │
│                                                     │               │
│                                                     ▼               │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                   Latency Auto-Test                         │    │
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
│  │                   Local Network Gateway                         │    │
│  └─────────────────────────┬───────────────────────────────────────┘    │
│                            ▼                                            │
│                ┌───────────────────┐                                    │
│                │    System Network │                                    │
│                │    + Developer    │                                    │
│                │    Terminals      │                                    │
│                └───────────────────┘                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### Selection Algorithm

1. **Fetch Config** — Retrieve and decode remote configuration data
2. **Build Node Pool** — Parse all available Cloudflare edge nodes
3. **Latency Testing** — TCP handshake to measure real connection time for each node
4. **Auto Selection** — Continuously monitors and picks the fastest node
5. **Failover** — If the current node fails, automatically switches to the next best option
6. **Real-time Monitoring** — Tracks the active node, UI updates every 3 seconds

### Why This Works Well for Cloudflare

- **Edge Network** — Cloudflare has 300+ edge locations worldwide
- **Random Assignment** — Nodes are dynamically assigned, latency varies by time of day
- **Continuous Testing** — Auto-test runs every minute with 50ms tolerance threshold
- **Smart Routing** — Picks the optimal node based on your actual network conditions

## Features

- **Node Management**: Parse and manage network node configurations
- **Intelligent Selection**: Automatic latency-based node selection
- **Real-time Latency Testing**: TCP latency measurement for quick node sorting
- **System Integration**: Seamless macOS network configuration
- **Developer Tools**: Network-aware terminal integration for development workflows
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
2. Paste your configuration URL in the settings panel
3. Click "Refresh" to load available nodes
4. Click "Start" to launch the service
5. Enable system network integration for automatic configuration

### Keyboard Shortcuts

- `Cmd+R`: Refresh configuration
- `Cmd+Shift+S`: Start/Stop service
- `Space`: Start/Stop service (when window is focused)

### Developer Integration

The application provides network-aware terminal integration for development tools:

- **Terminal**: Open a new terminal with network environment variables
- **Codex**: Launch Codex with network configuration
- **Claude**: Launch Claude Code with network settings

## Configuration

Generated configuration and logs are stored in:

```
~/Library/Application Support/CloudflareNodeSwitch/
```

### Network Settings

- **Default Port**: 7890 (configurable)
- **Protocol**: Mixed HTTP/HTTPS/SOCKS5
- **Auto-detection**: Interface auto-detection enabled

### Node Selection Modes

- **Auto Mode**: Automatic selection based on latency testing
- **Manual Mode**: Fixed node selection for specific requirements

## Architecture

The application follows a clean MVVM architecture:

- **AppState**: Central state management with Combine publishers
- **Views**: SwiftUI components for the user interface
- **Services**: Business logic for config parsing, generation, and system integration
- **Models**: Data structures for nodes and configuration

### Key Components

- `SubscriptionService`: Fetches and parses remote configuration data
- `SingBoxConfigBuilder`: Generates configuration from nodes
- `SystemProxyManager`: Manages macOS network settings
- `DeveloperProxyManager`: Handles terminal network integration

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

- [sing-box](https://sing-box.sagernet.org/) - The universal network toolkit
- SwiftUI - Apple's declarative UI framework
