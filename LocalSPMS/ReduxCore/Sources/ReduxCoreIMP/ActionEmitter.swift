import ReduxCoreIFC

// TODO: #5 MODERATE — @unchecked Sendable: safe because Continuation.yield is thread-safe,
// but this should be documented for future maintainers.
public final class ActionEmitter<A: Action>: Interacting, @unchecked Sendable {
    private let continuation: AsyncStream<A>.Continuation
    
    public init(continuation: AsyncStream<A>.Continuation) {
        self.continuation = continuation
    }
    
    public func send(_ action: A) async {
        continuation.yield(action)
    }
}
