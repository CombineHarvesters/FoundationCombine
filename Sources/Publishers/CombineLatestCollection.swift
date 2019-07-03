
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
    private var values: [Value?]
    private var completions: [Subscribers.Completion<Failure>] = []
    private let queue = DispatchQueue(label: "CombineLatestPublisherQueue")

    public init(
        _ publishers: Base,
        transform: @escaping ([Value]) -> Output
    ) {
        self.publishers = publishers
        self.transform = transform
        self.values = Array(repeating: nil, count: publishers.count)
    }

    public func receive<S>(subscriber: S)
        where
        S: Subscriber,
        S.Failure == Failure,
        S.Input == Output
    {

        let subscribers = publishers.enumerated().map { index, publisher in

            publisher
                .receive(on: queue)
                .handleEvents(receiveCompletion: { completion in

                    guard case .finished = completion else {
                        subscriber.receive(completion: completion)
                        return
                    }

                    self.completions.append(completion)

                    guard self.completions.count == self.publishers.count else { return }

                    subscriber.receive(completion: completion)
                })
                .sink { value in

                    self.values[index] = value

                    // Get non-optional array of values and make sure we have a
                    // full array of values.
                    let current = self.values.compactMap { $0 }
                    guard current.count == self.publishers.count else { return }

                    _ = subscriber.receive(self.transform(current))
                }
        }

        let subscription =  CombineLatestCollectionSubscription(cancellables: subscribers)
        subscriber.receive(subscription: subscription)
    }
}

@available(iOS 13, *)
@available(OSX 10.15, *)
public final class CombineLatestCollectionSubscription<C: Cancellable>: Subscription {

    private let cancellables: [C]
    fileprivate init(cancellables: [C]) {
        self.cancellables = cancellables
    }

    public func request(_ demand: Subscribers.Demand) {}

    public func cancel() {
        cancellables.forEach { $0.cancel() }
    }
}
