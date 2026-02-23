//
//  ViewContainer.swift
//  Composite_Async_Store_POC
//
//  Created by maxime wacker on 09/12/2025.
//

import Foundation
import ReduxCoreIFC
import ReduxCoreIMP

// MARK: - Adapter Classes

// Adapter to transform parent interactor to child interactor
@MainActor
final class AdaptedInteractor<ParentAction: Action, ChildAction: Action>: Interacting {
    private let parentInteractor: any Interacting<ParentAction>
    private let transform: (ChildAction) -> ParentAction
    
    init(
        parentInteractor: any Interacting<ParentAction>,
        transform: @escaping (ChildAction) -> ParentAction
    ) {
        self.parentInteractor = parentInteractor
        self.transform = transform
    }
    
    func send(_ action: ChildAction) async {
        await parentInteractor.send(transform(action))
    }
}

// MARK: - View Container

@MainActor
final class ViewContainer<S: StoreState, A: Action> {
    let store: Store<S, A>
    let interactor: ActionEmitter<A>
    
    private let actionContinuation: AsyncStream<A>.Continuation
    private let actionStream: AsyncStream<A>
    private var stateStreamTask: Task<Void, Never>?
    
    init(store: Store<S, A>) {
        self.store = store
        
        var continuation: AsyncStream<A>.Continuation!
        self.actionStream = AsyncStream { continuation = $0 }
        self.actionContinuation = continuation
        
        self.interactor = ActionEmitter(continuation: continuation)
        
        // Connect action stream to store
        self.stateStreamTask = Task {
            await store.startProcessing(actionStream)
        }
    }
    
    func presenter<Value: Equatable>(
        for keyPath: KeyPath<S, Value>
    ) async -> Presenter<Value> {
        let currentState = await store.state
        let stateStream = await store.subscribe()
        return Presenter(
            initialValue: currentState[keyPath: keyPath],
            stateStream: stateStream,
            keyPath: keyPath
        )
    }

    func presenter<Value: Equatable, SourceValue>(
        for keyPath: KeyPath<S, SourceValue>,
        transform: @escaping (SourceValue) -> Value
    ) async -> Presenter<Value> {
        let currentState = await store.state
        let stateStream = await store.subscribe()
        return Presenter(
            initialValue: transform(currentState[keyPath: keyPath]),
            stateStream: stateStream,
            keyPath: keyPath,
            transform: transform
        )
    }
    
    // Helper to create adapted interactor for child actions
    func adaptedInteractor<ChildAction: Action>(
        transform: @escaping (ChildAction) -> A
    ) -> AdaptedInteractor<A, ChildAction> {
        return AdaptedInteractor(
            parentInteractor: interactor,
            transform: transform
        )
    }
    
    // Helper to create child state presenter from parent state
    func childPresenter<ChildState: StoreState, Value: Equatable>(
        extractChildState: @escaping (S) -> ChildState,
        childKeyPath: KeyPath<ChildState, Value>
    ) async -> Presenter<Value> {
        let currentState = await store.state
        let stateStream = await store.subscribe()
        
        // Create a transformed stream that extracts child state
        let childStateStream = AsyncStream<ChildState> { continuation in
            let task = Task {
                for await parentState in stateStream {
                    continuation.yield(extractChildState(parentState))
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
        
        return Presenter(
            initialValue: extractChildState(currentState)[keyPath: childKeyPath],
            stateStream: childStateStream,
            keyPath: childKeyPath
        )
    }
    
    deinit {
        stateStreamTask?.cancel()
    }
}