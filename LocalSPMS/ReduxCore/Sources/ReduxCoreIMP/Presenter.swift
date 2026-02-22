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

    // nonisolated(unsafe) because deinit is non-isolated but Presenter is @MainActor.
    // Safe: written once in init, only read in deinit (after all other access),
    // and Task.cancel() is thread-safe.
    // @ObservationIgnored so @Observable macro does not synthesize access tracking for this property.
    @ObservationIgnored
    nonisolated(unsafe) private var task: Task<Void, Never>?

    public init(
        initialValue: Value,
        stateStream: AsyncStream<S>,
        keyPath: KeyPath<S, Value>
    ) where Value: Equatable {
        self.value = initialValue

        self.task = Task { [weak self] in
            for await state in stateStream {
                guard let self else { return }
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

        self.task = Task { [weak self] in
            for await state in stateStream {
                guard let self else { return }
                let newValue = transform(state[keyPath: keyPath])
                if self.value != newValue {
                    self.value = newValue
                }
            }
        }
    }

    deinit {
        task?.cancel()
    }
}
