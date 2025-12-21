//
//  File.swift
//  SwiftUINavigation
//
//  Created by Pardip Bhatti on 21/12/25.
//

import Foundation
import SwiftUI

// MARK: - Navigation Step Protocol
protocol NavigationStepProtocol: Equatable {
    associatedtype Destination: Hashable
    var destination: Destination? { get set }
    var isPresented: Bool { get set }
    var type: NavigationType { get set }
    var onComplete: (() -> Void)? { get set }
    var onDismiss: (() -> Void)? { get set }
}

// MARK: - Generic Navigation Step
public struct NavigationStep<T: Hashable>: @MainActor NavigationStepProtocol {
    public var destination: T?
    public var isPresented: Bool
    public var type: NavigationType
    public var onComplete: (() -> Void)?
    public var onDismiss: (() -> Void)?
    
    public init(
        destination: T? = nil,
        isPresented: Bool = false,
        type: NavigationType = .push,
        onComplete: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.destination = destination
        self.isPresented = isPresented
        self.type = type
        self.onComplete = onComplete
        self.onDismiss = onDismiss
    }
    
    public static func == (lhs: NavigationStep<T>, rhs: NavigationStep<T>) -> Bool {
        lhs.destination == rhs.destination &&
        lhs.isPresented == rhs.isPresented &&
        lhs.type == rhs.type
    }
}

// MARK: - Extensions
extension NavigationStep: Identifiable {
    public var id: T? { destination }
}
