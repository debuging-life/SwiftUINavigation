// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

// MARK: - Generic Coordinator
@MainActor
@Observable
public final class NavigationCoordinator<Destination: Hashable> {

    /// Typed navigation stack. Using `[Destination]` instead of the type-erased
    /// `NavigationPath` makes the stack introspectable and reconcilable, which is
    /// what lets us clean up correctly after the system back button / swipe-back.
    public var path: [Destination] = []

    public var presentedSheet: NavigationStep<Destination>?
    public var presentedFullScreenCover: NavigationStep<Destination>?

    // Per-push tokens kept 1:1 with `path`, so any pop can be reconciled.
    private var pushTokens: [UUID] = []
    private var onDismissHandlers: [UUID: () -> Void] = [:]

    // Dismiss handlers for modally presented destinations.
    private var sheetOnDismiss: (() -> Void)?
    private var fullScreenOnDismiss: (() -> Void)?

    public init() {}

    // MARK: - Push

    public func push(_ destination: Destination, onDismiss: (() -> Void)? = nil) {
        let token = UUID()
        pushTokens.append(token)
        if let onDismiss { onDismissHandlers[token] = onDismiss }
        path.append(destination)
    }

    public func push(_ destinations: [Destination]) {
        for destination in destinations { push(destination) }
    }

    public func pushAndReplace(to destination: Destination) {
        navigateToRoot()
        push(destination)
    }

    // MARK: - Pop

    public func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()   // onChange in the view fires reconcile(toDepth:)
    }

    public func navigateBack(count: Int) {
        guard count > 0, !path.isEmpty else { return }
        path.removeLast(min(count, path.count))
    }

    public func navigateToRoot() {
        path.removeAll()
    }

    /// Re-syncs handler bookkeeping with `path` after ANY pop — programmatic,
    /// system back button, or swipe-back gesture — firing the onDismiss handler
    /// for every destination that left the stack.
    public func reconcile(toDepth depth: Int) {
        guard depth < pushTokens.count else { return }
        while pushTokens.count > depth {
            let token = pushTokens.removeLast()
            onDismissHandlers.removeValue(forKey: token)?()
        }
    }

    // MARK: - Presentation

    public func presentSheet(_ destination: Destination, onDismiss: (() -> Void)? = nil) {
        sheetOnDismiss = onDismiss
        presentedSheet = NavigationStep(destination: destination, type: .sheet)
    }

    public func presentFullScreen(_ destination: Destination, onDismiss: (() -> Void)? = nil) {
        fullScreenOnDismiss = onDismiss
        presentedFullScreenCover = NavigationStep(destination: destination, type: .fullScreenCover)
    }

    public func dismissPresented() {
        presentedSheet = nil
        presentedFullScreenCover = nil
    }

    /// Called from the view's `.sheet(onDismiss:)` so user-driven (swipe-down)
    /// dismissals also fire the handler.
    public func didDismissSheet() {
        sheetOnDismiss?()
        sheetOnDismiss = nil
    }

    public func didDismissFullScreen() {
        fullScreenOnDismiss?()
        fullScreenOnDismiss = nil
    }

    // MARK: - Queries (now accurate, because the path is typed)

    public var isAtRoot: Bool { path.isEmpty }
    public var depth: Int { path.count }
    public var current: Destination? { path.last }
    public func contains(_ destination: Destination) -> Bool { path.contains(destination) }
    public var hasPresentation: Bool {
        presentedSheet != nil || presentedFullScreenCover != nil
    }
}
