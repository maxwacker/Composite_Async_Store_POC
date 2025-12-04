//
//  CounterState.swift
//  CounterFeature
//
//  Created by maxime wacker on 04/12/2025.
//
import ReduxCoreIFC

public struct CounterState: StoreState, Sendable {
    public var count: Int = 0
    public init(count: Int = 0) {
        self.count = count
    }
    
}

