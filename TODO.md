# TODO — Issues Identified by Code Review

Priority: CRITICAL first, then MODERATE. Fix order follows dependency chain.
Issues: 4 CRITICAL (#1 ✓resolved, #2 ✓resolved, #3 ✓resolved, #8 ✓resolved), 4 MODERATE (#4 ✓resolved, #5 ✓resolved, #6 ✓resolved, #7 ✓resolved), 1 ENHANCEMENT (#9 ✓resolved). All resolved.
1 ENHANCEMENT (#10 ✓resolved). All resolved.

---

## 1. ~~CRITICAL~~ RESOLVED — Presenter: retain cycle from unmanaged Task

**File:** `ReduxCoreIMP/Presenter.swift`

**Was:** The `Task` created in each initializer captured `self` strongly. Since the `for await` loop runs indefinitely, the Task kept `self` alive, `deinit` never fired, and the Store's `stateContinuations` dictionary grew without cleanup.

**Fix applied:** `[weak self]` + `guard let self else { return }` inside the loop. Task stored in `@ObservationIgnored nonisolated(unsafe) private var task: Task<Void, Never>?` and cancelled in `deinit`. `@ObservationIgnored` is required to prevent the `@Observable` macro from synthesizing access-tracking on the task property, which conflicted with `nonisolated(unsafe)` and caused a runtime crash.

---

## 2. ~~CRITICAL~~ RESOLVED — ViewContainer.childPresenter: orphaned Task in AsyncStream builder

**File:** `ViewContainer.swift`

**Was:** The `Task` inside the `AsyncStream` build closure was never stored. It could not be cancelled when the child stream's consumer stopped iterating, running indefinitely until the parent stream terminated.

**Fix applied:** Capture the `Task` in a local variable and use `continuation.onTermination` to cancel it when the consumer stops iterating. The Task's lifetime is now tied to the child stream's consumer.

---

## 3. ~~CRITICAL~~ RESOLVED — UserProfileView: TextField bound to `.constant("")`

**File:** `UserProfileView.swift`

**Was:** `.constant("")` discards typed text — the user can type visually, but the binding always reads as `""`, so the name is silently lost. On Login, the store's name field was always empty. The `onChange(of: namePresenter.value)` observed the presenter (not the TextField), so it only fired on store-driven changes, never from user input.

**Fix applied:** Added `@State private var nameText` for the TextField binding. `.setName(nameText)` is sent on Login tap (not per-keystroke). `onChange(of: namePresenter.value)` syncs store-driven changes (e.g. logout clearing the name) back to the local state.

---

## 4. ~~MODERATE~~ RESOLVED — Store.startProcessing: orphaned Task

**File:** `Store.swift`

**Was:** The Task was not stored or returned. A direct caller would leak it. The existing caller (`ViewContainer`) worked by accident — the `actionStream` terminates when its continuation is released, which stops the inner Task.

**Fix applied:** `startProcessing` now returns `@discardableResult Task<Void, Never>`, allowing callers to store and cancel it explicitly. Existing callers that don't need the handle are unaffected thanks to `@discardableResult`.

---

## 5. ~~MODERATE~~ RESOLVED — ActionEmitter: `@unchecked Sendable` without safety documentation

**File:** `ActionEmitter.swift`

**Was:** `@unchecked Sendable` opted out of compiler thread-safety checks without explaining why it was safe.

**Fix applied:** Replaced the TODO comment with a documentation comment explaining that the sole stored property (`AsyncStream.Continuation`) has a thread-safe `yield(_:)` method, which justifies `@unchecked Sendable`.

---

## 6. ~~MODERATE~~ RESOLVED — MockStore (both features): continuations array grows without cleanup

**Files:** `CounterView.swift`, `UserProfileView.swift`

**Was:** Each call to `presenter(for:)` appended a continuation to an array. Continuations were never removed when the corresponding stream terminated, causing the array to grow indefinitely during preview reloads.

**Fix applied:** Replaced the array with a `[UUID: Continuation]` dictionary. Each `presenter(for:)` call generates a UUID key. `continuation.onTermination` removes the entry when the stream's consumer stops iterating.

---

## 7. ~~MODERATE~~ RESOLVED — UserProfileView MockStore: `nonisolated(unsafe)` on middleware property

**File:** `UserProfileView.swift`

**Was:** `nonisolated(unsafe)` on the middleware property disabled isolation checking without explaining why it was safe.

**Fix applied:** Replaced the TODO comment with a documentation comment explaining that the property is an immutable `let` assigned once in `init` and the closure is `@Sendable`, so no mutable isolated state is shared.

---

## 8. ~~CRITICAL~~ RESOLVED — Store.dispatch: actor reentrancy allows stale state in middleware pipeline

**File:** `Store.swift`

**Was:** `dispatch` was called directly from `startProcessing`'s `for await` loop. Each `await middleware(state, act)` is a suspension point where actor reentrancy allowed concurrent dispatch executions — a second action could start processing while the first was suspended in a middleware, mutating state under it.

**Scenario:** User taps Login → `loginMiddleware` awaits `fetchUserProfile()` → user taps Logout during the wait → logout dispatch runs fully (sets `isLoggedIn = false`) → `loginMiddleware` resumes and returns `.loginSuccess` → reducer applies it → user is logged back in despite having tapped Logout.

**Fix applied:** Serialized dispatch via an internal `AsyncStream` queue (see ADR-005 in DECISIONS.md). `startProcessing` now forwards external actions into an internal `dispatchStream`. A single `processActions()` loop drains this stream, calling `dispatch` for each action. Since `for await` won't pull the next action until the current `dispatch` (including all middleware `await`s) fully completes, dispatches are strictly serial. No two dispatch calls are ever in-flight simultaneously.

---

## 9. ~~ENHANCEMENT~~ RESOLVED — Abstract the Presenter dependency in feature views

**Files:** `Presenter.swift`, `ViewContainer.swift`, `POCView.swift`, `CounterView.swift`, `UserProfileView.swift`

**Was:** Views depended on `Presenter<S, Value>` — a concrete class with two generic parameters. The state type `S` leaked into views even though they only accessed `.value: Value`. This created an asymmetry: the action side used `any Interacting<Action>` (abstract, one param) while the observation side exposed the full state type.

**Constraint:** SwiftUI's `@Observable` macro does not propagate through protocol existentials (`any SomeProtocol`) as of Swift 6.2, ruling out a pure protocol abstraction.

**Fix applied:** Removed `S` from `Presenter`'s type signature: `Presenter<S: StoreState, Value>` → `Presenter<Value>`. The `S` parameter was only consumed in initializer arguments (`AsyncStream<S>`, `KeyPath<S, Value>`) and never stored. Pushing `S` to init-level generic constraints (`public init<S: StoreState>(...)`) eliminates the type leak with no wrappers, no indirection, and no observation forwarding issues. See ADR-006 in DECISIONS.md.

---

## 10. ~~ENHANCEMENT~~ RESOLVED — Move ViewContainer and AdaptedInteractor into ReduxCoreIMP

**File:** `Composite_Async_Store_POC/ViewContainer.swift` → `ReduxCoreIMP/ViewContainer.swift`

**Was:** `ViewContainer` and `AdaptedInteractor` lived in the app target despite being fully generic — they depended only on `ReduxCoreIFC`/`ReduxCoreIMP` types with zero app-specific logic. Every app using ReduxCore would need to reimplement the same Store↔View bridge.

**Fix applied:** Moved `ViewContainer.swift` into `LocalSPMS/ReduxCore/Sources/ReduxCoreIMP/`. Added `public` access modifiers to both types and their API surface. Removed `import ReduxCoreIMP` (now internal to the module). Changed `AdaptedInteractor` from `@MainActor` to `@unchecked Sendable` (all stored properties are immutable `let`s; the transform closure is `@Sendable`) to satisfy Swift 6 strict concurrency in the SPM package context. See ADR-007 in DECISIONS.md.


