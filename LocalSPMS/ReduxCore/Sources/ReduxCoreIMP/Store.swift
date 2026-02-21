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
    
    public init(
        initialState: S,
        reducer: @escaping Reducer<S, A>,
        middlewares: [Middleware<S, A>] = []
    ) {
        self.state = initialState
        self.reducer = reducer
        self.middlewares = middlewares
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
    
    func dispatch(_ action: A) async {
        // Start by running the initial action through middlewares
        var actionsToProcess = [action]
        
        // Each middleware transforms the actions sequentially
        for middleware in middlewares {
            var nextActions: [A] = []
            for act in actionsToProcess {
                let results = await middleware(state, act)
                nextActions.append(contentsOf: results)
            }
            actionsToProcess = nextActions
        }
        
        // Apply all final actions to reducer
        for finalAction in actionsToProcess {
            reducer(&state, finalAction)
        }
        
        // Broadcast state once
        for continuation in stateContinuations.values {
            continuation.yield(state)
        }
    }
    
    // TODO: #4 MODERATE — Task not stored or returned. Caller cannot cancel it directly.
    // Fix: return the Task so the caller manages its lifecycle.
    public func startProcessing(_ actionStream: AsyncStream<A>) {
        Task {
            for await action in actionStream {
                await dispatch(action)
            }
        }
    }
}
