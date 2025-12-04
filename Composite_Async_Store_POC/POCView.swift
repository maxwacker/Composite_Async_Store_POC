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


// MARK: - Example Implementation with Composable States

// Sub-State: Counter



// Sub-State: User Profile
struct UserState: StoreState {
    var name: String = ""
    var email: String = ""
    var isLoggedIn: Bool = false
}

enum UserAction: Action {
    case setName(String)
    case setEmail(String)
    case login
    case logout
}

let userReducer: Reducer<UserState, UserAction> = { state, action in
    switch action {
    case .setName(let name):
        state.name = name
    case .setEmail(let email):
        state.email = email
    case .login:
        state.isLoggedIn = true
    case .logout:
        state.isLoggedIn = false
        state.name = ""
        state.email = ""
    }
}

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
    var user: UserState = UserState()
    var ui: UIState = UIState()
}

// Parent Action that encapsulates all sub-actions
enum AppAction: Action {
    case counter(CounterAction)
    case user(UserAction)
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

// Middleware example - Logging
func loggingMiddleware<S: StoreState, A: Action>() -> Middleware<S, A> {
    return { state, action in
        print("🔵 Action: \(action)")
        return action
    }
}

// MARK: - View Container

@MainActor
class ViewContainer<S: StoreState, A: Action> {
    let store: Store<S, A>
    let interactor: ActionEmitter<A>
    
    private let actionContinuation: AsyncStream<A>.Continuation
    private let actionStream: AsyncStream<A>
    private var stateStreamTask: Task<Void, Never>?
    
    init(store: Store<S, A>) {
        self.store = store
        
        var continuation: AsyncStream<A>.Continuation!
        self.actionStream = AsyncStream { continuation = $0 }
        self.actionContinuation = continuation
        
        self.interactor = ActionEmitter(continuation: continuation)
        
        // Connect action stream to store
        self.stateStreamTask = Task {
            await store.startProcessing(actionStream)
        }
    }
    
    func presenter<Value: Equatable>(
        for keyPath: KeyPath<S, Value>
    ) async -> Presenter<S, Value> {
        let currentState = await store.state
        let stateStream = await store.subscribe()
        return Presenter(
            initialValue: currentState[keyPath: keyPath],
            stateStream: stateStream,
            keyPath: keyPath
        )
    }
    
    func presenter<Value: Equatable, SourceValue>(
        for keyPath: KeyPath<S, SourceValue>,
        transform: @escaping (SourceValue) -> Value
    ) async -> Presenter<S, Value> {
        let currentState = await store.state
        let stateStream = await store.subscribe()
        return Presenter(
            initialValue: transform(currentState[keyPath: keyPath]),
            stateStream: stateStream,
            keyPath: keyPath,
            transform: transform
        )
    }
    
    deinit {
        stateStreamTask?.cancel()
    }
}

// MARK: - Example SwiftUI Views (Independent of Redux)



struct UserProfileView: View {
    let interactor: any Interacting<AppAction>
    let namePresenter: Presenter<AppState, String>
    let isLoggedInPresenter: Presenter<AppState, Bool>
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoggedInPresenter.value {
                Text("Welcome, \(namePresenter.value)!")
                    .font(.title2)
                
                Button("Logout") {
                    Task {
                        await interactor.send(.user(.logout))
                    }
                }
                .buttonStyle(.bordered)
            } else {
                TextField("Name", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: namePresenter.value) { _, newValue in
                        Task {
                            await interactor.send(.user(.setName(newValue)))
                        }
                    }
                
                Button("Login") {
                    Task {
                        await interactor.send(.user(.login))
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - Usage Example

struct ContentView: View {
    let container: ViewContainer<AppState, AppAction>
    
    @State private var counterPresenter: Presenter<AppState, Int>?
    @State private var namePresenter: Presenter<AppState, String>?
    @State private var isLoggedInPresenter: Presenter<AppState, Bool>?
    
    var body: some View {
        Group {
            if let counterPresenter,
               let namePresenter,
               let isLoggedInPresenter {
                TabView {
                    CounterView(
                        interactor: container.interactor,
                        counterPresenter: counterPresenter
                    )
                    .tabItem {
                        Label("Counter", systemImage: "number")
                    }
                    
                    UserProfileView(
                        interactor: container.interactor,
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
            // Create presenters for sub-state slices using KeyPath composition
            counterPresenter = await container.presenter(for: \.counter.count)
            namePresenter = await container.presenter(for: \.user.name)
            isLoggedInPresenter = await container.presenter(for: \.user.isLoggedIn)
        }
    }
}
