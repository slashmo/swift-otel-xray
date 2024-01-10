# X-Ray Support for OpenTelemetry Swift

[![CI](https://github.com/slashmo/opentelemetry-swift-xray/actions/workflows/ci.yml/badge.svg)](https://github.com/slashmo/opentelemetry-swift-xray/actions/workflows/ci.yml)
[![Swift support](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fslashmo%2Fswift-otel%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/slashmo/swift-otel-xray)
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
