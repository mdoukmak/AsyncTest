//
//  AsyncTestTests.swift
//  AsyncTestTests
//
//  Created by Muhammad Doukmak on 8/25/23.
//

import XCTest

protocol MyProtocol {
    func myFunc() async -> Int
}

final class Spy: MyProtocol {
    var completions: [() -> Void] = []
    var stream: AsyncStream<Int>? = nil
    var continuation: AsyncStream<Int>.Continuation?

    init() {
        self.stream = AsyncStream { self.continuation = $0 }
    }

    func myFunc() async -> Int {
        for await c in stream! {
            return c
        }
        return -1
    }
}

final class MySUT {
    let collaborator: MyProtocol
    init(collaborator: MyProtocol) {
        self.collaborator = collaborator
    }

    func getInt() async -> Int {
        let value = await collaborator.myFunc()
        if value == 1 {
            return 7
        } else {
            return value
        }
    }
}

final class AsyncTestTests: XCTestCase {
    func test_returnsSeven_whenSpyReturns1() {
        let spy = Spy()
        let sut = MySUT(collaborator: spy)

        let exp = expectation(description: "Wait for task completion")
        Task {
            let captured = await sut.getInt()
            XCTAssertEqual(captured, 7)
            exp.fulfill()
        }

        spy.continuation?.yield(1)
        spy.continuation?.finish()
        wait(for: [exp])
    }
}
