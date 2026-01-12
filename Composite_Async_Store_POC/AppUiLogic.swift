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

// Sub-State: Global UI Settings
// Note: This should only contain truly application-wide UI concerns.
// Feature-specific concerns like loading states and error messages
// should live in their respective feature states (CounterState, UserProfileState, etc.)
struct UIState: StoreState {
    var theme: Theme = .light
    
    enum Theme: String, Equatable {
        case light, dark
    }
}

enum UIAction: Action {
    case toggleTheme
}

let uiReducer: Reducer<UIState, UIAction> = { state, action in
    switch action {
    case .toggleTheme:
        state.theme = state.theme == .light ? .dark : .light
    }
}
