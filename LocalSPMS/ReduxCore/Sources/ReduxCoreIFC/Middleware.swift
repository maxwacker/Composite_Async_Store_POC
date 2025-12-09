//
//  Middleware.swift
//  Composite_Async_Store_POC
//
//  Created by maxime wacker on 02/12/2025.
//

public typealias Middleware<S: StoreState, A: Action> = (S, A) async -> [A]

/// Lift a middleware from sub-state/sub-action to parent state/parent action
public func liftMiddleware<ParentState: StoreState, SubState: StoreState, ParentAction: Action, SubAction: Action>(
    _ middleware: @escaping Middleware<SubState, SubAction>,
    state stateKeyPath: KeyPath<ParentState, SubState>,
    extractAction: @escaping @Sendable (ParentAction) -> SubAction?,
    embedAction: @escaping @Sendable (SubAction) -> ParentAction
) -> Middleware<ParentState, ParentAction> {
    return { parentState, parentAction in
        guard let subAction = extractAction(parentAction) else {
            return [parentAction]  // Not a sub-action, pass through
        }
        
        let subState = parentState[keyPath: stateKeyPath]
        let resultActions = await middleware(subState, subAction)
        
        return resultActions.map(embedAction)
    }
}
