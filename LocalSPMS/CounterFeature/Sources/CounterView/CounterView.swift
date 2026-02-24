//
//  CounterView.swift
//  CounterFeature
//
//  Created by maxime wacker on 04/12/2025.
//
import SwiftUI

import ReduxCoreIFC
import ReduxCoreIMP

import CounterRedux
import DesignSystemIFC

public struct CounterView: View {
    let interactor: any Interacting<CounterAction>
    let counterPresenter: Presenter<Int>

    public init(interactor: any Interacting<CounterAction>, counterPresenter: Presenter<Int>) {
        self.interactor = interactor
        self.counterPresenter = counterPresenter
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Counter: \(counterPresenter.value)")
                .dsHeadline()
            
            HStack(spacing: 16) {
                Button("−") {
                    Task {
                        await interactor.send(.decrement)
                    }
                }
                .dsPrimaryButton()
                
                Button("+") {
                    Task {
                        await interactor.send(.increment)
                    }
                }
                .dsPrimaryButton()
                
                Button("Reset") {
                    Task {
                        await interactor.send(.reset)
                    }
                }
                .dsPrimaryButton()
            }
        }
        .padding()
        .dsCard()
    }
}

#if DEBUG
import SwiftUI
import DesignSystemDefaultIMP

// MARK: - Mock Store for Previews

/// A simplified store implementation for SwiftUI previews that combines
/// both presenter and interactor functionality in a single object.
@MainActor
final class MockStore<S: StoreState, A: Action>: Interacting {
    private var state: S
    private let reducer: Reducer<S, A>
    private var continuations: [UUID: AsyncStream<S>.Continuation] = [:]

    init(initialState: S, reducer: @escaping Reducer<S, A>) {
        self.state = initialState
        self.reducer = reducer
    }
    
    // MARK: - Interacting Conformance
    
    nonisolated func send(_ action: A) async {
        await MainActor.run {
            print("Preview action: \(action)")
            reducer(&state, action)
            
            // Notify all subscribers of the state change
            for continuation in continuations.values {
                continuation.yield(state)
            }
        }
    }
    
    // MARK: - Presenter Creation
    
    /// Creates a Presenter for a specific keypath of the state
    func presenter<Value: Equatable>(
        for keyPath: KeyPath<S, Value>
    ) -> Presenter<Value> {
        let id = UUID()
        let stream = AsyncStream<S> { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
            self.continuations[id] = continuation
            continuation.yield(self.state)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.continuations.removeValue(forKey: id)
                }
            }
        }
        
        return Presenter(
            initialValue: state[keyPath: keyPath],
            stateStream: stream,
            keyPath: keyPath
        )
    }
}

// MARK: - Preview

#Preview {
    PreviewContent()
        .frame(width: 500, height: 400)
        .background(Color(.windowBackgroundColor))
}

private struct PreviewContent: View {
    @State private var mockStore = MockStore(
        initialState: CounterState(count: 42),
        reducer: counterReducer
    )

    var body: some View {
        CounterView(
            interactor: mockStore,
            counterPresenter: mockStore.presenter(for: \.count)
        )
        .brandTheme()
    }
}
#endif
