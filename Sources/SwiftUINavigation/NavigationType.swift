//
//  File.swift
//  SwiftUINavigation
//
//  Created by Pardip Bhatti on 21/12/25.
//

import Foundation

public enum NavigationType {
    case push
    case sheet
    case fullScreenCover
    // `.present` removed — it was never wired to a presentation modifier.
}
