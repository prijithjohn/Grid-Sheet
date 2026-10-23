# Grid Sheet (GridX)

A high-performance, calculation-intensive desktop spreadsheet application built with Flutter for Windows.

Designed with corporate desktop functionalism, pixel-crisp borders, sub-millisecond formula evaluation, and offline local-first data sovereignty.

---

## Key Features (MVP Target)

- **High-Density Canvas Viewport**: Custom-painted virtualized grid supporting up to 1,000,000 rows by 16,384 columns (`A`–`XFD`) with smooth 60 FPS scrolling.
- **Deterministic Formula Engine**: Lexer, Pratt AST parser, Directed Acyclic Graph (DAG) dependency tracking, and cycle detection.
- **Extensive Function Library**: Standard math, logical, lookup, statistical, and text functions (`SUM`, `AVERAGE`, `COUNT`, `COUNTA`, `IF`, `SUMIF`, `SUMIFS`, `VLOOKUP`, etc.).
- **Cell Styling & Formatting**: Rich fonts, background colors, custom borders, alignments, and number formatting (Currency, Percentage, Dates).
- **Multi-Sheet Management**: Dynamic tab strip with add, rename, duplicate, reorder, and cross-sheet formula references.
- **Universal Tabular I/O**: Native `.gsheet` JSON persistence, RFC 4180 CSV/TSV import/export preview, and Microsoft Excel `.xlsx` compatibility.
- **Reversible History**: Full Undo/Redo stack backed by the Command pattern.
- **Theme Parity**: Light "Grid Professional" (`#217346`) and Dark "Graphite & Mint" (`#101412` / `#4edea3`) themes.

---

## Project Structure

```text
GridSheet/
├── .github/
│   └── workflows/
│       ├── ci.yml                     # Continuous Integration (Lint, Format, Test, Build)
│       └── release-windows.yml        # Windows release & packaging workflow
├── assets/
│   ├── icons/                         # Application icons and SVG glyphs
│   └── images/                        # Visual branding assets
├── docs/
│   ├── product/
│   │   ├── REQUIREMENTS.md            # Product Requirements Document & MVP scope
│   │   └── ACCEPTANCE_CRITERIA.md     # Pass/fail observable criteria per feature
│   ├── architecture/
│   │   ├── ARCHITECTURE.md            # System architecture and layer boundaries
│   │   └── ADR/
│   │       └── 0001-initial-architecture-and-tech-stack.md
│   ├── design/
│   │   ├── STITCH_SCREEN_INVENTORY.md # Inventory of 23 Stitch reference screens
│   │   └── DESIGN_SYSTEM.md           # Tokens, palette, typography, grid metrics
│   ├── testing/
│   │   └── TEST_STRATEGY.md           # Unit, widget, integration & smoke test plan
│   ├── releases/                      # Release notes and changelogs
│   └── IMPLEMENTATION_PLAN.md         # Phased implementation roadmap (Phases 00–10)
├── lib/
│   ├── app/                           # App initialization and theme setup
│   ├── core/
│   │   ├── commands/                  # Undo/Redo Command pattern implementation
│   │   ├── errors/                    # Spreadsheet error definitions (#DIV/0!, #REF!)
│   │   ├── keyboard/                  # Desktop shortcut dispatcher
│   │   └── utilities/                 # Coordinate math and clipboard helpers
│   ├── domain/
│   │   ├── workbook/                  # Workbook aggregate model
│   │   ├── worksheet/                 # Worksheet sparse matrix model
│   │   ├── cell/                      # Cell, CellCoordinate, CellStyle entities
│   │   └── formula/                   # Lexer, Pratt parser, DAG, and Evaluator
│   ├── data/
│   │   ├── persistence/               # Native .gsheet JSON serialization
│   │   ├── serialization/             # DTO mapping and schema versions
│   │   └── import_export/             # CSV, TSV, and XLSX engines
│   ├── features/
│   │   ├── home/                      # Welcome & recent workbooks screen
│   │   ├── workbook/                  # Active workbook workspace container
│   │   ├── grid/                      # Viewport, CustomPainter, and selection
│   │   ├── formula_bar/               # Name Box and formula editor bar
│   │   ├── formatting/                # Ribbon styling tools & Format Cells dialog
│   │   ├── worksheets/                # Bottom sheet tab management strip
│   │   ├── import_export/             # CSV preview and import dialogs
│   │   ├── file_management/           # Save As and Open dialogs
│   │   └── settings/                  # Appearance, shortcuts, and preferences
│   └── main.dart                      # Application entry point
├── test/
│   ├── unit/                          # Headless pure Dart domain tests
│   ├── widget/                        # Component and layout widget tests
│   ├── integration/                   # Subsystem integration tests
│   └── fixtures/                      # Sample CSV, XLSX, and JSON test files
├── integration_test/                  # End-to-end desktop workflow tests
├── windows/                           # Native Windows C++/CMake platform runner
├── .gitignore                         # Configured with reference file protection
├── analysis_options.yaml              # Linting rules for Flutter and Dart
└── pubspec.yaml                       # Dependencies and asset declarations
```

---

## Documentation Quick Links

- [Requirements Specification (PRD)](file:///d:/poc/infologia_Tech/GridSheet/docs/product/REQUIREMENTS.md)
- [Acceptance Criteria](file:///d:/poc/infologia_Tech/GridSheet/docs/product/ACCEPTANCE_CRITERIA.md)
- [System Architecture](file:///d:/poc/infologia_Tech/GridSheet/docs/architecture/ARCHITECTURE.md)
- [ADR 0001: Technology Stack](file:///d:/poc/infologia_Tech/GridSheet/docs/architecture/ADR/0001-initial-architecture-and-tech-stack.md)
- [Stitch Screen Inventory](file:///d:/poc/infologia_Tech/GridSheet/docs/design/STITCH_SCREEN_INVENTORY.md)
- [Design System & Tokens](file:///d:/poc/infologia_Tech/GridSheet/docs/design/DESIGN_SYSTEM.md)
- [Test Strategy](file:///d:/poc/infologia_Tech/GridSheet/docs/testing/TEST_STRATEGY.md)
- [Implementation Plan](file:///d:/poc/infologia_Tech/GridSheet/docs/IMPLEMENTATION_PLAN.md)

---

## Getting Started

### Prerequisites

- **Flutter SDK**: 3.47.5+ (channel stable)
- **Dart SDK**: 3.13.4+
- **Operating System**: Windows 10 / 11 (64-bit)
- **C++ Build Tools (for local native compilation)**: Visual Studio 2022 with "Desktop development with C++" workload (MSVC, CMake, Windows 10/11 SDK).

### Setup & Verification

1. Install dependencies:
   ```powershell
   flutter pub get
   ```

2. Verify static analysis and formatting:
   ```powershell
   dart format --output=none --set-exit-if-changed .
   flutter analyze
   ```

3. Run automated tests:
   ```powershell
   flutter test
   ```

4. Launch application in Windows desktop mode:
   ```powershell
   flutter run -d windows
   ```
