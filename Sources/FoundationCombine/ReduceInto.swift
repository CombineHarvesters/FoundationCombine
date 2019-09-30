
import Combine

extension Publisher {

    /// Applies a closure that accumulates each element of a stream and
    /// publishes a final result upon completion.
    ///
    /// - Parameter initialValue: The value to use as the initial accumulating
    ///                           value.
    /// - Parameter updateAccumulatingResult: A closure that updates the
    ///                                       accumulating value with the next
    ///                                       element from the upstream
    ///                                       publisher to produce a new value.
    public func reduce<Value>(
        into initialValue: Value,
        _ updateAccumulatingResult: @escaping (inout Value, Output) -> ()
    ) -> Publishers.Reduce<Self, Value> {

        reduce(initialValue) { (value, output) -> Value in
            var variable = value
            updateAccumulatingResult(&variable, output)
            return variable
        }
    }

    /// Applies an error-throwing closure that accumulates each element of a
    /// stream and publishes a final result upon completion.
    ///
    /// - Parameter initialValue: The value to use as the initial accumulating
    ///                           value.
    /// - Parameter updateAccumulatingResult: An error-throwing closure that
    ///                                       updates the accumulating value
    ///                                       with the next element from the
    ///                                       upstream publisher to produce a
    ///                                       new value.
    public func tryReduce<Value>(
        into initialValue: Value,
        _ updateAccumulatingResult: @escaping (inout Value, Output) throws -> ()
    ) -> Publishers.TryReduce<Self, Value> {

        tryReduce(initialValue) { (value, output) -> Value in
            var variable = value
            try updateAccumulatingResult(&variable, output)
            return variable
        }
    }
}
