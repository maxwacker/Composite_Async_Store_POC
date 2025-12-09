//
//  UserProbileLoginMiddleware.swift
//  UserProfileFeature
//
//  Created by maxime wacker on 09/12/2025.
//

import ReduxCoreIFC

func fetchUserProfile() async -> (name: String, email: String) {
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    return (name: "Maxime", email: "maxime@example.com")
}

public func loginMiddleware() -> Middleware<UserProfileState, UserProfileAction> {
    return { state, action in
        if case .login = action {
            let (name, email) = await fetchUserProfile()
            return [
                .loginSuccess(name: name, email: email)
            ]
        }
        return [action]
    }
}

