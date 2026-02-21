//
//  Presenter.swift
//  Composite_Async_Store_POC
//
//  Created by maxime wacker on 02/12/2025.
//
import ReduxCoreIFC


import Observation
@MainActor
@Observable
public class Presenter<S: StoreState, Value> {
    public var value: Value
    
    public init(
        initialValue: Value,
        stateStream: AsyncStream<S>,
        keyPath: KeyPath<S, Value>
    ) where Value: Equatable {
        self.value = initialValue
        
        // TODO: #1 CRITICAL — Retain cycle: Task captures self strongly, stream never terminates,
        // so Presenter is never deallocated. Fix: [weak self] + stored Task + deinit cancel.
        Task {
            for await state in stateStream {
                let newValue = state[keyPath: keyPath]
                if self.value != newValue {
                    self.value = newValue
                }
            }
        }
    }

    // Convenience initializer for computed/transformed values
    public init<SourceValue>(
        initialValue: Value,
        stateStream: AsyncStream<S>,
        keyPath: KeyPath<S, SourceValue>,
        transform: @escaping (SourceValue) -> Value
    ) where Value: Equatable {
        self.value = initialValue

        // TODO: #1 CRITICAL — Same retain cycle as primary initializer above.
        Task {
            for await state in stateStream {
                let newValue = transform(state[keyPath: keyPath])
                if self.value != newValue {
                    self.value = newValue
                }
            }
        }
    }
}
