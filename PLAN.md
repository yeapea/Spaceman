# PLAN.md

Index of active planning documents for Spaceman.

See `CLAUDE.md` for repo-wide conventions (language policy, hygiene,
architecture overview).

## Structure

```
plans/
  todo/       # Active plans awaiting work
  archive/    # Completed or superseded plans
```

- Each plan is a focused, English-language Markdown document.
- Plans are chunked: prefer multiple small, self-contained files over one
  monolithic doc, so they can be produced, reviewed, and updated
  incrementally.
- When a plan is finished, move it from `plans/todo/` to `plans/archive/`.

## Active plans (plans/todo/)

### Deep audit — initial pass

- [`plans/todo/audit-security.md`](plans/todo/audit-security.md) —
  Security analysis (sandbox posture, private SPI exposure, Sparkle trust
  chain, UserDefaults data handling, supply chain).
- [`plans/todo/audit-state-of-the-art.md`](plans/todo/audit-state-of-the-art.md) —
  Where the codebase diverges from current Apple platform best practices
  (Swift concurrency, SwiftUI lifecycle, observation, async APIs).
- [`plans/todo/audit-deprecations-macos.md`](plans/todo/audit-deprecations-macos.md) —
  Deprecated or soft-deprecated APIs for macOS 15 Sequoia (and forward-
  looking notes for macOS 26).
- [`plans/todo/audit-improvements.md`](plans/todo/audit-improvements.md) —
  Quality, correctness, performance, UX, and maintainability improvements
  that do not fit under the other three headings.

## Workflow

1. Pick an item from a plan. Convert it to a concrete task (ideally opened
   as a GitHub issue or a branch).
2. Implement on a feature branch, keep PRs small.
3. When the plan item is resolved, strike it through in the plan doc, or
   move the entire plan to `plans/archive/` if fully done.
