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

class MessageComposerTests: XCTestCase {
    struct MockFetchers {
        var message = ConcurrencyTests.errorMessage
        var interval: DispatchTimeInterval = .milliseconds(1)
        func fastFetcher(completion: @escaping (String) -> Void) {
            DispatchQueue.global().async {
                completion(self.message)
            }
        }
        func slowFetcher(completion: @escaping (String) -> Void) {
            DispatchQueue.global().asyncAfter(deadline: .now() + interval) {
                completion(self.message)
            }
        }
        func loseFetcher(completion: @escaping (String) -> Void) {}
    }

    func testMakingMessage() {
        let expectation = self.expectation(description: "testMakingMessage")

        let composer = MessageComposer(fetchers: [
            MockFetchers(message: "Hello", interval: .milliseconds(1)).fastFetcher(completion:),
            MockFetchers(message: "world", interval: .milliseconds(1)).slowFetcher(completion:)
            ])
        composer.load { (message) in
            XCTAssertEqual(ConcurrencyTests.expectMessage, message)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 10)

        XCTAssertEqual(ConcurrencyTests.expectMessage, composer.fetch())
    }

    func testMakingError() {
        let expectation = self.expectation(description: "testMakingError")

        let composer = MessageComposer(fetchers: [
            MockFetchers(message: "Hello", interval: .milliseconds(1)).fastFetcher(completion:),
            MockFetchers(message: "world", interval: .milliseconds(2)).slowFetcher(completion:)
            ])
        composer.load(timeout: .milliseconds(1)) { (message) in
            XCTAssertEqual(ConcurrencyTests.errorMessage, message)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
        XCTAssertEqual(ConcurrencyTests.errorMessage, composer.fetch(timeout: .milliseconds(1)))
    }

    func testFasterSecondFetcher() {
        let expectation = self.expectation(description: "testFasterSecondFetcher")

        let composer = MessageComposer(fetchers: [
            MockFetchers(message: "Hello", interval: .milliseconds(2)).slowFetcher(completion:),
            MockFetchers(message: "world", interval: .milliseconds(1)).fastFetcher(completion:)
            ])
        composer.load(timeout: .milliseconds(3)) { (message) in
            XCTAssertEqual(ConcurrencyTests.expectMessage, message)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(ConcurrencyTests.expectMessage, composer.fetch(timeout: .milliseconds(3)))
    }

    func testLostFirstFetcher() {
        let expectation = self.expectation(description: "testLostFirstFetcher")

        let composer = MessageComposer(fetchers: [
            MockFetchers(message: "Hello", interval: .milliseconds(1)).loseFetcher(completion:),
            MockFetchers(message: "world", interval: .milliseconds(1)).fastFetcher(completion:)
            ])
        composer.load(timeout: .milliseconds(2)) { (message) in
            XCTAssertEqual(ConcurrencyTests.errorMessage, message)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(ConcurrencyTests.errorMessage, composer.fetch(timeout: .milliseconds(2)))
    }
}
