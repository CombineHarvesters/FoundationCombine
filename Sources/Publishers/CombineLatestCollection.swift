
import Combine
import Foundation

@available(iOS 13, *)
@available(OSX 10.15, *)
extension Collection where Element: Publisher {

    public func combineLatest<T>(
        _ transform: @escaping ([Element.Output]) -> T
    ) -> CombineLatestCollection<Self, T> {
        CombineLatestCollection(self, transform: transform)
    }
}

/// A custom `Publisher` that
@available(iOS 13, *)
@available(OSX 10.15, *)
public final class CombineLatestCollection<Base, Output>: Publisher
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

    public func receive<S>(subscriber: S)
        where
        S: Subscriber,
        S.Failure == Failure,
        S.Input == Output
    {
        let subscription =  CombineLatestCollectionSubscription(subscriber: subscriber,
                                                                publishers: publishers,
                                                                transform: transform)
        subscriber.receive(subscription: subscription)
    }
}

@available(iOS 13, *)
@available(OSX 10.15, *)
public final class CombineLatestCollectionSubscription<Publishers, Subscriber, Output>: Subscription
    where
    Publishers: Collection,
    Publishers.Element: Publisher,
    Subscriber: Combine.Subscriber,
    Subscriber.Failure == Publishers.Element.Failure,
    Subscriber.Input == Output
{

    public typealias Value = Publishers.Element.Output
    public typealias Failure = Publishers.Element.Failure

    private let subscribers: [Subscribers.Sink<Value, Failure>]

    fileprivate init(subscriber: Subscriber,
                     publishers: Publishers,
                     transform: @escaping ([Value]) -> Output) {

        var values: [Value?] = Array(repeating: nil, count: publishers.count)
        var completions: [Subscribers.Completion<Failure>] = []
        let queue = DispatchQueue(label: "CombineLatestCollection")

        subscribers = publishers.enumerated().map { index, publisher in

            publisher
                .receive(on: queue)
                .handleEvents(receiveCompletion: { completion in

                    guard case .finished = completion else {
                        subscriber.receive(completion: completion)
                        return
                    }

                    completions.append(completion)

                    guard completions.count == publishers.count else { return }

                    subscriber.receive(completion: completion)
                })
                .sink { value in

                    values[index] = value

                    // Get non-optional array of values and make sure we have a
                    // full array of values.
                    let current = values.compactMap { $0 }
                    guard current.count == publishers.count else { return }

                    _ = subscriber.receive(transform(current))
                }
        }
    }

    public func request(_ demand: Subscribers.Demand) {
    }

    public func cancel() {
        subscribers.forEach { $0.cancel() }
    }
}
