//
//  UserProfileAction.swift
//  UserProfileFeature
//
//  Created by maxime wacker on 09/12/2025.
//

import ReduxCoreIFC

public enum UserProfileAction: Action {
    case setName(String)
    case setEmail(String)
    case login
    case logout
    case loginSuccess(name: String, email: String) 
    case loginFailure(String)
}
