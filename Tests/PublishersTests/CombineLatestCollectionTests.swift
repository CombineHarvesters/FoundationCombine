
import Combine
import Publishers
import XCTest

final class CombineLatestCollectionTests: XCTestCase {

    func testSuccess() {

        let value1 = PassthroughSubject<Int, TestingError>()
        let value2 = PassthroughSubject<Int, TestingError>()

        let combineLatest = [value1, value2].combineLatest { $0.reduce(0, +) }
        let tracking = TrackingSubscriber()

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

        XCTAssertEqual(tracking.history, [.subscription(Subscriptions.empty),
                                          .value(5),
                                          .value(7),
                                          .value(9),
                                          .completion(.finished)])
    }

    func testFailure() {

        let value1 = PassthroughSubject<Int, TestingError>()
        let value2 = PassthroughSubject<Int, TestingError>()

        let combineLatest = [value1, value2].combineLatest { $0.reduce(0, +) }
        let tracking = TrackingSubscriber()

        let error = TestingError(description: "Test")

        value1.send(1)
        combineLatest.subscribe(tracking) // Subscription
        value2.send(2)
        value1.send(3) // Five
        value2.send(4) // Seven
        value1.send(completion: .failure(error)) // Completion
        value1.send(5)
        value2.send(6)
        value2.send(completion: .finished)
        value2.send(7)

        XCTAssertEqual(tracking.history, [.subscription(Subscriptions.empty),
                                          .value(5),
                                          .value(7),
                                          .completion(.failure(error))])
    }

    func testCancel() {

        let value1 = PassthroughSubject<Int, TestingError>()
        let value2 = PassthroughSubject<Int, TestingError>()

        let combineLatest = [value1, value2].combineLatest { $0.reduce(0, +) }
        let tracking = TrackingSubscriber()

        value1.send(1)
        combineLatest.subscribe(tracking) // Subscription
        value2.send(2)
        value1.send(3) // Five
        value2.send(4) // Seven
        tracking.subscriptions.forEach { $0.cancel() }
        value1.send(5)
        value2.send(6)
        value2.send(completion: .finished)
        value2.send(7)

        XCTAssertEqual(tracking.history, [.subscription(Subscriptions.empty),
                                          .value(5),
                                          .value(7)])
    }
}
