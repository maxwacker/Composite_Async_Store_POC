//
//  POCView.swift
//  Composite_Async_Store_POC
//
//  Created by maxime wacker on 02/12/2025.
//

import SwiftUI
import Observation

import ReduxCoreIMP

import CounterView

import UserProfileView

// MARK: - Content View

struct ContentView: View {
    let container: ViewContainer<AppState, AppAction>
    
    @State private var counterPresenter: Presenter<Int>?
    @State private var namePresenter: Presenter<String>?
    @State private var isLoggedInPresenter: Presenter<Bool>?
    
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
