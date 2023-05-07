# X-Ray Support for OpenTelemetry Swift

[![CI](https://github.com/slashmo/opentelemetry-swift-xray/actions/workflows/ci.yaml/badge.svg)](https://github.com/slashmo/opentelemetry-swift-xray/actions/workflows/ci.yaml)
[![Swift 5.7](https://img.shields.io/badge/Swift-5.7-%23f05137)](https://swift.org)
[![Made for Swift Distributed Tracing](https://img.shields.io/badge/Made%20for-Swift%20Distributed%20Tracing-%23f05137)](https://github.com/apple/swift-distributed-tracing)

This library adds support for [AWS X-Ray](https://aws.amazon.com/xray/) to [OpenTelemetry Swift](https://github.com/slashmo/opentelemetry-swift).

## Development

### Formatting

To ensure a consitent code style we use [SwiftFormat](https://github.com/nicklockwood/SwiftFormat).
To automatically run it before you push to GitHub, you may define a `pre-push` Git hook executing
the *soundness* script:

```sh
echo './scripts/soundness.sh' > .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```
