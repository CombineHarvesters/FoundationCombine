
import Combine

/// A publisher to wrap standard Cocoa completion-block APIs.
public struct CompletionPublisher<Output, Failure: Error> {

    fileprivate typealias Request = (Subscribers.Demand, AnySubscriber<Output, Failure>) -> Void
    public typealias Cancel = () -> Void
    private let request: Request
    private let cancel: Cancel

    fileprivate init(request: @escaping Request, cancel: @escaping Cancel = {}) {
        self.request = request
        self.cancel = cancel
    }
}

extension CompletionPublisher: Publisher {

    public func receive<Subscriber>(subscriber: Subscriber)
        where
        Subscriber: Combine.Subscriber,
        Subscriber.Failure == Failure,
        Subscriber.Input == Output
    {
        let subscription = Subscription(subscriber: subscriber, request: request, cancel: cancel)
        subscriber.receive(subscription: subscription)
    }
}

extension CompletionPublisher {

    fileprivate final class Subscription {

        private let subscriber: AnySubscriber<Output, Failure>
        private let request: Request
        private let _cancel: Cancel
        init<Subscriber>(subscriber: Subscriber, request: @escaping Request, cancel: @escaping Cancel)
            where
            Subscriber: Combine.Subscriber,
            Subscriber.Input == Output,
            Subscriber.Failure == Failure
        {
            self.subscriber = AnySubscriber(subscriber)
            self.request = request
            self._cancel = cancel
        }
    }
}

extension CompletionPublisher.Subscription: Subscription {

    fileprivate func request(_ demand: Subscribers.Demand) {
        request(demand, subscriber)
    }

    fileprivate func cancel() {
        _cancel()
    }
}

// MARK: - (Output?, Failure?) -> Void

extension CompletionPublisher {

    public typealias OutputFailureCompletion = (Output?, Failure?) -> Void

    /// An initializer which takes a function that uses a standard
    /// `(Output?, Failure?) -> Void` completion block and a cancel function.
    ///
    /// Using this initializer, you can easily pass existing Cocoa functions
    /// that accept a single completion closure as their only parameter such as
    /// `start(completionHandler:)` for MKLocalSearch.
    ///
    ///     extension MKLocalSearch {
    ///         static func publisher(for request: MKLocalSearch.Request) -> CompletionPublisher<MKLocalSearch.Response, Error> {
    ///             let search = Self(request: request)
    ///             return CompletionPublisher(perform: search.start, cancel: search.cancel)
    ///         }
    ///     }
    ///
    /// You can also wrap functions that accept multiple parameters such as
    /// CLGeocoder's
    /// `reverseGeocodeLocation(_:preferredLocale:completionHandler:)` method.
    ///
    ///     extension CLGeocoder {
    ///         func reverseGeocodeLocation(_ location: CLLocation, preferredLocale locale: Locale? = nil) -> CompletionPublisher<[CLPlacemark], Error> {
    ///             CompletionPublisher(perform: { self.reverseGeocodeLocation(location, preferredLocale: locale, completionHandler: $0) }, cancel: cancelGeocode)
    ///         }
    ///     }
    ///
    /// - Parameter perform: The function to perform that takes a completion
    ///                      closure of format `(Output?, Failure?) -> Void`.
    /// - Parameter cancel: A function which cancels the process.
    public init(perform: @escaping (@escaping OutputFailureCompletion) -> Void,
                cancel: @escaping Cancel = {}) {

        let request: Request = { _, subscriber in

            perform { output, failure in

                guard let output = output else {
                    subscriber.receive(completion: .failure(failure!))
                    return
                }

                _ = subscriber.receive(output)
                subscriber.receive(completion: .finished)
            }
        }

        self.init(request: request, cancel: cancel)
    }
}

// MARK: - (Failure?) -> Void

extension CompletionPublisher where Output == Void {

    public typealias FailureCompletion = (Failure?) -> Void

    /// An initializer which takes a function that wants a `(Failure?) -> Void`
    /// completion block and a cancel function.
    ///
    /// Using this initializer, you can wrap functions that take a completion
    /// block that only accepts an optional error parameter. For example
    /// GKScore's `report(_:withCompletionHandler:)` method.
    ///
    ///     extension GKScore {
    ///         static func report(_ scores: [GKScore]) -> CompletionPublisher<Void, Error> {
    ///             CompletionPublisher(perform: { self.report(scores, withCompletionHandler: $0) })
    ///         }
    ///     }
    ///
    /// The publisher will publish a void value just before the completion to
    /// allow further chaining in the success, which occurs when there is no
    /// error.
    ///
    /// - Parameter perform: The function to perform that takes a completion
    ///                      closure of format `(Failure?) -> Void`.
    /// - Parameter cancel: A function which cancels the process.
    public init(perform: @escaping (@escaping FailureCompletion) -> Void,
                cancel: @escaping Cancel = {}) {

        let request: Request = { _, subscriber in

            perform { failure in

                guard let failure = failure else {
                    _ = subscriber.receive(())
                    subscriber.receive(completion: .finished)
                    return
                }

                subscriber.receive(completion: .failure(failure))
            }
        }

        self.init(request: request, cancel: cancel)
    }
}

// MARK: - () -> Void

extension CompletionPublisher where Output == Void, Failure == Never {

    public typealias Completion = () -> Void

    /// An initializer which takes a function that wants a `() -> Void`
    /// completion block and a cancel function.
    ///
    /// Using this initializer, you can wrap functions that take a completion
    /// block that accepts no parameteres. For example
    /// `SKTextureAtlas.preloadTextureAtlases(_:withCompletionHandler:)` as
    /// shown below.
    ///
    ///     extension SKTextureAtlas {
    ///         static func preloadTextureAtlases(_ textureAtlases: [SKTextureAtlas]) -> CompletionPublisher<Void, Never> {
    ///             CompletionPublisher(perform: { self.preloadTextureAtlases(textureAtlases, withCompletionHandler: $0) })
    ///         }
    ///     }
    ///
    /// If the function only takes the one completion block argument, then you
    /// can simply pass that function as in the case of
    /// `SKTextureAtlas.preload(completionHandler:)`.
    ///
    ///     extension SKTextureAtlas {
    ///         var preloadPublisher: CompletionPublisher<Void, Never> {
    ///             CompletionPublisher(perform: preload)
    ///         }
    ///     }
    ///
    /// The publisher will publish a void value just before the completion to
    /// allow further chaining in the success.
    ///
    /// - Parameter perform: The function to perform that takes a completion
    ///                      closure of format `() -> Void`.
    /// - Parameter cancel: A function which cancels the process.
    public init(perform: @escaping (@escaping Completion) -> Void,
                cancel: @escaping Cancel = {}) {

        let request: Request = { _, subscriber in

            perform {
                _ = subscriber.receive(())
                subscriber.receive(completion: .finished)
            }
        }

        self.init(request: request, cancel: cancel)
    }
}

// MARK: - (Failure?, Output?) -> Void

extension CompletionPublisher {

    public typealias FailureOutputCompletion = (Failure?, Output?) -> Void

    /// An initializer which takes a function that uses a totally non-standard
    /// `(Failure?, Output?) -> Void` completion block and a cancel function.
    ///
    /// I'm shocked when I saw a single API provide the parameters this way
    /// around, but this initializer is provided for completeness.
    ///
    /// The API in question is from SpriteKit:
    /// `SKTextureAtlas.preloadTextureAtlasesNamed(_:withCompletionHandler:)`.
    ///
    /// We can wrap it like so:
    ///
    ///     extension SKTextureAtlas {
    ///         static func preloadTextureAtlasesNamed(_ atlasNames: [String]) -> CompletionPublisher<[SKTextureAtlas], Error> {
    ///             CompletionPublisher(perform: { self.preloadTextureAtlasesNamed(atlasNames, withCompletionHandler: $0) })
    ///         }
    ///     }
    ///
    /// - Parameter perform: The function to perform that takes a completion
    ///                      closure of format `(Failure?, Output?) -> Void`.
    /// - Parameter cancel: A function which cancels the process.
    public init(perform: @escaping (@escaping FailureOutputCompletion) -> Void,
                cancel: @escaping Cancel = {}) {

        let request: Request = { _, subscriber in

            perform { failure, output in

                guard let output = output else {
                    subscriber.receive(completion: .failure(failure!))
                    return
                }

                _ = subscriber.receive(output)
                subscriber.receive(completion: .finished)
            }
        }

        self.init(request: request, cancel: cancel)
    }
}
