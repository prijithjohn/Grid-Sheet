# Phase 07 — CSV/TSV Import & Export

## 1. Phase Metadata
- **Phase Number:** `07`
- **Phase Name:** CSV/TSV Import & Export
- **Status:** `NOT STARTED`
- **Prerequisites:** Phase 01 (Domain), Phase 02 (Application State & Commands), Phase 06 (File Persistence).
- **Implementation Branch:** `feature/phase-07-csv-tsv-import-export`
- **Remote CI Run:** Pending implementation.

---

## 2. Purpose & Expected User-Visible Outcome
- **Purpose:** Enable seamless data interoperability with external tools and datasets via RFC 4180-compliant CSV and TSV streaming parsers and writers, an interactive CSV Import Configuration Preview dialog, and system clipboard TSV copy-paste integration.
- **Expected Outcome:** Users can open `.csv` or `.tsv` files with an interactive preview dialog displaying delimiter detection, import datasets into the active sheet, export active sheets to CSV, and copy/paste tabular data between Grid Sheet and external apps (e.g. Excel, Notepad, browsers).

---

## 3. Verified Starting State
- Phase 01 `Worksheet` provides sparse matrix cell storage.
- Phase 02 `SetCellTextCommand` and `ClearRangeCommand` support multi-cell data insertions.
- Phase 06 native persistence foundation established.

---

## 4. Scope Included
- **RFC 4180 CSV / TSV Engine (`csv_engine.dart`):**
  - Streaming reader handling quotes, embedded commas, newlines, and escaping (`""`).
  - Delimiter detection (comma `,`, semicolon `;`, tab `\t`, pipe `|`).
  - Text encoding support (UTF-8 with and without BOM, ASCII).
  - Streaming CSV writer generating valid RFC 4180 output from worksheet coordinates.
- **CSV Import Configuration Preview Dialog (`file_workflow_csv_import_configuration_preview` — Stitch Screen 16):**
  - 20-row interactive preview table.
  - Delimiter radio/dropdown selector.
  - "First row contains column headers" checkbox.
  - Text encoding selector.
  - Import destination selector (New Worksheet, Replace Active Sheet, Active Cell Offset).
- **Clipboard Interoperability (`clipboard_manager.dart`):**
  - Copy selected range to system clipboard formatted as tab-delimited text (`\t` and `\n`).
  - Paste clipboard TSV content into active grid coordinates, auto-expanding cells and recording a single undoable compound command.
- Unit and widget tests testing RFC 4180 compliance, large dataset imports, and clipboard paste sequences.

---

## 5. Explicit Out-of-Scope Items
- Full Microsoft Excel OpenXML (`.xlsx`) binary round-trip writing (deferred to future enhancement; notice that CSV support does not imply full XLSX feature parity).
- SQL database imports or web API connectors.

---

## 6. Dependencies on Earlier Phases
- **Phase 01:** `CellCoordinate`, `CellModel`, `Worksheet`.
- **Phase 02:** `WorkbookState`, `CommandStack`, `SetCellTextCommand`.
- **Phase 06:** File picker and storage services.

---

## 7. Relevant Architecture & Existing Files
- `lib/data/import_export/`: Directory for parsers and serializers.
- `lib/features/import_export/`: Dialogs and UI previews.
- `docs/design/STITCH_SCREEN_INVENTORY.md`: Screen 16 (`file_workflow_csv_import_configuration_preview`).

---

## 8. Proposed Implementation Steps
1. Implement RFC 4180 `CsvEngine` in `lib/data/import_export/csv_engine.dart`.
2. Implement auto-detection heuristics for delimiters and line endings.
3. Implement `CsvImportPreviewDialog` in `lib/features/import_export/dialogs/csv_import_dialog.dart`.
4. Implement `ClipboardManager` handling TSV format on Windows desktop.
5. Bind `Ctrl+C`, `Ctrl+X`, and `Ctrl+V` to `ClipboardManager` in `desktop_shortcuts.dart`.
6. Add File -> Import CSV and File -> Export CSV menu actions.
7. Author RFC 4180 unit tests and clipboard widget integration tests.

---

## 9. Required Tests & Verification
- Unit & Widget Tests:
  - `test/unit/import_export/csv_engine_test.dart` (quotes, commas, escaped quotes, multiline cells)
  - `test/unit/import_export/delimiter_detection_test.dart` (comma, semicolon, tab, pipe)
  - `test/widget/import_export/csv_import_dialog_test.dart` (preview rendering, delimiter switching)
  - `test/unit/import_export/clipboard_tsv_test.dart` (copy range to TSV, paste rectangular block)
- Target: 25+ tests, 100% pass rate.

---

## 10. Exact Acceptance Criteria
- [ ] RFC 4180 CSV parser handles embedded commas, newlines within quotes, and double quotes cleanly.
- [ ] Delimiter detection accurately identifies tabs, commas, and semicolons.
- [ ] CSV Import Preview dialog displays accurate 20-row preview before importing into sheet.
- [ ] Copying a selected 3x3 range places standard TSV onto system clipboard.
- [ ] Pasting multi-line TSV into Grid Sheet populates cells starting from active cursor and can be completely undone in one `Ctrl+Z`.
- [ ] Zero static analysis errors or warnings.

---

## 11. Commands Needed for Verification
```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test test/unit/import_export/ test/widget/import_export/
```

---

## 12. Git & CI Requirements
- Feature Branch: `feature/phase-07-csv-tsv-import-export`
- Base: Verified Phase 06 branch.

---

## 13. Known Risks & Rollback Considerations
- **Risk:** Large CSV files (100k+ rows) locking the UI thread during parsing.
- **Prevention:** Parse in a background isolate or streaming chunk iterator.
- **Rollback:** `git revert <commit-sha>`.

---

## 14. Required Evidence for Completion
- 25+ import/export and clipboard tests passing.
- RFC 4180 edge cases verified.
- Phase Execution Report filed.

---

## 15. Entry Gate
- Phase 06 verified and signed off.

## 16. Exit Gate
- All 6 acceptance criteria verified, import/export test suite green.

---

## 17. Status & Evidence Links
- Status: `NOT STARTED` ([`PHASE-STATUS.md`](../engineering/phase-control/PHASE-STATUS.md)).
