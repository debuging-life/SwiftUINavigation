//
//  File.swift
//  SwiftUINavigation
//
//  Created by Pardip Bhatti on 22/12/25.
//

import SwiftUI

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
