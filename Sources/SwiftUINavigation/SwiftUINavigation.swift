// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

// MARK: - Generic Coordinator
@Observable
public class NavigationCoordinator<Destination: Hashable> {
    public var navigationPath = NavigationPath()
        public var presentedSheet: NavigationStep<Destination>?
        public var presentedFullScreenCover: NavigationStep<Destination>?
        public var presentedItem: NavigationStep<Destination>?
        
        private var onCompleteHandlers: [UUID: () -> Void] = [:]
        private var onDismissHandlers: [UUID: () -> Void] = [:]
        private var stepIdentifiers: [Destination: UUID] = [:]
        
        public init() {}
    
    public func navigate(to step: NavigationStep<Destination>) {
        let identifier = UUID()
        
        if let destination = step.destination {
            stepIdentifiers[destination] = identifier
            
            if let onComplete = step.onComplete {
                onCompleteHandlers[identifier] = onComplete
            }
            
            if let onDismiss = step.onDismiss {
                onDismissHandlers[identifier] = onDismiss
            }
        }
        
        switch step.type {
        case .push:
            if let destination = step.destination {
                navigationPath.append(destination)
            }
        case .present:
            presentedItem = step
        case .sheet:
            presentedSheet = step
        case .fullScreenCover:
            presentedFullScreenCover = step
        }
    }
    
    // MARK: - Multiple Navigation
    
    /// Navigate to multiple destinations in sequence
    /// - Parameters:
    ///   - destinations: Array of destinations to navigate to
    ///   - onBatchComplete: Called after all destinations are pushed (optional)
    public func navigateToMultiple(
        _ destinations: [Destination],
        onBatchComplete: (() -> Void)? = nil
    ) {
        guard !destinations.isEmpty else { return }
        
        for destination in destinations {
            navigationPath.append(destination)
            let identifier = UUID()
            stepIdentifiers[destination] = identifier
        }
        
        // Call batch completion handler if provided
        onBatchComplete?()
    }
    
    /// Navigate to multiple destinations with individual callbacks
    /// - Parameter steps: Array of destinations with their respective callbacks
    public func navigateToMultiple(_ steps: [(destination: Destination, onComplete: (() -> Void)?, onDismiss: (() -> Void)?)]) {
        for step in steps {
            let identifier = UUID()
            stepIdentifiers[step.destination] = identifier
            
            if let onComplete = step.onComplete {
                onCompleteHandlers[identifier] = onComplete
            }
            
            if let onDismiss = step.onDismiss {
                onDismissHandlers[identifier] = onDismiss
            }
            
            navigationPath.append(step.destination)
        }
    }
    
    /// Navigate back multiple steps
    /// - Parameter count: Number of steps to go back (default: all)
    public func navigateBack(count: Int? = nil) {
        let stepsToRemove = count ?? navigationPath.count
        
        for _ in 0..<min(stepsToRemove, navigationPath.count) {
            navigationPath.removeLast()
        }
    }
    
    // MARK: - Existing Methods
    
    public func completeStep(for destination: Destination) {
        if let identifier = stepIdentifiers[destination], let handler = onCompleteHandlers[identifier] {
            handler()
            onCompleteHandlers.removeValue(forKey: identifier)
        }
    }
    
    public func dismissStep(for destination: Destination) {
        if let identifier = stepIdentifiers[destination], let handler = onDismissHandlers[identifier] {
            handler()
            onDismissHandlers.removeValue(forKey: identifier)
            stepIdentifiers.removeValue(forKey: destination)
        }
    }
    
    public func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    public func navigateToRoot() {
        navigationPath = NavigationPath()
        onCompleteHandlers.removeAll()
        onDismissHandlers.removeAll()
        stepIdentifiers.removeAll()
    }
    
    public func dismissPresented() {
        if let step = presentedSheet, let destination = step.destination {
            dismissStep(for: destination)
        }
        
        if let step = presentedFullScreenCover, let destination = step.destination {
            dismissStep(for: destination)
        }
        
        if let step = presentedItem, let destination = step.destination {
            dismissStep(for: destination)
        }
        
        presentedSheet = nil
        presentedFullScreenCover = nil
        presentedItem = nil
    }
}
