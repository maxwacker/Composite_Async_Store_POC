//
//  UserProfileState.swift
//  UserProfileFeature
//
//  Created by maxime wacker on 09/12/2025.
//

import ReduxCoreIFC

public struct UserProfileState: StoreState {
    public var name: String = ""
    public var email: String = ""
    public var isLoggedIn: Bool = false
    
    public init(name: String = "", email: String = "", isLoggedIn: Bool = false) {
        self.name = name
        self.email = email
        self.isLoggedIn = isLoggedIn
    }
}
