//
//  CounterAction.swift
//  CounterFeature
//
//  Created by maxime wacker on 04/12/2025.
//
import ReduxCoreIFC

public enum CounterAction: Action, Sendable {
    case increment
    case decrement
    case reset
}
