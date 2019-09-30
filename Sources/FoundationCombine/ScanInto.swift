
import Combine

extension Publisher {

    /// Transforms elements from the upstream publisher by providing the current
    /// element to a closure along with the last value returned by the closure.
    ///
    ///     let pub = (1...3)
    ///         .publisher
    ///         .scan(into: []) { $0.append($1) }
    ///         .sink(receiveValue: { print ("\($0)", terminator: " ") })
    ///      Prints "[1] [1, 2] [1, 2, 3] ".
    ///
    /// - Parameter initialValue: The value to use as the initial accumulating
    ///                           value.
    /// - Parameter updateAccumulatingResult: A closure that updates the
    ///                                       accumulating value with the next
    ///                                       element from the upstream
    ///                                       publisher to produce a new value.
    public func scan<Value>(
        into initialValue: Value,
        _ updateAccumulatingResult: @escaping (inout Value, Output) -> ()
    ) -> Publishers.Scan<Self, Value> {

        scan(initialValue) { (value, output) -> Value in
            var variable = value
            updateAccumulatingResult(&variable, output)
            return variable
        }
    }
}
