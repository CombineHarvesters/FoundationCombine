
import Combine
import Foundation

extension Collection where Element: Publisher {

    /// Combine the array of publishers to give a single publisher of an array
    /// of their outputs.
    public var combineLatest: CombineLatestCollection<Self> {
        CombineLatestCollection(self)
    }
}

/// A `Publisher` that combines an array of publishers to provide an output of
/// an array of their respective outputs.
///
/// Changes will be sent if any of the publishers' values changes.
///
/// When any publisher fails, that will cause the failure of this publisher.
///
/// When all publishers complete successfully, that will cause the successful
/// completion of this publisher.
public struct CombineLatestCollection<Publishers>
    where
    Publishers: Collection,
    Publishers.Element: Publisher
{
    public typealias Output = [Publishers.Element.Output]
    public typealias Failure = Publishers.Element.Failure

    private let publishers: Publishers
    public init(_ publishers: Publishers) {
        self.publishers = publishers
    }
}

extension CombineLatestCollection: Publisher {

    public func receive<Subscriber>(subscriber: Subscriber)
        where
        Subscriber: Combine.Subscriber,
        Subscriber.Failure == Failure,
        Subscriber.Input == Output
    {
        let subscription = Subscription(subscriber: subscriber,
                                        publishers: publishers)
        subscriber.receive(subscription: subscription)
    }
}

extension CombineLatestCollection {

    /// A subscription for a CombineLatestCollection publisher.
    fileprivate final class Subscription<Subscriber>
        where
        Subscriber: Combine.Subscriber,
        Subscriber.Failure == Publishers.Element.Failure,
        Subscriber.Input == Output
    {

        private var cancellables: [AnyCancellable] = []
        private let subscriber: Subscriber
        private let publishers: Publishers

        init(subscriber: Subscriber, publishers: Publishers) {
            self.subscriber = subscriber
            self.publishers = publishers
        }
    }
}

extension CombineLatestCollection.Subscription: Combine.Subscription {

    func request(_ demand: Subscribers.Demand) {

        let subscriber = self.subscriber
        let publishers = self.publishers
        var values: [Publishers.Element.Output?] = Array(repeating: nil, count: publishers.count)
        var completions = 0
        var hasCompleted = false
        let lock = NSLock()

        cancellables = publishers.enumerated().map { index, publisher in

            publisher.sink(receiveCompletion: { completion in

                lock.lock()
                defer { lock.unlock() }

                guard case .finished = completion else {
                    // One failure in any of the publishers cause a
                    // failure for this subscription.
                    subscriber.receive(completion: completion)
                    hasCompleted = true
                    return
                }

                completions += 1

                guard completions == publishers.count else { return }
                subscriber.receive(completion: completion)
                hasCompleted = true

            }, receiveValue: { value in

                lock.lock()
                defer { lock.unlock() }

                guard !hasCompleted else { return }

                values[index] = value

                // Get non-optional array of values and make sure we
                // have a full array of values.
                let current = values.compactMap { $0 }
                guard current.count == publishers.count else { return }
                _ = subscriber.receive(current)
            })
        }
    }

    func cancel() {
        cancellables.forEach { $0.cancel() }
    }
}
