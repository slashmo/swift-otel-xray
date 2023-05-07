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

import Instrumentation
@testable import OpenTelemetryXRay
import XCTest

final class XRayPropagatorTests: XCTestCase {
    private let propagator = XRayPropagator()
    private let injector = DictionaryInjector()
    private let extractor = DictionaryExtractor()

    // MARK: - Inject

    func test_injectsTraceparentHeader_notSampled() {
        let spanContext = OTel.SpanContext(
            traceID: OTel.TraceID(bytes: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)),
            spanID: OTel.SpanID(bytes: (1, 2, 3, 4, 5, 6, 7, 8)),
            traceFlags: [],
            isRemote: false
        )
        var headers = [String: String]()

        propagator.inject(spanContext, into: &headers, using: injector)

        XCTAssertEqual(
            headers,
            ["X-Amzn-Trace-Id": "Root=1-01020304-05060708090a0b0c0d0e0f10;Parent=0102030405060708;Sampled=0"]
        )
    }

    func test_injectsTraceparentHeader_sampled() {
        let spanContext = OTel.SpanContext(
            traceID: OTel.TraceID(bytes: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)),
            spanID: OTel.SpanID(bytes: (1, 2, 3, 4, 5, 6, 7, 8)),
            traceFlags: .sampled,
            isRemote: false
        )
        var headers = [String: String]()

        propagator.inject(spanContext, into: &headers, using: injector)

        XCTAssertEqual(
            headers,
            ["X-Amzn-Trace-Id": "Root=1-01020304-05060708090a0b0c0d0e0f10;Parent=0102030405060708;Sampled=1"]
        )
    }

    // MARK: - Extract

    func test_extractsNil_withoutTracingHeader() throws {
        let headers = ["Content-Type": "application/json"]

        XCTAssertNil(try propagator.extractSpanContext(from: headers, using: extractor))
    }

    func test_extractsTracingHeader_notSampled() throws {
        let headers = [
            "X-Amzn-Trace-Id": "Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=0",
        ]

        let spanContext = try XCTUnwrap(propagator.extractSpanContext(from: headers, using: extractor))

        XCTAssertEqual(spanContext.traceID.description, "5759e988bd862e3fe1be46a994272793")
        XCTAssertEqual(spanContext.spanID.description, "0000000000000000")
        XCTAssertTrue(spanContext.traceFlags.isEmpty)
        XCTAssertNil(spanContext.traceState)
    }

    func test_extractsTracingHeader_sampled() throws {
        let headers = [
            "X-Amzn-Trace-Id": "Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=1",
        ]

        let spanContext = try XCTUnwrap(propagator.extractSpanContext(from: headers, using: extractor))

        XCTAssertEqual(spanContext.traceID.description, "5759e988bd862e3fe1be46a994272793")
        XCTAssertEqual(spanContext.spanID.description, "0000000000000000")
        XCTAssertEqual(spanContext.traceFlags, .sampled)
        XCTAssertNil(spanContext.traceState)
    }

    func test_extractsTracingHeader_notSampled_withParent() throws {
        let headers = [
            "X-Amzn-Trace-Id": "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=0",
        ]

        let spanContext = try XCTUnwrap(propagator.extractSpanContext(from: headers, using: extractor))

        XCTAssertEqual(spanContext.traceID.description, "5759e988bd862e3fe1be46a994272793")
        XCTAssertEqual(spanContext.spanID.description, "53995c3f42cd8ad8")
        XCTAssertTrue(spanContext.traceFlags.isEmpty)
        XCTAssertNil(spanContext.traceState)
    }

    func test_extractsTracingHeader_sampled_withParent() throws {
        let headers = [
            "X-Amzn-Trace-Id": "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=1",
        ]

        let spanContext = try XCTUnwrap(propagator.extractSpanContext(from: headers, using: extractor))

        XCTAssertEqual(spanContext.traceID.description, "5759e988bd862e3fe1be46a994272793")
        XCTAssertEqual(spanContext.spanID.description, "53995c3f42cd8ad8")
        XCTAssertEqual(spanContext.traceFlags, .sampled)
        XCTAssertNil(spanContext.traceState)
    }

    func test_extractFails_missingTraceID() throws {
        let headers = ["X-Amzn-Trace-Id": "Root=1-123-456;Sampled=1"]

        XCTAssertThrowsError(
            try propagator.extractSpanContext(from: headers, using: extractor),
            XRayPropagator.TraceHeaderParsingError(value: "1-123-456", reason: .invalidTraceIDLength(9))
        )
    }

    func test_extractsTracingHeader_missingSampleDecision() throws {
        let tracingHeader = "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8"
        let headers = ["X-Amzn-Trace-Id": tracingHeader]

        let spanContext = try XCTUnwrap(propagator.extractSpanContext(from: headers, using: extractor))

        XCTAssertEqual(spanContext.traceID.description, "5759e988bd862e3fe1be46a994272793")
        XCTAssertEqual(spanContext.spanID.description, "53995c3f42cd8ad8")
        XCTAssertTrue(spanContext.traceFlags.isEmpty)
        XCTAssertNil(spanContext.traceState)
    }

    func test_extractFails_invalidTraceIDLength() throws {
        let tracingHeader = "Parent=53995c3f42cd8ad8;Sampled=1"
        let headers = ["X-Amzn-Trace-Id": tracingHeader]

        XCTAssertThrowsError(
            try propagator.extractSpanContext(from: headers, using: extractor),
            XRayPropagator.TraceHeaderParsingError(value: tracingHeader, reason: .missingTraceID)
        )
    }

    func test_extractFails_unsupportedTraceIDVersion() throws {
        let traceID = "2-5759e988-bd862e3fe1be46a994272793"
        let headers = ["X-Amzn-Trace-Id": "Root=\(traceID);Sampled=1"]

        XCTAssertThrowsError(
            try propagator.extractSpanContext(from: headers, using: extractor),
            XRayPropagator.TraceHeaderParsingError(value: traceID, reason: .unsupportedTraceIDVersion("2"))
        )
    }

    func test_extractFails_invalidTraceIDDelimiters() throws {
        let traceID = "1_5759e988*bd862e3fe1be46a994272793"
        let headers = ["X-Amzn-Trace-Id": "Root=\(traceID);Sampled=1"]

        XCTAssertThrowsError(
            try propagator.extractSpanContext(from: headers, using: extractor),
            XRayPropagator.TraceHeaderParsingError(value: traceID, reason: .invalidTraceIDDelimiters)
        )
    }

    func test_extractFails_invalidSpanIDLength() throws {
        let tracingHeader = "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=short;Sampled=1"
        let headers = ["X-Amzn-Trace-Id": tracingHeader]

        XCTAssertThrowsError(
            try propagator.extractSpanContext(from: headers, using: extractor),
            XRayPropagator.TraceHeaderParsingError(value: "short", reason: .invalidSpanIDLength(5))
        )
    }

    // MARK: - End To End

    func test_injectExtractedSpanContext() throws {
        let headers = [
            "X-Amzn-Trace-Id": "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=1",
        ]

        let extractedSpanContext = try XCTUnwrap(propagator.extractSpanContext(from: headers, using: extractor))

        var injectedHeaders = [String: String]()

        propagator.inject(extractedSpanContext, into: &injectedHeaders, using: injector)

        XCTAssertEqual(injectedHeaders["X-Amzn-Trace-Id"], headers["X-Amzn-Trace-Id"])
    }
}

private struct DictionaryInjector: Injector {
    init() {}

    func inject(_ value: String, forKey key: String, into carrier: inout [String: String]) {
        carrier[key] = value
    }
}

private struct DictionaryExtractor: Extractor {
    init() {}

    func extract(key: String, from carrier: [String: String]) -> String? {
        carrier[key]
    }
}
