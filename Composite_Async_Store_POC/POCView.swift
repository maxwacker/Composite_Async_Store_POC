//
//  POCView.swift
//  Composite_Async_Store_POC
//
//  Created by maxime wacker on 02/12/2025.
//

import SwiftUI
import Observation

import ReduxCoreIFC
import ReduxCoreIMP

import CounterRedux
import CounterView

import UserProfileRedux
import UserProfileView

// Sub-State: UI Settings
struct UIState: StoreState {
    var isLoading: Bool = false
    var errorMessage: String?
    var theme: Theme = .light
    
    enum Theme: String, Equatable {
        case light, dark
    }
}

enum UIAction: Action {
    case startLoading
    case stopLoading
    case setError(String?)
    case toggleTheme
}

let uiReducer: Reducer<UIState, UIAction> = { state, action in
    switch action {
    case .startLoading:
        state.isLoading = true
    case .stopLoading:
        state.isLoading = false
    case .setError(let message):
        state.errorMessage = message
    case .toggleTheme:
        state.theme = state.theme == .light ? .dark : .light
    }
}

// Composed App State
struct AppState: StoreState {
    var counter: CounterState = CounterState()
    var user: UserProfileState = UserProfileState()
    var ui: UIState = UIState()
}

// Parent Action that encapsulates all sub-actions
enum AppAction: Action {
    case counter(CounterAction)
    case user(UserProfileAction)
    case ui(UIAction)
}

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
    ),
    lift(
        reducer: uiReducer,
        state: \.ui,
        action: { action in
            if case .ui(let uiAction) = action {
                return uiAction
            }
            return nil
        }
    )
)

// MARK: - Content View

struct ContentView: View {
    let container: ViewContainer<AppState, AppAction>
    
    @State private var counterPresenter: Presenter<CounterState, Int>?
    @State private var namePresenter: Presenter<UserProfileState, String>?
    @State private var isLoggedInPresenter: Presenter<UserProfileState, Bool>?
    
    var body: some View {
        Group {
            if let counterPresenter,
               let namePresenter,
               let isLoggedInPresenter {
                TabView {
                    CounterView(
                        interactor: container.adaptedInteractor { counterAction in
                            AppAction.counter(counterAction)
                        },
                        counterPresenter: counterPresenter
                    )
                    .tabItem {
                        Label("Counter", systemImage: "number")
                    }
                    
                    UserProfileView(
                        interactor: container.adaptedInteractor { userProfileAction in
                            AppAction.user(userProfileAction)
                        }
                        ,
                        namePresenter: namePresenter,
                        isLoggedInPresenter: isLoggedInPresenter
                    )
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            // Create child state presenter for counter
            counterPresenter = await container.childPresenter(
                extractChildState: \.counter,
                childKeyPath: \.count
            )
            
            // Create child state presenters for userProfile
            //namePresenter = await container.presenter(for: \.user.name)
            namePresenter = await container.childPresenter(
                extractChildState: \.user,
                childKeyPath: \.name)
            //isLoggedInPresenter = await container.presenter(for: \.user.isLoggedIn)
            isLoggedInPresenter = await container.childPresenter(
                extractChildState: \.user,
                childKeyPath: \.isLoggedIn)
        }
    }
}

// MARK: - Main POC View

struct POCView: View {
    let container: ViewContainer<AppState, AppAction>
    
    var body: some View {
        ContentView(container: container)
    }
}

#Preview {
    let store = Store(
        initialState: AppState(),
        reducer: appReducer,
        middlewares: appMiddlewares
    )
    let container = ViewContainer(store: store)
    return POCView(container: container)
}
