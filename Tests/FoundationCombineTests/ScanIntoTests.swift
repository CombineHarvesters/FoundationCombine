
import Combine
import CombineTesting
import FoundationCombine
import XCTest

final class ScanIntoTests: XCTestCase {

    func testScanInto() {

        let publisher = (1...3)
            .publisher
            .scan(into: []) { $0.append($1) }

        let subscriber = TestSubscriber<[Int], Never>()
        publisher.subscribe(subscriber)

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .input([1]),
            .input([1,2]),
            .input([1,2,3]),
            .completion(.finished)
        ])
    }

    func testTryScanIntoSuccess() {

        let publisher = (1...3)
            .publisher
            .tryScan(into: []) { $0.append($1) }
            .mapError { TestError($0.localizedDescription) }

        let subscriber = TestSubscriber<[Int], TestError>()
        publisher.subscribe(subscriber)

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .input([1]),
            .input([1,2]),
            .input([1,2,3]),
            .completion(.finished)
        ])
    }

    func testTryScanIntoFailure() {

        let publisher = (1...3)
            .publisher
            .tryScan(into: [Int]()) {
                if $1 == 3 { throw TestError("Ooops!") }
                $0.append($1)
            }
            .mapError { TestError($0.localizedDescription) }

        let subscriber = TestSubscriber<[Int], TestError>()
        publisher.subscribe(subscriber)

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .input([1]),
            .input([1,2]),
            .completion(.failure("Ooops!"))
        ])
    }
}
