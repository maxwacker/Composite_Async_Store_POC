# Contributing to Composite Async Store POC

## Prerequisites

- Xcode 26.3 or later
- macOS 15 (Sequoia) or later — required for the AI agent features in Xcode
- An Anthropic account (Claude Pro, Max, or API key) for AI-assisted development sessions
- GitUp (optional, for visual Git navigation) — see note on commit workflow below

---

## 1. Clone the repo

```bash
git clone https://github.com/maxwacker/Composite_Async_Store_POC.git
cd Composite_Async_Store_POC
git checkout develop
```

---

## 2. Install the commit message hook

Git hooks are not versioned, so you need to install the `prepare-commit-msg`
hook manually after cloning.

> **Important:** This hook is a safety net for **manual commits from Terminal
> only**. It injects the structured commit template when your message is empty,
> so you don't have to remember the format. It has **no effect** on commits
> produced by the Claude Agent, which follows the commit format via `CLAUDE.md`
> instructions. GitUp does **not** trigger Git hooks, so always use Terminal
> when committing manually.

```bash
cat > .git/hooks/prepare-commit-msg << 'EOF'
#!/bin/sh
COMMIT_MSG_FILE="$1"
COMMIT_SOURCE="$2"

if [ "$COMMIT_SOURCE" = "merge" ] || \
   [ "$COMMIT_SOURCE" = "squash" ] || \
   [ "$COMMIT_SOURCE" = "commit" ]; then
  exit 0
fi

CURRENT_MSG=$(grep -v "^#" "$COMMIT_MSG_FILE" | tr -d '[:space:]')
if [ -n "$CURRENT_MSG" ]; then
  exit 0
fi

cat > "$COMMIT_MSG_FILE" << 'TEMPLATE'
# <type>(<scope>): <short summary>
# Types: feat | fix | refactor | test | docs | chore | build
# Scopes: core | counter | userprofile | app | infra | <module name>

## What

## Why

## Alternatives considered

## AI-Session
# If no AI session was involved, write: "No AI session — manual commit."

TEMPLATE
EOF

chmod +x .git/hooks/prepare-commit-msg
```

---

## 3. Set up Claude Agent in Xcode

1. Open `Composite_Async_Store_POC.xcodeproj` in Xcode 26.3
2. Go to **Xcode → Settings → Intelligence**
3. Select **Claude Agent** and connect your Anthropic account
4. The agent will automatically read `CLAUDE.md` at the start of each session —
   no additional configuration needed

---

## 4. Understand the commit format

Every commit in this project — whether produced by an AI session or manually —
follows this format:

```
<type>(<scope>): <short summary>

## What
What changed, technically.

## Why
Why this approach was chosen.

## Alternatives considered
What was weighed and rejected, or "None" if straightforward.

## AI-Session
What the AI session explored and decided, or "No AI session — manual commit."
```

The `prepare-commit-msg` hook injects this template automatically when
committing from Terminal with no `-m` flag.

---

## 5. Read the architectural context

Before starting any significant work, read:

- **`CLAUDE.md`** — full architecture map, key concepts, Swift conventions,
  and the AI workflow rules. The Claude Agent reads this; you should too.
- **`DECISIONS.md`** — log of architectural decisions (ADR format). Explains
  *why* the codebase is structured the way it is.

---

## Project structure at a glance

```
LocalSPMS/
├── ReduxCore/
│   ├── ReduxCoreIFC/     # Protocols & typealiases (never import IMP from here)
│   └── ReduxCoreIMP/     # Implementations (Store, ActionEmitter, Presenter)
├── CounterFeature/
│   ├── CounterRedux/     # State, Action, Reducer
│   └── CounterView/      # SwiftUI view + MockStore (#if DEBUG)
└── UserProfileFeature/
    ├── UserProfileRedux/ # State, Action, Reducer, Middleware
    └── UserProfileView/  # SwiftUI view + MockStore with middleware (#if DEBUG)

Composite_Async_Store_POC/
├── DemoApp.swift         # Composition root
├── POCView.swift         # Top-level view hierarchy
├── ViewContainer.swift   # Store ↔ View bridge
└── AppUiLogic.swift      # Global UI state
```