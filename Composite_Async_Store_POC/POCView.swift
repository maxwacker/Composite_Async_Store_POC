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

// MARK: - Adapter Classes

// Adapter to transform parent interactor to child interactor
@MainActor
final class AdaptedInteractor<ParentAction: Action, ChildAction: Action>: Interacting {
    private let parentInteractor: any Interacting<ParentAction>
    private let transform: (ChildAction) -> ParentAction
    
    init(
        parentInteractor: any Interacting<ParentAction>,
        transform: @escaping (ChildAction) -> ParentAction
    ) {
        self.parentInteractor = parentInteractor
        self.transform = transform
    }
    
    func send(_ action: ChildAction) async {
        await parentInteractor.send(transform(action))
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
    
    // Helper to create adapted interactor for child actions
    func adaptedInteractor<ChildAction: Action>(
        transform: @escaping (ChildAction) -> A
    ) -> AdaptedInteractor<A, ChildAction> {
        return AdaptedInteractor(
            parentInteractor: interactor,
            transform: transform
        )
    }
    
    // Helper to create child state presenter from parent state
    func childPresenter<ChildState: StoreState, Value: Equatable>(
        extractChildState: @escaping (S) -> ChildState,
        childKeyPath: KeyPath<ChildState, Value>
    ) async -> Presenter<ChildState, Value> {
        let currentState = await store.state
        let stateStream = await store.subscribe()
        
        // Create a transformed stream that extracts child state
        let childStateStream = AsyncStream<ChildState> { continuation in
            Task {
                for await parentState in stateStream {
                    continuation.yield(extractChildState(parentState))
                }
            }
        }
        
        return Presenter(
            initialValue: extractChildState(currentState)[keyPath: childKeyPath],
            stateStream: childStateStream,
            keyPath: childKeyPath
        )
    }
    
    deinit {
        stateStreamTask?.cancel()
    }
}


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
    @State private var container: ViewContainer<AppState, AppAction>?
    
    var body: some View {
        Group {
            if let container {
                ContentView(container: container)
            } else {
                ProgressView("Initializing...")
            }
        }
        .task {
            // Create the store with middleware
            // FIXME : Why do we need to repeat it there, since it's already done in ReduxApp
            let store = Store(
                initialState: AppState(),
                reducer: appReducer,
                middlewares: appMiddlewares
            )
            
            // Create the container
            container = ViewContainer(store: store)
        }
    }
}

#Preview {
    POCView()
}
