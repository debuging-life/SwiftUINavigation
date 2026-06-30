//
//  CoordinatorView.swift
//  SwiftUINavigation
//
//  Created by Pardip Bhatti on 22/12/25.
//

import SwiftUI

public struct CoordinatorView<
    Destination: Hashable,
    Root: View,
    DestinationContent: View
>: View {

    private let coordinator: NavigationCoordinator<Destination>
    private let rootView: Root
    private let destinationBuilder: (Destination) -> DestinationContent
    private let onDeepLink: (@MainActor (URL, NavigationCoordinator<Destination>) -> Void)?
    private let environmentKeyPath: WritableKeyPath<EnvironmentValues, NavigationCoordinator<Destination>>

    public init(
        coordinator: NavigationCoordinator<Destination>,
        environmentKeyPath: WritableKeyPath<EnvironmentValues, NavigationCoordinator<Destination>>,
        @ViewBuilder rootView: () -> Root,
        @ViewBuilder destinationBuilder: @escaping (Destination) -> DestinationContent,
        onDeepLink: (@MainActor (URL, NavigationCoordinator<Destination>) -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.environmentKeyPath = environmentKeyPath
        self.rootView = rootView()
        self.destinationBuilder = destinationBuilder
        self.onDeepLink = onDeepLink
    }

    public var body: some View {
        @Bindable var coordinator = coordinator   // local bindings, parent owns the instance

        NavigationStack(path: $coordinator.path) {
            rootView
                .navigationDestination(for: Destination.self) { destination in
                    destinationBuilder(destination)   // concrete type, no AnyView
                }
        }
        .sheet(
            item: $coordinator.presentedSheet,
            onDismiss: { coordinator.didDismissSheet() }
        ) { step in
            if let destination = step.destination {
                destinationBuilder(destination)
            }
        }
        .fullScreenCover(
            item: $coordinator.presentedFullScreenCover,
            onDismiss: { coordinator.didDismissFullScreen() }
        ) { step in
            if let destination = step.destination {
                destinationBuilder(destination)
            }
        }
        .onChange(of: coordinator.path) { _, newPath in
            coordinator.reconcile(toDepth: newPath.count)
        }
        .onOpenURL { url in
            onDeepLink?(url, coordinator)
        }
        .environment(environmentKeyPath, coordinator)
    }
}
