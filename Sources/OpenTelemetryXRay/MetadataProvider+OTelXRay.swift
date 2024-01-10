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

import Logging
import ServiceContextModule

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Logger.MetadataProvider {
    /// A metadata provider exposing the current trace and span ID using X-Ray specific formatting.
    ///
    /// - Parameters:
    ///   - traceIDKey: The metadata key of the trace ID. Defaults to "trace-id".
    ///   - spanIDKey: The metadata key of the span ID. Defaults to "span-id".
    /// - Returns: A metadata provider ready to use with Logging.
    public static func otelXRay(traceIDKey: String = "trace-id", spanIDKey: String = "span-id") -> Logger.MetadataProvider {
        .init {
            guard let spanContext = ServiceContext.current?.spanContext else { return [:] }

            let traceIDBytes = spanContext.traceID.hexBytes
            let timestampBytes = traceIDBytes[0 ..< 8]
            let randomBytes = traceIDBytes[8...]

            return [
                traceIDKey: "1-\(String(decoding: timestampBytes, as: UTF8.self))-\(String(decoding: randomBytes, as: UTF8.self))",
                spanIDKey: "\(spanContext.spanID)",
            ]
        }
    }

    /// A metadata provider exposing the current trace and span ID using X-Ray specific formatting.
    public static let otelXRay = Logger.MetadataProvider.otelXRay()
}
