//
//  UserProfileReducer.swift
//  UserProfileFeature
//
//  Created by maxime wacker on 09/12/2025.
//

import ReduxCoreIFC

public let userReducer: Reducer<UserProfileState, UserProfileAction> = { state, action in
    switch action {
    case .setName(let name):
        state.name = name
    case .setEmail(let email):
        state.email = email
    case .login:
        state.isLoggedIn = false
    case .logout:
        state.isLoggedIn = false
        state.name = ""
        state.email = ""
    case .loginSuccess(name: let name, email: let email):
        state.name = name
        state.email = email
        state.isLoggedIn = true
    case .loginFailure(let error):
        print(error)
    }
}
