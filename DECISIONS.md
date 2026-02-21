# DECISIONS.md — Architectural Decision Log

---

## ADR-001: AsyncStream as the State Broadcasting Primitive

**Date:** 2025-12-02 (inferred from initial commit)
**Status:** Accepted

### Context

The project needed a mechanism to broadcast state changes from the `Store` actor to the `Presenter` layer, which in turn drives SwiftUI reactivity. The Store is an `actor`, so the broadcasting mechanism must integrate naturally with Swift concurrency.

### Decision

Use `AsyncStream<S>` for all state broadcasting from the Store, with `@Observable` (Observation framework) on the Presenter as the reactive shell.

### Rationale

- **Native concurrency alignment:** `AsyncStream` is the natural output type from actor-isolated code — it composes cleanly with `async/await` and requires no bridging or external framework.
- **Clean separation of concerns:** `AsyncStream` carries raw state; the `@Observable` Presenter converts it to SwiftUI-digestible reactivity. This "AsyncStream core / Observable shell" pattern keeps the data pipeline framework-agnostic until the last mile.
- **Lifecycle control:** `AsyncStream.Continuation` with `onTermination` handles cleanup automatically when consumers stop iterating — no manual subscription management needed.
- **Minimal dependencies:** The core framework depends only on Foundation and Swift concurrency — nothing else.

### Alternatives Considered

- **`AsyncSequence` via `AsyncAlgorithms`:** Would provide richer operators but adds an external dependency for something the POC doesn't yet need. `AsyncStream` is sufficient for the broadcast pattern.
- **Custom `@Observable` directly on the Store:** Would skip the stream entirely but couples the Store actor to the UI framework, breaking the layered architecture.

---

## ADR-002: Local SPM Packages for Feature Isolation

**Date:** 2025-12-03 (inferred from ReduxCore SPM extraction commit)
**Status:** Accepted

### Context

As the POC grew beyond a single-file prototype, the codebase needed modular boundaries for:
- The Redux core framework (reusable across any feature)
- Individual features (Counter, UserProfile) with their own state/actions/reducers/views

### Decision

Use local Swift Package Manager packages under `LocalSPMS/` with each package exporting clearly named library products (e.g., `ReduxCoreIFC`, `ReduxCoreIMP`, `CounterRedux`, `CounterView`).

### Rationale

- **Compile-time isolation:** Each SPM package enforces access control boundaries. Features cannot accidentally reach into the Store's internals or depend on sibling features.
- **Fast iteration:** Developers can work on a single feature package with minimal recompilation of the rest of the app.
- **Explicit dependency graph:** `Package.swift` manifests make dependencies visible and auditable (e.g., `CounterFeature` depends on `ReduxCore`, not on `UserProfileFeature`).
- **Preview independence:** Each feature view file can contain its own `MockStore` and `#Preview` blocks, runnable without building the full app target.

### Alternatives Considered

- **Xcode project groups only:** Simpler setup but no compile-time access control, no independent previews, and no enforced dependency graph.
- **Remote SPM packages:** Appropriate for shared libraries but premature for a POC where packages evolve alongside the app.

---

## ADR-003: ActionEmitter / Presenter Separation (Interacting vs Presenting)

**Date:** 2025-12-03 (inferred from Interacting protocol introduction)
**Status:** Accepted

### Context

Views need to (a) send user actions to the store and (b) observe state slices for rendering. These are fundamentally different directions of data flow and should not be conflated.

### Decision

Split the view's Store dependency into two explicit contracts:
- **`Interacting<A>`** — a protocol with a single method `send(_ action: A) async`, implemented by `ActionEmitter` in production and `MockStore` in previews.
- **`Presenter<S, Value>`** — an `@Observable` class that subscribes to an `AsyncStream<S>` and exposes a `value` property derived via `KeyPath` extraction.

Views declare their dependencies as `let interactor: any Interacting<FeatureAction>` and `let somePresenter: Presenter<FeatureState, ValueType>`.

### Rationale

- **Testability:** Views can be tested or previewed by injecting a `MockStore` as the interactor and creating presenters from controlled state streams — no real Store needed.
- **Single Responsibility:** `ActionEmitter` only emits; `Presenter` only observes. Neither knows about the other.
- **Type safety:** `Presenter` is generic over both the state type and the extracted value type, using `KeyPath` for compile-time safe state slicing.
- **View ignorance of Redux:** Views import `ReduxCoreIFC` (for `Interacting`) and `ReduxCoreIMP` (for `Presenter`), but never import or reference `Store`, `ViewContainer`, or reducer/middleware types. This keeps feature views fully decoupled from the composition root.

### Alternatives Considered

- **Single `Store` reference in views:** Simpler API surface, but couples views to the Store actor and makes isolated previews difficult.
- **ViewModel per feature:** Common in MVVM, but adds an indirection layer that duplicates what `Presenter` already provides. The Presenter *is* the view's read model.

---

## ADR-004: MockStore Pattern for Self-Contained SwiftUI Previews

**Date:** 2025-12-10 (inferred from MockStore commits)
**Status:** Accepted

### Context

SwiftUI Previews require all dependencies to be satisfied at build time. With the `Interacting` + `Presenter` split, previews need both an action sink and a state source — ideally without spinning up a real `Store` actor.

### Decision

Each feature view file defines a `MockStore<S, A>` class (under `#if DEBUG`) that:
1. Conforms to `Interacting` (so it can receive actions from the view)
2. Holds a local `state` and `reducer`, applying actions synchronously on `@MainActor`
3. Maintains `AsyncStream<S>.Continuation`s and yields state after each action
4. Exposes a `presenter(for:)` method that creates a real `Presenter` subscribed to its internal stream

The UserProfile variant additionally supports an optional async middleware closure for simulating side effects (e.g., login delay).

### Rationale

- **Self-contained previews:** Each feature's preview is fully autonomous — no app-level composition required.
- **Realistic behavior:** Because `MockStore` applies the real reducer and feeds real `Presenter` instances, previews exercise the actual data flow path, not a separate mock.
- **Incremental complexity:** CounterFeature's `MockStore` is minimal (reducer only). UserProfileFeature's extends it with middleware support. This shows the pattern scales without mandating complexity upfront.

### Alternatives Considered

- **Using the real `Store` actor in previews:** Works (and is done in `POCView`'s preview) but requires composing the full app state and middlewares, which defeats the purpose of feature isolation.
- **Static/hardcoded preview data:** Faster to set up but doesn't validate interaction logic or state transitions.
