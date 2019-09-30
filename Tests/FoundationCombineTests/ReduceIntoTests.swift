
import Combine
import CombineTesting
import FoundationCombine
import XCTest

final class ReduceIntoTests: XCTestCase {

    func testReduceInto() {

        let subject = PassthroughSubject<Int, Never>()
        let publisher = subject.reduce(into: []) { $0.append($1) }
        let subscriber = TestSubscriber<[Int], Never>()

        publisher.subscribe(subscriber) // Subscription
        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(completion: .finished) // [1,2,3], Completion

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .input([1,2,3]),
            .completion(.finished)
        ])
    }

    func testTryReduceIntoSuccess() {

        let subject = PassthroughSubject<Int, Error>()
        let publisher = subject
            .tryReduce(into: []) { $0.append($1) }
            .mapError { TestError($0.localizedDescription) }
        let subscriber = TestSubscriber<[Int], TestError>()

        publisher.subscribe(subscriber) // Subscription
        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(completion: .finished) // [1,2,3], Completion

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .input([1,2,3]),
            .completion(.finished)
        ])
    }

    func testTryReduceIntoFailure() {

        let subject = PassthroughSubject<Int, Error>()
        let publisher = subject
            .tryReduce(into: [Int]()) { (_,_) in throw TestError("Ooops!") }
            .mapError { TestError($0.localizedDescription) }
        let subscriber = TestSubscriber<[Int], TestError>()

        publisher.subscribe(subscriber) // Subscription
        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(completion: .finished) // [1,2,3], Completion

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .completion(.failure("Ooops!"))
        ])
    }
}
