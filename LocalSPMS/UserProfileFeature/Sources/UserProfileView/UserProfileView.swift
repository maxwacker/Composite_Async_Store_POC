//
//  UserProfileView.swift
//  UserProfileFeature
//
//  Created by maxime wacker on 09/12/2025.
//
import SwiftUI

import ReduxCoreIFC
import ReduxCoreIMP

import UserProfileRedux

public struct UserProfileView: View {
    let interactor: any Interacting<UserProfileAction>
    let namePresenter: Presenter<String>
    let isLoggedInPresenter: Presenter<Bool>

    @State private var nameText: String = ""

    public init(interactor: any Interacting<UserProfileAction>, namePresenter: Presenter<String>, isLoggedInPresenter: Presenter<Bool>) {
        self.interactor = interactor
        self.namePresenter = namePresenter
        self.isLoggedInPresenter = isLoggedInPresenter
    }

    public var body: some View {
        VStack(spacing: 16) {
            if isLoggedInPresenter.value {
                Text("Welcome, \(namePresenter.value)!")
                    .font(.title2)

                Button("Logout") {
                    Task {
                        await interactor.send(.logout)
                    }
                }
                .buttonStyle(.bordered)
            } else {
                TextField("Name", text: $nameText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: namePresenter.value) { _, newValue in
                        if nameText != newValue {
                            nameText = newValue
                        }
                    }

                Button("Login") {
                    Task {
                        await interactor.send(.setName(nameText))
                        await interactor.send(.login)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

#if DEBUG
import SwiftUI
// MARK: - Mock Store for Previews

/// A simplified store implementation for SwiftUI previews that combines
/// both presenter and interactor functionality in a single object.
@MainActor
final class MockStore<S: StoreState, A: Action>: Interacting {
    private var state: S
    private let reducer: Reducer<S, A>
    private var continuations: [UUID: AsyncStream<S>.Continuation] = [:]

    /// Optional middleware for simulating async behavior (e.g., login).
    ///
    /// `nonisolated(unsafe)` is safe here because:
    /// - The property is an immutable `let`, assigned once in `init` and never mutated.
    /// - The closure is `@Sendable`, so it captures no mutable isolated state.
    private nonisolated(unsafe) let middleware: (@Sendable (S, A) async -> A?)?
    
    init(
        initialState: S,
        reducer: @escaping Reducer<S, A>,
        middleware: (@Sendable (S, A) async -> A?)? = nil
    ) {
        self.state = initialState
        self.reducer = reducer
        self.middleware = middleware
    }
    
    // MARK: - Interacting Conformance
    
    nonisolated func send(_ action: A) async {
        let currentState = await MainActor.run {
            print("Preview action: \(action)")
            
            // Apply reducer with the action
            reducer(&state, action)
            
            // Notify all subscribers of the state change
            for continuation in continuations.values {
                continuation.yield(state)
            }
            
            return state
        }
        
        // Run middleware if provided (for side effects like login)
        if let middleware = middleware {
            if let followUpAction = await middleware(currentState, action) {
                // Send the follow-up action (e.g., loginSuccess)
                await send(followUpAction)
            }
        }
    }
    
    // MARK: - Presenter Creation
    
    /// Creates a Presenter for a specific keypath of the state
    func presenter<Value: Equatable>(
        for keyPath: KeyPath<S, Value>
    ) -> Presenter<Value> {
        let id = UUID()
        let stream = AsyncStream<S> { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
            self.continuations[id] = continuation
            continuation.yield(self.state)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.continuations.removeValue(forKey: id)
                }
            }
        }
        
        return Presenter(
            initialValue: state[keyPath: keyPath],
            stateStream: stream,
            keyPath: keyPath
        )
    }
}

// MARK: - Preview

#Preview("Logged Out") {
    LoggedOutPreview()
        .frame(width: 500, height: 400)
        .background(Color(.windowBackgroundColor))
}

#Preview("Logged In") {
    LoggedInPreview()
        .frame(width: 500, height: 400)
        .background(Color(.windowBackgroundColor))
}

private struct LoggedOutPreview: View {
    @State private var mockStore = MockStore(
        initialState: UserProfileState(name: "", isLoggedIn: false),
        reducer: userReducer,
        middleware: { state, action in
            // Simulate login middleware behavior
            guard case .login = action else { return nil }
            
            // Simulate network delay
            try? await Task.sleep(for: .seconds(1))
            
            // Simulate successful login with current name
            let name = state.name.isEmpty ? "Guest" : state.name
            return .loginSuccess(name: name, email: "\(name.lowercased())@example.com")
        }
    )
    
    var body: some View {
        UserProfileView(
            interactor: mockStore,
            namePresenter: mockStore.presenter(for: \.name),
            isLoggedInPresenter: mockStore.presenter(for: \.isLoggedIn)
        )
    }
}

private struct LoggedInPreview: View {
    @State private var mockStore = MockStore(
        initialState: UserProfileState(name: "Jane Doe", email: "jane@example.com", isLoggedIn: true),
        reducer: userReducer,
        middleware: { state, action in
            // Simulate login middleware behavior for re-login
            guard case .login = action else { return nil }
            
            // Simulate network delay
            try? await Task.sleep(for: .seconds(1))
            
            // Simulate successful login
            let name = state.name.isEmpty ? "Guest" : state.name
            return .loginSuccess(name: name, email: "\(name.lowercased().replacingOccurrences(of: " ", with: "."))@example.com")
        }
    )
    
    var body: some View {
        UserProfileView(
            interactor: mockStore,
            namePresenter: mockStore.presenter(for: \.name),
            isLoggedInPresenter: mockStore.presenter(for: \.isLoggedIn)
        )
    }
}
#endif


