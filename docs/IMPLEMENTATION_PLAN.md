# Grid Sheet — Phased Implementation Plan

## Overview & Execution Strategy

This implementation plan decomposes the development of Grid Sheet into 11 disciplined, verifiable phases. Each phase defines explicit inputs, deliverables, dependencies, technical risks, acceptance criteria, and measurable completion conditions.

```mermaid
gantt
    title Grid Sheet Engineering Roadmap
    dateFormat  YYYY-MM-DD
    section Setup
    Phase 00: Audit & Structure Setup       :done,    p0, 2026-10-23, 1d
    section Core Engine & State
    Phase 01: Domain Model & Coordinates    :done,    p1, after p0, 2d
    Phase 02: Application State & Commands  :active,  p2, after p1, 2d
    Phase 03: Formula Parser & DAG Engine   :         p3, after p2, 3d
    section Presentation
    Phase 04: Virtualized Canvas Grid       :         p4, after p3, 4d
    Phase 05: Formula Bar & Sheet Strip UI  :         p5, after p4, 3d
    Phase 06: Ribbon Bar & Cell Formatting  :         p6, after p5, 3d
    section Data & Tools
    Phase 07: File Persistence & CSV/XLSX   :         p7, after p6, 3d
    Phase 08: Sort, Filter, Find & Replace  :         p8, after p7, 2d
    section Desktop Experience
    Phase 09: Window Shell, Keys & Theming  :         p9, after p8, 2d
    Phase 10: Performance, Packaging & CI   :         p10, after p9, 2d
```

---

## Phase Breakdown

### Phase 00: Repository Audit and Project Structure Setup (Completed)
- **Primary Goal**: Establish clean Git hygiene, protect reference assets, establish target directory hierarchy, configure Windows desktop embedding, verify initial test/analysis baselines, and author foundational specifications.
- **Dependencies**: None.
- **Deliverables**:
  - Validated local reference protection in `.gitignore` (`stitch_desktop_spreadsheet_app_design.zip`, `Spreadsheet_Application_Frontend_RnD_Report_v2 (1).pdf`).
  - Target directory layout spanning `lib/`, `test/`, `assets/`, `docs/`, `.github/`.
  - Comprehensive documentation (`REQUIREMENTS.md`, `ACCEPTANCE_CRITERIA.md`, `ARCHITECTURE.md`, `ADR-0001`, `STITCH_SCREEN_INVENTORY.md`, `DESIGN_SYSTEM.md`, `TEST_STRATEGY.md`, `IMPLEMENTATION_PLAN.md`).
  - GitHub Actions CI/CD workflows (`ci.yml`, `release-windows.yml`).
  - Baseline verification: `dart format`, `flutter analyze`, `flutter test` passing with 0 warnings.
- **Risks**: Local Visual Studio C++ toolchain missing on developer workstation blocks local `flutter build windows` (mitigated by GitHub Actions Windows runner).
- **Completion Condition**: Phase 00 engineering audit report approved. (Verified & Complete)

---

### Phase 01: Core Domain Model & Coordinate Engine (Completed)
- **Primary Goal**: Build the pure Dart domain foundation for coordinates, cells, sparse matrix worksheets, and multi-sheet workbooks with zero UI dependencies.
- **Dependencies**: Phase 00.
- **Key Modules**:
  - `lib/domain/cell/cell_coordinate.dart`: `(row, col)` <-> `A1`, `B2:D10` conversions, anchor parsing (`$A$1`).
  - `lib/domain/cell/cell_model.dart`: Raw text, parsed AST, computed value (`CellValue`), data type.
  - `lib/domain/cell/cell_style.dart`: Font family, size, weight, fill color, text color, borders, number format.
  - `lib/domain/worksheet/worksheet_model.dart`: Sparse matrix storage, row heights map, column widths map.
  - `lib/domain/workbook/workbook_model.dart`: Worksheet list, active sheet pointer, sheet CRUD operations.
- **Unit Tests**: Full coordinate math tests, range intersection/containment tests, sparse matrix memory benchmarks (73 domain tests + 1 isolation test).
- **Completion Condition**: 100% test pass rate on all coordinate and sparse worksheet unit tests. (Verified & Complete)

---

### Phase 02: Application State and Commands (Current Phase)
- **Primary Goal**: Implement the reactive application state manager, selection/navigation state, and the reversible Command pattern execution engine (Undo/Redo) for workbook and worksheet mutations.
- **Dependencies**: Phase 01.
- **Key Modules**:
  - `lib/core/commands/command.dart`: Abstract `Command` contract with `execute()`, `undo()`, `canExecute`, and descriptive action labels.
  - `lib/core/commands/command_stack.dart`: Reversible history manager with configurable undo/redo depth and state change listeners.
  - `lib/core/commands/cell_commands.dart`: `SetCellTextCommand`, `ClearRangeCommand`, `FormatRangeCommand`.
  - `lib/core/commands/worksheet_commands.dart`: `AddWorksheetCommand`, `RemoveWorksheetCommand`, `RenameWorksheetCommand`, `ReorderWorksheetCommand`, `ResizeColumnCommand`, `ResizeRowCommand`.
  - `lib/app/state/selection_state.dart`: Active cell coordinate, primary selection range, multi-selection ranges, mode (single cell, range, entire row, entire column).
  - `lib/app/state/workbook_state.dart`: Central reactive controller coordinating active `Workbook`, active `Worksheet`, `SelectionState`, and `CommandStack`. Notifies UI components of changes (cell edits, selection shifts, tab switches, undo/redo availability).
- **Unit Tests**: Full suite testing command reversibility (undo/redo), state transitions, invalid/noop operations, selection boundaries, and edge cases.
- **Completion Condition**: 100% test pass rate across command execution, undo/redo stacks, and application state transitions.

---

### Phase 03: Formula Lexer, AST Parser, Dependency Graph & Evaluation Engine
- **Primary Goal**: Implement the deterministic calculation engine capable of parsing expressions, resolving cell references, detecting circular dependencies, and evaluating standard spreadsheet functions.
- **Dependencies**: Phase 01, Phase 02.
- **Key Modules**:
  - `lib/domain/formula/lexer/formula_lexer.dart`: Tokenizer for arithmetic, comparisons, strings, cell references.
  - `lib/domain/formula/parser/formula_parser.dart`: Recursive descent / Pratt parser constructing `FormulaNode` AST.
  - `lib/domain/formula/graph/dependency_graph.dart`: Directed acyclic graph tracking cell dependencies with cycle detection (DFS / Tarjan).
  - `lib/domain/formula/evaluator/formula_evaluator.dart`: Topological evaluation engine with error propagation (`#DIV/0!`, `#VALUE!`, `#REF!`, `#NAME?`).
  - `lib/domain/formula/functions/function_registry.dart`: Built-in function library (`SUM`, `AVERAGE`, `COUNT`, `COUNTA`, `MIN`, `MAX`, `IF`, `SUMIF`, `SUMIFS`, `VLOOKUP`).
- **Unit Tests**: Arithmetic precedence tests, function accuracy test suite, circular reference detection tests.
- **Completion Condition**: Complete test suite of 100+ formula test cases passing deterministically.

---

### Phase 04: Virtualized High-Density Grid Canvas & Viewport Scrolling
- **Primary Goal**: Construct the high-performance Flutter `CustomPainter` rendering visible cells, gridlines, headers, and selection rings at 60 FPS.
- **Dependencies**: Phase 02, Phase 03.
- **Key Modules**:
  - `lib/features/grid/widgets/grid_viewport.dart`: Bi-directional scroll controllers, visible range calculator.
  - `lib/features/grid/painters/grid_painter.dart`: Custom canvas painter for cell backgrounds, gridlines, and text.
  - `lib/features/grid/painters/selection_painter.dart`: Selection bounding box (`#107C41`), soft green fill (`#E2F0D9`), 5x5px autofill handle.
  - `lib/features/grid/widgets/column_header_strip.dart`: Column letters (`A`, `B`, `C`...), interactive drag-resize handles.
  - `lib/features/grid/widgets/row_header_strip.dart`: Row numbers (`1`, `2`, `3`...), interactive drag-resize handles.
- **Tests**: Scroll performance widget tests, hit-testing coordinate translation tests.
- **Completion Condition**: Grid renders up to 100,000 rows with smooth 60 FPS scrolling and zero text clipping.

---

### Phase 05: Formula Bar, Status Bar & Sheet Management UI
- **Primary Goal**: Implement the interactive Formula Bar, Status Bar with live aggregates, and the bottom Sheet Tab strip.
- **Dependencies**: Phase 04.
- **Key Modules**:
  - `lib/features/formula_bar/widgets/formula_bar.dart`: Name Box (`A1`), `fx` button, formula text input, expander.
  - `lib/features/formula_bar/widgets/formula_syntax_helper.dart`: Function parameter tooltip and autocompletion popover.
  - `lib/features/worksheets/widgets/sheet_tab_strip.dart`: Sheet tabs, active indicator, `+` button, tab context menu.
  - `lib/features/grid/widgets/status_bar.dart`: Calculation state, selection aggregate chips (`AVERAGE`, `COUNT`, `SUM`), zoom slider.
- **Tests**: Text synchronization widget tests, aggregate calculation tests, tab switching tests.
- **Completion Condition**: Real-time formula input synchronization and active range stats functional.

---

### Phase 06: Ribbon Bar, Formatting Engine & Styling Dialogs
- **Primary Goal**: Build the expanded/collapsed Ribbon toolbar and cell formatting dialogs matching the Stitch design system.
- **Dependencies**: Phase 05.
- **Key Modules**:
  - `lib/features/workbook/widgets/ribbon_bar.dart`: Ribbon tabs (File, Home, Insert, Data, Formulas, View).
  - `lib/features/formatting/widgets/font_group.dart`: Font family, font size, bold, italic, underline, fill, font color.
  - `lib/features/formatting/widgets/alignment_group.dart`: Horizontal, vertical, wrap text, merge & center.
  - `lib/features/formatting/widgets/number_format_group.dart`: Currency, percent, comma, decimals.
  - `lib/features/formatting/dialogs/format_cells_dialog.dart`: Comprehensive format cells modal dialog.
- **Tests**: Style application widget tests, format painter tests.
- **Completion Condition**: All formatting tokens apply cleanly and render with exact typography and colors.

---

### Phase 07: File Persistence, CSV/TSV Import/Export & XLSX Compatibility
- **Primary Goal**: Implement native `.gsheet` serialization, RFC 4180 CSV/TSV import/export with interactive preview, and OpenXML XLSX support.
- **Dependencies**: Phase 06.
- **Key Modules**:
  - `lib/data/persistence/workbook_serializer.dart`: Native JSON serialization with versioning.
  - `lib/data/import_export/csv_engine.dart`: Delimiter detection, RFC 4180 streaming reader/writer.
  - `lib/data/import_export/xlsx_engine.dart`: OpenXML workbook reader/writer.
  - `lib/features/import_export/dialogs/csv_import_dialog.dart`: 20-row preview, delimiter selector.
  - `lib/features/import_export/dialogs/xlsx_compatibility_dialog.dart`: Feature compatibility warning dialog.
- **Tests**: Round-trip serialization fidelity tests, CSV edge cases (embedded commas/quotes), XLSX import tests.
- **Completion Condition**: 100% round-trip fidelity on `.gsheet`, successful CSV import preview, and valid XLSX export.

---

### Phase 08: Sorting, Filtering, Search & Replace
- **Primary Goal**: Implement data manipulation utilities including multi-level custom sort, column filter dropdown, and find/replace.
- **Dependencies**: Phase 07.
- **Key Modules**:
  - `lib/features/grid/dialogs/find_replace_dialog.dart`: Find and Replace dialog with case/entire-cell matches.
  - `lib/features/grid/dialogs/custom_sort_dialog.dart`: Multi-level sorting builder.
  - `lib/features/grid/widgets/column_filter_dropdown.dart`: Sort A-Z, search filter, unique value checklist.
- **Tests**: Multi-column sort algorithms, filter visibility predicates, search match tests.
- **Completion Condition**: Correct sorting and filtering across tabular datasets without corrupting formulas.

---

### Phase 09: Desktop Window Shell, Keyboard Navigation & Theming (Light/Dark)
- **Primary Goal**: Deliver the custom Windows title bar, system window controls, comprehensive keyboard shortcuts, and theme parity.
- **Dependencies**: Phase 08.
- **Key Modules**:
  - `lib/app/widgets/window_title_bar.dart`: Custom Windows frame, quick access tools, minimize/maximize/close.
  - `lib/core/keyboard/shortcut_manager.dart`: Desktop hotkey dispatcher (`Ctrl+S`, `Ctrl+Z`, `Ctrl+F`, `Alt+Q`).
  - `lib/features/settings/dialogs/keyboard_shortcuts_dialog.dart`: Shortcuts reference catalog.
  - `lib/features/settings/screens/appearance_settings_screen.dart`: Theme switching ("Grid Professional" vs "Graphite & Mint").
- **Tests**: Theme transition widget tests, shortcut trigger tests.
- **Completion Condition**: Instantaneous theme toggle and full keyboard shortcut parity with standard spreadsheets.

---

### Phase 10: Performance Optimization, Windows Installer & CI/CD Release
- **Primary Goal**: Optimize memory and rendering benchmarks, generate native Windows installer (`MSIX` or Inno Setup), and validate automated release publishing.
- **Dependencies**: Phase 09.
- **Key Modules**:
  - Viewport draw-call optimizations and glyph caching.
  - Packaging scripts for Windows installer.
  - `.github/workflows/release-windows.yml`: Tagged build automation with checksums and GitHub Draft Release.
- **Tests**: End-to-end integration tests, memory leak profiling, Windows release smoke testing.
- **Completion Condition**: Tagged release pipeline builds and packages clean Windows installer executable.
