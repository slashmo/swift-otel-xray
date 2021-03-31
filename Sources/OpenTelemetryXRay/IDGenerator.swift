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
@_exported import OpenTelemetry

/// Generates trace and span ids using a `RandomNumberGenerator` in an X-Ray compatible format.
///
/// - SeeAlso: [AWS X-Ray: Tracing header](https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-tracingheader)
public struct XRayIDGenerator: OTelIDGenerator {
    private let getCurrentSecondsSinceEpoch: () -> UInt32
    private var randomNumberGenerator: RandomNumberGenerator

    /// Initialize an X-Ray compatible `OTelIDGenerator` backed by the given `RandomNumberGenerator`.
    ///
    /// - Parameter randomNumberGenerator: The `RandomNumberGenerator` to use, defaults to a `SystemRandomNumberGenerator`.
    public init(randomNumberGenerator: RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.init(
            randomNumberGenerator: randomNumberGenerator,
            getCurrentSecondsSinceEpoch: {
                DispatchWallTime.now().secondsSinceEpoch
            }
        )
    }

    init(randomNumberGenerator: RandomNumberGenerator, getCurrentSecondsSinceEpoch: @escaping () -> UInt32) {
        self.randomNumberGenerator = randomNumberGenerator
        self.getCurrentSecondsSinceEpoch = getCurrentSecondsSinceEpoch
    }

    public mutating func generateTraceID() -> OTel.TraceID {
        var traceIDBytes: OTel.TraceID.Bytes = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        withUnsafeMutableBytes(of: &traceIDBytes) { ptr in
            ptr.storeBytes(of: self.getCurrentSecondsSinceEpoch().bigEndian, as: UInt32.self)
            ptr.storeBytes(
                of: randomNumberGenerator.next(upperBound: UInt32.max).bigEndian,
                toByteOffset: 4,
                as: UInt32.self
            )
            ptr.storeBytes(
                of: randomNumberGenerator.next(upperBound: UInt64.max).bigEndian,
                toByteOffset: 8,
                as: UInt64.self
            )
        }
        return OTel.TraceID(bytes: traceIDBytes)
    }

    public mutating func generateSpanID() -> OTel.SpanID {
        var spanIDBytes: OTel.SpanID.Bytes = (0, 0, 0, 0, 0, 0, 0, 0)
        withUnsafeMutableBytes(of: &spanIDBytes) { ptr in
            ptr.storeBytes(of: randomNumberGenerator.next().bigEndian, as: UInt64.self)
        }
        return OTel.SpanID(bytes: spanIDBytes)
    }
}

extension DispatchWallTime {
    fileprivate var secondsSinceEpoch: UInt32 {
        let seconds = Int64(bitPattern: self.rawValue) / -1_000_000_000
        return UInt32(seconds)
    }
}
