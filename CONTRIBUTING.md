# Contributing to Cloudflare Node Switch

Thank you for your interest in contributing to Cloudflare Node Switch! This document provides guidelines and information for contributors.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```sh
   git clone https://github.com/yourusername/CloudflareNodeSwitch.git
   cd CloudflareNodeSwitch
   ```
3. **Create a branch** for your changes:
   ```sh
   git checkout -b feature/your-feature-name
   ```

## Development Setup

### Prerequisites

- macOS 14.0 or newer
- Xcode 15.0+ or Swift toolchain
- sing-box installed via Homebrew

### Building the Project

```sh
swift build
```

### Running Tests

```sh
swift test
```

### Creating an App Bundle

```sh
script/package_app.sh
```

## Code Style

### Swift Code Guidelines

1. **Follow Swift API Design Guidelines**
   - Use clear, descriptive naming
   - Keep functions focused and concise
   - Document public APIs with doc comments

2. **Formatting**
   - Use 4 spaces for indentation
   - Keep lines under 120 characters when possible
   - Use `swiftformat` if available

3. **Architecture**
   - Maintain MVVM architecture pattern
   - Keep views lightweight and declarative
   - Use Combine for state management

### Commit Messages

- Use clear, descriptive commit messages
- Start with a verb in imperative mood (e.g., "Add", "Fix", "Update")
- Keep the subject line under 72 characters
- Reference issue numbers when applicable

Example:
```
Add latency sorting to node list

- Implement TCP latency measurement
- Add visual indicators for node status
- Update UI to show latency values

Closes #42
```

## Pull Request Process

1. **Ensure your code compiles** without errors
2. **Run all tests** to verify functionality
3. **Update documentation** if adding new features
4. **Submit your PR** with a clear description

### PR Template

```markdown
## Description

Brief description of changes

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring

## Testing

- [ ] All existing tests pass
- [ ] Added tests for new functionality
- [ ] Manual testing completed

## Checklist

- [ ] Code follows project style guidelines
- [ ] Documentation has been updated
- [ ] No breaking changes introduced
```

## Reporting Issues

### Bug Reports

When reporting bugs, please include:

1. **Environment details**
   - macOS version
   - sing-box version
   - Application version

2. **Steps to reproduce**
   - Clear, numbered steps
   - Expected vs actual behavior

3. **Logs and screenshots**
   - Application logs from `~/Library/Application Support/CloudflareNodeSwitch/`
   - Screenshots if applicable

### Feature Requests

For feature requests:

1. **Describe the use case** - Why is this feature needed?
2. **Proposed solution** - How should it work?
3. **Alternatives considered** - What other approaches did you consider?

## Code of Conduct

### Our Standards

- **Respectful communication** - Be kind and considerate
- **Collaborative approach** - Help others learn and grow
- **Focus on quality** - Write clean, maintainable code
- **Transparency** - Be open about limitations and trade-offs

### Unacceptable Behavior

- Harassment or discrimination
- Spam or off-topic content
- Malicious code or security vulnerabilities
- Violation of privacy or legal requirements

## License

By contributing to Cloudflare Node Switch, you agree that your contributions will be licensed under the MIT License.

## Questions?

If you have questions about contributing, please:

1. Check existing documentation and issues
2. Open a discussion issue for general questions
3. Contact the maintainers for sensitive matters

Thank you for contributing to Cloudflare Node Switch!