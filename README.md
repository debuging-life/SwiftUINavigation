# SwiftUINavigation

A type-safe, declarative navigation system for SwiftUI apps using the Coordinator pattern. Say goodbye to navigation chaos and prop drilling!

[![Swift Version](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2016.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🎯 Why SwiftUINavigation?

Managing navigation in SwiftUI apps can quickly become messy:
- ❌ Prop drilling navigation state through multiple view layers
- ❌ Scattered navigation logic across your app
- ❌ Difficult to test navigation flows
- ❌ Complex deep linking implementation

SwiftUINavigation solves these problems with a clean, type-safe coordinator pattern:
- ✅ **Type-Safe Navigation** - Compile-time safety with enum-based destinations
- ✅ **Centralized Control** - All navigation logic in one place
- ✅ **No Prop Drilling** - Access coordinator via SwiftUI Environment
- ✅ **Deep Linking Ready** - Built-in URL handling support
- ✅ **Testable** - Easy to mock and test navigation flows
- ✅ **CoordinatorView Helper** - Minimal boilerplate setup

## 📦 Installation

### Swift Package Manager

Add SwiftUINavigation to your project in Xcode:

1. File > Add Package Dependencies
2. Enter package URL: `https://github.com/debuging-life/SwiftUINavigation`
3. Select version and add to your target

Or add it to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/debuging-life/SwiftUINavigation", from: "1.1.0")
]
```

## 🚀 Quick Start (3 Steps)

### Step 1: Define Your Destinations

Create an enum with your app screens:
```swift
import SwiftUINavigation

enum AuthDestinations: Hashable {
    case signin
    case signup
    case verifyEmail
    case forgotPassword
}
```

### Step 2: Create Environment Key
```swift
typealias AuthCoordinator = NavigationCoordinator<AuthDestinations>

extension EnvironmentValues {
    @Entry var authCoordinator: AuthCoordinator = AuthCoordinator()
}
```

### Step 3: Setup CoordinatorView
```swift
struct AuthCoordinatorView: View {
    var authViewModel: AuthVM
    
    var body: some View {
        CoordinatorView(
            environmentKeyPath: \.authCoordinator,
            rootView: {
                SigninView(authVM: authViewModel)
                    .navigationTitle("Sign In")
                    .navigationBarTitleDisplayMode(.large)
            },
            destinationBuilder: { destination in
                destinationView(for: destination)
            },
            onDeepLink: handleDeepLink
        )
    }
    
    @ViewBuilder
    private func destinationView(for destination: AuthDestinations) -> some View {
        switch destination {
        case .signin:
            SigninView(authVM: authViewModel)
                .navigationTitle("Sign In")
                .navigationBarTitleDisplayMode(.large)
        case .signup:
            SignupView(authVM: authViewModel)
                .navigationTitle("Sign Up")
                .navigationBarTitleDisplayMode(.large)
        case .verifyEmail:
            VerifyEmailView()
                .navigationTitle("Verify Email")
                .navigationBarTitleDisplayMode(.large)
        case .forgotPassword:
            ForgotPasswordView()
                .navigationTitle("Reset Password")
                .navigationBarTitleDisplayMode(.large)
        }
    }
    
    @Sendable
    private func handleDeepLink(_ url: URL, _ coordinator: AuthCoordinator) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }
        
        switch components.path {
        case "/signin":
            coordinator.push(.signin)
        case "/signup":
            coordinator.push(.signup)
        case "/verify":
            coordinator.push(.verifyEmail)
        default:
            break
        }
    }
}
```

That's it! Now navigate from any child view:
```swift
struct SigninView: View {
    @Environment(\.authCoordinator) var coordinator
    var authVM: AuthVM
    
    var body: some View {
        VStack {
            // Your sign-in UI...
            
            Button("Don't have an account? Sign Up") {
                coordinator.push(.signup)
            }
            
            Button("Forgot Password?") {
                coordinator.presentSheet(.forgotPassword)
            }
        }
    }
}
```

## 📚 Core Concepts

### 1. Destinations (Your App Screens)

Define all possible screens as enum cases:
```swift
enum AppDestinations: Hashable {
    case home
    case profile
    case settings
    
    // With data
    case userDetail(userId: String)
    case productDetail(product: Product)
}
```

**Why enum?**
- ✅ Type-safe: Can't navigate to non-existent screens
- ✅ Autocomplete: Xcode suggests available destinations
- ✅ Refactor-friendly: Rename once, updates everywhere

### 2. CoordinatorView (The Setup)

The `CoordinatorView` handles all navigation boilerplate:
```swift
CoordinatorView(
    environmentKeyPath: \.yourCoordinator,  // Where to store coordinator
    rootView: { YourRootView() },           // Starting screen
    destinationBuilder: { destination in    // How to build each screen
        // Return view for destination
    },
    onDeepLink: { url, coordinator in       // Optional: handle deep links
        // Parse URL and navigate
    }
)
```

### 3. Environment (Access Anywhere)

Access the coordinator in any child view:
```swift
struct AnyChildView: View {
    @Environment(\.authCoordinator) var coordinator
    
    var body: some View {
        Button("Navigate") {
            coordinator.push(.someDestination)
        }
    }
}
```

No need to pass coordinator through props! ✨

## 🎓 Usage Examples

### Basic Navigation
```swift
struct HomeView: View {
    @Environment(\.appCoordinator) var coordinator
    
    var body: some View {
        VStack(spacing: 20) {
            Button("View Profile") {
                coordinator.push(.profile)
            }
            
            Button("Settings") {
                coordinator.push(.settings)
            }
            
            Button("Back") {
                coordinator.navigateBack()
            }
            
            Button("Go to Root") {
                coordinator.navigateToRoot()
            }
        }
    }
}
```

### Passing Data with Navigation
```swift
enum ShopDestinations: Hashable {
    case productList
    case productDetail(product: Product)
    case cart
}

struct ProductListView: View {
    @Environment(\.shopCoordinator) var coordinator
    let products: [Product]
    
    var body: some View {
        List(products) { product in
            Button(product.name) {
                coordinator.push(.productDetail(product: product))
            }
        }
    }
}

// In destinationBuilder:
case .productDetail(let product):
    ProductDetailView(product: product)
```

### Presenting Sheets & Full Screen Covers
```swift
Button("Show Settings Sheet") {
    coordinator.presentSheet(.settings)
}

Button("Show Onboarding Full Screen") {
    coordinator.presentFullScreen(.onboarding)
}

Button("Dismiss") {
    coordinator.dismissPresented()
}
```

### Navigation with Callbacks
```swift
Button("Edit Profile") {
    coordinator.push(.editProfile, onComplete: {
        print("Profile updated!")
        // Refresh data, show toast, etc.
    })
}

Button("Show Modal") {
    coordinator.presentSheet(.addItem, onDismiss: {
        print("Modal dismissed")
        // Reload list, update UI, etc.
    })
}
```

### Multiple Steps Navigation
```swift
// Navigate through multiple screens at once
coordinator.navigateToMultiple([
    .welcome,
    .tutorial,
    .features
])

// Go back multiple steps
coordinator.navigateBack(count: 2)  // Back 2 screens
coordinator.navigateBack()          // Back 1 screen
```

### Checking Navigation State
```swift
struct SomeView: View {
    @Environment(\.appCoordinator) var coordinator
    
    var body: some View {
        VStack {
            Text("Navigation Depth: \(coordinator.depth)")
            
            if coordinator.isAtRoot {
                Text("At Root Screen")
            }
            
            if coordinator.isAt(.profile) {
                Text("Currently on Profile")
            }
            
            Button("Back") {
                coordinator.navigateBack()
            }
            .disabled(coordinator.isAtRoot)
        }
    }
}
```

## 🔗 Deep Linking

### Basic Deep Link Handling
```swift
@Sendable
private func handleDeepLink(_ url: URL, _ coordinator: AuthCoordinator) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
        return
    }
    
    switch components.path {
    case "/signin":
        coordinator.push(.signin)
        
    case "/signup":
        coordinator.push(.signup)
        
    case "/verify":
        // Get query parameters
        if let email = components.queryItems?.first(where: { $0.name == "email" })?.value {
            coordinator.push(.verifyEmail(email: email))
        }
        
    case "/reset":
        // Get token from query
        if let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
            coordinator.push(.resetPassword(token: token))
        }
        
    default:
        print("Unknown deep link: \(url)")
    }
}
```

### Example Deep Link URLs
```
myapp://signin
myapp://signup
myapp://verify?email=user@example.com
myapp://reset?token=abc123
myapp://product/123
myapp://user/456/profile
```

### Advanced: Deep Link Parser

Create a reusable parser:
```swift
struct DeepLinkParser {
    static func parse(_ url: URL) -> AuthDestinations? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        let queryParams = Dictionary(
            uniqueKeysWithValues: components.queryItems?.map { ($0.name, $0.value ?? "") } ?? []
        )
        
        switch components.path {
        case "/signin":
            return .signin
        case "/signup":
            return .signup
        case "/verify":
            return .verifyEmail(email: queryParams["email"] ?? "")
        case "/reset":
            return .resetPassword(token: queryParams["token"] ?? "")
        default:
            return nil
        }
    }
}

// Usage in handleDeepLink:
@Sendable
private func handleDeepLink(_ url: URL, _ coordinator: AuthCoordinator) {
    if let destination = DeepLinkParser.parse(url) {
        coordinator.push(destination)
    } else {
        print("Unknown deep link: \(url)")
    }
}
```

### Deep Link with Authentication Check
```swift
@Sendable
private func handleDeepLink(_ url: URL, _ coordinator: AuthCoordinator) {
    guard let destination = DeepLinkParser.parse(url) else {
        return
    }
    
    // Check if destination requires authentication
    switch destination {
    case .profile, .settings, .editProfile:
        if !authViewModel.isAuthenticated {
            coordinator.push(.signin)
            // Store intended destination to redirect after login
            return
        }
    default:
        break
    }
    
    coordinator.push(destination)
}
```

## 🛠️ Advanced Usage

### Multiple Coordinators (Recommended)

Separate coordinators for different app sections:
```swift
// Auth Flow
enum AuthDestinations: Hashable {
    case signin, signup, verifyEmail
}

// Main App Flow
enum AppDestinations: Hashable {
    case home, profile, settings
}

// Shopping Flow
enum ShopDestinations: Hashable {
    case productList, productDetail(Product), cart, checkout
}

// Define environment keys
extension EnvironmentValues {
    @Entry var authCoordinator = NavigationCoordinator<AuthDestinations>()
    @Entry var appCoordinator = NavigationCoordinator<AppDestinations>()
    @Entry var shopCoordinator = NavigationCoordinator<ShopDestinations>()
}
```

### Switching Between Flows
```swift
struct RootView: View {
    @State private var isAuthenticated = false
    
    var body: some View {
        if isAuthenticated {
            AppCoordinatorView()
        } else {
            AuthCoordinatorView()
        }
    }
}
```

### Conditional Navigation
```swift
Button("Continue") {
    if user.hasCompletedOnboarding {
        coordinator.push(.home)
    } else {
        coordinator.push(.onboarding)
    }
}
```

### Navigation with Validation
```swift
Button("Save and Continue") {
    // Validate form
    guard viewModel.isValid else {
        showError = true
        return
    }
    
    // Save data
    viewModel.save()
    
    // Navigate
    coordinator.push(.success)
}
```

### Custom Destination Builder Logic
```swift
@ViewBuilder
private func destinationView(for destination: AppDestinations) -> some View {
    switch destination {
    case .home:
        HomeView()
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        coordinator.push(.settings)
                    }
                }
            }
            
    case .profile:
        if let user = authViewModel.currentUser {
            ProfileView(user: user)
                .navigationTitle("Profile")
        } else {
            Text("User not found")
        }
        
    case .settings:
        SettingsView()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
    }
}
```

## 🧪 Testing

Testing navigation is straightforward:
```swift
import XCTest
@testable import YourApp
@testable import SwiftUINavigation

class NavigationTests: XCTestCase {
    var coordinator: NavigationCoordinator<AuthDestinations>!
    
    override func setUp() {
        super.setUp()
        coordinator = NavigationCoordinator<AuthDestinations>()
    }
    
    func testBasicNavigation() {
        coordinator.push(.signin)
        
        XCTAssertEqual(coordinator.depth, 1)
        XCTAssertTrue(coordinator.isAt(.signin))
        XCTAssertFalse(coordinator.isAtRoot)
    }
    
    func testNavigateBack() {
        coordinator.push(.signin)
        coordinator.push(.signup)
        
        XCTAssertEqual(coordinator.depth, 2)
        
        coordinator.navigateBack()
        
        XCTAssertEqual(coordinator.depth, 1)
        XCTAssertTrue(coordinator.isAt(.signin))
    }
    
    func testNavigateToRoot() {
        coordinator.push(.signin)
        coordinator.push(.signup)
        coordinator.push(.verifyEmail)
        
        coordinator.navigateToRoot()
        
        XCTAssertTrue(coordinator.isAtRoot)
        XCTAssertEqual(coordinator.depth, 0)
    }
    
    func testPresentSheet() {
        coordinator.presentSheet(.forgotPassword)
        
        XCTAssertTrue(coordinator.hasPresentation)
        XCTAssertTrue(coordinator.isSheetPresented(.forgotPassword))
    }
    
    func testNavigationCallbacks() {
        var completionCalled = false
        
        coordinator.push(.signin, onComplete: {
            completionCalled = true
        })
        
        coordinator.completeStep(for: .signin)
        
        XCTAssertTrue(completionCalled)
    }
    
    func testDeepLinkParsing() {
        let url = URL(string: "myapp://verify?email=test@example.com")!
        let destination = DeepLinkParser.parse(url)
        
        XCTAssertEqual(destination, .verifyEmail(email: "test@example.com"))
    }
}
```

## 📋 Best Practices

### ✅ DO: Organize by Flow
```swift
// Good: Separate coordinators per flow
AuthCoordinator  // signin, signup, verify
AppCoordinator   // home, profile, settings
ShopCoordinator  // products, cart, checkout
```

### ✅ DO: Use Associated Values for Data
```swift
// Good: Pass data with destination
case userDetail(userId: String)
case productDetail(product: Product)
case chat(conversationId: UUID, userName: String)
```

### ✅ DO: Keep Destination Builder Simple
```swift
// Good: Clear switch statement
@ViewBuilder
private func destinationView(for destination: AuthDestinations) -> some View {
    switch destination {
    case .signin:
        SigninView()
    case .signup:
        SignupView()
    }
}
```

### ✅ DO: Handle Deep Links Gracefully
```swift
// Good: Validation and error handling
@Sendable
private func handleDeepLink(_ url: URL, _ coordinator: AuthCoordinator) {
    guard let destination = DeepLinkParser.parse(url) else {
        print("Unknown deep link: \(url)")
        return
    }
    
    if destination.requiresAuth && !isAuthenticated {
        coordinator.push(.signin)
        return
    }
    
    coordinator.push(destination)
}
```

### ❌ DON'T: Mix Multiple Flows in One Coordinator
```swift
// Bad: Too many unrelated destinations
enum GlobalDestinations: Hashable {
    case signin, signup, home, profile, product, cart, settings
}
```

### ❌ DON'T: Store Shared State in Destinations
```swift
// Bad: Relying on external state
var selectedUserId: String?
case userDetail

// Good: Pass data with destination
case userDetail(userId: String)
```

### ❌ DON'T: Add Complex Logic to Destination Builder
```swift
// Bad: Business logic in builder
@ViewBuilder
private func destinationView(for destination: AppDestinations) -> some View {
    switch destination {
    case .profile:
        if user.isPremium && Date().isPastNoon && !user.hasSeenToday {
            PremiumProfileView()
        } else {
            StandardProfileView()
        }
    }
}

// Good: Pass decision to view
@ViewBuilder
private func destinationView(for destination: AppDestinations) -> some View {
    switch destination {
    case .profile:
        ProfileView(user: user)  // Let view handle logic
    }
}
```

## 📖 API Reference

### NavigationCoordinator
```swift
public class NavigationCoordinator<Destination: Hashable>

// Properties
public var navigationPath: NavigationPath
public var presentedSheet: NavigationStep<Destination>?
public var presentedFullScreenCover: NavigationStep<Destination>?

// Navigation
public func push(_ destination: Destination, onComplete: (() -> Void)? = nil)
public func presentSheet(_ destination: Destination, onDismiss: (() -> Void)? = nil)
public func presentFullScreen(_ destination: Destination, onDismiss: (() -> Void)? = nil)
public func navigateBack()
public func navigateBack(count: Int?)
public func navigateToRoot()
public func dismissPresented()

// Batch Navigation
public func navigateToMultiple(_ destinations: [Destination], onBatchComplete: (() -> Void)? = nil)

// State Queries
public func isAt(_ destination: Destination) -> Bool
public var isAtRoot: Bool
public var depth: Int
public var hasPresentation: Bool
public func isSheetPresented(_ destination: Destination) -> Bool
public func isFullScreenPresented(_ destination: Destination) -> Bool
```

### CoordinatorView
```swift
public struct CoordinatorView<Destination: Hashable, Content: View>

public init(
    coordinator: NavigationCoordinator<Destination>? = nil,
    environmentKeyPath: WritableKeyPath<EnvironmentValues, NavigationCoordinator<Destination>>,
    @ViewBuilder rootView: () -> Content,
    @ViewBuilder destinationBuilder: @escaping (Destination) -> some View,
    onDeepLink: (@Sendable (URL, NavigationCoordinator<Destination>) -> Void)? = nil
)
```

### NavigationStep
```swift
public struct NavigationStep<T: Hashable>

public var destination: T?
public var isPresented: Bool
public var type: NavigationType
public var onComplete: (() -> Void)?
public var onDismiss: (() -> Void)?
```

### NavigationType
```swift
public enum NavigationType {
    case push
    case present
    case sheet
    case fullScreenCover
}
```

## 🎯 Real-World Example

Complete authentication flow with deep linking:
```swift
// 1. Define destinations
enum AuthDestinations: Hashable {
    case signin
    case signup
    case verifyEmail(email: String)
    case resetPassword(token: String)
    case termsAndConditions
}

// 2. Create coordinator type
typealias AuthCoordinator = NavigationCoordinator<AuthDestinations>

// 3. Register in environment
extension EnvironmentValues {
    @Entry var authCoordinator: AuthCoordinator = AuthCoordinator()
}

// 4. Setup coordinator view
struct AuthCoordinatorView: View {
    @StateObject var authViewModel = AuthVM()
    
    var body: some View {
        CoordinatorView(
            environmentKeyPath: \.authCoordinator,
            rootView: {
                SigninView(authVM: authViewModel)
                    .navigationTitle("Welcome")
                    .navigationBarTitleDisplayMode(.large)
            },
            destinationBuilder: { destination in
                destinationView(for: destination)
            },
            onDeepLink: handleDeepLink
        )
    }
    
    @ViewBuilder
    private func destinationView(for destination: AuthDestinations) -> some View {
        switch destination {
        case .signin:
            SigninView(authVM: authViewModel)
                .navigationTitle("Sign In")
                
        case .signup:
            SignupView(authVM: authViewModel)
                .navigationTitle("Create Account")
                
        case .verifyEmail(let email):
            VerifyEmailView(email: email, authVM: authViewModel)
                .navigationTitle("Verify Email")
                
        case .resetPassword(let token):
            ResetPasswordView(token: token, authVM: authViewModel)
                .navigationTitle("Reset Password")
                
        case .termsAndConditions:
            TermsAndConditionsView()
                .navigationTitle("Terms & Conditions")
        }
    }
    
    @Sendable
    private func handleDeepLink(_ url: URL, _ coordinator: AuthCoordinator) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }
        
        let queryParams = Dictionary(
            uniqueKeysWithValues: components.queryItems?.map { ($0.name, $0.value ?? "") } ?? []
        )
        
        switch components.path {
        case "/signin":
            coordinator.push(.signin)
        case "/signup":
            coordinator.push(.signup)
        case "/verify":
            coordinator.push(.verifyEmail(email: queryParams["email"] ?? ""))
        case "/reset":
            coordinator.push(.resetPassword(token: queryParams["token"] ?? ""))
        default:
            print("Unknown deep link: \(url)")
        }
    }
}

// 5. Use in views
struct SigninView: View {
    @Environment(\.authCoordinator) var coordinator
    @ObservedObject var authVM: AuthVM
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textContentType(.password)
            
            Button("Sign In") {
                authVM.signIn(email: email, password: password)
            }
            .buttonStyle(.borderedProminent)
            
            Button("Don't have an account? Sign Up") {
                coordinator.push(.signup)
            }
            
            Button("Forgot Password?") {
                coordinator.presentSheet(.resetPassword(token: ""))
            }
            
            Button("Terms & Conditions") {
                coordinator.push(.termsAndConditions)
            }
            .font(.footnote)
        }
        .padding()
    }
}
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the Coordinator pattern from iOS development
- Built with SwiftUI and modern Swift concurrency
- Thanks to the Swift community for feedback and contributions

## 📞 Support

- 📧 Email: your.email@example.com
- 🐦 Twitter: [@yourhandle](https://twitter.com/yourhandle)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/SwiftUINavigation/discussions)

---

Made with ❤️ for the SwiftUI community
