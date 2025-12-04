//
//  Reducer.swift
//  ReduxCore
//
//  Created by maxime wacker on 03/12/2025.
//

public typealias Reducer<S: StoreState, A: Action> = @Sendable (inout S, A) -> Void
//extension Reducer: Sendable {}

/// Lift a reducer from a sub-state to a parent state using a WritableKeyPath
public func lift<ParentState: StoreState, SubState: StoreState, A: Action>(
    reducer: @escaping Reducer<SubState, A>,
    state keyPath: WritableKeyPath<ParentState, SubState> & Sendable
) -> Reducer<ParentState, A> {
    return { parentState, action in
        reducer(&parentState[keyPath: keyPath], action)
    }
}

/// Lift a reducer that handles a subset of parent actions
public func lift<ParentState: StoreState, SubState: StoreState, ParentAction: Action, SubAction: Action>(
    reducer: @escaping Reducer<SubState, SubAction>,
    state stateKeyPath: WritableKeyPath<ParentState, SubState> & Sendable,
    action actionPrism: @escaping @Sendable (ParentAction) -> SubAction?
) -> Reducer<ParentState, ParentAction> {
    return { parentState, parentAction in
        guard let subAction = actionPrism(parentAction) else { return }
        reducer(&parentState[keyPath: stateKeyPath], subAction)
    }
}

/// Combine multiple reducers into one
public func combine<S: StoreState, A: Action>(_ reducers: Reducer<S, A>...) -> Reducer<S, A> {
    return { state, action in
        for reducer in reducers {
            reducer(&state, action)
        }
    }
}

