//
//  DemoApp.swift
//  Composite_Async_Store_POC
//
//  Created by maxime wacker on 03/12/2025.
//
import ReduxCoreIFC
import ReduxCoreIMP
import SwiftUI

import CounterRedux
import UserProfileRedux

// MARK: - App State and Actions

// Composed App State
struct AppState: StoreState {
    var counter: CounterState = CounterState()
    var user: UserProfileState = UserProfileState()
}

// Parent Action that encapsulates all sub-actions
enum AppAction: Action {
    case counter(CounterAction)
    case user(UserProfileAction)
}

// MARK: - App Reducer

// Composed Reducer using lift
let appReducer: Reducer<AppState, AppAction> = combine(
    lift(
        reducer: counterReducer,
        state: \.counter,
        action: { action in
            if case .counter(let counterAction) = action {
                return counterAction
            }
            return nil
        }
    ),
    lift(
        reducer: userReducer,
        state: \.user,
        action: { action in
            if case .user(let userAction) = action {
                return userAction
            }
            return nil
        }
    )
)

// MARK: - App Middlewares

let appMiddlewares: [Middleware<AppState, AppAction>] = [    
    liftMiddleware(
        loginMiddleware(),
        state: \.user,
        extractAction: { action in
            if case .user(let userAction) = action {
                return userAction
            }
            return nil
        },
        embedAction: { AppAction.user($0) }
    )
]

// MARK: - App

@main
struct ReduxApp: App {
    @State private var container: ViewContainer<AppState, AppAction>

    init() {
        let store = Store(
            initialState: AppState(),
            reducer: appReducer,
            middlewares: appMiddlewares
        )

        self._container = State(initialValue: ViewContainer(store: store))
    }

    var body: some Scene {
        WindowGroup {
            POCView(container: container)
        }
    }
}
