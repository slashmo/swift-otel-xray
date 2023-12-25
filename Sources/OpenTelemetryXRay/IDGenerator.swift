//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenTelemetry open source project
//
// Copyright (c) 2021 Moritz Lang and the Swift OpenTelemetry project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import struct Dispatch.DispatchWallTime
import NIOConcurrencyHelpers
@_exported import OTel

/// Generates trace and span ids using a `RandomNumberGenerator` in an X-Ray compatible format.
///
/// - SeeAlso: [AWS X-Ray: Tracing header](https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-tracingheader)
public struct XRayIDGenerator<NumberGenerator: RandomNumberGenerator & Sendable>: OTelIDGenerator {
    private let getCurrentSecondsSinceEpoch: @Sendable () -> UInt32
    private let randomNumberGenerator: NIOLockedValueBox<NumberGenerator>

    /// Initialize an X-Ray compatible `OTelIDGenerator` backed by the given `RandomNumberGenerator`.
    ///
    /// - Parameter randomNumberGenerator: The `RandomNumberGenerator` to use, defaults to a `SystemRandomNumberGenerator`.
    public init(randomNumberGenerator: NumberGenerator) {
        self.init(
            randomNumberGenerator: randomNumberGenerator,
            getCurrentSecondsSinceEpoch: {
                DispatchWallTime.now().secondsSinceEpoch
            }
        )
    }

    init(randomNumberGenerator: NumberGenerator, getCurrentSecondsSinceEpoch: @Sendable @escaping () -> UInt32) {
        self.randomNumberGenerator = .init(randomNumberGenerator)
        self.getCurrentSecondsSinceEpoch = getCurrentSecondsSinceEpoch
    }

    public func nextTraceID() -> OTelTraceID {
        var traceIDBytes: OTelTraceID.Bytes = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        withUnsafeMutableBytes(of: &traceIDBytes) { ptr in
            ptr.storeBytes(of: self.getCurrentSecondsSinceEpoch().bigEndian, as: UInt32.self)
            ptr.storeBytes(
                of: randomNumberGenerator.withLockedValue { $0.next(upperBound: UInt32.max) }.bigEndian,
                toByteOffset: 4,
                as: UInt32.self
            )
            ptr.storeBytes(
                of: randomNumberGenerator.withLockedValue { $0.next(upperBound: UInt64.max) }.bigEndian,
                toByteOffset: 8,
                as: UInt64.self
            )
        }
        return OTelTraceID(bytes: traceIDBytes)
    }

    public func nextSpanID() -> OTelSpanID {
        var spanIDBytes: OTelSpanID.Bytes = (0, 0, 0, 0, 0, 0, 0, 0)
        withUnsafeMutableBytes(of: &spanIDBytes) { ptr in
            ptr.storeBytes(of: randomNumberGenerator.withLockedValue { $0.next() }.bigEndian, as: UInt64.self)
        }
        return OTelSpanID(bytes: spanIDBytes)
    }
}

extension DispatchWallTime {
    fileprivate var secondsSinceEpoch: UInt32 {
        let seconds = Int64(bitPattern: self.rawValue) / -1_000_000_000
        return UInt32(seconds)
    }
}

extension XRayIDGenerator where NumberGenerator == SystemRandomNumberGenerator {
    public init() {
        self.init(randomNumberGenerator: SystemRandomNumberGenerator())
    }
}
