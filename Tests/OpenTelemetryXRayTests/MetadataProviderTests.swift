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

@testable import Logging
@testable import OpenTelemetry
@testable import OpenTelemetryXRay
import ServiceContextModule
import XCTest

final class MetadataProviderTests: XCTestCase {
    func test_providesMetadataFromSpanContext_withDefaultLabels() throws {
        guard #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) else {
            throw XCTSkip("Task locals are not supported on this platform.")
        }

        let stream = InterceptingStream()
        var logger = Logger(label: "test")
        logger.handler = StreamLogHandler(label: "test", stream: stream, metadataProvider: .otelXRay)

        var generator = XRayIDGenerator()

        let spanContext = OTel.SpanContext(
            traceID: generator.generateTraceID(),
            spanID: generator.generateSpanID(),
            traceFlags: .sampled,
            isRemote: true
        )

        var context = ServiceContext.topLevel
        context.spanContext = spanContext
        ServiceContext.$current.withValue(context) {
            logger.info("This is a test message", metadata: ["explicit": "42"])
        }

        XCTAssertEqual(stream.strings.count, 1)
        let message = try XCTUnwrap(stream.strings.first)

        let traceIDBytes = spanContext.traceID.hexBytes
        let timestampBytes = traceIDBytes[0 ..< 8]
        let randomBytes = traceIDBytes[8...]
        let expectedTraceId = "1-\(String(decoding: timestampBytes, as: UTF8.self))-\(String(decoding: randomBytes, as: UTF8.self))"

        XCTAssertTrue(message.contains("span-id=\(spanContext.spanID)"))
        XCTAssertTrue(message.contains("trace-id=\(expectedTraceId)"))
        XCTAssertTrue(message.contains("explicit=42"))
        XCTAssertTrue(message.contains("This is a test message"))
    }

    func test_providesMetadataFromSpanContext_withCustomLabels() throws {
        guard #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) else {
            throw XCTSkip("Task locals are not supported on this platform.")
        }

        let stream = InterceptingStream()
        var logger = Logger(label: "test")
        let metadataProvider = Logger.MetadataProvider.otelXRay(traceIDKey: "custom_trace_id", spanIDKey: "custom_span_id")
        logger.handler = StreamLogHandler(label: "test", stream: stream, metadataProvider: metadataProvider)

        var generator = XRayIDGenerator()

        let spanContext = OTel.SpanContext(
            traceID: generator.generateTraceID(),
            spanID: generator.generateSpanID(),
            traceFlags: .sampled,
            isRemote: true
        )

        var context = ServiceContext.topLevel
        context.spanContext = spanContext
        ServiceContext.$current.withValue(context) {
            logger.info("This is a test message", metadata: ["explicit": "42"])
        }

        XCTAssertEqual(stream.strings.count, 1)
        let message = try XCTUnwrap(stream.strings.first)

        let traceIDBytes = spanContext.traceID.hexBytes
        let timestampBytes = traceIDBytes[0 ..< 8]
        let randomBytes = traceIDBytes[8...]
        let expectedTraceId = "1-\(String(decoding: timestampBytes, as: UTF8.self))-\(String(decoding: randomBytes, as: UTF8.self))"

        XCTAssertTrue(message.contains("custom_span_id=\(spanContext.spanID)"))
        XCTAssertTrue(message.contains("custom_trace_id=\(expectedTraceId)"))
        XCTAssertTrue(message.contains("explicit=42"))
        XCTAssertTrue(message.contains("This is a test message"))
    }

    func test_doesNotProvideMetadataWithoutSpanContext() throws {
        guard #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) else {
            throw XCTSkip("Task locals are not supported on this platform.")
        }

        let stream = InterceptingStream()
        var logger = Logger(label: "test")
        let metadataProvider = Logger.MetadataProvider.otelXRay
        logger.handler = StreamLogHandler(label: "test", stream: stream, metadataProvider: metadataProvider)

        logger.info("This is a test message", metadata: ["explicit": "42"])

        XCTAssertEqual(stream.strings.count, 1)
        let message = try XCTUnwrap(stream.strings.first)

        XCTAssertFalse(message.contains("trace-id"))
        XCTAssertFalse(message.contains("span-id"))
        XCTAssertTrue(message.contains("explicit=42"))
        XCTAssertTrue(message.contains("This is a test message"))
    }
}

final class InterceptingStream: TextOutputStream {
    var interceptedText: String?
    var strings = [String]()

    func write(_ string: String) {
        strings.append(string)
        interceptedText = (interceptedText ?? "") + string
    }
}

extension InterceptingStream: @unchecked Sendable {}