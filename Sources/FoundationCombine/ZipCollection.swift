
import Foundation
import Combine

extension Collection where Element: Publisher {
    /// Combine the array of publishers to give a single array of the `Zip ` of their outputs
    public var zip: ZipCollection<Self> {
        ZipCollection(self)
    }
}

/// A `Publisher` that combines an array of publishers to provide an output of an array of the `Zip` of their respective outputs.
///
/// This behaves similarly to Combine's `Publishers.Zip` except:
/// - It takes an arbitrary number of publishers
/// - The publishers should all have the same type
///
/// The failure of any publisher causes a failure of this publisher. When all the publishers complete successfully, this publsher completes successfully
public struct ZipCollection<Publishers>: Publisher
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

    public func receive<Subscriber>(subscriber: Subscriber)
        where
        Subscriber: Combine.Subscriber,
        Subscriber.Failure == Failure,
        Subscriber.Input == Output
    {
        let subscription = Subscription(subscriber: subscriber, publishers: publishers)
        subscriber.receive(subscription: subscription)
    }
}

extension ZipCollection {
    /// A subscription for a Zip publisher
    fileprivate final class Subscription<Subscriber>: Combine.Subscription
        where
        Subscriber: Combine.Subscriber,
        Subscriber.Failure == Failure,
        Subscriber.Input == Output
    {
        private let subscribers: [AnyCancellable]
        private let queues: [Queue<Publishers.Element.Output>]

        init(subscriber: Subscriber, publishers: Publishers) {
            var count = publishers.count
            let outputs = publishers.map { _ in Queue<Publishers.Element.Output>() }
            queues = outputs
            var completions = 0
            var hasCompleted = false
            let lock = NSLock()

            subscribers = publishers.enumerated().map { index, publisher in
                publisher.sink(receiveCompletion: { completion in
                    lock.lock()
                    defer { lock.unlock() }

                    guard case .finished = completion else {
                        // Any failure causes the entire subscription to fail.
                        subscriber.receive(completion: completion)
                        hasCompleted = true
                        outputs.forEach { queue in
                            queue.removeAll()
                        }
                        return
                    }

                    completions += 1

                    guard completions == count else { return }

                    subscriber.receive(completion: completion)
                    hasCompleted = true
                }, receiveValue: { value in
                    lock.lock()
                    defer { lock.unlock() }

                    guard !hasCompleted else { return }
                    outputs[index].enqueue(value)

                    guard (outputs.compactMap{ $0.peek() }.count) == count else { return }

                    _ = subscriber.receive(outputs.compactMap({ $0.dequeue() }))
                })
            }
        }

        public func cancel() {
            subscribers.forEach { $0.cancel() }
            queues.forEach { $0.removeAll() }
        }
        
        public func request(_ demand: Subscribers.Demand) {}
    }
}


/// A generic structure around a FIFO collection
fileprivate final class Queue<T> {
    typealias Element = T

    private var elements = [Element]()

    /// Add an element to the back of the queue
    func enqueue(_ element: Element) {
        elements.append(element)
    }

    /// Remove an element from the front of the queue
    func dequeue() -> Element? {
        guard !elements.isEmpty else { return nil }

        return elements.removeFirst()
    }

    /// Examine the element at the head of the queue without removing it
    func peek() -> Element? {
        elements.first
    }

    /// Remove all elements from the queue
    func removeAll() {
        elements.removeAll()
    }
}
