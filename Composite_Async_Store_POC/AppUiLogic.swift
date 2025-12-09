//
//  AppUiLogic.swift
//  Composite_Async_Store_POC
//
//  Created by maxime wacker on 09/12/2025.
//

import Foundation
import ReduxCoreIFC
import ReduxCoreIMP

// MARK: - UI State and Actions

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