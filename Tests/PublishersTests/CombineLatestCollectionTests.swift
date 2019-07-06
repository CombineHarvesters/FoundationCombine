
import Combine
import Publishers
import XCTest

@available(iOS 13, *)
@available(OSX 10.15, *)
final class CombineLatestCollectionTests: XCTestCase {

    func testCombineLatest() {

        let expectation = self.expectation(description: "test combine latest")

        let value1 = PassthroughSubject<Int, TestingError>()
        let value2 = PassthroughSubject<Int, TestingError>()

        let combineLatest = [value1, value2].combineLatest { $0.reduce(0, +) }
        let tracking = TrackingSubscriber(
            receiveSubscription: { $0.request(.unlimited) },
            receiveCompletion:  { _ in expectation.fulfill() }
        )

        value1.send(1)
        combineLatest.subscribe(tracking) // Subscription
        value2.send(2)
        value1.send(3) // Five
        value2.send(4) // Seven
        value1.send(completion: .finished)
        value1.send(5)
        value2.send(6) // Nine
        value2.send(completion: .finished) // Completion
        value2.send(7)

        wait(for: [expectation], timeout: 0.5)

        XCTAssertEqual(tracking.history, [.subscription(Subscriptions.empty),
                                          .value(5),
                                          .value(7),
                                          .value(9),
                                          .completion(.finished)])
    }

    func testBasic() {

        let e = expectation(description: "test")

        let twelve = Publishers.Just(12)
        let four = Publishers.Just(4)
        _ = [twelve, four]
            .combineLatest { $0.reduce(0, +) }
            .sink { value in
                XCTAssertEqual(value, 16)
                e.fulfill()
            }

        wait(for: [e], timeout: 1)
    }

    func testReceiveSubscription() {

        let receivedSubscription = expectation(description: "received subscription")

        let value = Publishers.Just(0)

        _ = [value]
            .combineLatest { $0.reduce(0, +) }
            .handleEvents(receiveSubscription: { _ in
                receivedSubscription.fulfill()
            })
            .sink { _ in }

        wait(for: [receivedSubscription], timeout: 1)
    }

    func testReceiveCancel() {

        let receivedCancel = expectation(description: "receive cancel")

        let value = Publishers.Just(0)

        let publisher = [value]
            .combineLatest { $0.reduce(0, +) }
            .handleEvents(receiveCancel: {
                receivedCancel.fulfill()
            })
            .sink { _ in }

        publisher.cancel()

        wait(for: [receivedCancel], timeout: 1)
    }

    func testValue() {

        var receivedValue = expectation(description: "received value")

        let value1 = PassthroughSubject<Int, Error>()
        let value2 = PassthroughSubject<Int, Error>()
        var expectedValue = 0

        _ = [value1, value2]
            .combineLatest { $0.reduce(0, +) }
            .sink { value in
                XCTAssertEqual(value, expectedValue)
                receivedValue.fulfill()
            }

        expectedValue = 5
        value1.send(4)
        value2.send(1)
        wait(for: [receivedValue], timeout: 1)

        receivedValue = expectation(description: "received value")
        expectedValue = 9
        value2.send(5)
        wait(for: [receivedValue], timeout: 1)
    }

    func testFailure() {

        struct TestError: Error {}

        let receivedFinish = expectation(description: "received finished")

        let value1 = PassthroughSubject<Int, Error>()
        let value2 = PassthroughSubject<Int, Error>()

        _ = [value1, value2]
            .combineLatest { $0.reduce(0, +) }
            .handleEvents(receiveCompletion: { completion in

                if case .failure(let error) = completion {
                    XCTAssert(error is TestError)
                    receivedFinish.fulfill()
                }
            })
            .sink { _ in }

        value1.send(completion: .failure(TestError()))
        wait(for: [receivedFinish], timeout: 1)
    }

    func testFinished() {

        let receivedFinish = expectation(description: "received finished")

        let value1 = PassthroughSubject<Int, Never>()
        let value2 = PassthroughSubject<Int, Never>()

        _ = [value1, value2]
            .combineLatest { $0.reduce(0, +) }
            .handleEvents(receiveCompletion: { completion in

                if case .finished = completion {
                    receivedFinish.fulfill()
                }
            })
            .sink { _ in }

        value1.send(completion: .finished)
        value2.send(completion: .finished)
        wait(for: [receivedFinish], timeout: 1)
    }
}
