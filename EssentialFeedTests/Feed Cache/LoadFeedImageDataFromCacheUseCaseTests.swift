//
//  LoadFeedImageDataFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Avelino Rodrigues on 08/09/2021.
//

import EssentialFeed
import XCTest

class LoadFeedImageDataFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertTrue(store.receivedMessages.isEmpty)
    }

    func test_loadImageDataFromURL_requestsStoredDataForURL() {
        let (sut, store) = makeSUT()
        let url = anyURL()

        _ = sut.loadImageData(from: url) { _ in }

        XCTAssertEqual(store.receivedMessages, [.retrieve(dataFor: url)])
    }

    func test_loadImageDataFromURL_failsOnStoreError() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: failed(), when: {
            let retrievalError = anyNSError()
            store.completeRetrieval(with: retrievalError)
        })
    }

    func test_loadImageDataFromURL_deliversNotFoundErrorOnNotFound() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: notFound(), when: {
            store.completeRetrieval(with: .none)
        })
    }

    func test_loadImageDataFromURL_deliversStoredDataOnFoundData() {
        let (sut, store) = makeSUT()
        let foundData = anyData()

        expect(sut, toCompleteWith: .success(foundData), when: {
            store.completeRetrieval(with: foundData)
        })
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: LocalFeedImageDataLoader, store: FeedImageDataStoreSpy) {
        let store = FeedImageDataStoreSpy()
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store)
        trackForMemoryLeaks(sut)

        return (sut, store)
    }

    private func failed() -> FeedImageDataLoader.Result {
        return .failure(LocalFeedImageDataLoader.LoadError.failed)
    }

    private func notFound() -> FeedImageDataLoader.Result {
        return .failure(LocalFeedImageDataLoader.LoadError.notFound)
    }

    private func expect(_ sut: LocalFeedImageDataLoader, toCompleteWith expectedResult: FeedImageDataLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")

        action()

        _ = sut.loadImageData(from: anyURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
                case let (.success(receivedData), .success(expectedData)):
                    XCTAssertEqual(receivedData, expectedData)
                case let (.failure(receivedError as LocalFeedImageDataLoader.LoadError), .failure(expectedError as LocalFeedImageDataLoader.LoadError)):
                    XCTAssertEqual(receivedError, expectedError)
                default:
                    XCTFail()
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }
}
