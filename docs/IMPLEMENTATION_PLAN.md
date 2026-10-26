# Grid Sheet — Canonical Phased Implementation Plan

## 1. Overview & Execution Strategy

This implementation plan defines the canonical engineering roadmap for Grid Sheet across Phase 00 through Phase 10. Each phase is an independently verifiable, test-backed unit of engineering work bounded by strict entry criteria and exit criteria defined in [`docs/engineering/phase-control/PHASE-READINESS-GATE.md`](engineering/phase-control/PHASE-READINESS-GATE.md).

For detailed phase specifications, see [`docs/phases/`](phases/).
For the current status of all phases, see [`docs/engineering/phase-control/PHASE-STATUS.md`](engineering/phase-control/PHASE-STATUS.md).

```mermaid
gantt
    title Grid Sheet Canonical Engineering Roadmap
    dateFormat  YYYY-MM-DD
    section Baseline
    Phase 00: Setup & Repository Foundation    :done,    p0, 2026-10-23, 1d
    Phase 01: Domain Model & Coordinates       :done,    p1, after p0, 2d
    Phase 02: Application State & Commands     :done,    p2, after p1, 2d
    section Desktop Shell & Presentation
    Phase 03: Desktop Shell & Virtualized Grid :active,  p3, after p2, 4d
    section Calculation Subsystem
    Phase 04: Formula Parser & DAG Engine      :         p4, after p3, 3d
    section Formatting & State Integration
    Phase 05: Formatting & Command Integration :         p5, after p4, 3d
    section Data Persistence & Tools
    Phase 06: Native File Persistence (.gsheet):         p6, after p5, 3d
    Phase 07: CSV/TSV Import & Export          :         p7, after p6, 2d
    Phase 08: Common Spreadsheet Workflows     :         p8, after p7, 2d
    section Stabilization & Distribution
    Phase 09: Performance, A11y & Theming      :         p9, after p8, 2d
    Phase 10: Windows Packaging & Release      :         p10, after p9, 2d
```

---

## 2. Canonical Phase Roadmap Summary

### Phase 00: Project Foundation & Engineering Setup
- **Status:** `VERIFIED — AWAITING REVIEW`
- **Specification:** [`docs/phases/PHASE-00-FOUNDATION.md`](phases/PHASE-00-FOUNDATION.md)
- **Primary Goal:** Repository hygiene, reference archive protection in `.gitignore`, target directory layout, CI/CD pipelines (`ci.yml`, `release-windows.yml`), architecture specifications, and baseline quality gates.
- **Key Deliverables:** Clean Windows desktop project layout, GitHub Actions runner workflows, PRD, Architecture, and Design tokens.

---

### Phase 01: Core Domain Model & Coordinate Engine
- **Status:** `VERIFIED — AWAITING REVIEW`
- **Specification:** [`docs/phases/PHASE-01-DOMAIN-MODEL.md`](phases/PHASE-01-DOMAIN-MODEL.md)
- **Primary Goal:** Pure Dart domain foundation for coordinates, cells, sparse matrix worksheets, and multi-sheet workbooks with zero Flutter dependencies.
- **Key Deliverables:** `CellCoordinate` (A1 to XFD1048576), `CellRange`, `CellValue`, `CellStyle`, `CellModel`, `Worksheet` sparse matrix storage, `Workbook` aggregate, and 74 unit tests.

---

### Phase 02: Application State & Commands
- **Status:** `VERIFIED — AWAITING REVIEW`
- **Specification:** [`docs/phases/PHASE-02-APPLICATION-STATE.md`](phases/PHASE-02-APPLICATION-STATE.md)
- **Primary Goal:** Central reactive state management, multi-range selection navigation, and reversible Command pattern execution engine (Undo/Redo).
- **Key Deliverables:** `CommandStack` with history branch eviction, cell and worksheet mutation commands, `SelectionState`, `WorkbookState` reactive facade, and 64 new unit tests (125 total passing).

---

### Phase 03: Desktop Application Shell & Stitch Foundation UI
- **Status:** `VERIFIED — AWAITING REVIEW`
- **Specification:** [`docs/phases/PHASE-03-DESKTOP-SHELL.md`](phases/PHASE-03-DESKTOP-SHELL.md)
- **Primary Goal:** Construct the desktop UI shell matching the Stitch design system tokens and build a **fully functioning, virtualized spreadsheet grid canvas**.
- **Sub-Phases:**
  - **Sub-Phase 03A:** Application Shell Chrome & Navigation (Title bar 36px, Ribbon toolbar 88px/32px, Formula bar 28px, Sheet tabs 28px, Status bar 22px, Desktop keyboard shortcuts).
  - **Sub-Phase 03B:** Virtualized Spreadsheet Grid Canvas (Custom RenderBox / CustomPainter 2D viewport, sticky row/column headers with drag-resize, `#107C41` green selection border, 5x5px autofill handle, soft `#E2F0D9` fill, in-grid text editing).
- **Key Deliverables:** Functional spreadsheet application window on Windows desktop with responsive layout and interactive grid.

---

### Phase 04: Formula Engine
- **Status:** `NOT STARTED`
- **Specification:** [`docs/phases/PHASE-04-FORMULA-ENGINE.md`](phases/PHASE-04-FORMULA-ENGINE.md)
- **Primary Goal:** Deterministic calculation subsystem capable of parsing expressions, resolving cell references, detecting circular dependencies, and evaluating standard spreadsheet functions.
- **Key Deliverables:** Lexer, Pratt/Recursive-descent AST Parser, Directed Acyclic Graph (DAG) cycle detector, topological evaluator, and built-in function library (`SUM`, `AVERAGE`, `COUNT`, `MIN`, `MAX`, `IF`, `SUMIF`, `VLOOKUP`).

---

### Phase 05: Formatting, Worksheet Integration & Undo/Redo Integration
- **Status:** `NOT STARTED`
- **Specification:** [`docs/phases/PHASE-05-FORMATTING-INTEGRATION.md`](phases/PHASE-05-FORMATTING-INTEGRATION.md)
- **Primary Goal:** Visual cell styling, number formatting, format painting, and modal dialogs. **Strictly reuse and integrate the existing Phase 02 `CommandStack` and `WorkbookState`** without duplicating undo/redo history.
- **Key Deliverables:** Ribbon formatting groups (Font, Alignment, Numbers), Format Cells dialog (Stitch Screen 13), Format Painter, and unified undo/redo for both content and styling.

---

### Phase 06: Native File Persistence & Recovery
- **Status:** `NOT STARTED`
- **Specification:** [`docs/phases/PHASE-06-FILE-PERSISTENCE.md`](phases/PHASE-06-FILE-PERSISTENCE.md)
- **Primary Goal:** Secure, versioned `.gsheet` JSON file serialization, atomic saving, auto-saving, crash recovery journaling, and unsaved changes warnings.
- **Key Deliverables:** Native file serializer, File Open/Save As dialogs, recovery journal service, and unsaved changes modal.

---

### Phase 07: CSV/TSV Import & Export
- **Status:** `NOT STARTED`
- **Specification:** [`docs/phases/PHASE-07-CSV-TSV-IMPORT-EXPORT.md`](phases/PHASE-07-CSV-TSV-IMPORT-EXPORT.md)
- **Primary Goal:** External data interoperability via RFC 4180 streaming reader/writer, interactive CSV Import Preview dialog (Stitch Screen 16), delimiter auto-detection, and system clipboard TSV copy-paste.
- **Key Deliverables:** Streaming CSV/TSV engine, 20-row preview dialog, clipboard manager (`Ctrl+C`/`Ctrl+V`).

---

### Phase 08: Common Spreadsheet Workflows
- **Status:** `NOT STARTED`
- **Specification:** [`docs/phases/PHASE-08-SPREADSHEET-WORKFLOWS.md`](phases/PHASE-08-SPREADSHEET-WORKFLOWS.md)
- **Primary Goal:** Productivity data tools including Find and Replace dialog (`Ctrl+F`), multi-level Custom Sort dialog, Column Filter dropdowns with unique value checklists, and real-time selection aggregates in the status bar.
- **Key Deliverables:** Find & replace controller, custom sort builder, column filter row masks, and status bar stat chips.

---

### Phase 09: Performance, Accessibility & Stabilization
- **Status:** `NOT STARTED`
- **Specification:** [`docs/phases/PHASE-09-PERFORMANCE-STABILIZATION.md`](phases/PHASE-09-PERFORMANCE-STABILIZATION.md)
- **Primary Goal:** 60 FPS viewport rendering budget across 100,000 scattered cells, text layout caching, memory leak audits, instant Light/Dark theme switching ("Grid Professional" vs "Graphite & Mint"), screen reader accessibility semantics, and keyboard shortcuts catalog dialog.
- **Key Deliverables:** Viewport text caching, disposal audits, dark mode theme switcher, accessibility semantics, and shortcuts catalog.

---

### Phase 10: Windows Packaging & Release
- **Status:** `NOT STARTED`
- **Specification:** [`docs/phases/PHASE-10-PACKAGING-RELEASE.md`](phases/PHASE-10-PACKAGING-RELEASE.md)
- **Primary Goal:** Production Windows desktop installer / portable executable generation, SHA-256 checksum publishing, and automated GitHub Actions release workflow.
- **Key Deliverables:** Standalone Windows installer, `checksums.txt`, tagged GitHub release pipeline, and end-to-end installation smoke verification.
