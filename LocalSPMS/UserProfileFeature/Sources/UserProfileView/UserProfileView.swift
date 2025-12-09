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
    let namePresenter: Presenter<UserProfileState, String>
    let isLoggedInPresenter: Presenter<UserProfileState, Bool>
    
    public init(interactor: any Interacting<UserProfileAction>, namePresenter: Presenter<UserProfileState, String>, isLoggedInPresenter: Presenter<UserProfileState, Bool>) {
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
                TextField("Name", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: namePresenter.value) { _, newValue in
                        Task {
                            await interactor.send(.setName(newValue))
                        }
                    }
                
                Button("Login") {
                    Task {
                        await interactor.send(.login)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

