// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

/// A type-safe navigation coordinator for a single `NavigationStack`.
///
/// Own one instance in a parent view (`@State`), hand it to a ``CoordinatorView``,
/// and drive navigation by calling methods on it from anywhere — including child
/// views that read it from the environment:
///
/// ```swift
/// @Environment(NavigationCoordinator<Route>.self) private var router
/// // ...
/// router.push(.detail(id: "42"))
/// ```
///
/// The stack is stored as a typed `[Destination]`, which keeps it introspectable
/// and lets the coordinator reconcile its own lifecycle bookkeeping after *any*
/// pop — programmatic, the system back button, or the swipe-back gesture.
@MainActor
@Observable
public final class NavigationCoordinator<Destination: Hashable> {

    /// The typed navigation stack bound to the `NavigationStack`. The root view is
    /// index `-1`; `path[0]` is the first pushed screen.
    public var path: [Destination] = []

    /// The destination currently presented as a sheet, or `nil`.
    public var presentedSheet: Destination?

    /// The destination currently presented as a full-screen cover, or `nil`.
    public var presentedFullScreenCover: Destination?

    /// `onDismiss` handlers kept exactly parallel to ``path`` (one slot per pushed
    /// screen, `nil` when none was supplied). Reconciled by length, so it stays
    /// correct no matter how the stack is mutated.
    private var dismissHandlers: [(() -> Void)?] = []
    private var sheetOnDismiss: (() -> Void)?
    private var fullScreenOnDismiss: (() -> Void)?

    /// Creates an empty coordinator (the stack starts at the root view).
    public init() {}

    /// Creates a coordinator pre-seeded with a stack — handy for deep links and
    /// state restoration.
    public init(path: [Destination]) {
        self.path = path
        self.dismissHandlers = Array(repeating: nil, count: path.count)
    }

    // MARK: - Push

    /// Pushes a destination onto the stack.
    /// - Parameter onDismiss: Called when this screen later leaves the stack by any
    ///   means — programmatic pop, the system back button, or a swipe-back.
    public func push(_ destination: Destination, onDismiss: (() -> Void)? = nil) {
        dismissHandlers.append(onDismiss)
        path.append(destination)
    }

    /// Pushes several destinations in order.
    public func push(_ destinations: [Destination]) {
        for destination in destinations { push(destination) }
    }

    // MARK: - Pop

    /// Pops the top screen. Returns the destination that was removed, if any.
    @discardableResult
    public func pop() -> Destination? {
        guard !path.isEmpty else { return nil }
        let removed = path.removeLast()
        reconcile()
        return removed
    }

    /// Pops up to `count` screens.
    public func pop(_ count: Int) {
        guard count > 0, !path.isEmpty else { return }
        path.removeLast(min(count, path.count))
        reconcile()
    }

    /// Pops back until `destination` is the top of the stack. No-op if it isn't on
    /// the stack or is already on top.
    public func pop(to destination: Destination) {
        guard let index = path.firstIndex(of: destination) else { return }
        let keep = index + 1
        guard keep < path.count else { return }
        path.removeLast(path.count - keep)
        reconcile()
    }

    /// Pops everything back to the root view.
    public func popToRoot() {
        guard !path.isEmpty else { return }
        path.removeAll()
        reconcile()
    }

    // MARK: - Replace

    /// Replaces the entire stack in one update, firing `onDismiss` for every screen
    /// that was on the previous stack.
    public func setStack(_ destinations: [Destination]) {
        let previous = dismissHandlers
        dismissHandlers = Array(repeating: nil, count: destinations.count)
        path = destinations
        for handler in previous.reversed() { handler?() }
    }

    /// Clears the stack and pushes a single destination — the "log in / log out"
    /// style root swap.
    public func replace(with destination: Destination, onDismiss: (() -> Void)? = nil) {
        setStack([])
        push(destination, onDismiss: onDismiss)
    }

    // MARK: - Presentation

    /// Presents a destination as a sheet.
    /// - Parameter onDismiss: Called when the sheet is dismissed by any means,
    ///   including an interactive swipe-down.
    public func presentSheet(_ destination: Destination, onDismiss: (() -> Void)? = nil) {
        sheetOnDismiss = onDismiss
        presentedSheet = destination
    }

    /// Presents a destination as a full-screen cover.
    public func presentFullScreenCover(_ destination: Destination, onDismiss: (() -> Void)? = nil) {
        fullScreenOnDismiss = onDismiss
        presentedFullScreenCover = destination
    }

    /// Dismisses the sheet, if one is presented.
    public func dismissSheet() { presentedSheet = nil }

    /// Dismisses the full-screen cover, if one is presented.
    public func dismissFullScreenCover() { presentedFullScreenCover = nil }

    /// Dismisses any presented sheet and full-screen cover.
    public func dismissPresented() {
        presentedSheet = nil
        presentedFullScreenCover = nil
    }

    // MARK: - Queries

    /// `true` when the stack is empty (showing the root view).
    public var isAtRoot: Bool { path.isEmpty }

    /// Number of pushed screens above the root.
    public var depth: Int { path.count }

    /// The destination on top of the stack, or `nil` at the root.
    public var top: Destination? { path.last }

    /// Whether `destination` is anywhere on the current stack.
    public func contains(_ destination: Destination) -> Bool { path.contains(destination) }

    /// Whether a sheet is currently presented.
    public var isPresentingSheet: Bool { presentedSheet != nil }

    /// Whether a full-screen cover is currently presented.
    public var isPresentingFullScreenCover: Bool { presentedFullScreenCover != nil }

    /// Whether any sheet or full-screen cover is presented.
    public var isPresenting: Bool { isPresentingSheet || isPresentingFullScreenCover }

    // MARK: - Reconciliation

    /// Re-syncs lifecycle bookkeeping with the current ``path``, firing the
    /// `onDismiss` handler for every screen that has left the stack.
    ///
    /// ``CoordinatorView`` calls this automatically whenever the stack changes, so
    /// the system back button and swipe-back gesture are handled for you. You only
    /// need to call it yourself if you mutate ``path`` directly outside a
    /// ``CoordinatorView``.
    public func reconcile() {
        if dismissHandlers.count > path.count {
            let removed = Array(dismissHandlers[path.count...])
            dismissHandlers.removeLast(dismissHandlers.count - path.count)
            for handler in removed.reversed() { handler?() }
        } else if dismissHandlers.count < path.count {
            // The stack grew without going through `push` (e.g. a direct mutation);
            // keep the handler array parallel so future pops stay aligned.
            dismissHandlers.append(contentsOf: repeatElement(nil, count: path.count - dismissHandlers.count))
        }
    }

    // Called by `CoordinatorView` from the `.sheet`/`.fullScreenCover` onDismiss.
    func fireSheetDismiss() {
        sheetOnDismiss?()
        sheetOnDismiss = nil
    }

    func fireFullScreenDismiss() {
        fullScreenOnDismiss?()
        fullScreenOnDismiss = nil
    }
}
