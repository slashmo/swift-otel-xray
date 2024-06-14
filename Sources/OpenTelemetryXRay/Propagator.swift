//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2021 Moritz Lang and the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Instrumentation
@_exported import OTel

/// An `OTelPropagator` that propagates span context through the `X-Amzn-Trace-Id` header.
///
/// - SeeAlso: [AWS X-Ray: Tracing Header](https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-tracingheader)
public struct XRayPropagator: OTelPropagator {
    private static let tracingHeader = "X-Amzn-Trace-Id"

    /// Initialize an X-Ray compatible propagator.
    public init() {}

    public func inject<Carrier, Inject>(
        _ spanContext: OTelSpanContext,
        into carrier: inout Carrier,
        using injector: Inject
    ) where Inject: Injector, Carrier == Inject.Carrier {
        let traceIDBytes = spanContext.traceID.hexBytes
        let timestampBytes = traceIDBytes[0 ..< 8]
        let randomBytes = traceIDBytes[8...]

        let tracingHeader = [
            "Root=1-\(String(decoding: timestampBytes, as: UTF8.self))-\(String(decoding: randomBytes, as: UTF8.self))",
            "Parent=\(spanContext.spanID)",
            "Sampled=\(spanContext.traceFlags.contains(.sampled) ? "1" : "0")",
        ].joined(separator: ";")

        injector.inject(tracingHeader, forKey: Self.tracingHeader, into: &carrier)
    }

    public func extractSpanContext<Carrier, Extract>(
        from carrier: Carrier,
        using extractor: Extract
    ) throws -> OTelSpanContext? where Extract: Extractor, Carrier == Extract.Carrier {
        guard let tracingHeader = extractor.extract(key: Self.tracingHeader, from: carrier) else {
            return nil
        }

        var extractedTraceID: OTelTraceID?
        var spanID: OTelSpanID?
        var extractedTraceFlags: OTelTraceFlags?

        let parts = tracingHeader.split(separator: ";")
        var iterator = parts.makeIterator()

        while let part = iterator.next() {
            if part.starts(with: "Root=") {
                let startIndex = part.index(part.startIndex, offsetBy: 5)
                extractedTraceID = try extractTraceID(part[startIndex...])
            } else if part.starts(with: "Parent=") {
                let startIndex = part.index(part.startIndex, offsetBy: 7)
                spanID = try extractSpanID(part[startIndex...])
            } else if part.starts(with: "Sampled=") {
                let startIndex = part.index(part.startIndex, offsetBy: 8)
                let sampledString = part[startIndex...]
                extractedTraceFlags = sampledString == "1" ? .sampled : []
            }
        }

        guard let traceID = extractedTraceID else {
            throw TraceHeaderParsingError(value: tracingHeader, reason: .missingTraceID)
        }

        return OTelSpanContext(
            traceID: traceID,
            spanID: spanID ?? OTelSpanID(bytes: (0, 0, 0, 0, 0, 0, 0, 0)),
            parentSpanID: nil,
            traceFlags: extractedTraceFlags ?? [],
            traceState: nil,
            isRemote: true
        )
    }

    private func extractTraceID(_ string: some StringProtocol) throws -> OTelTraceID {
        let result = try string.utf8.withContiguousStorageIfAvailable { traceIDBytes -> OTelTraceID in
            guard traceIDBytes.count == 35 else {
                throw TraceHeaderParsingError(value: String(string), reason: .invalidTraceIDLength(string.count))
            }

            guard traceIDBytes[0] == UInt8(ascii: "1") else {
                throw TraceHeaderParsingError(
                    value: String(string),
                    reason: .unsupportedTraceIDVersion(String(string[string.startIndex]))
                )
            }

            guard traceIDBytes[1] == UInt8(ascii: "-"), traceIDBytes[10] == UInt8(ascii: "-") else {
                throw TraceHeaderParsingError(value: String(string), reason: .invalidTraceIDDelimiters)
            }

            var traceIDStorage: OTelTraceID.Bytes = (
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            )
            withUnsafeMutableBytes(of: &traceIDStorage) { ptr in
                let timestampRegion = UnsafeMutableRawBufferPointer(rebasing: ptr[0 ..< 4])
                let randomRegion = UnsafeMutableRawBufferPointer(rebasing: ptr[4...])
                Hex.convert(traceIDBytes[2 ..< 10], toBytes: timestampRegion)
                Hex.convert(traceIDBytes[11 ..< 35], toBytes: randomRegion)
            }

            return OTelTraceID(bytes: traceIDStorage)
        }
        return try result ?? extractTraceID(String(string))
    }

    private func extractSpanID(_ string: some StringProtocol) throws -> OTelSpanID {
        let result = try string.utf8.withContiguousStorageIfAvailable { spanIDBytes -> OTelSpanID in
            guard spanIDBytes.count == 16 else {
                throw TraceHeaderParsingError(value: String(string), reason: .invalidSpanIDLength(spanIDBytes.count))
            }

            var bytes: OTelSpanID.Bytes = (0, 0, 0, 0, 0, 0, 0, 0)
            withUnsafeMutableBytes(of: &bytes) { ptr in
                Hex.convert(spanIDBytes, toBytes: ptr)
            }
            return OTelSpanID(bytes: bytes)
        }
        return try result ?? extractSpanID(String(string))
    }
}

extension XRayPropagator {
    public struct TraceHeaderParsingError: Error, Equatable {
        public let value: String
        public let reason: Reason
    }
}

extension XRayPropagator.TraceHeaderParsingError {
    public enum Reason: Equatable, Sendable {
        case missingTraceID
        case invalidTraceIDLength(Int)
        case unsupportedTraceIDVersion(String)
        case invalidTraceIDDelimiters

        case invalidSpanIDLength(Int)
    }
}
