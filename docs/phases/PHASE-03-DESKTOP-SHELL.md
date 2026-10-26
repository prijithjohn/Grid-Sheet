# Phase 03 — Desktop Application Shell & Stitch Foundation UI

## 1. Phase Metadata
- **Phase Number:** `03`
- **Phase Name:** Desktop Application Shell & Stitch Foundation UI
- **Status:** `READY` (Gated on Phase 02 CI verification and owner sign-off)
- **Prerequisites:** Phase 02 complete, verified, and signed off.
- **Implementation Branch:** `feature/phase-03-application-shell`
- **Sub-Phases:**
  - **Sub-Phase 03A:** Desktop Application Shell Chrome & Stitch Design System
  - **Sub-Phase 03B:** Virtualized Spreadsheet Grid Canvas & Viewport Rendering
- **Remote CI Run:** Pending implementation and pull request.

---

## 2. Purpose & Expected User-Visible Outcome
- **Purpose:** Deliver the complete desktop user interface for Grid Sheet matching the Stitch design specifications ([`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md) and [`STITCH_SCREEN_INVENTORY.md`](../design/STITCH_SCREEN_INVENTORY.md)). Bind the UI directly to [`WorkbookState`](../../lib/app/state/workbook_state.dart) and desktop keyboard shortcuts.
- **Expected Outcome:** A fully functioning corporate spreadsheet application window on Windows desktop featuring:
  - Custom Fluent title bar (36px) with dirty indicator and window controls.
  - Collapsible Ribbon toolbar (88px/32px) with Home/Insert/View tabs.
  - Interactive Formula Bar (28px) with Name Box coordinate display and formula editor.
  - **Genuinely functioning, virtualized 2D spreadsheet grid canvas** with bi-directional scrolling, sticky column/row headers, 1px `#E3E7E4` gridlines, `#107C41` green selection border, 5x5px autofill handle, soft `#E2F0D9` range fill, pointer hit-testing, in-grid text editing, and keyboard navigation.
  - Interactive Sheet Tab strip (28px) with tab navigation, sheet addition (`+`), and right-click context menu.
  - Status Bar (22px) displaying calculation mode, selection aggregates (Sum, Count, Average), and zoom slider.
  - Comprehensive desktop keyboard shortcuts (`Ctrl+Z`, `Ctrl+Y`, Arrow keys, `Delete`).

---

## 3. Verified Starting State
- Phase 02 complete at commit `9cdc188`.
- 125 tests passing, 0 analysis issues.
- `lib/main.dart` is currently the starter counter widget.
- Reference designs present in `stitch_desktop_spreadsheet_app_design.zip` (Screen 1 & 2 verified).

---

## 4. Scope Included

### Sub-Phase 03A: Application Shell Chrome & Stitch Design System
- **Design System Tokens (`lib/core/theme/`):**
  - "Grid Professional" light palette (`#217346`, `#107C41`, `#185C37`, `#E2F0D9`, `#F5F7F6`, `#FFFFFF`, `#E3E7E4`, `#D9E1DC`, `#202124`, `#5F6B63`).
  - "Graphite & Mint" dark palette (`#101412`, `#181c1a`, `#1c201e`, `#272b29`, `#4edea3`, `#10b981`, `#3c4a42`, `#e0e3df`, `#bbcabf`).
  - Typography tokens: `Inter` for all UI chrome; `JetBrains Mono` with tabular numerals (`tnum`) for formulas, numbers, and coordinates.
  - Dimensional tokens: Title Bar (36px), Ribbon (88px expanded, 32px collapsed), Formula Bar (28px), Sheet Tab Strip (28px), Status Bar (22px), Left Tool Dock (48px).
- **Custom Window Title Bar (`lib/features/workbook/widgets/window_title_bar.dart`):**
  - App monogram/icon and application title.
  - Dynamic file name display (`Untitled.gsheet` or loaded file path).
  - Unsaved modifications indicator dot (`●`) wired to `WorkbookState.isDirty`.
  - Command palette search trigger placeholder (`Alt+Q`).
  - Window caption controls (Minimize, Maximize/Restore, Close) styled for Windows 11 Fluent desktop.
- **Ribbon Toolbar (`lib/features/workbook/widgets/ribbon_bar.dart`):**
  - Tab headers: Home, Insert, Page Layout, Formulas, Data, View.
  - Home Tab action groups: Clipboard (Paste, Cut, Copy), Font, Alignment, Cells, and Undo/Redo.
  - Direct integration with `WorkbookState.canUndo` and `WorkbookState.canRedo`.
  - Ribbon collapse/expand toggle button.
- **Formula Bar (`lib/features/formula_bar/widgets/formula_bar.dart`):**
  - Name Box (64px width): Displays `WorkbookState.activeCellAddress` (e.g. `B2`).
  - Function helper button (`fx`, 24px width).
  - Monospaced formula input field bidirectionally synchronized with `WorkbookState.activeCellInput`.
- **Sheet Tab Strip (`lib/features/worksheets/widgets/sheet_tab_strip.dart`):**
  - Tab list rendered dynamically from `WorkbookState.sheets`.
  - Active tab highlighting (`#FFFFFF` background, 2px top border in `#107C41`).
  - Add Sheet (`+`) button triggering `WorkbookState.addWorksheet()`.
  - Right-click context menu (Rename Sheet, Delete Sheet with last-sheet protection).
- **Status Bar (`lib/features/grid/widgets/status_bar.dart`):**
  - Calculation mode badge ("Ready").
  - Live aggregate pills (Average, Count, Sum) calculated from active selection.
  - Zoom slider with visual percentage readout (50% to 200%, default 100%).
- **Desktop Keyboard Shortcuts (`lib/core/keyboard/desktop_shortcuts.dart`):**
  - `Ctrl+Z` (Undo), `Ctrl+Y` / `Ctrl+Shift+Z` (Redo).
  - Wired directly to `WorkbookState`.

### Sub-Phase 03B: Virtualized Spreadsheet Grid Canvas
- **Viewport Architecture (`lib/features/grid/widgets/grid_viewport.dart`):**
  - Bi-directional 2D scroll management synchronizing grid body with header strips.
  - Mathematical computation of visible row index range `[firstVisibleRow, lastVisibleRow]` and column index range `[firstVisibleCol, lastVisibleCol]` based on scroll offsets and custom dimension maps.
- **Sticky Header Strips:**
  - Column Header strip (`column_header_strip.dart`): Letters `A`, `B`, `C`... synchronized horizontally; interactive mouse drag-resize handles updating column widths via `WorkbookState.resizeColumn()`.
  - Row Header strip (`row_header_strip.dart`): Numbers `1`, `2`, `3`... synchronized vertically; interactive mouse drag-resize handles updating row heights via `WorkbookState.resizeRow()`.
- **Custom Canvas Rendering (`lib/features/grid/painters/grid_painter.dart`):**
  - `CustomPainter` rendering only cells within the calculated visible viewport window.
  - Crisp 1px `#E3E7E4` gridlines.
  - Text painter rendering cell display values with `JetBrains Mono` and tabular alignment.
- **Interactive Selection Overlay (`lib/features/grid/painters/selection_painter.dart`):**
  - Active cell perimeter: 2px solid `#107C41` bounding border.
  - Bottom-right autofill anchor handle: 5x5px filled square `#107C41`.
  - Range selection fill: `#E2F0D9` rendered at 12% opacity across multi-cell ranges.
- **Pointer Hit-Testing & Interactions:**
  - Pixel `(x, y)` to `CellCoordinate` mapping taking custom column widths and row heights into account.
  - Single click to select active cell (`WorkbookState.selectCell()`).
  - Click-and-drag or Shift+Click to extend bounding range (`WorkbookState.extendSelection()`).
  - Column header click selects entire column (`WorkbookState.selectEntireColumn()`).
  - Row header click selects entire row (`WorkbookState.selectEntireRow()`).
  - Top-left corner box click selects entire worksheet (`WorkbookState.selectAll()`).
- **In-Grid Text Editing & Keyboard Navigation:**
  - Double-click or typing directly into a selected cell activates an in-grid text editing overlay positioned precisely over the cell bounds.
  - Pressing `Enter` commits the value and advances cursor down.
  - Pressing `Tab` commits the value and advances cursor right.
  - Pressing `Escape` cancels the edit without committing.
  - Arrow keys (`Up`, `Down`, `Left`, `Right`) navigate active selection cursor.
  - `Delete` / `Backspace` clears selection via `WorkbookState.clearSelection()`.

---

## 5. Explicit Out-of-Scope Items
- Formula parsing, AST tree construction, and DAG calculation engine (strictly deferred to Phase 04).
- Cell formatting modal dialogs and custom border pickers (strictly deferred to Phase 05).
- File persistence to disk (`.gsheet` file saving/opening) (strictly deferred to Phase 06).
- CSV/TSV file import/export (strictly deferred to Phase 07).

---

## 6. Dependencies on Earlier Phases

### Sub-Phase 03A Dependencies
- **Phase 01:** `CellCoordinate`, `CellRange`, `Worksheet`, `Workbook`.
- **Phase 02:** `WorkbookState`, `SelectionState`, `CommandStack`.

### Sub-Phase 03B Dependencies
- **Sub-Phase 03A:** Design tokens, theme setup, application shell scaffold, keyboard shortcut bindings.
- **Phase 01:** `CellCoordinate` offset math, `Worksheet` sparse matrix and dimension maps.
- **Phase 02:** `WorkbookState` mutation routing, `SelectionState` cursor and range math, `SetCellTextCommand`, `ResizeColumnCommand`, `ResizeRowCommand`.

---

## 7. Relevant Architecture & Existing Files
- `lib/domain/domain.dart`: Coordinate arithmetic, range bounding geometry, sparse matrix models.
- `lib/app/state/workbook_state.dart`: Central reactive controller for selection, mutations, and undo/redo.
- `lib/app/state/selection_state.dart`: Cursor navigation, bounding box normalization, disjoint multi-ranges.
- `docs/design/DESIGN_SYSTEM.md`: Color palettes, typography scale, layout dimensions.
- `docs/design/STITCH_SCREEN_INVENTORY.md`: Screen 1 (Main Editor Light) and Screen 2 (Main Editor Dark).

---

## 8. Proposed Implementation Steps

### Sub-Phase 03A Steps (Application Shell Chrome)
1. **Design System & Theme:** Implement `app_colors.dart`, `app_typography.dart`, `app_dimensions.dart`, and `app_theme.dart` in `lib/core/theme/`.
2. **Title Bar:** Implement `window_title_bar.dart` with dirty indicator listener, file name, and caption controls.
3. **Ribbon Bar:** Implement `ribbon_bar.dart` with Home tab button groups, collapse toggle, and undo/redo buttons.
4. **Formula Bar:** Implement `formula_bar.dart` with Name Box and bidirectional formula input synchronization.
5. **Sheet Tab Strip:** Implement `sheet_tab_strip.dart` and `sheet_tab_item.dart` with add button and context menu.
6. **Status Bar:** Implement `status_bar.dart` with aggregate calculations (Sum, Count, Average) and zoom slider.
7. **Desktop Shortcuts:** Implement `desktop_shortcuts.dart` binding `Ctrl+Z`, `Ctrl+Y`, and navigation actions.
8. **Shell Assembly:** Assemble chrome zones in `workbook_screen.dart` with a provisional canvas area placeholder.
9. **03A Automated Verification:** Run unit and widget test suites for all shell components.

### Sub-Phase 03B Steps (Virtualized Grid Canvas)
10. **2D Viewport Management:** Implement `grid_viewport.dart` with synchronized horizontal/vertical scroll controllers and visible coordinate window calculator.
11. **Header Strips:** Implement `column_header_strip.dart` and `row_header_strip.dart` with interactive mouse drag-resize handles.
12. **Grid Canvas Painter:** Implement `grid_painter.dart` rendering visible cells, background fills, 1px gridlines, and tabular text.
13. **Selection Painter:** Implement `selection_painter.dart` rendering 2px `#107C41` active border, autofill anchor, and `#E2F0D9` range fill.
14. **Pointer Hit-Testing:** Implement coordinate hit-testing mapping mouse events to cell coordinates and range extensions.
15. **In-Grid Editing:** Implement in-grid cell editor overlay with auto-focus and commit/cancel keyboard handling (`Enter`, `Tab`, `Esc`).
16. **Keyboard Navigation:** Bind Arrow keys to selection cursor movements and `Delete` to clear selection.
17. **Full Screen Integration:** Replace the provisional canvas placeholder in `workbook_screen.dart` with the genuine virtualized grid.
18. **03B Automated Verification:** Run widget and interaction test suites for canvas rendering, scrolling, editing, and selection.

---

## 9. Required Automated Tests

### Sub-Phase 03A Test Matrix (Application Shell Chrome)
- `test/widget/theme/app_theme_test.dart`:
  - Verifies exact hex values for "Grid Professional" light theme tokens.
  - Verifies exact hex values for "Graphite & Mint" dark theme tokens.
  - Confirms typography styling adheres to `Inter` for UI and `JetBrains Mono` for formula/tabular text.
- `test/widget/shell/window_title_bar_test.dart`:
  - Renders title and file name accurately.
  - Displays dirty dot (`●`) when `WorkbookState.isDirty == true`, hides when clean.
  - Action buttons dispatch expected events.
- `test/widget/shell/ribbon_bar_test.dart`:
  - Renders tab bar (Home, Insert, Page Layout, Formulas, Data, View).
  - Toggles between expanded (88px) and collapsed (32px) heights.
  - Undo and Redo buttons reflect `WorkbookState.canUndo` / `WorkbookState.canRedo` enabled/disabled states.
- `test/widget/formula_bar/formula_bar_test.dart`:
  - Name Box displays active cell address (e.g. `A1`, `C5`).
  - Typing in formula input and pressing `Enter` calls `WorkbookState.editActiveCell()`.
  - External active cell changes update formula input text reactively.
- `test/widget/worksheets/sheet_tab_strip_test.dart`:
  - Renders all sheet tabs in workbook order.
  - Highlights active worksheet tab with white background and green top border.
  - Clicking a tab switches active sheet via `WorkbookState.setActiveSheetIndex()`.
  - Clicking `+` button triggers `WorkbookState.addWorksheet()`.
  - Right-click context menu displays Rename and Delete options.
- `test/widget/shell/status_bar_test.dart`:
  - Displays "Ready" calculation mode badge.
  - Calculates and renders correct Sum, Count, and Average for active cell selection.
  - Adjusts zoom slider from 50% to 200%.
- `test/widget/shell/keyboard_shortcuts_test.dart`:
  - `Ctrl+Z` invokes `WorkbookState.undo()`.
  - `Ctrl+Y` invokes `WorkbookState.redo()`.

### Sub-Phase 03B Test Matrix (Virtualized Grid Canvas)
- `test/widget/grid/grid_viewport_test.dart`:
  - Calculates correct visible row/column ranges during 2D scrolling.
  - Scrolling grid body synchronously updates column and row header scroll positions.
  - Virtualization check: ensures off-screen cells do not allocate text painters or widget objects.
- `test/widget/grid/grid_canvas_test.dart`:
  - CustomPainter renders visible cell values with correct alignment.
  - Renders 1px `#E3E7E4` gridlines without visual bleeding.
  - Custom column widths and row heights render with exact dimensions.
- `test/widget/grid/selection_interaction_test.dart`:
  - Clicking cell `(row, col)` selects cell and draws 2px `#107C41` perimeter.
  - Dragging from `A1` to `C3` creates normalized rectangular selection with `#E2F0D9` fill.
  - Clicking column header selects entire column; clicking row header selects entire row.
  - Clicking top-left corner box selects entire sheet.
- `test/widget/grid/header_resize_test.dart`:
  - Dragging column divider resizes column and executes `ResizeColumnCommand`.
  - Dragging row divider resizes row and executes `ResizeRowCommand`.
  - Resizing respects minimum threshold clamping (preventing UI collapse).
- `test/widget/grid/in_grid_editing_test.dart`:
  - Double-clicking cell opens in-grid text editing field.
  - Typing new text and pressing `Enter` commits value via `WorkbookState.editActiveCell()`.
  - Pressing `Escape` cancels edit without modifying cell content.
- `test/widget/grid/keyboard_navigation_test.dart`:
  - Arrow keys move active selection cursor (`Up`, `Down`, `Left`, `Right`).
  - `Shift+Arrow` extends selection range.
  - `Delete` key calls `WorkbookState.clearSelection()`.

---

## 10. Exact Acceptance Criteria

### Sub-Phase 03A Acceptance Criteria (Application Shell Chrome)
- [ ] **CRIT-03A-1:** The application launches and renders the full desktop window frame with 5 distinct chrome zones matching Stitch specifications.
- [ ] **CRIT-03A-2:** Title Bar displays file name, caption controls, and toggles dirty dot indicator (`●`) on unsaved modifications.
- [ ] **CRIT-03A-3:** Ribbon toolbar renders all primary tabs, toggles between expanded (88px) and collapsed (32px), and reflects live undo/redo availability.
- [ ] **CRIT-03A-4:** Formula Bar Name Box displays active cell coordinate, and formula input text bidirectionally synchronizes with active cell raw input.
- [ ] **CRIT-03A-5:** Sheet Tab strip renders all worksheets, highlights active tab, adds new sheets via `+` button, and supports rename/delete via context menu.
- [ ] **CRIT-03A-6:** Status Bar displays calculation mode ("Ready"), live selection aggregate chips (Sum, Count, Average), and zoom slider.
- [ ] **CRIT-03A-7:** Desktop hotkeys (`Ctrl+Z`, `Ctrl+Y`) trigger undo/redo commands on `WorkbookState`.
- [ ] **CRIT-03A-8:** All Sub-Phase 03A widget tests pass with 0 static analysis issues.

### Sub-Phase 03B Acceptance Criteria (Virtualized Grid Canvas)
- [ ] **CRIT-03B-1:** Grid canvas virtualizes rendering, drawing only visible cells at 60 FPS without allocating off-screen widgets.
- [ ] **CRIT-03B-2:** Bi-directional scrolling pans the grid smoothly while keeping column headers pinned at the top and row headers pinned at the left.
- [ ] **CRIT-03B-3:** Single-clicking any cell sets the primary active cursor and outlines it with a 2px `#107C41` green border and 5x5px autofill handle.
- [ ] **CRIT-03B-4:** Mouse dragging across cells selects contiguous rectangular ranges highlighted with soft green fill (`#E2F0D9` at 12% opacity).
- [ ] **CRIT-03B-5:** Dragging column or row header dividers dynamically resizes dimensions, clamps to minimum bounds, and routes through `CommandStack`.
- [ ] **CRIT-03B-6:** Double-clicking a cell or typing directly activates the in-grid text editor; pressing `Enter` commits the value and marks state dirty.
- [ ] **CRIT-03B-7:** Keyboard navigation using Arrow keys moves the active cell cursor; `Shift+Arrow` extends range; `Delete` clears cell content.
- [ ] **CRIT-03B-8:** All Sub-Phase 03B grid tests pass with 0 static analysis issues.

---

## 11. Manual Verification Steps

### Sub-Phase 03A Manual Verification
1. Launch app (`flutter run -d windows` if local compiler available, or execute widget test inspector).
2. Verify Title Bar height is 36px, Ribbon is 88px, Formula Bar is 28px, Sheet Strip is 28px, Status Bar is 22px.
3. Verify brand colors match `#217346` Primary and `#F5F7F6` Recessed Chrome.
4. Click `+` on sheet tab strip; verify a new tab (e.g. `Sheet2`) appears and is selected.
5. Right-click `Sheet2`; select Rename, enter `Expenses`, verify tab label updates.
6. Type `=100` into formula bar and press `Enter`; verify dirty indicator dot (`●`) appears in Title Bar.
7. Press `Ctrl+Z`; verify dirty dot clears or updates, and undo executes.

### Sub-Phase 03B Manual Verification
1. Scroll down to row 100 and right to column Z; verify column and row headers remain perfectly aligned with grid cells.
2. Click cell `B3`; verify green 2px border and autofill square appear.
3. Drag mouse from `B3` to `E8`; verify bounding rectangle fills with soft translucent green (`#E2F0D9`).
4. Look at Status Bar; verify Count reflects `24` cells selected.
5. Drag divider between column `B` and `C` to the right; verify column `B` widens smoothly.
6. Double-click cell `C3`, type `Quarterly Sales`, press `Enter`; verify cell renders text and cursor advances to `C4`.
7. Press `Up Arrow` to return to `C3`; press `Delete`; verify text is cleared. Press `Ctrl+Z`; verify text is restored.

---

## 12. Commands Needed for Verification
```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test
flutter run -d windows  # Manual visual check when toolchain available
```

---

## 13. Git & CI Requirements
- Feature Branch: `feature/phase-03-application-shell`
- Base Commit: Verified Phase 02 completion commit on `feature/phase-02-application-state`.
- Pull Request: Open PR to `main` upon completion to trigger GitHub Actions Windows runner for analysis, testing, and release build compilation.

---

## 14. Known Risks & Rollback Considerations
- **Risk:** Frame drops or jank during rapid diagonal scrolling.
  - *Mitigation:* Virtualized `CustomPainter` draws strictly inside viewport bounding box; off-screen text layouts are skipped.
- **Risk:** Hit-testing offset inaccuracies when custom column widths or row heights are applied.
  - *Mitigation:* Hit-tester uses cumulative prefix sums of dimensions rather than naive uniform multiplication.
- **Rollback:** `git checkout feature/phase-02-application-state`.

---

## 15. Required Evidence for Completion

### Sub-Phase 03A Evidence
- All Sub-Phase 03A widget tests passing (theme, title bar, ribbon, formula bar, sheet tabs, status bar, shortcuts).
- 0 static analysis issues.
- Documented visual inspection report matching Stitch screen specifications.

### Sub-Phase 03B Evidence
- All Sub-Phase 03B grid tests passing (viewport virtualization, cell rendering, selection painter, header resizing, in-grid editing, keyboard navigation).
- 0 static analysis issues.
- Phase 03 Execution Report completed adhering to [`PHASE-EXECUTION-REPORT-TEMPLATE.md`](../engineering/phase-control/PHASE-EXECUTION-REPORT-TEMPLATE.md).

---

## 16. Entry & Exit Gates

### Sub-Phase 03A Entry Gate
- Phase 02 verified, PR CI run passed, project owner sign-off recorded.
- Working tree clean.

### Sub-Phase 03A Exit Gate
- All 8 `CRIT-03A` acceptance criteria verified.
- All 03A widget tests passing.

### Sub-Phase 03B Entry Gate
- Sub-Phase 03A exit criteria 100% verified.

### Sub-Phase 03B Exit Gate (Phase 03 Full Exit)
- All 8 `CRIT-03B` acceptance criteria verified.
- All 03B grid canvas tests passing.
- Total test suite passing with 0 failures.
- Phase Execution Report presented to project owner for approval.

---

## 17. Status & Evidence Links
- Readiness Status: `READY` ([`PHASE-STATUS.md`](../engineering/phase-control/PHASE-STATUS.md)).
- Design System: [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md).
- Stitch Screen Inventory: [`STITCH_SCREEN_INVENTORY.md`](../design/STITCH_SCREEN_INVENTORY.md).
