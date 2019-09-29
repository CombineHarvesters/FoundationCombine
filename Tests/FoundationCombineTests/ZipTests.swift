
import Combine
import CombineTesting
import FoundationCombine
import XCTest

final class ZipTests: XCTestCase {

    func testSuccess() {
        let a = PassthroughSubject<Int, Never>()
        let b = PassthroughSubject<Int, Never>()
        let publisher = [a, b].zipCollection
        let subscriber = TestSubscriber<[Int], Never>()

        publisher.subscribe(subscriber) // Subscription
        a.send(1)
        a.send(2)
        b.send(10) // [1, 10]
        a.send(3)
        b.send(20) // [2, 20]
        b.send(30) // [3, 30]
        b.send(completion: .finished) // Completion
        a.send(completion: .finished) // Completion
        a.send(4)
        b.send(40)

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .input([1, 10]),
            .input([2, 20]),
            .input([3, 30]),
            .completion(.finished)
        ])
    }

    func testFailure() {
        let a = PassthroughSubject<Int, TestError>()
        let b = PassthroughSubject<Int, TestError>()
        let publisher = [a, b].zipCollection
        let subscriber = TestSubscriber<[Int], TestError>()

        publisher.subscribe(subscriber) // subscription
        a.send(1)
        b.send(10) // [1, 10]
        a.send(completion: .failure("Error")) // completion
        a.send(2)
        b.send(20)
        a.send(completion: .finished)

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .input([1, 10]),
            .completion(.failure("Error"))
        ])
    }

    func testCancel() {
        let a = PassthroughSubject<Int, TestError>()
        let b = PassthroughSubject<Int, TestError>()
        let publisher = [a, b].zipCollection
        let subscriber = TestSubscriber<[Int], TestError>()

        publisher.subscribe(subscriber) // subscription
        a.send(1)
        b.send(10) // [1, 10]
        subscriber.subscriptions.forEach { $0.cancel() }
        a.send(2)
        b.send(20)
        a.send(completion: .finished)

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .input([1, 10])
        ])
    }
}
