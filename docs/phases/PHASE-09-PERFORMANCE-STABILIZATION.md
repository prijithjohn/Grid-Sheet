# Phase 09 — Performance, Accessibility & Stabilization

## 1. Phase Metadata
- **Phase Number:** `09`
- **Phase Name:** Performance, Accessibility & Stabilization
- **Status:** `NOT STARTED`
- **Prerequisites:** Phase 03 (Shell & Canvas), Phase 05 (Formatting), Phase 08 (Spreadsheet Workflows).
- **Implementation Branch:** `feature/phase-09-performance-stabilization`
- **Remote CI Run:** Pending implementation.

---

## 2. Purpose & Expected User-Visible Outcome
- **Purpose:** Harden the desktop application for prolonged professional usage, high-density financial modeling, and accessible computing. Optimize the custom canvas rendering engine to guarantee 60 FPS scrolling on 100,000-cell sheets, eliminate memory leaks, provide instant Light/Dark theme switching ("Grid Professional" vs. "Graphite & Mint"), and implement screen reader accessibility and comprehensive keyboard navigation.
- **Expected Outcome:** Fluid, lag-free viewport panning and scrolling, zero frame drops, instantaneous dark mode toggle, accessible coordinate reading via screen readers, and an interactive Keyboard Shortcuts catalog dialog (`settings_keyboard_shortcuts`).

---

## 3. Verified Starting State
- Complete application features implemented across Phases 00 through 08.
- Full UI and domain test suites passing.

---

## 4. Scope Included
- **Rendering & Viewport Optimizations:**
  - Viewport draw-call batching and text layout caching (`TextPainter` cache for visible cells).
  - Dirty-region canvas clipping: repaint only invalidated cells during single-cell editing or cursor shifts.
  - Benchmark validation maintaining <16.6ms frame budget (60 FPS) across a sheet with 100,000 scattered cells.
- **Memory & Resource Leak Audits:**
  - Strict disposal audits of all `ScrollController`, `TextEditingController`, and `ChangeNotifier` listeners.
  - Zero memory leaks during repeated workbook opening, sheet adding/deleting, and tab switches.
- **Theme Parity & Settings Screen (`settings_appearance_dark_theme` — Stitch Screen 20):**
  - Instantaneous switching between Light ("Grid Professional") and Dark ("Graphite & Mint").
  - Seamless color token re-evaluation across title bar, ribbon, gridlines, headers, and status bar.
- **Accessibility (a11y) & Assistive Technology:**
  - Screen reader semantics emitting active cell coordinate and calculated value (e.g. "B5, Numeric, 1,250.00").
  - Clear keyboard focus indicators.
  - High-contrast mode support.
- **Keyboard Shortcuts Dialog (`settings_keyboard_shortcuts` — Stitch Screen 22):**
  - Searchable dialog cataloging all navigation, editing, formatting, and file hotkeys.
- Performance benchmark suites and accessibility widget tests.

---

## 5. Explicit Out-of-Scope Items
- Mobile touch gestures or responsive mobile web adaptations (strictly Windows desktop-first).
- Native installer packaging (dedicated to Phase 10).

---

## 6. Dependencies on Earlier Phases
- **Phase 03:** Grid viewport, title bar, theme system.
- **Phase 05:** Formatting engine and style tokens.
- **Phase 08:** Workflow dialogs and status bar.

---

## 7. Relevant Architecture & Existing Files
- `lib/core/theme/app_theme.dart`: Light/Dark theme tokens.
- `lib/features/grid/painters/grid_painter.dart`: Custom canvas rendering.
- `lib/features/settings/dialogs/keyboard_shortcuts_dialog.dart`: Shortcuts reference.
- `docs/design/STITCH_SCREEN_INVENTORY.md`: Screen 20, 22.

---

## 8. Proposed Implementation Steps
1. Profile `GridPainter` draw calls and implement `TextPainter` cache.
2. Implement dirty-rect invalidation for cursor and selection movements.
3. Conduct memory leak audits on controllers and listeners.
4. Implement `AppearanceSettingsScreen` and hook into app-level theme provider.
5. Add `Semantics` widgets around active cell and viewport.
6. Implement `KeyboardShortcutsDialog` matching Stitch Screen 22.
7. Run performance benchmark tests on 100k-cell worksheets.

---

## 9. Required Tests & Verification
- Performance & Accessibility Tests:
  - `test/unit/performance/viewport_benchmark_test.dart` (frame budget benchmarks, 100k cell matrix)
  - `test/unit/performance/memory_leak_test.dart` (disposal checks, workbook reload memory stability)
  - `test/widget/theme/theme_switch_test.dart` (light to dark token evaluation)
  - `test/widget/accessibility/grid_semantics_test.dart` (screen reader announcements)
  - `test/widget/settings/keyboard_shortcuts_dialog_test.dart` (catalog search)
- Target: 20+ tests, 100% pass rate.

---

## 10. Exact Acceptance Criteria
- [ ] Viewport scrolling on a 100,000-cell dataset maintains steady 60 FPS without frame drops.
- [ ] Toggling between Light and Dark themes updates all UI chrome and grid canvas instantaneously.
- [ ] Active cell updates trigger proper `Semantics` announcements for assistive screen readers.
- [ ] Disposing workbook screens and dialogs leaves zero dangling listeners or memory leaks.
- [ ] Keyboard Shortcuts reference dialog (`settings_keyboard_shortcuts`) displays all active hotkeys.
- [ ] Zero static analysis errors or warnings.

---

## 11. Commands Needed for Verification
```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test test/unit/performance/ test/widget/accessibility/
```

---

## 12. Git & CI Requirements
- Feature Branch: `feature/phase-09-performance-stabilization`
- Base: Verified Phase 08 branch.

---

## 13. Known Risks & Rollback Considerations
- **Risk:** Overly aggressive text layout caching consuming excessive RAM.
- **Prevention:** LRU cache eviction limiting cache to visible viewport bounds + 10% buffer.
- **Rollback:** `git revert <commit-sha>`.

---

## 14. Required Evidence for Completion
- Performance benchmarks meeting 16.6ms frame budget.
- Memory leak audit report.
- Phase Execution Report filed.

---

## 15. Entry Gate
- Phase 08 verified and signed off.

## 16. Exit Gate
- All 6 acceptance criteria verified, performance and a11y tests green.

---

## 17. Status & Evidence Links
- Status: `NOT STARTED` ([`PHASE-STATUS.md`](../engineering/phase-control/PHASE-STATUS.md)).
