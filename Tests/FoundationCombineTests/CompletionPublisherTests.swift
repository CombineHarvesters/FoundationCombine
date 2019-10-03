
import Combine
import CombineTesting
import FoundationCombine
import XCTest

final class CompletionPublisherTests: XCTestCase {

    // MARK: - (Output?, Failure?) -> Void

    fileprivate class OutputFailureAPI {
        var completion: (Int?, TestError?) -> Void = { _, _ in }
        func run(completion: @escaping (Int?, TestError?) -> Void) {
            self.completion = completion
        }
    }

    func test_outputFailureCompletion_success() {
        let api = OutputFailureAPI()
        let publisher = CompletionPublisher(perform: api.run)
        let subscriber = TestSubscriber<Int, TestError>()
        publisher.subscribe(subscriber)

        api.completion(19, nil)

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .input(19),
            .completion(.finished)
        ])
    }

    func test_outputFailureCompletion_failure() {
        let api = OutputFailureAPI()
        let publisher = CompletionPublisher(perform: api.run)
        let subscriber = TestSubscriber<Int, TestError>()
        publisher.subscribe(subscriber)

        api.completion(nil, "Nope!")

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .completion(.failure("Nope!"))
        ])
    }

    func test_outputFailureCompletion_cancel() {
        let api = OutputFailureAPI()
        var cancelled = false
        let publisher = CompletionPublisher(perform: api.run, cancel: { cancelled = true })
        let cancellable = publisher
            .replaceError(with: 8)
            .sink(receiveValue: { _ in })

        cancellable.cancel()
        XCTAssertEqual(cancelled, true)
    }

    // MARK: - (Failure?) -> Void

    fileprivate class FailureAPI {
        var completion: (TestError?) -> Void = { _ in }
        func run(completion: @escaping (TestError?) -> Void) {
            self.completion = completion
        }
    }

    func test_failureCompletion_success() {
        let api = FailureAPI()
        let publisher = CompletionPublisher(perform: api.run)
        let subscriber = TestSubscriber<Void, TestError>()
        publisher.subscribe(subscriber)

        api.completion(nil)

        let expected: [TestSubscriber<Void, Never>.Event] = [
            .subscription,
            .input(()),
            .completion(.finished)
        ]

        // This is needed because Void is not Equatable?
        XCTAssertEqual(subscriber.events.description, expected.description)
    }

    func test_failureCompletion_failure() {
        let api = FailureAPI()
        let publisher = CompletionPublisher(perform: api.run)
        let subscriber = TestSubscriber<Void, TestError>()
        publisher.subscribe(subscriber)

        api.completion("Nope!")

        let expected: [TestSubscriber<Void, TestError>.Event] = [
            .subscription,
            .completion(.failure("Nope!"))
        ]

        // This is needed because Void is not Equatable?
        XCTAssertEqual(subscriber.events.description, expected.description)
    }

    func test_failureCompletion_cancel() {
        let api = FailureAPI()
        var cancelled = false
        let publisher = CompletionPublisher(perform: api.run, cancel: { cancelled = true })
        let cancellable = publisher
            .replaceError(with: ())
            .sink(receiveValue: { _ in })

        cancellable.cancel()
        XCTAssertEqual(cancelled, true)
    }

    // MARK: - () -> Void

    fileprivate class VoidAPI {
        var completion: () -> Void = { }
        func run(completion: @escaping () -> Void) {
            self.completion = completion
        }
    }

    func test_voidCompletion_success() {
        let api = VoidAPI()
        let publisher = CompletionPublisher(perform: api.run)
        let subscriber = TestSubscriber<Void, Never>()
        publisher.subscribe(subscriber)

        api.completion()
        let expected: [TestSubscriber<Void, Never>.Event] = [
            .subscription,
            .input(()),
            .completion(.finished)
        ]

        // This is needed because Void is not Equatable?
        XCTAssertEqual(subscriber.events.description, expected.description)
    }

    func test_voidCompletion_cancel() {
        let api = VoidAPI()
        var cancelled = false
        let publisher = CompletionPublisher(perform: api.run, cancel: { cancelled = true })
        let cancellable = publisher
            .replaceError(with: ())
            .sink(receiveValue: { _ in })

        cancellable.cancel()
        XCTAssertEqual(cancelled, true)
    }

    // MARK: - (Failure?, Output?) -> Void

    fileprivate class FailureOutputAPI {
        var completion: (TestError?, Int?) -> Void = { _, _ in }
        func run(completion: @escaping (TestError?, Int?) -> Void) {
            self.completion = completion
        }
    }

    func test_failureOutputCompletion_success() {
        let api = FailureOutputAPI()
        let publisher = CompletionPublisher(perform: api.run)
        let subscriber = TestSubscriber<Int, TestError>()
        publisher.subscribe(subscriber)

        api.completion(nil, 122)

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .input(122),
            .completion(.finished)
        ])
    }

    func test_failureOutputCompletion_failure() {
        let api = FailureOutputAPI()
        let publisher = CompletionPublisher(perform: api.run)
        let subscriber = TestSubscriber<Int, TestError>()
        publisher.subscribe(subscriber)

        api.completion("Nope!", nil)

        XCTAssertEqual(subscriber.events, [
            .subscription,
            .completion(.failure("Nope!"))
        ])
    }

    func test_failureOutputCompletion_cancel() {
        let api = FailureOutputAPI()
        var cancelled = false
        let publisher = CompletionPublisher(perform: api.run, cancel: { cancelled = true })
        let cancellable = publisher
            .replaceError(with: 8)
            .sink(receiveValue: { _ in })

        cancellable.cancel()
        XCTAssertEqual(cancelled, true)
    }
}
