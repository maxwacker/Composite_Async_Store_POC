import ReduxCoreIFC

final class ActionEmitter<A: Action>: Interacting, @unchecked Sendable {
    private let continuation: AsyncStream<A>.Continuation
    
    init(continuation: AsyncStream<A>.Continuation) {
        self.continuation = continuation
    }
    
    func send(_ action: A) async {
        continuation.yield(action)
    }
}
