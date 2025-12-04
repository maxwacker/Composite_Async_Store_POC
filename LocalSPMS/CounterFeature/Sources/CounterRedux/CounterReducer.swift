//
//  CounterReducer.swift
//  CounterFeature
//
//  Created by maxime wacker on 04/12/2025.
//
import ReduxCoreIFC

public let counterReducer: Reducer<CounterState, CounterAction> = { state, action in
    switch action {
    case .increment:
        state.count += 1
    case .decrement:
        state.count -= 1
    case .reset:
        state.count = 0
    }
}
