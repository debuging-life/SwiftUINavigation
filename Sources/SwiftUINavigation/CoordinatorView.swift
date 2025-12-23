//
//  CoordinatorView.swift
//  SwiftUINavigation
//
//  Created by Pardip Bhatti on 22/12/25.
//

import SwiftUI

public struct CoordinatorView<Destination: Hashable, Content: View>: View {
    @State private var coordinator: NavigationCoordinator<Destination>
    private let rootView: Content
    private let destinationBuilder: (Destination) -> AnyView
    private let onDeepLink: (@Sendable (URL, NavigationCoordinator<Destination>) -> Void)? // ← Added @Sendable
    private let environmentKeyPath: WritableKeyPath<EnvironmentValues, NavigationCoordinator<Destination>>
    
    public init(
        coordinator: NavigationCoordinator<Destination>? = nil,
        environmentKeyPath: WritableKeyPath<EnvironmentValues, NavigationCoordinator<Destination>>,
        @ViewBuilder rootView: () -> Content,
        @ViewBuilder destinationBuilder: @escaping (Destination) -> some View,
        onDeepLink: (@Sendable (URL, NavigationCoordinator<Destination>) -> Void)? = nil // ← Added @Sendable
    ) {
        self._coordinator = State(initialValue: coordinator ?? NavigationCoordinator<Destination>())
        self.environmentKeyPath = environmentKeyPath
        self.rootView = rootView()
        self.destinationBuilder = { destination in
            AnyView(destinationBuilder(destination))
        }
        self.onDeepLink = onDeepLink
    }
    
    public var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            rootView
                .navigationDestination(for: Destination.self) { destination in
                    destinationBuilder(destination)
                }
                .sheet(item: $coordinator.presentedSheet) { step in
                    if let destination = step.destination {
                        destinationBuilder(destination)
                    }
                }
                .fullScreenCover(item: $coordinator.presentedFullScreenCover) { step in
                    if let destination = step.destination {
                        destinationBuilder(destination)
                    }
                }
                .onOpenURL { url in
                    onDeepLink?(url, coordinator)
                }
        }
        .environment(environmentKeyPath, coordinator)
    }
}
