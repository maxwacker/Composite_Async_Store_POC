//
//  Store.swift
//  ReduxCore
//
//  Created by maxime wacker on 03/12/2025.
//

import Foundation // For UUID

import ReduxCoreIFC

public actor Store<S: StoreState, A: Action> {
    /*private(set)*/ public var state: S
    private let reducer: Reducer<S, A>
    private let middlewares: [Middleware<S, A>]

    private var stateContinuations: [UUID: AsyncStream<S>.Continuation] = [:]

    /// Internal serialization queue. All actions are funneled through this stream
    /// so that a single processing loop drains them one at a time, preventing
    /// actor reentrancy in the middleware pipeline. See ADR-005.
    private let dispatchContinuation: AsyncStream<A>.Continuation
    private let dispatchStream: AsyncStream<A>
    private var processingTask: Task<Void, Never>?

    public init(
        initialState: S,
        reducer: @escaping Reducer<S, A>,
        middlewares: [Middleware<S, A>] = []
    ) {
        self.state = initialState
        self.reducer = reducer
        self.middlewares = middlewares

        var continuation: AsyncStream<A>.Continuation!
        self.dispatchStream = AsyncStream { continuation = $0 }
        self.dispatchContinuation = continuation
    }

    public func subscribe() -> AsyncStream<S> {
        let id = UUID()
        return AsyncStream { continuation in
            stateContinuations[id] = continuation

            // Emit current state immediately
            continuation.yield(state)

            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.unsubscribe(id: id)
                }
            }
        }
    }

    private func unsubscribe(id: UUID) {
        stateContinuations.removeValue(forKey: id)
    }

    // MARK: - Dispatch Serialization

    /// Enqueues an action for serialized processing.
    ///
    /// Actions are placed on an internal `AsyncStream` and processed one at a time
    /// by a single loop in `processActions()`. This eliminates actor reentrancy:
    /// the loop won't pull the next action until the current one (including all
    /// middleware `await`s) has fully completed.
    private func enqueue(_ action: A) {
        dispatchContinuation.yield(action)
    }

    /// The serial processing loop. Only one instance of this runs at a time,
    /// ensuring that each action's full middleware→reducer→broadcast cycle
    /// completes before the next action begins.
    private func processActions() async {
        for await action in dispatchStream {
            await dispatch(action)
        }
    }

    /// Runs a single action through the middleware pipeline, applies resulting
    /// actions to the reducer, and broadcasts the new state.
    ///
    /// This method is only called from `processActions()`, which guarantees
    /// serial execution — no two dispatch calls are in-flight simultaneously.
    private func dispatch(_ action: A) async {
        var actionsToProcess = [action]

        for middleware in middlewares {
            var nextActions: [A] = []
            for act in actionsToProcess {
                let results = await middleware(state, act)
                nextActions.append(contentsOf: results)
            }
            actionsToProcess = nextActions
        }

        for finalAction in actionsToProcess {
            reducer(&state, finalAction)
        }

        for continuation in stateContinuations.values {
            continuation.yield(state)
        }
    }

    // MARK: - Public API

    /// Connects an external action stream to the store's serialized dispatch queue.
    ///
    /// Actions from the external stream are forwarded into the internal serialization
    /// queue. The processing loop is started on the first call.
    @discardableResult
    public func startProcessing(_ actionStream: AsyncStream<A>) -> Task<Void, Never> {
        // Start the serial processing loop if not already running
        if processingTask == nil {
            processingTask = Task { await processActions() }
        }

        // Forward external actions into the serialization queue
        return Task {
            for await action in actionStream {
                self.enqueue(action)
            }
        }
    }
}
