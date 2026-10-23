# Grid Sheet — Acceptance Criteria (AC)

This document maps all **17 formal acceptance criteria** (`AC-01` to `AC-17`) established in Section 14 and Section 25 of the R&D Report (`Spreadsheet_Application_Frontend_RnD_Report_v2 (1).pdf`), enriched with specific test scenarios for Grid Sheet.

---

## Formal R&D Acceptance Criteria (`AC-01` to `AC-17`)

### AC-01: Workbook Round-Trip Integrity
- **Criterion**: A workbook can be created, saved, closed, and reopened with all supported data preserved.
- **Verification**: Create workbook with strings, numbers, formulas, formatting, custom column widths, and 3 worksheets. Save to `.gsheet`. Close application. Reopen file. Every cell value, formula AST, style token, and tab order must match original with 100% fidelity.

### AC-02: Reversible Editing Operations
- **Criterion**: Editing a cell updates the visible workbook state and can be undone/redone when the operation is supported.
- **Verification**: Execute cell edits, text deletions, range clears, and formatting applications. Verify UI updates immediately. Press `Ctrl+Z` to undo each step; verify previous state is restored. Press `Ctrl+Y` to redo; verify forward state is re-applied.

### AC-03: Table Sorting Integrity
- **Criterion**: Table sorting moves complete rows together and filtering does not delete hidden records.
- **Verification**: Create a 5-column table where column A has unique IDs and column E has numeric values. Sort by column E ascending. Verify that records in columns A–D stay tied to their original row context. Apply a filter hiding 50% of rows. Verify count of active records is unchanged and clearing the filter restores all hidden rows intact.

### AC-04: Formula Correctness & Coverage
- **Criterion**: Formula tests match independently calculated expected results for all supported functions and edge cases.
- **Verification**: Execute table-driven test suite for `SUM`, `AVERAGE`, `MIN`, `MAX`, `COUNT`, `COUNTA`, `IF`, `SUMIF`, `SUMIFS`, `VLOOKUP`, arithmetic operators, and parentheses precedence. 100% of test cases must match verified expected values.

### AC-05: Visible Errors on Invalid Formulas
- **Criterion**: Invalid formulas show a visible error and do not silently produce a plausible but incorrect value.
- **Verification**:
  - Division by zero (`=10/0`) displays `#DIV/0!`.
  - Type mismatch (`=10 + "abc"`) displays `#VALUE!`.
  - Reference to nonexistent or deleted sheet displays `#REF!`.
  - Unknown function call (`=FOOBAR()`) displays `#NAME?`.
  - Selecting error cell displays the error diagnostics tooltip with explanation.

### AC-06: CSV Import/Export Robustness
- **Criterion**: CSV import/export round-trips commas, quotes, line breaks, Unicode, empty fields, and supported line endings.
- **Verification**: Load test CSV fixture containing quoted commas (`"Smith, Jane"`), escaped quotes (`"He said ""Hello"""`), embedded newlines (`"Line1\nLine2"`), and multi-byte UTF-8 characters. Verify parsed grid cells match expected tokens. Export back to CSV and verify byte-level equivalence.

### AC-07: Save Failure Visibility
- **Criterion**: Save failures are visible and do not produce a false saved state.
- **Verification**: Attempt saving to a read-only directory or simulated disk-full error. The application must display an error modal explaining the failure, keep the active document in memory, and retain the `[Unsaved Changes]` status badge in the title bar.

### AC-08: Reference Performance Benchmarks
- **Criterion**: The agreed reference workbook opens and supports the agreed editing tasks within measured performance thresholds.
- **Verification**: Open benchmark workbook (10,000 rows x 20 columns). Viewport render time must remain under 16.6ms (60 FPS scrolling). Cell edit latency must not exceed 50ms. Total memory usage must remain under 250MB.

### AC-09: Keyboard-Only Usability
- **Criterion**: The UI remains usable with keyboard-only navigation for the agreed core tasks.
- **Verification**: Complete the following journey without mouse input: Navigate to `B2` using arrows -> Press `Enter` to enter edit mode -> Type `=SUM(A1:A10)` -> Press `Enter` -> Press `Shift+Right` to select range -> Press `Ctrl+B` to bold -> Press `Ctrl+S` to trigger save.

### AC-10: Disclosure of Compatibility Limits
- **Criterion**: The product and documentation clearly disclose unsupported Excel features and file compatibility limits.
- **Verification**: Documentation clearly lists non-supported items (VBA, 3D charts, external links). When opening or saving files with complex features, display the XLSX Compatibility Warning dialog (`file_workflow_xlsx_compatibility_warning`).

### AC-11: Authentication Validation Errors
- **Criterion**: Invalid login and registration inputs produce understandable messages without exposing secrets.
- **Verification**: Submitting invalid email formats, passwords shorter than policy, or mismatched confirmation fields displays inline validation errors without exposing internal server tokens or crashing.

### AC-12: Session Restoration and Sign-Out
- **Criterion**: Session restoration and sign-out behavior are tested on each target desktop platform.
- **Verification**: Logging in persists session token securely. Relaunching the app restores user profile ("Finance Org"). Clicking "Sign Out" completely clears tokens and returns to offline/guest mode.

### AC-13: No Plaintext Secret Storage
- **Criterion**: No password or authentication secret is stored in plaintext local preferences or logs.
- **Verification**: Inspect `.dart_tool`, local SharedPreferences, log files, and Windows Registry. Zero passwords or plain authentication credentials appear in plaintext storage.

### AC-14: Comprehensive CSV Edge Cases
- **Criterion**: CSV import correctly handles quoted delimiters, embedded newlines, Unicode, and empty fields.
- **Verification**: Covered by automated tests in `test/unit/import_export/csv_engine_test.dart` asserting proper cell segmentation.

### AC-15: XLSX Test Matrix
- **Criterion**: An XLSX test matrix records behavior for multiple sheets, formulas, values, dates, formatting, hidden sheets, merged cells, and unsupported features.
- **Verification**: Maintain documented test matrix comparing input `.xlsx` files against parsed `Workbook` domain models.

### AC-16: Safe Import Non-Overwriting
- **Criterion**: Import never silently overwrites the source workbook.
- **Verification**: Importing a CSV or XLSX file loads data into a new in-memory document marked "Untitled [Imported]". Saving prompts the user for a new filename and destination path.

### AC-17: Compatibility Summary on Export
- **Criterion**: The user receives a compatibility summary before saving imported content if meaningful features are unsupported.
- **Verification**: Exporting to XLSX when unsupported formatting or formulas are present triggers the compatibility warning modal before disk writing.
