//
//  NavigationDestination.swift
//  SwiftUINavigation
//
//  Created by Pardip Bhatti on 22/12/25.
//

import SwiftUI

/// A route that knows how to build its own view.
///
/// Conform your route type to this and you can use the `destinationBuilder`-free
/// ``CoordinatorView`` initializer — each screen is built from `view()` and its
/// `title` / `navigationBarTitleDisplayMode` are applied automatically.
///
/// ```swift
/// enum Route: NavigationDestination {
///     case detail(id: String)
///     case settings
///
///     @ViewBuilder
///     func view() -> some View {
///         switch self {
///         case .detail(let id): DetailView(id: id)
///         case .settings:       SettingsView()
///         }
///     }
///
///     var title: String? {
///         switch self {
///         case .detail: "Detail"
///         case .settings: "Settings"
///         }
///     }
/// }
/// ```
public protocol NavigationDestination: Hashable {
    associatedtype ViewType: View

    @ViewBuilder
    func view() -> ViewType

    var title: String? { get }
    var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode { get }
}

public extension NavigationDestination {
    var title: String? { nil }
    var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode { .automatic }
}

/// Builds a ``NavigationDestination``'s view and applies its `title` /
/// `navigationBarTitleDisplayMode`. Used by ``CoordinatorView``'s convenience
/// initializer; you rarely construct this directly.
public struct RoutedDestinationView<Destination: NavigationDestination>: View {
    let destination: Destination

    public var body: some View {
        if let title = destination.title {
            destination.view()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(destination.navigationBarTitleDisplayMode)
        } else {
            destination.view()
        }
    }
}
