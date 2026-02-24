# CLAUDE.md — Persistent AI Session Instructions

## Project Context

This is a **Composite Redux Store POC** for SwiftUI, demonstrating a composable, modular Redux architecture built on Swift concurrency primitives. The app is a macOS/iOS proof-of-concept with two feature modules (Counter, UserProfile) composed into a single application state tree.

### Architecture Overview

```
View ←(observes)← Presenter ←(AsyncStream<S>)← Store ←(AsyncStream<A>)← ActionEmitter ←(send)← View
```

**Data flow:** User interaction → `Interacting.send(action)` → `ActionEmitter` yields to `AsyncStream<A>` → `Store.dispatch` runs middlewares then reducer → state mutated → `AsyncStream<S>` broadcasts → `Presenter` (via `@Observable`) updates SwiftUI views.

### Key Concepts

| Concept | Location | Role |
|---------|----------|------|
| **Store** | `ReduxCoreIMP/Store.swift` | `actor` holding state, dispatching actions through middlewares/reducer, broadcasting via `AsyncStream<S>` |
| **ActionEmitter** | `ReduxCoreIMP/ActionEmitter.swift` | Implements `Interacting`; yields actions into an `AsyncStream<A>.Continuation` |
| **Presenter** | `ReduxCoreIMP/Presenter.swift` | `@MainActor @Observable` class; subscribes to `AsyncStream<S>`, extracts values via `KeyPath`, drives SwiftUI reactivity |
| **Interacting** | `ReduxCoreIFC/Interacting.swift` | Protocol: `send(_ action: A) async` — the only dependency views have on the dispatch layer |
| **Reducer** | `ReduxCoreIFC/Reducer.swift` | Typealias: `@Sendable (inout S, A) -> Void` with `lift()` and `combine()` composition helpers |
| **Middleware** | `ReduxCoreIFC/Middleware.swift` | Typealias: `(S, A) async -> [A]` with `liftMiddleware()` for composing child→parent |
| **ViewContainer** | `ReduxCoreIMP/ViewContainer.swift` | Bridge between Store and Views; owns `ActionEmitter`, creates `Presenter`s and `AdaptedInteractor`s |
| **MockStore** | Feature `#if DEBUG` blocks | Preview-only object implementing both `Interacting` and presenter creation for self-contained SwiftUI previews |
| **DesignTokensProtocol** | `DesignSystemIFC/DesignTokensProtocol.swift` | Semantic design token contract: colors, fonts, spacings, corner radii |
| **FallbackTokens** | `DesignSystemIFC/FallbackTokens.swift` | Neutral system defaults enabling standalone feature previews without concrete brand tokens |
| **BrandThemeModifier** | `DesignSystemDefaultIMP/BrandThemeModifier.swift` | ViewModifier that reads `colorScheme` and injects `BrandTokens` or `DarkBrandTokens`; exposed via `.brandTheme()` |

### Package Structure

```
LocalSPMS/
├── ReduxCore/                 # Core framework
│   ├── ReduxCoreIFC/          # Protocols & typealiases (Action, StoreState, Reducer, Middleware, Interacting)
│   └── ReduxCoreIMP/          # Implementations (Store, ActionEmitter, Presenter, ViewContainer, AdaptedInteractor)
├── DesignSystem/              # Design token system
│   ├── DesignSystemIFC/       # DesignTokensProtocol, FallbackTokens, EnvironmentKey, ViewModifiers, View extensions
│   └── DesignSystemDefaultIMP/ # BrandTokens (light), DarkBrandTokens (dark), BrandThemeModifier (.brandTheme())
├── CounterFeature/
│   ├── CounterRedux/          # CounterState, CounterAction, counterReducer
│   └── CounterView/           # CounterView + MockStore preview
└── UserProfileFeature/
    ├── UserProfileRedux/      # UserProfileState, UserProfileAction, userReducer, loginMiddleware
    └── UserProfileView/       # UserProfileView + MockStore preview (with middleware support)
```

Main app files: `DemoApp.swift` (composition root), `POCView.swift` (view hierarchy with `.brandTheme()` injection).

### Current State of the POC

- Two features (Counter, UserProfile) fully working with composable state/actions/reducers/middlewares
- `lift()` and `combine()` proven for reducer composition; `liftMiddleware()` proven for middleware composition
- Feature views depend only on `Interacting` protocol, `Presenter`, and `DesignSystemIFC` — no knowledge of Store internals or concrete brand tokens
- DesignSystem SPM package with IFC/IMP split; environment-based token injection via `.brandTheme()` with automatic light/dark mode switching
- SwiftUI Previews use a `MockStore` pattern (defined per-feature under `#if DEBUG`) that unifies `Interacting` and presenter creation, with `.brandTheme()` for brand-accurate preview theming
- UserProfile MockStore supports optional middleware for simulating async login in previews
- Swift Tools Version 6.2, targeting iOS 18 / macOS 15+

## Swift Conventions Observed in This Codebase

- **Naming:** PascalCase for types/protocols, camelCase for properties/methods/functions
- **Access control:** `public` on SPM-exported API; `internal`/`private` within modules; `let` for immutable bindings
- **Concurrency:** `actor` for thread-safe state; `@MainActor` on UI-bound classes; `Sendable` conformance on all protocols/typealiases crossing isolation boundaries; `async/await` throughout — **no Combine**
- **SwiftUI state:** `@State private var` for local view state; `@Observable` macro (not `ObservableObject`) for the presenter layer
- **Composition:** Functional-style `lift()` / `combine()` free functions, not methods on types
- **File organization:** One primary type per file; `// MARK: -` sections for logical grouping
- **Previews:** Wrapped in `#if DEBUG` / `#endif`; use dedicated `PreviewContent` structs with `@State private var mockStore`
- **Imports:** Explicit per-module (`import ReduxCoreIFC`, `import ReduxCoreIMP`, `import CounterRedux`) — no wildcard or umbrella imports

## Mandatory Commit Workflow

Every commit produced during an AI session **must** use this format:

```
<type>(<scope>): <short summary>

## What
<Bullet points describing the concrete changes>

## Why
<Rationale — what problem this solves or what goal it advances>

## Alternatives considered
<Other approaches weighed and why they were not chosen, or "None" if straightforward>

## AI-Session
<Summary of what the AI understood, explored, and decided during this session>
```

**Types:** `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `build`
**Scopes:** `core`, `counter`, `userprofile`, `app`, `infra`, or the relevant module name

### Decision Logging

For any significant architectural choice (new pattern, structural change, dependency decision), add an entry to `DECISIONS.md` at the project root following the format already established in that file.

## Reminders

- Read files before modifying them — never propose blind changes.
- Avoid over-engineering; change only what is requested.
- Do not introduce Combine — this project deliberately uses AsyncStream + @Observable.
- Respect the IFC/IMP separation in ReduxCore (protocols in IFC, implementations in IMP).
- Feature views must depend only on `Interacting` and `Presenter`, not on `Store` or `ViewContainer`.
- Keep `MockStore` patterns inside `#if DEBUG` blocks in each feature's view file.

## About the prepare-commit-msg hook

A `prepare-commit-msg` hook is installed in `.git/hooks/`. It injects the
structured commit template when the message is empty. This hook is a safety
net for manual commits from Terminal only — it has no effect on commits
produced by the Claude Agent, which follows the commit format via the
instructions in this file. If you are composing a commit message
programmatically, make sure it includes all four sections:
`## What`, `## Why`, `## Alternatives considered`, `## AI-Session`.
