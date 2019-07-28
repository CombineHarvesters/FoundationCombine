
import Combine
import Foundation

extension Collection where Element: Publisher {

    public func combineLatest<T>(
        _ transform: @escaping ([Element.Output]) -> T
    ) -> CombineLatestCollection<Self, T> {
        CombineLatestCollection(self, transform: transform)
    }
}

/// A custom `Publisher` that
public struct CombineLatestCollection<Base, Output>: Publisher
    where
    Base: Collection,
    Base.Element: Publisher
{

    public typealias Value = Base.Element.Output
    public typealias Failure = Base.Element.Failure

    private let publishers: Base
    private let transform: ([Value]) -> Output

    public init(_ publishers: Base, transform: @escaping ([Value]) -> Output) {
        self.publishers = publishers
        self.transform = transform
    }

    public func receive<Subscriber>(subscriber: Subscriber)
        where
        Subscriber: Combine.Subscriber,
        Subscriber.Failure == Failure,
        Subscriber.Input == Output
    {
        let subscription = Subscription(subscriber: subscriber,
                                        publishers: publishers,
                                        transform: transform)
        subscriber.receive(subscription: subscription)
    }
}

extension CombineLatestCollection {

    public final class Subscription<Subscriber>: Combine.Subscription
        where
        Subscriber: Combine.Subscriber,
        Subscriber.Failure == Base.Element.Failure,
        Subscriber.Input == Output
    {

        private let subscribers: [AnyCancellable]

        fileprivate init(subscriber: Subscriber,
                         publishers: Base,
                         transform: @escaping ([Value]) -> Output) {

            var values: [Value?] = Array(repeating: nil, count: publishers.count)
            var completions = 0
            var hasCompleted = false
            var lock = pthread_mutex_t()

            subscribers = publishers.enumerated().map { index, publisher in

                publisher
                    .sink(receiveCompletion: { completion in

                        pthread_mutex_lock(&lock)
                        defer { pthread_mutex_unlock(&lock) }

                        guard case .finished = completion else {
                            // One failure in any of the publishers cause a
                            // failure for this subscription.
                            subscriber.receive(completion: completion)
                            hasCompleted = true
                            return
                        }

                        completions += 1

                        if completions == publishers.count {
                            subscriber.receive(completion: completion)
                            hasCompleted = true
                        }

                    }, receiveValue: { value in

                        pthread_mutex_lock(&lock)
                        defer { pthread_mutex_unlock(&lock) }

                        guard !hasCompleted else { return }

                        values[index] = value

                        // Get non-optional array of values and make sure we
                        // have a full array of values.
                        let current = values.compactMap { $0 }
                        if current.count == publishers.count {
                            _ = subscriber.receive(transform(current))
                        }
                    })
            }
        }

        public func request(_ demand: Subscribers.Demand) {}

        public func cancel() {
            subscribers.forEach { $0.cancel() }
        }
    }
}
