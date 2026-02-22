import ReduxCoreIFC

// @unchecked Sendable is safe: the sole stored property is AsyncStream.Continuation,
// whose yield(_:) method is documented as thread-safe (callable from any context).
public final class ActionEmitter<A: Action>: Interacting, @unchecked Sendable {
    private let continuation: AsyncStream<A>.Continuation
    
    public init(continuation: AsyncStream<A>.Continuation) {
        self.continuation = continuation
    }
    
    public func send(_ action: A) async {
        continuation.yield(action)
    }
}
