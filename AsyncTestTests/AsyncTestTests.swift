//
//  AsyncTestTests.swift
//  AsyncTestTests
//
//  Created by Muhammad Doukmak on 8/25/23.
//

import XCTest

protocol NumProvider {
    func getNum() async -> Int
}

final class NumProviderSpy: NumProvider {
    var stream: AsyncStream<Int>? = nil
    var continuation: AsyncStream<Int>.Continuation?

    init() {
        self.stream = AsyncStream { self.continuation = $0 }
    }

    func getNum() async -> Int {
        var latest = 0
        for await c in stream! {
            latest = c
        }
        return latest
    }
}

final class MySUT {
    let numProvider: NumProvider
    init(collaborator: NumProvider) {
        self.numProvider = collaborator
    }

    func isSeven() async -> Bool {
        let value = await numProvider.getNum()
        return value == 7
    }
}

final class AsyncTestTests: XCTestCase {
    func test_isSeven_returnsTrue_whenSpyReturnsSeven() {
        let spy = NumProviderSpy()
        let sut = MySUT(collaborator: spy)

        let exp = expectation(description: "Wait for task completion")
        Task {
            let captured = await sut.isSeven()
            XCTAssertTrue(captured)
            exp.fulfill()
        }

        spy.continuation?.yield(7)
        spy.continuation?.finish()
        wait(for: [exp])
    }

    func test_isSeven_returnsFalse_whenSpyReturnsSix() {
        let spy = NumProviderSpy()
        let sut = MySUT(collaborator: spy)

        let exp = expectation(description: "Wait for task completion")
        Task {
            let captured = await sut.isSeven()
            XCTAssertFalse(captured)
            exp.fulfill()
        }

        spy.continuation?.yield(6)
        spy.continuation?.finish()
        wait(for: [exp])
    }

}
