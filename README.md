# To use this package follow the instructions or below code

## set destinations

```Swift
//
//  AuthDestinations.swift
//  loudowls
//
//  Created by Pardip Bhatti on 10/03/25.
//

import SwiftUI
import SwiftUINavigation

enum AuthDestinations: Hashable {
    case signin
    case signup
    case verifyEmail
}

typealias AuthCoordinator = NavigationCoordinator<AuthDestinations>

extension EnvironmentValues {
    @Entry var authCoordinator: AuthCoordinator = AuthCoordinator()
}

```

## then create own coordinator view

```Swift
//
//  AuthCoordinatorView.swift
//  loudowls
//
//  Created by Pardip Bhatti on 10/03/25.
//

import SwiftUI
import SwiftUINavigation

struct AuthCoordinatorView: View {
    @State private var coordinator: AuthCoordinator = AuthCoordinator()
    var authViewmodel: AuthVM

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            SigninView(authVM: authViewmodel)
            .navigationDestination(
                for: AuthDestinations.self
            ) { destination in
                destinationView(for: destination)
            }
            .sheet(item: $coordinator.presentedSheet) { step in
                if let destination = step.destination {
                    destinationView(for: destination)
                }
            }
            .fullScreenCover(
                item: $coordinator.presentedFullScreenCover
            ) { step in
                if let destination = step.destination {
                    destinationView(for: destination)
                }
            }
            .onOpenURL(perform: openDeepLinkIfFound(for: ))
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.large)
        }
        .environment(\.authCoordinator, coordinator)
    }
}

extension AuthCoordinatorView {
    @ViewBuilder
    func destinationView(for destination: AuthDestinations) -> some View {
        switch destination {
        case .signin:
            SigninView(authVM: authViewmodel)
                .navigationTitle("Sign In")
                .navigationBarTitleDisplayMode(.large)
        case .signup:
            SignupView(authVM: authViewmodel)
                .navigationTitle("Sign Up")
                .navigationBarTitleDisplayMode(.large)
        case .verifyEmail:
            VerifyEmail()
        }
    }

    func openDeepLinkIfFound(for deepLink: URL) {
        guard let components = URLComponents(url: deepLink, resolvingAgainstBaseURL: true) else {
            return
        }

        switch components.path {
        case "/home":
            if let _ = components.queryItems?.first(where: { $0.name == "id" })?.value {
                // Load timer and navigate
                // let timer = loadTimer(id: timerID)
                // push(.timerDetail(timer: timer))
            }

        default:
            break
        }
    }
}
```
