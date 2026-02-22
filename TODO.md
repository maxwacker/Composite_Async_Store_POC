# TODO — Issues Identified by Code Review

Priority: CRITICAL first, then MODERATE. Fix order follows dependency chain.
Issues: 4 CRITICAL (#1 ✓resolved, #2 ✓resolved, #3 ✓resolved, #8), 4 MODERATE (#4, #5, #6, #7).

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

## 4. MODERATE — Store.startProcessing: orphaned Task

**File:** `Store.swift` — lines 74–80

```swift
public func startProcessing(_ actionStream: AsyncStream<A>) {
    Task {
        for await action in actionStream {
            await dispatch(action)
        }
    }
}
```

The Task is not stored or returned. The caller (`ViewContainer.init`) stores its own wrapping Task (`stateStreamTask`) and cancels it in `deinit`, so in practice the outer Task gets cancelled. But `startProcessing` itself doesn't enforce this — a direct caller would leak the Task.

**Fix:** Return the Task or store it as a property so the caller can manage its lifecycle explicitly.

---

## 5. MODERATE — ActionEmitter: `@unchecked Sendable` without safety documentation

**File:** `ActionEmitter.swift` — line 3

```swift
public final class ActionEmitter<A: Action>: Interacting, @unchecked Sendable {
```

`@unchecked Sendable` opts out of the compiler's thread-safety checks. The class holds a single `AsyncStream<A>.Continuation`, which *is* thread-safe (`yield` is safe to call from any context). But the `@unchecked` annotation should be documented so future maintainers know *why* it's safe.

**Fix:** Add a comment explaining that `Continuation.yield` is thread-safe, which is the sole justification for `@unchecked Sendable`.

---

## 6. MODERATE — MockStore (both features): continuations array grows without cleanup

**Files:**
- `CounterView.swift` — line 66 (`continuations` array)
- `UserProfileView.swift` — line 68 (`continuations` array)

Each call to `presenter(for:)` appends a continuation to the array. Continuations are never removed when the corresponding `Presenter` or stream is deallocated. In a preview session with repeated view reloads, this array grows indefinitely.

**Fix:** Use `continuation.onTermination` to remove the finished continuation from the array.

---

## 7. MODERATE — UserProfileView MockStore: `nonisolated(unsafe)` on middleware property

**File:** `UserProfileView.swift` — line 71

```swift
private nonisolated(unsafe) let middleware: (@Sendable (S, A) async -> A?)?
```

`nonisolated(unsafe)` disables isolation checking. The property is a `let` set once in `init` and the closure is `@Sendable`, so it is safe in practice. But the annotation should be documented.

**Fix:** Add a comment explaining why `nonisolated(unsafe)` is justified (immutable `let`, `@Sendable` closure).

---

## 8. CRITICAL — Store.dispatch: actor reentrancy allows stale state in middleware pipeline

**File:** `Store.swift` — lines 49–72 (dispatch method)

```swift
func dispatch(_ action: A) async {
    var actionsToProcess = [action]

    for middleware in middlewares {
        var nextActions: [A] = []
        for act in actionsToProcess {
            let results = await middleware(state, act)  // ← suspension point
            nextActions.append(contentsOf: results)
        }
        actionsToProcess = nextActions
    }

    for finalAction in actionsToProcess {
        reducer(&state, finalAction)
    }
    // broadcast...
}
```

Each `await middleware(state, act)` is a suspension point. While a middleware is suspended (e.g., `loginMiddleware` sleeps for 1 second), the actor can process other `dispatch` calls. Those concurrent dispatches run their reducers and mutate `state`. When the original dispatch resumes, the middleware's decision was based on a state snapshot that no longer reflects reality.

**Scenario:** User taps Login → `loginMiddleware` awaits `fetchUserProfile()` → user taps Logout during the wait → logout dispatch runs fully (sets `isLoggedIn = false`) → `loginMiddleware` resumes and returns `.loginSuccess` → reducer applies it → user is logged back in despite having tapped Logout.

**Fix:** This is an architectural decision. Options include:
- Snapshot state at dispatch entry and pass the snapshot (not live `state`) to middlewares — middlewares see a consistent view but may act on outdated data.
- Queue dispatches so only one runs at a time (serialize through the action stream, not direct dispatch calls) — eliminates reentrancy but adds latency.
- Let middlewares check current state before returning actions — pushes responsibility to each middleware.
- Accept the behavior and document it as a known limitation of the POC.
