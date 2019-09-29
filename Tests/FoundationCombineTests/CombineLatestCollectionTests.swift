
import Combine
import CombineTesting
import FoundationCombine
import XCTest

final class CombineLatestCollectionTests: XCTestCase {

    func testSuccess() {

        let a = PassthroughSubject<Int, Never>()
        let b = PassthroughSubject<Int, Never>()
        let combineLatest = [a, b].combineLatest
        let subscriber = TestSubscriber<[Int], Never>()

        a.send(1)
        combineLatest.subscribe(subscriber) // Subscription
        b.send(2)
        a.send(3) // [3,2]
        b.send(4) // [3,4]
        a.send(completion: .finished)
        a.send(5)
        b.send(6) // [3,6]
        b.send(completion: .finished) // Completion
        b.send(7)

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .input([3,2]),
            .input([3,4]),
            .input([3,6]),
            .completion(.finished)
        ])
    }

    func testFailure() {

        let a = PassthroughSubject<Int, TestError>()
        let b = PassthroughSubject<Int, TestError>()
        let combineLatest = [a, b].combineLatest
        let subscriber = TestSubscriber<[Int], TestError>()

        a.send(1)
        combineLatest.subscribe(subscriber) // subscription
        b.send(2)
        a.send(3) // [3,2]
        b.send(4) // [3,4]
        a.send(completion: .failure("Error")) // completion
        a.send(5)
        b.send(6)
        b.send(completion: .finished)
        b.send(7)

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .input([3,2]),
            .input([3,4]),
            .completion(.failure("Error"))
        ])
    }

    func testCancel() {

        let a = PassthroughSubject<Int, Never>()
        let b = PassthroughSubject<Int, Never>()
        let combineLatest = [a, b].combineLatest
        let subscriber = TestSubscriber<[Int], Never>()

        a.send(1)
        combineLatest.subscribe(subscriber) // Subscription
        b.send(2)
        a.send(3) // [3,2]
        b.send(4) // [3,4]
        subscriber.subscriptions.forEach { $0.cancel() }
        a.send(5)
        b.send(6)
        b.send(completion: .finished)
        b.send(7)

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .input([3,2]),
            .input([3,4])
        ])
    }
}
