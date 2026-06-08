# Cloudflare Node Switch

A macOS SwiftUI application for managing VLESS subscription nodes with intelligent latency-based auto-selection.

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