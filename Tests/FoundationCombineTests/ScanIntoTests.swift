
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
}
