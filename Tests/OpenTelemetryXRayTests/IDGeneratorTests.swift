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

@testable import OpenTelemetryXRay
import XCTest

final class XRayIDGeneratorTests: XCTestCase {
    func test_generatesRandomTraceID() {
        let idGenerator = XRayIDGenerator(
            randomNumberGenerator: ConstantNumberGenerator(value: .max),
            getCurrentSecondsSinceEpoch: { 1_616_064_590 }
        )

        let maxTraceID = idGenerator.nextTraceID()

        XCTAssertEqual(
            maxTraceID,
            OTelTraceID(bytes: (96, 83, 48, 78, 255, 255, 255, 254, 255, 255, 255, 255, 255, 255, 255, 254))
        )
    }

    func test_generatesRandomTraceID_withRandomNumberGenerator() {
        let idGenerator = XRayIDGenerator(
            randomNumberGenerator: ConstantNumberGenerator(value: .random(in: 0 ..< .max)),
            getCurrentSecondsSinceEpoch: { 1_616_064_590 }
        )

        let randomTraceID = idGenerator.nextTraceID()

        XCTAssertTrue(
            randomTraceID.description.starts(with: "6053304e"),
            "X-Ray trace ids must start with the current timestamp."
        )
    }

    func test_generatesUniqueTraceIDs() {
        let idGenerator = XRayIDGenerator()
        var traceIDs = Set<OTelTraceID>()

        for _ in 0 ..< 1000 {
            traceIDs.insert(idGenerator.nextTraceID())
        }

        XCTAssertEqual(traceIDs.count, 1000, "Generating 1000 X-Ray trace ids should result in 1000 unique trace ids.")
    }

    func test_generatesRandomSpanID() {
        let idGenerator = XRayIDGenerator(randomNumberGenerator: ConstantNumberGenerator(value: .max))

        let maxSpanID = idGenerator.nextSpanID()

        XCTAssertEqual(
            maxSpanID,
            OTelSpanID(bytes: (255, 255, 255, 255, 255, 255, 255, 255))
        )
    }

    func test_generatesRandomSpanID_withRandomNumberGenerator() {
        let randomValue = UInt64.random(in: 0 ..< .max)
        let randomHexString = String(randomValue, radix: 16, uppercase: false)
        let hexString = randomHexString.count == 16 ? randomHexString : "0\(randomHexString)"
        let idGenerator = XRayIDGenerator(randomNumberGenerator: ConstantNumberGenerator(value: randomValue))

        let randomSpanID = idGenerator.nextSpanID()

        XCTAssertEqual(randomSpanID.description, hexString)
    }

    func test_generatesUniqueSpanIDs() {
        let idGenerator = XRayIDGenerator()
        var spanIDs = Set<OTelSpanID>()

        for _ in 0 ..< 1000 {
            spanIDs.insert(idGenerator.nextSpanID())
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
