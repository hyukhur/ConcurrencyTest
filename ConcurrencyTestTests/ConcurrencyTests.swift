//
//  ConcurrencyTestTests.swift
//  ConcurrencyTestTests
//


import XCTest
@testable import ConcurrencyTest

class ConcurrencyTests: XCTestCase {
    static let expectMessage = "Hello world"
    static let tryThreadhold = 100

    func testloadMessage() {
        let expectation = self.expectation(description: "testloadMessage")
        loadMessage { combinedMessage in
            XCTAssertTrue([ConcurrencyTests.expectMessage, ConcurrencyTests.errorMessage].contains(combinedMessage), combinedMessage)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 10)
    }

    func testloadMessageWithinTimeout() {
        var expected = ""
        let group = DispatchGroup()

        for _ in (0..<ConcurrencyTests.tryThreadhold) {
            let start = Date()
            var diff = TimeInterval(0)
            group.enter()
            loadMessage { combinedMessage in
                expected = combinedMessage
                diff = Date().timeIntervalSince(start)
                group.leave()
            }
            group.wait()
            if TimeInterval(2) >= diff {
                break
            }
        }

        XCTAssertEqual(ConcurrencyTests.expectMessage, expected)
    }

    static let errorMessage = "Unable to load message - Time out exceeded"
    func testloadMessageTimeout() {
        var expected = ""
        let group = DispatchGroup()

        for _ in (0..<ConcurrencyTests.tryThreadhold) {
            let start = Date()
            var diff = TimeInterval(0)
            group.enter()
            loadMessage { combinedMessage in
                expected = combinedMessage
                diff = Date().timeIntervalSince(start)
                group.leave()
            }
            group.wait()
            if TimeInterval(2) < diff {
                break
            }
        }

        XCTAssertEqual(ConcurrencyTests.errorMessage, expected)
    }
}
