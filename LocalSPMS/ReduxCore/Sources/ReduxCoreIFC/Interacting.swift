//
//  Interacting.swift
//  ReduxCore
//
//  Created by maxime wacker on 03/12/2025.
//
public protocol Interacting<Action> {
    associatedtype Action
    func send(_ action: Action) async
}
