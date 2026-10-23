# ADR 0001: Technology Stack and Core Architecture for Desktop Spreadsheet

## Status
**Accepted** (2026-10-23)

## Context
Grid Sheet requires building a professional desktop spreadsheet application for Windows capable of high-density tabular presentation, sub-millisecond formula evaluation, smooth multi-axis viewport scrolling, and offline desktop operation. The application must feature rich visual aesthetics (light "Grid Professional" and dark "Graphite & Mint" themes), standard keyboard shortcuts, and full undo/redo command capabilities.

Key architectural requirements:
1. Native Windows desktop performance (60 FPS scrolling, low memory footprint).
2. Clean separation between UI presentation and spreadsheet calculation logic.
3. Complete determinism and testability without requiring a running UI or emulator.
4. Support for standard spreadsheet file workflows (`.gsheet`, `.xlsx`, `.csv`, `.tsv`).

## Decision

1. **Framework & Language**:
   - Use **Flutter Desktop (Windows)** with **Dart 3.13.4+**.
   - Flutter compiles to native ARM64/x64 Windows machine code via CMake and the MSVC C++ toolchain, delivering native rendering speeds and tight OS integration.

2. **Presentation Subsystem**:
   - Implement the primary spreadsheet grid using Flutter's **`CustomPainter`** on a single canvas rather than composing individual cell `Widget` instances.
   - Virtualize rendering by calculating row/column offsets to paint only visible cells plus a modest overdraw buffer.

3. **Domain & Calculation Engine**:
   - Build the domain model (`Workbook`, `Worksheet`, `Cell`, `CellCoordinate`) and calculation engine (`Lexer`, `Pratt Parser`, `DAG Dependency Graph`, `Topological Evaluator`) as **pure Dart libraries with zero Flutter dependencies**.
   - Store worksheet cells in a sparse coordinate mapping structure to ensure minimal memory overhead on sparse worksheets.

4. **Command & History Architecture**:
   - Adopt the **Command Pattern** for all user mutations (`SetCellCommand`, `FormatRangeCommand`, `InsertRowCommand`, `DeleteSheetCommand`).
   - Every command implements `execute()` and `undo()` with immutable before/after state snapshots.

5. **CI/CD Platform**:
   - Utilize **GitHub Actions** with `windows-latest` runners to enforce automated linting (`flutter analyze`), formatting verification (`dart format`), unit and widget tests (`flutter test`), and Windows native release compilation (`flutter build windows`).

## Consequences

### Positive
- **High Performance**: `CustomPainter` avoids the widget tree overhead, delivering 60+ FPS even with dense cell formatting.
- **Pure Dart Portability & Fast Testing**: Headless unit tests for formulas, DAG calculations, and persistence execute in milliseconds without launching the Flutter engine.
- **Reliable Undo/Redo**: The Command pattern guarantees 100% reversible state mutations.
- **Modern Desktop Visuals**: Flutter's graphics pipeline delivers pixel-crisp borders, fluid animations, and instantaneous theme switching between Light and Dark modes.

### Negative / Trade-Offs
- **Custom Canvas Complexity**: Implementing custom text selection, cell cursors, and touch/mouse hit-testing on a `CustomPainter` requires careful coordinate geometry math compared to using pre-built widgets.
- **Windows Build Environment**: Compiling release binaries on Windows requires Visual Studio C++ desktop build tools (`MSVC`, `CMake`, `Windows 10/11 SDK`). While available out-of-the-box in GitHub Actions CI, local developer environments must have this workload installed.
