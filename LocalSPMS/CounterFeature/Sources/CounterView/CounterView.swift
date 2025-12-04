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

public struct CounterView: View {
    let interactor: any Interacting<CounterAction>
    let counterPresenter: Presenter<CounterState, Int>
    
    public init(interactor: any Interacting<CounterAction>, counterPresenter: Presenter<CounterState, Int>) {
        self.interactor = interactor
        self.counterPresenter = counterPresenter
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Counter: \(counterPresenter.value)")
                .font(.largeTitle)
            
            HStack(spacing: 16) {
                Button("−") {
                    Task {
                        await interactor.send(.decrement)
                    }
                }
                .buttonStyle(.bordered)
                
                Button("+") {
                    Task {
                        await interactor.send(.increment)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Reset") {
                    Task {
                        await interactor.send(.reset)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

#if DEBUG
import SwiftUI

// Type-erased presenter wrapper for previews
@MainActor
@Observable
final class AnyPresenter<S: StoreState, Value> {
    var value: Value
    
    init(initialValue: Value) {
        self.value = initialValue
    }
}

// Extension to make AnyPresenter work as Presenter for previews
extension AnyPresenter {
    static func preview(_ initialValue: Value) -> Presenter<S, Value> {
        // Create a dummy stream that never emits
        let stream = AsyncStream<S> { _ in }
        
        // This is a workaround - we create a real Presenter with a dummy keypath
        // Since we can't create keypaths generically, we'll use a different approach
        fatalError("Use mock store instead")
    }
}

// Better approach: Create a minimal mock store for previews
actor PreviewStore<S: StoreState, A: Action> {
    var state: S
    let reducer: Reducer<S, A>
    
    private var continuations: [AsyncStream<S>.Continuation] = []
    
    init(initialState: S, reducer: @escaping Reducer<S, A>) {
        self.state = initialState
        self.reducer = reducer
    }
    
    func subscribe() -> AsyncStream<S> {
        AsyncStream { continuation in
            continuations.append(continuation)
            continuation.yield(state)
        }
    }
    
    func dispatch(_ action: A) {
        reducer(&state, action)
        for continuation in continuations {
            continuation.yield(state)
        }
    }
}

#Preview {
    Group {
        PreviewContent()
    }
    .frame(width: 500, height: 400)
    .background(Color(.windowBackgroundColor))
}

private struct PreviewContent: View {
    @State private var presenter: Presenter<CounterState, Int>?
    
    var body: some View {
        Group {
            if let presenter {
                CounterView(
                    interactor: PreviewInteractor(),
                    counterPresenter: presenter
                )
            } else {
                ProgressView()
            }
        }
        .task {
            let store = PreviewStore(
                initialState: CounterState(count: 42),
                reducer: counterReducer
            )
            
            let stream = await store.subscribe()
            let initialState = await store.state
            
            presenter = Presenter(
                initialValue: initialState.count,
                stateStream: stream,
                keyPath: \.count
            )
        }
    }
}

private final class PreviewInteractor: Interacting, @unchecked Sendable {
    func send(_ action: CounterAction) async {
        print("Preview action: \(action)")
    }
}
#endif
