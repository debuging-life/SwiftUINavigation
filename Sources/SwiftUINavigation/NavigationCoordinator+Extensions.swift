//
//  NavigationCoordinator+Extensions.swift
//  SwiftUINavigation
//
//  Created by Pardip Bhatti on 22/12/25.
//

import SwiftUI

public extension NavigationCoordinator {
    /// Push and replace - navigate to new destination after clearing path
    func pushAndReplace(to destination: Destination) {
        navigateToRoot()
        navigate(to: NavigationStep(destination: destination, type: .push))
    }
    
    /// Present sheet with completion
    func presentSheet(
        _ destination: Destination,
        onDismiss: (() -> Void)? = nil
    ) {
        navigate(to: NavigationStep(
            destination: destination,
            type: .sheet,
            onDismiss: onDismiss
        ))
    }
    
    /// Present full screen cover with completion
    func presentFullScreen(
        _ destination: Destination,
        onDismiss: (() -> Void)? = nil
    ) {
        navigate(to: NavigationStep(
            destination: destination,
            type: .fullScreenCover,
            onDismiss: onDismiss
        ))
    }
    
    /// Push with completion
    func push(
        _ destination: Destination,
        onComplete: (() -> Void)? = nil
    ) {
        navigate(to: NavigationStep(
            destination: destination,
            type: .push,
            onComplete: onComplete
        ))
    }
}
