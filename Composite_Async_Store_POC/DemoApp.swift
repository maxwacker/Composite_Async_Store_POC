//
//  DemoApp.swift
//  Composite_Async_Store_POC
//
//  Created by maxime wacker on 03/12/2025.
//
import ReduxCoreIFC
import ReduxCoreIMP
import SwiftUI

import UserProfileRedux

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
