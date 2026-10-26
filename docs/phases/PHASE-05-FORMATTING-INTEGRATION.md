# Phase 05 — Formatting, Worksheet Integration & Undo/Redo Integration

## 1. Phase Metadata
- **Phase Number:** `05`
- **Phase Name:** Formatting, Worksheet Integration & Undo/Redo Integration
- **Status:** `NOT STARTED`
- **Prerequisites:** Phase 02 (Application State & Commands), Phase 03 (Desktop Shell), Phase 04 (Formula Engine).
- **Implementation Branch:** `feature/phase-05-formatting-integration`
- **Remote CI Run:** Pending implementation.

---

## 2. Purpose & Expected User-Visible Outcome
- **Purpose:** Deliver rich visual cell styling, number formatting, format painting, and modal formatting dialogs directly integrated into the application ribbon and context menus. **Strictly reuse and integrate the existing Phase 02 `CommandStack` and `WorkbookState`** for all formatting mutations, ensuring unified, single-stack undo/redo across both content and style edits.
- **Expected Outcome:** Users can select individual cells or ranges and apply bold, italics, font size, background fill, borders, text alignment, and number formats (Currency, Percentage, Date, Commas). Changes reflect immediately on the grid canvas and are 100% reversible via `Ctrl+Z`.

---

## 3. Verified Starting State
- Phase 01 `CellStyle` entity defines font family, size, weight, italic, underline, fill color, text color, horizontal/vertical alignment, borders, and number format strings.
- Phase 02 `FormatRangeCommand` already executes functional style updates with full undo restoration.
- Phase 03 desktop shell provides ribbon button clusters and grid canvas rendering.

---

## 4. Scope Included
- **Ribbon Formatting Groups (`lib/features/formatting/widgets/`):**
  - Font Group: Font family dropdown, font size picker, Bold (`Ctrl+B`), Italic (`Ctrl+I`), Underline (`Ctrl+U`), Fill Color picker popup, Font Color picker popup.
  - Alignment Group: Horizontal (Left, Center, Right), Vertical (Top, Middle, Bottom), Text Wrap toggle, Merge & Center.
  - Number Format Group: Currency (`$`), Percent (`%`), Comma (`,`), Increase/Decrease Decimals.
- **Format Cells Modal Dialog (`editor_format_cells_dialog` — Stitch Screen 13):**
  - Multi-tab dialog: Number (General, Number, Currency, Accounting, Date, Percentage), Alignment, Font, Border (presets, line styles, border colors), Fill.
- **Format Painter:** Click to copy active cell styling and apply to target range on next click.
- **Command Architecture Integration:**
  - Route all style applications through `WorkbookState.applyStyleToSelection()` and `FormatRangeCommand`.
  - Zero duplicate undo/redo history. Both content edits and style modifications share the single, canonical `CommandStack`.
- Widget test suites verifying formatting UI controls, style persistence across undo/redo, and dialog interactions.

---

## 5. Explicit Out-of-Scope Items
- Conditional formatting rules engine (deferred to future enhancement).
- Cell comments and notes (deferred).
- Native file serialization to disk (deferred to Phase 06).

---

## 6. Dependencies on Earlier Phases
- **Phase 01:** `CellStyle`, `CellModel`, `Worksheet`.
- **Phase 02:** `CommandStack`, `FormatRangeCommand`, `WorkbookState`.
- **Phase 03:** Ribbon toolbar, grid canvas, sheet tabs.

---

## 7. Relevant Architecture & Existing Files
- `lib/domain/cell/cell_style.dart`: Immutable style tokens.
- `lib/core/commands/cell_commands.dart`: `FormatRangeCommand`.
- `lib/app/state/workbook_state.dart`: `applyStyleToSelection()`.
- `docs/design/STITCH_SCREEN_INVENTORY.md`: Screen 13 (`editor_format_cells_dialog`).

---

## 8. Proposed Implementation Steps
1. Create `FontGroupWidget` in `lib/features/formatting/widgets/font_group.dart`.
2. Create `AlignmentGroupWidget` in `lib/features/formatting/widgets/alignment_group.dart`.
3. Create `NumberFormatGroupWidget` in `lib/features/formatting/widgets/number_format_group.dart`.
4. Implement `FormatCellsDialog` matching Stitch Screen 13 in `lib/features/formatting/dialogs/format_cells_dialog.dart`.
5. Implement `FormatPainterController` for copy-paste styling.
6. Mount formatting groups into `RibbonBar` (Home tab).
7. Connect format changes directly to `WorkbookState.applyStyleToSelection()`.
8. Author widget tests verifying styling application, number format rendering, and undo/redo reversibility.

---

## 9. Required Tests & Verification
- Widget Test Suites:
  - `test/widget/formatting/font_group_test.dart` (bold, italic, color triggers)
  - `test/widget/formatting/alignment_group_test.dart` (alignments, text wrap)
  - `test/widget/formatting/number_format_test.dart` (currency, percent, decimal shifts)
  - `test/widget/formatting/format_cells_dialog_test.dart` (modal tabs, borders)
  - `test/widget/formatting/format_undo_integration_test.dart` (single command stack verification)
- Target: 25+ new widget tests, 100% pass rate.

---

## 10. Exact Acceptance Criteria
- [ ] Formatting buttons in Ribbon update selected cell/range style immediately.
- [ ] Number formats (Currency, Percent, Comma, 2 decimals) format numeric cells correctly.
- [ ] Format Cells modal dialog opens via Ribbon or context menu and applies multi-attribute styles.
- [ ] Pressing `Ctrl+Z` reverses formatting edits back to previous cell styles.
- [ ] Formatting edits share the exact same `CommandStack` as text edits (e.g. Edit Text -> Apply Bold -> Undo -> Bold removed -> Undo -> Text reverted).
- [ ] Zero static analysis errors or warnings.

---

## 11. Commands Needed for Verification
```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test test/widget/formatting/
```

---

## 12. Git & CI Requirements
- Feature Branch: `feature/phase-05-formatting-integration`
- Base: Verified Phase 04 branch.

---

## 13. Known Risks & Rollback Considerations
- **Risk:** Creating a separate undo history for formatting.
- **Prevention:** Strictly enforce calling `WorkbookState.applyStyleToSelection()` backed by Phase 02 `FormatRangeCommand`.
- **Rollback:** `git revert <commit-sha>`.

---

## 14. Required Evidence for Completion
- 25+ formatting widget tests passing.
- Single command stack integration verified.
- Phase Execution Report filed.

---

## 15. Entry Gate
- Phase 02, 03, and 04 verified and signed off.

## 16. Exit Gate
- All 6 acceptance criteria verified, formatting undo/redo green.

---

## 17. Status & Evidence Links
- Status: `NOT STARTED` ([`PHASE-STATUS.md`](../engineering/phase-control/PHASE-STATUS.md)).
