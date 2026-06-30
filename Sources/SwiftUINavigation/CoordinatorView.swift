//
//  CoordinatorView.swift
//  SwiftUINavigation
//
//  Created by Pardip Bhatti on 22/12/25.
//

import SwiftUI

/// Hosts a `NavigationStack` driven by a ``NavigationCoordinator`` and wires up
/// destinations, sheets, full-screen covers, and deep links.
///
/// The coordinator is injected into the environment, so any child can read it with
/// zero setup:
///
/// ```swift
/// @Environment(NavigationCoordinator<Route>.self) private var router
/// ```
public struct CoordinatorView<
    Destination: Hashable,
    Root: View,
    DestinationContent: View
>: View {

    private let coordinator: NavigationCoordinator<Destination>
    private let rootView: Root
    private let destinationBuilder: (Destination) -> DestinationContent
    private let onDeepLink: (@MainActor (URL, NavigationCoordinator<Destination>) -> Void)?

    public init(
        coordinator: NavigationCoordinator<Destination>,
        @ViewBuilder rootView: () -> Root,
        @ViewBuilder destinationBuilder: @escaping (Destination) -> DestinationContent,
        onDeepLink: (@MainActor (URL, NavigationCoordinator<Destination>) -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.rootView = rootView()
        self.destinationBuilder = destinationBuilder
        self.onDeepLink = onDeepLink
    }

    public var body: some View {
        @Bindable var coordinator = coordinator   // local bindings; the parent owns the instance

        NavigationStack(path: $coordinator.path) {
            rootView
                .navigationDestination(for: Destination.self, destination: destinationBuilder)
        }
        .sheet(
            item: sheetItem(coordinator),
            onDismiss: { coordinator.fireSheetDismiss() }
        ) { item in
            destinationBuilder(item.value)
        }
        .fullScreenCover(
            item: coverItem(coordinator),
            onDismiss: { coordinator.fireFullScreenDismiss() }
        ) { item in
            destinationBuilder(item.value)
        }
        .onChange(of: coordinator.path) { _, _ in
            coordinator.reconcile()   // catches the system back button & swipe-back
        }
        .onOpenURL { url in
            onDeepLink?(url, coordinator)
        }
        .environment(coordinator)
    }

    private func sheetItem(
        _ coordinator: NavigationCoordinator<Destination>
    ) -> Binding<IdentifiedDestination<Destination>?> {
        Binding(
            get: { coordinator.presentedSheet.map { IdentifiedDestination($0) } },
            set: { coordinator.presentedSheet = $0?.value }
        )
    }

    private func coverItem(
        _ coordinator: NavigationCoordinator<Destination>
    ) -> Binding<IdentifiedDestination<Destination>?> {
        Binding(
            get: { coordinator.presentedFullScreenCover.map { IdentifiedDestination($0) } },
            set: { coordinator.presentedFullScreenCover = $0?.value }
        )
    }
}

// MARK: - NavigationDestination convenience

public extension CoordinatorView
where Destination: NavigationDestination, DestinationContent == RoutedDestinationView<Destination> {

    /// Convenience initializer for destinations that build their own views.
    ///
    /// When `Destination` conforms to ``NavigationDestination`` you don't pass a
    /// `destinationBuilder` — each screen is built from its `view()` and its
    /// `title` / `navigationBarTitleDisplayMode` are applied automatically:
    ///
    /// ```swift
    /// CoordinatorView(coordinator: router) {
    ///     HomeView()
    /// }
    /// ```
    init(
        coordinator: NavigationCoordinator<Destination>,
        @ViewBuilder rootView: () -> Root,
        onDeepLink: (@MainActor (URL, NavigationCoordinator<Destination>) -> Void)? = nil
    ) {
        self.init(
            coordinator: coordinator,
            rootView: rootView,
            destinationBuilder: { RoutedDestinationView(destination: $0) },
            onDeepLink: onDeepLink
        )
    }
}

// MARK: - Supporting types

/// Wraps a `Destination` so `.sheet(item:)` / `.fullScreenCover(item:)` can use it
/// without requiring `Destination: Identifiable`.
struct IdentifiedDestination<Destination: Hashable>: Identifiable {
    let value: Destination
    var id: Destination { value }
    init(_ value: Destination) { self.value = value }
}
