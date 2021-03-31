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

@testable import OpenTelemetryXRay
import XCTest

final class XRayIDGeneratorTests: XCTestCase {
    func test_generatesRandomTraceID() {
        var idGenerator = XRayIDGenerator(
            randomNumberGenerator: ConstantNumberGenerator(value: .max),
            getCurrentSecondsSinceEpoch: { 1_616_064_590 }
        )

        let maxTraceID = idGenerator.generateTraceID()

        XCTAssertEqual(
            maxTraceID,
            OTel.TraceID(bytes: (96, 83, 48, 78, 255, 255, 255, 254, 255, 255, 255, 255, 255, 255, 255, 254))
        )
    }

    func test_generatesRandomTraceID_withRandomNumberGenerator() {
        var idGenerator = XRayIDGenerator(
            randomNumberGenerator: ConstantNumberGenerator(value: .random(in: 0 ..< .max)),
            getCurrentSecondsSinceEpoch: { 1_616_064_590 }
        )

        let randomTraceID = idGenerator.generateTraceID()

        XCTAssertTrue(
            randomTraceID.description.starts(with: "6053304e"),
            "X-Ray trace ids must start with the current timestamp."
        )
    }

    func test_generatesUniqueTraceIDs() {
        var idGenerator = XRayIDGenerator()
        var traceIDs = Set<OTel.TraceID>()

        for _ in 0 ..< 1000 {
            traceIDs.insert(idGenerator.generateTraceID())
        }

        XCTAssertEqual(traceIDs.count, 1000, "Generating 1000 X-Ray trace ids should result in 1000 unique trace ids.")
    }

    func test_generatesRandomSpanID() {
        var idGenerator = XRayIDGenerator(randomNumberGenerator: ConstantNumberGenerator(value: .max))

        let maxSpanID = idGenerator.generateSpanID()

        XCTAssertEqual(
            maxSpanID,
            OTel.SpanID(bytes: (255, 255, 255, 255, 255, 255, 255, 255))
        )
    }

    func test_generatesRandomSpanID_withRandomNumberGenerator() {
        let randomValue = UInt64.random(in: 0 ..< .max)
        let randomHexString = String(randomValue, radix: 16, uppercase: false)
        let hexString = randomHexString.count == 16 ? randomHexString : "0\(randomHexString)"
        var idGenerator = XRayIDGenerator(randomNumberGenerator: ConstantNumberGenerator(value: randomValue))

        let randomSpanID = idGenerator.generateSpanID()

        XCTAssertEqual(randomSpanID.description, hexString)
    }

    func test_generatesUniqueSpanIDs() {
        var idGenerator = XRayIDGenerator()
        var spanIDs = Set<OTel.SpanID>()

        for _ in 0 ..< 1000 {
            spanIDs.insert(idGenerator.generateSpanID())
        }

        XCTAssertEqual(spanIDs.count, 1000, "Generating 1000 span ids should result in 1000 unique span ids.")
    }
}

private struct ConstantNumberGenerator: RandomNumberGenerator {
    let value: UInt64

    func next() -> UInt64 {
        value
    }
}
