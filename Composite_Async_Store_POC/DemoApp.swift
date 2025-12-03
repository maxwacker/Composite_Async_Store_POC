//
//  DemoApp.swift
//  Composite_Async_Store_POC
//
//  Created by maxime wacker on 03/12/2025.
//
import ReduxCoreIFC
import ReduxCoreIMP
import SwiftUI

@main
struct ReduxApp: App {
    @State private var container: ViewContainer<AppState, AppAction>
    
    init() {
        let store = Store(
            initialState: AppState(),
            reducer: appReducer,
            middlewares: [loggingMiddleware()]
        )
        
        self._container = State(initialValue: ViewContainer(store: store))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
        }
    }
}
