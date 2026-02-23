//
//  ViewContainer.swift
//  ReduxCoreIMP
//
//  Created by maxime wacker on 09/12/2025.
//

import Foundation
import ReduxCoreIFC

// MARK: - Adapter Classes

/// Adapter to transform a parent interactor into a child interactor.
/// Wraps a parent `Interacting` and maps child actions to parent actions via a transform closure.
///
/// Not `@MainActor` — all stored properties are immutable `let`s, and both
/// `any Interacting<ParentAction>` (which requires `Sendable`) and the
/// `@Sendable` transform closure are safe to use from any isolation context.
public final class AdaptedInteractor<ParentAction: Action, ChildAction: Action>: Interacting, @unchecked Sendable {
    private let parentInteractor: any Interacting<ParentAction>
    private let transform: @Sendable (ChildAction) -> ParentAction

    public init(
        parentInteractor: any Interacting<ParentAction>,
        transform: @escaping @Sendable (ChildAction) -> ParentAction
    ) {
        self.parentInteractor = parentInteractor
        self.transform = transform
    }

    public func send(_ action: ChildAction) async {
        await parentInteractor.send(transform(action))
    }
}

// MARK: - View Container

/// Bridge between `Store` and SwiftUI views.
///
/// Owns an `ActionEmitter` for dispatching actions and provides factory methods
/// for creating `Presenter` instances bound to state key paths. Generic over
/// the app's state and action types — contains no app-specific logic.
@MainActor
public final class ViewContainer<S: StoreState, A: Action> {
    public let store: Store<S, A>
    public let interactor: ActionEmitter<A>

    private let actionContinuation: AsyncStream<A>.Continuation
    private let actionStream: AsyncStream<A>
    private var stateStreamTask: Task<Void, Never>?

    public init(store: Store<S, A>) {
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

    public func presenter<Value: Equatable>(
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

    public func presenter<Value: Equatable, SourceValue>(
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

    /// Creates an adapted interactor that maps child actions to parent actions.
    public func adaptedInteractor<ChildAction: Action>(
        transform: @escaping @Sendable (ChildAction) -> A
    ) -> AdaptedInteractor<A, ChildAction> {
        return AdaptedInteractor(
            parentInteractor: interactor,
            transform: transform
        )
    }

    /// Creates a presenter for a child state slice extracted from the parent state.
    public func childPresenter<ChildState: StoreState, Value: Equatable>(
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
