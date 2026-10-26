# Phase 08 — Common Spreadsheet Workflows

## 1. Phase Metadata
- **Phase Number:** `08`
- **Phase Name:** Common Spreadsheet Workflows
- **Status:** `NOT STARTED`
- **Prerequisites:** Phase 03 (Desktop Shell & Canvas), Phase 04 (Formula Engine), Phase 05 (Formatting Integration).
- **Implementation Branch:** `feature/phase-08-spreadsheet-workflows`
- **Remote CI Run:** Pending implementation.

---

## 2. Purpose & Expected User-Visible Outcome
- **Purpose:** Deliver essential high-productivity data manipulation workflows matching the Stitch design specifications: interactive Find and Replace (`Ctrl+F` / `Ctrl+H`), multi-level Custom Sort dialog, Excel-style Column Filter dropdowns with unique value checklists, and real-time selection aggregate calculations.
- **Expected Outcome:** Users can search and replace strings across cells, sort multi-column tables with custom hierarchies, filter rows dynamically without corrupting formulas, and view instant summary stats (Sum, Average, Count, Min, Max) in the status bar for any active cell selection.

---

## 3. Verified Starting State
- Phase 03 desktop grid canvas and selection models.
- Phase 04 calculation engine.
- Phase 05 formatting and command integration.

---

## 4. Scope Included
- **Find & Replace Subsystem (`editor_find_and_replace_dialog` — Stitch Screen 12):**
  - Search term matching (case sensitive, match entire cell content, search by rows/columns).
  - Find Next (`Enter`), Find Previous (`Shift+Enter`), Replace (`Alt+R`), Replace All (`Alt+A`).
  - Search scope: Active Sheet or Entire Workbook.
  - Cell cursor navigation jumping to matching coordinates.
- **Custom Sort Dialog (`editor_custom_sort_dialog` — Stitch Screen 14):**
  - Multi-level sort builder: "Sort by [Column] [Sort On: Cell Values] [Order: A to Z / Smallest to Largest]", with "+ Add Level" and "Delete Level".
  - "My data has headers" checkbox preventing header row sorting.
  - Preserves cell formulas and relative offsets cleanly.
- **Column Filter Dropdown (`editor_column_filter_dropdown` — Stitch Screen 15):**
  - Filter toggle button on column headers.
  - Sort Sheet A to Z / Sort Sheet Z to A quick actions.
  - Search box with instant filtering of values.
  - Unique value checklist with "(Select All)" toggle.
  - Filter predicate engine hiding non-matching rows in grid viewport.
- **Selection Aggregates Engine:**
  - Real-time computation of `AVERAGE`, `COUNT`, `COUNTA`, `MIN`, `MAX`, `SUM` across selected range.
  - Displayed as clickable pill chips in the Status Bar.
- Unit and widget tests testing sort stability, filter row masks, search matching, and aggregate accuracy.

---

## 5. Explicit Out-of-Scope Items
- Pivot table generation and OLAP cubes (deferred).
- Data validation rules and dropdown validation lists (deferred).

---

## 6. Dependencies on Earlier Phases
- **Phase 01:** `CellCoordinate`, `CellRange`, `Worksheet`.
- **Phase 02:** `WorkbookState`, `CommandStack`, `SelectionState`.
- **Phase 03:** Header strips, Status Bar widgets.

---

## 7. Relevant Architecture & Existing Files
- `lib/features/grid/dialogs/`: Directory for sorting and find dialogs.
- `lib/features/grid/widgets/`: Column filter and status widgets.
- `docs/design/STITCH_SCREEN_INVENTORY.md`: Screens 10, 12, 14, 15.

---

## 8. Proposed Implementation Steps
1. Implement `FindReplaceController` and `FindReplaceDialog` in `lib/features/grid/dialogs/find_replace_dialog.dart`.
2. Implement `SortEngine` and `CustomSortDialog` in `lib/features/grid/dialogs/custom_sort_dialog.dart`.
3. Implement `FilterEngine` and `ColumnFilterDropdown` in `lib/features/grid/widgets/column_filter_dropdown.dart`.
4. Integrate row visibility mask in `Worksheet` / `GridViewport`.
5. Connect active selection aggregates to `StatusBarWidget`.
6. Bind `Ctrl+F` and `Ctrl+H` hotkeys in `desktop_shortcuts.dart`.
7. Author comprehensive unit and widget tests.

---

## 9. Required Tests & Verification
- Unit & Widget Tests:
  - `test/unit/workflows/find_replace_engine_test.dart` (case matching, entire cell, replace all count)
  - `test/unit/workflows/custom_sort_test.dart` (multi-column sort, numbers vs strings, header row preservation)
  - `test/unit/workflows/filter_engine_test.dart` (unique values checklist, row visibility mask)
  - `test/widget/workflows/find_replace_dialog_test.dart` (focus, button shortcuts)
  - `test/widget/workflows/status_bar_aggregates_test.dart` (live stats from selection)
- Target: 25+ tests, 100% pass rate.

---

## 10. Exact Acceptance Criteria
- [ ] Find and Replace dialog locates matching cells and navigates the grid cursor accurately.
- [ ] Replace All correctly replaces all occurrences and reports the total count.
- [ ] Custom Sort reorders multi-column rows according to hierarchical sort rules without corrupting unselected rows.
- [ ] Column Filter dropdown lists all unique values in the column with search filtering.
- [ ] Applying a filter conceals non-matching rows in the grid viewport without deleting data.
- [ ] Status bar displays accurate SUM, AVERAGE, and COUNT for numeric selections.
- [ ] Zero static analysis errors or warnings.

---

## 11. Commands Needed for Verification
```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test test/unit/workflows/ test/widget/workflows/
```

---

## 12. Git & CI Requirements
- Feature Branch: `feature/phase-08-spreadsheet-workflows`
- Base: Verified Phase 07 branch.

---

## 13. Known Risks & Rollback Considerations
- **Risk:** Sorting tabular data that contains formulas with relative cell references could point to invalid rows if offsets aren't handled.
- **Prevention:** Adjust formula coordinates or warn user during sort.
- **Rollback:** `git revert <commit-sha>`.

---

## 14. Required Evidence for Completion
- 25+ workflow tests passing.
- Phase Execution Report filed.

---

## 15. Entry Gate
- Phase 03, 04, and 05 verified and signed off.

## 16. Exit Gate
- All 7 acceptance criteria verified, workflow tests green.

---

## 17. Status & Evidence Links
- Status: `NOT STARTED` ([`PHASE-STATUS.md`](../engineering/phase-control/PHASE-STATUS.md)).
