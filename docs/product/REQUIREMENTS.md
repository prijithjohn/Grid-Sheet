# Grid Sheet — Product Requirements Document (PRD)

## 1. Executive Summary & Vision

**Grid Sheet** (internally branded **GridX** in Stitch design references) is a high-performance, calculation-intensive desktop spreadsheet application built with Flutter for Windows. It is engineered specifically for corporate productivity, financial modeling, and data manipulation workflows, emphasizing:
- **Maximum visual density and crisp layout**: Pixel-aligned UI, zero decorative clutter, and high visible cell density per viewport.
- **Ultra-fast keyboard-first interactions**: Familiar desktop spreadsheet hotkeys (`Ctrl+S`, `Ctrl+Z`, `Ctrl+Y`, `Ctrl+C`, `Ctrl+V`, `Alt+Q`, navigation with arrows, Shift/Ctrl selections).
- **Rock-solid formula evaluation**: Deterministic formula parsing, abstract syntax tree (AST) construction, directed acyclic graph (DAG) dependency management, and cycle detection.
- **Offline desktop sovereignty**: Complete local file control, zero cloud lock-in, and instant startup without mandatory network connectivity.

> [!NOTE]
> **Reference File Status**:
> - **Design Reference**: Located and audited locally at `stitch_desktop_spreadsheet_app_design.zip` (23 screen prototypes, 2 complete design token specs: "Grid Professional" light theme and "Graphite & Mint" dark theme).
> - **R&D Reference**: Located, protected in `.gitignore`, and audited locally at `Spreadsheet_Application_Frontend_RnD_Report_v2 (1).pdf` ("Flutter-Only Spreadsheet Application: Frontend Research, Authentication and Existing-File Workflows").
>
> All requirements, functional scopes (`FR-01` to `FR-15`), authentication items (`AUTH-01` to `AUTH-06`), file handling (`FILE-01` to `FILE-08`), and acceptance criteria (`AC-01` to `AC-17`) in this document directly synthesize the R&D Report and the Stitch design prototypes.

---

## 2. Target Platforms & Runtime Environment

- **Primary Operating System**: Windows 10 / Windows 11 (64-bit desktop).
- **Framework & Language**: Flutter 3.47.5 (Stable channel) with Dart 3.13.4.
- **Architecture**: x64 native Windows binary compiled via CMake and MSVC.
- **Display & Scaling**: High-DPI aware rendering with dynamic DPI scaling across multi-monitor setups.
- **Platform Roadmap**: Desktop is the primary target. Flutter web may be evaluated later after desktop behavior is validated. Mobile is not an initial target.

---

## 3. Supported File Formats & I/O Strategy

| Format | Extension | Capabilities | R&D Guidance & Notes |
| :--- | :--- | :--- | :--- |
| **Grid Sheet Native** | `.gsheet` / `.json` | Full fidelity (Values, Formulas, Formatting, Multi-sheet metadata) | Canonical internal versioned serialization format with atomic/safe writes (`FILE-05`). |
| **Comma-Separated Values** | `.csv` | Import & Export (RFC 4180 compliant) | First dependable import/export target (`FILE-02`). Must handle quoted commas, newlines, and Unicode (`AC-14`). |
| **Tab-Separated Values** | `.tsv` / `.txt` | Import & Export | Standard clipboard and tabular data exchange. |
| **Microsoft Excel OpenXML** | `.xlsx` | Read/Write (Values, Formulas, Basic Styles, Multi-sheets) | XLSX import investigated separately from export (`FILE-03`). Includes compatibility warning dialog (`FILE-06`, `AC-17`). |
| **Portable Document Format** | `.pdf` | Export Only | Print-ready sheet snapshot export. |

---

## 4. Functional Requirements Traceability Matrix

### 4.1. Core Workbook & Sheet Management
- **FR-01**: Create, rename, open, and close a workbook locally.
- **FR-02**: Create, rename, reorder, and switch between sheets.
- **FR-11**: Save and reopen workbooks locally with predictable recovery behavior; interrupted or failed saves must be reported (`AC-07`).

### 4.2. Grid Canvas, Navigation & Selection
- **FR-03**: Select cells, ranges, rows, and columns with visual bounding box (`#107C41`) and soft green range tint (`#E2F0D9` at 12% opacity).
- **FR-04**: Edit cell values and text; support copy, cut, paste, and fill handle where feasible.
- **FR-05**: Insert, delete, resize, and rename rows and columns.
- **FR-13**: Provide keyboard navigation and shortcuts for common spreadsheet actions (`Arrow keys`, `Tab`, `Enter`, `Home`, `Ctrl+Home`, `Shift+Arrow`).
- **FR-15**: Provide a status bar area for active cell coordinate, selection aggregates, and workbook calculation state.

### 4.3. Formatting & Data Presentation
- **FR-06**: Create a table quickly from a selected range or pasted data.
- **FR-07**: Apply basic number formats (Currency, Percent, Comma, Decimals), font styling (Family, Size, Bold, Italic, Underline), alignment, borders, and background fill.
- **FR-08**: Sort and filter a table or range without corrupting associated row associations (`AC-03`).

### 4.4. Formula Calculation Subsystem
- **FR-09**: Support a defined starter set of formulas with visible errors for invalid formulas (`AC-04`, `AC-05`).
  - **Starter Functions**: `SUM`, `AVERAGE`, `MIN`, `MAX`, `COUNT`, `COUNTA`, `IF`, and basic arithmetic expressions (`+`, `-`, `*`, `/`, `^`).
  - **Extended Functions**: `SUMIF`, `SUMIFS`, `VLOOKUP`, `XLOOKUP`, `INDEX`, `MATCH`, `CONCATENATE`.
  - **Standard Errors**: `#DIV/0!`, `#VALUE!`, `#REF!`, `#NAME?`, `#NUM!`, `#N/A`, `#CIRCULAR!`.
- **FR-10**: Provide unlimited undo/redo for supported editing operations backed by the Command pattern.
- **FR-14**: Display clear validation, import, save, and formula error diagnostics (`editor_formula_error_diagnostics`).

### 4.5. Existing-File & Import/Export Requirements
- **FILE-01**: Open an existing local file through a native Windows file picker.
- **FILE-02**: Support CSV import as the first dependable import path.
- **FILE-03**: Investigate XLSX import separately from XLSX export; do not assume a library that writes XLSX can faithfully read existing XLSX files.
- **FILE-04**: Preview workbook sheet names, row/column counts where available, and import warnings before opening.
- **FILE-05**: Never overwrite the source file during import (`AC-16`). Open as a working copy or ask the user to choose a new save path.
- **FILE-06**: Clearly warn when unsupported formulas, formatting, merged cells, tables, external links, macros, or workbook features may not be preserved (`file_workflow_xlsx_compatibility_warning`).
- **FILE-07**: Preserve a known source file fixture and compare imported values and formulas against expected results.
- **FILE-08**: Save/export behavior must be explicit about the chosen format and potential compatibility loss.

### 4.6. Authentication & User Profile Scope
- **AUTH-01**: Registration and login UI with email/password fields and validation (`login_local_account`).
- **AUTH-02**: Authentication requests are handled by a supported identity provider; no password is stored in local app preferences (`AC-13`).
- **AUTH-03**: Password reset, sign-out, session expiry, and user-visible authentication errors are defined and tested (`AC-11`, `AC-12`).
- **AUTH-04**: A successful login does not imply cloud file storage or synchronization; editing remains strictly local-first.
- **AUTH-05**: Evaluate desktop provider feasibility before committing to an SDK.
- **AUTH-06**: Users can open and edit local files without requiring an active online account.

---

## 5. Non-Functional Requirements

- **Correctness**: Formula outputs and data transformations must be deterministic and covered by tests (`AC-04`).
- **Responsiveness**: Viewport navigation, typing, and editing remain responsive at 60 FPS for datasets up to 100,000 active cells.
- **Data Integrity**: Saving, reopening, sorting, filtering, and importing must not silently lose or misassociate data (`AC-03`, `AC-06`).
- **Recovery**: Interrupted or failed saves must be reported; the app must never claim a save succeeded when it did not (`AC-07`).
- **Maintainability**: Strict logical separation between UI Presentation, Application State, Formula Evaluation, and Persistence.
- **Security & Privacy**: Local files handled strictly through user-authorized file access; zero secrets or passwords in logs or plaintext files.

---

## 6. Non-Goals & Explicit Exclusions (Out of Scope for Initial Phases)

As confirmed by Section 5 of the R&D Report, the following are explicitly deferred:
1. **Multi-user real-time collaboration**: No live cursors, WebSockets, or CRDT/OT synchronization.
2. **Cloud sync / Remote Storage**: No mandatory cloud storage, Google Drive, or OneDrive sync in MVP.
3. **Backend / Microservices**: No custom server runtime or backend API dependencies.
4. **Excel Macro / VBA Support**: No visual basic or script execution runtime.
5. **Broad Excel Feature Parity**: Pivot tables, 3D charts, forms connected to data, and automation webhooks remain deferred.
