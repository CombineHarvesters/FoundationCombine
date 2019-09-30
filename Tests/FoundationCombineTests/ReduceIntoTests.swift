
import Combine
import CombineTesting
import FoundationCombine
import XCTest

final class ReduceIntoTests: XCTestCase {

    func test() {

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
}
