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
        // Run middlewares
        var currentAction: A? = action
        for middleware in middlewares {
            guard let action = currentAction else { break }
            currentAction = await middleware(state, action)
        }
        
        // Apply reducer if middleware didn't cancel the action
        if let finalAction = currentAction {
            reducer(&state, finalAction)
            
            // Broadcast to all subscribers
            for continuation in stateContinuations.values {
                continuation.yield(state)
            }
        }
    }
    
    public func startProcessing(_ actionStream: AsyncStream<A>) {
        Task {
            for await action in actionStream {
                await dispatch(action)
            }
        }
    }
}
