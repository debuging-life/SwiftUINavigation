# SwiftUINavigation

A type-safe, declarative navigation system for SwiftUI apps using the Coordinator pattern. Say goodbye to navigation chaos and prop drilling!

[![Swift Version](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🎯 Why SwiftUINavigation?

Managing navigation in SwiftUI apps can quickly become messy:
- ❌ Prop drilling navigation state through multiple view layers
- ❌ Scattered navigation logic across your app
- ❌ Navigation that breaks when an ancestor re-renders
- ❌ Complex deep linking implementation

SwiftUINavigation solves these with a clean, type-safe coordinator:
- ✅ **Type-Safe** — compile-time safety with enum-based routes
- ✅ **Centralized** — all navigation logic in one `@Observable` object
- ✅ **Zero prop drilling** — read the coordinator from the environment anywhere
- ✅ **Robust** — a typed stack that survives ancestor re-renders, the system back button, and swipe-back, with no bookkeeping leaks
- ✅ **Deep-link ready** — built-in `onOpenURL` handling
- ✅ **Swift 6** — full strict-concurrency clean, `@MainActor` throughout

## 📦 Installation

### Swift Package Manager

Add the package in Xcode (**File ▸ Add Package Dependencies**) with the URL:

```
https://github.com/debuging-life/SwiftUINavigation
```

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/debuging-life/SwiftUINavigation", from: "2.0.0")
]
```

**Requirements:** iOS 17+, Swift 6.

## 🚀 Quick Start

### 1. Define your routes

Conform an enum to `NavigationDestination` and let each case build its own view:

```swift
import SwiftUI
import SwiftUINavigation

enum Route: NavigationDestination {
    case detail(id: String)
    case settings

    @ViewBuilder
    func view() -> some View {
        switch self {
        case .detail(let id): DetailView(id: id)
        case .settings:       SettingsView()
        }
    }

    // Optional — applied automatically when present.
    var title: String? {
        switch self {
        case .detail:   "Detail"
        case .settings: "Settings"
        }
    }
}
```

### 2. Host it with `CoordinatorView`

Own the coordinator in a `@State` and hand it to `CoordinatorView`. Because your
routes build themselves, you don't pass a destination builder:

```swift
struct AppRootView: View {
    @State private var router = NavigationCoordinator<Route>()

    var body: some View {
        CoordinatorView(coordinator: router) {
            HomeView()   // the root screen
        }
    }
}
```

That's the whole setup. `CoordinatorView` builds each pushed/presented screen,
applies its title, and injects the coordinator into the environment.

### 3. Navigate from anywhere

Any child reads the coordinator from the environment — no prop drilling:

```swift
struct HomeView: View {
    @Environment(NavigationCoordinator<Route>.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Button("Open detail") { router.push(.detail(id: "42")) }
            Button("Open settings as a sheet") { router.presentSheet(.settings) }
        }
    }
}
```

## 🧭 The Coordinator API

`NavigationCoordinator<Destination>` is an `@MainActor`, `@Observable` class. The
stack is a typed `[Destination]`, so it's introspectable and always in sync.

### Push

```swift
router.push(.detail(id: "42"))                       // push one
router.push([.settings, .detail(id: "1")])           // push several
router.push(.detail(id: "42")) {                     // with an onDismiss handler
    print("detail left the stack")
}
```

The `onDismiss` closure fires when that screen leaves the stack **by any means** —
a programmatic pop, the system back button, or a swipe-back gesture.

### Pop

```swift
router.pop()                       // pop the top screen (returns the removed route)
router.pop(2)                      // pop up to 2 screens
router.pop(to: .settings)          // pop back until .settings is on top
router.popToRoot()                 // pop everything back to the root
```

### Replace the stack

```swift
router.setStack([.settings, .detail(id: "9")])   // replace the whole stack
router.replace(with: .settings)                  // clear, then push one (login/logout swap)
```

### Sheets & full-screen covers

```swift
router.presentSheet(.settings) { print("sheet dismissed") }
router.presentFullScreenCover(.detail(id: "1"))

router.dismissSheet()
router.dismissFullScreenCover()
router.dismissPresented()          // dismiss whichever is showing
```

`onDismiss` fires for both programmatic dismissal and interactive swipe-down.

### Query the state

```swift
router.isAtRoot                    // Bool
router.depth                       // number of pushed screens
router.top                         // the top route, or nil at the root
router.contains(.settings)         // Bool
router.isPresentingSheet           // Bool
router.isPresentingFullScreenCover // Bool
router.isPresenting                // either of the above
```

## 🔗 Deep linking

Pass an `onDeepLink` closure — it runs on the main actor with the coordinator,
so you can drive navigation directly from a URL:

```swift
CoordinatorView(coordinator: router) {
    HomeView()
} onDeepLink: { url, router in
    switch url.path {
    case "/settings":
        router.push(.settings)
    case let path where path.hasPrefix("/detail/"):
        router.push(.detail(id: url.lastPathComponent))
    default:
        break
    }
}
```

You can also seed a stack up front (handy for cold-start deep links or state
restoration):

```swift
@State private var router = NavigationCoordinator<Route>(path: [.settings, .detail(id: "1")])
```

## 🧱 Custom destination building

If you'd rather not conform to `NavigationDestination` (or you want full control
over how each screen is built), use the explicit initializer. `Destination` only
needs to be `Hashable`:

```swift
enum Route: Hashable {
    case detail(id: String)
    case settings
}

CoordinatorView(coordinator: router) {
    HomeView()
} destinationBuilder: { route in
    switch route {
    case .detail(let id): DetailView(id: id)
    case .settings:       SettingsView()
    }
}
```

The same builder is used for pushed screens, sheets, and full-screen covers.
There's no `AnyView` anywhere — the concrete view type is preserved end-to-end, so
SwiftUI keeps each screen's identity (and its `@State`, scroll position, etc.)
across ancestor re-renders.

## 🛡️ How it stays robust

- **Typed stack.** `path` is `[Destination]`, not the erased `NavigationPath`, so
  it can be inspected, reconciled, and restored.
- **Self-healing bookkeeping.** `onDismiss` handlers are kept exactly parallel to
  the stack and reconciled by length on every change — programmatic pop, system
  back button, or swipe-back all fire the right handlers, with no leaks.
- **Single source of truth.** The coordinator is owned by your parent view and
  injected into the environment; there's never a stale second instance the back
  button could be bound to.
- **`@MainActor` everywhere.** Clean compile under Swift 6 full strict concurrency.

## ❓ Troubleshooting: "the back button stops working after a while"

There is no timer or async work in this package, so it can't break on its own. A
delayed failure almost always comes from **app-side state re-rendering an ancestor
of `CoordinatorView`** (e.g. an elapsed-time counter). To find it, add this to the
ancestor's `body`:

```swift
let _ = print("ancestor body re-evaluated at \(Date())")
```

If it keeps printing while idle, move the frequently-changing value into a small
leaf view (or a separately-scoped `@Observable`) so only that leaf re-renders, not
the navigation container.

## 📄 License

MIT — see [LICENSE](LICENSE).
