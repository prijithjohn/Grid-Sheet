# Phase 06 — Native File Persistence & Recovery

## 1. Phase Metadata
- **Phase Number:** `06`
- **Phase Name:** Native File Persistence & Recovery
- **Status:** `NOT STARTED`
- **Prerequisites:** Phase 01 (Domain Models), Phase 02 (Application State), Phase 05 (Formatting Integration).
- **Implementation Branch:** `feature/phase-06-file-persistence`
- **Remote CI Run:** Pending implementation.

---

## 2. Purpose & Expected User-Visible Outcome
- **Purpose:** Provide secure, deterministic file storage for Grid Sheet workbooks using a native, versioned `.gsheet` JSON format. Ensure user data safety through periodic auto-saving, crash recovery journaling, unsaved change warnings on close, and seamless File Open / Save As workflows.
- **Expected Outcome:** Users can save their workbooks to local disk (`Ctrl+S`), specify file locations with Save As (`file_workflow_save_as_export_dialog`), open existing files (`file_workflow_open_existing_workbook`), and recover unsaved edits following an unexpected crash or power loss.

---

## 3. Verified Starting State
- `WorkbookState.isDirty` tracks unsaved mutations and `WorkbookState.markClean()` resets it.
- `WorkbookState.filePath` holds active file path.
- `Workbook` aggregate holds all worksheets, cell models, and metadata.

---

## 4. Scope Included
- **Native JSON Serialization (`workbook_serializer.dart`):**
  - Schema versioning (`schemaVersion: 1`).
  - Round-trip fidelity preserving all sheets, sparse cells, raw inputs, computed values, formatting styles, row heights, and column widths.
- **Persistence Engine (`file_persistence_service.dart`):**
  - Atomic file writing (writing to temporary file and renaming to prevent corruption).
  - Open file deserialization with schema validation.
- **Auto-Save & Recovery Journal (`recovery_service.dart`):**
  - Background auto-save interval (e.g. every 60 seconds when dirty).
  - Write-ahead recovery journal in app cache directory.
  - Startup crash recovery prompt when orphaned recovery journals are detected.
- **File Dialogs & UI Workflows (`lib/features/file_management/`):**
  - Native Windows file picker integration for `.gsheet`.
  - Unsaved changes confirmation dialog on window close or new file creation.
  - Recent files tracking (persisting recent paths in local app storage).
- Unit and widget tests testing 100% round-trip fidelity, corrupted file handling, and recovery restore.

---

## 5. Explicit Out-of-Scope Items
- CSV/TSV parsing and export (dedicated to Phase 07).
- Cloud storage synchronization or multi-user sharing (strictly local-first MVP).
- Full binary Excel format (.xlsx/.xlsm) write support (deferred).

---

## 6. Dependencies on Earlier Phases
- **Phase 01:** `Workbook`, `Worksheet`, `CellModel`, `CellStyle`, `CellValue`.
- **Phase 02:** `WorkbookState` (`loadWorkbook()`, `markClean()`, `isDirty`).
- **Phase 03:** Window title bar file name and dirty indicator dot.

---

## 7. Relevant Architecture & Existing Files
- `lib/domain/workbook/workbook_model.dart`: Primary data aggregate.
- `lib/app/state/workbook_state.dart`: File path and clean/dirty state.
- Target path: `lib/data/persistence/` and `lib/features/file_management/`.

---

## 8. Proposed Implementation Steps
1. Define `.gsheet` JSON schema specifications in `docs/architecture/GSHEET_SCHEMA.md`.
2. Implement `WorkbookSerializer` with JSON encoding and decoding in `lib/data/persistence/`.
3. Implement `FilePersistenceService` with atomic file writes and file picker integration.
4. Implement `RecoveryService` managing crash journals in app data cache.
5. Implement `UnsavedChangesDialog` and hook into desktop window close events.
6. Connect `Ctrl+S` hotkey and Save button in Title Bar to persistence service.
7. Author comprehensive round-trip tests and recovery simulation tests.

---

## 9. Required Tests & Verification
- Unit & Integration Tests:
  - `test/unit/persistence/workbook_serializer_test.dart` (round-trip serialization fidelity)
  - `test/unit/persistence/schema_version_test.dart` (version migration and invalid JSON rejection)
  - `test/unit/persistence/recovery_service_test.dart` (crash journal creation, recovery detection)
  - `test/widget/file_management/unsaved_changes_dialog_test.dart` (save/discard/cancel options)
- Target: 20+ tests, 100% pass rate.

---

## 10. Exact Acceptance Criteria
- [ ] Saving a workbook produces a valid, readable `.gsheet` JSON file on disk.
- [ ] Loading a `.gsheet` file completely restores all worksheets, cells, formulas, and formatting without data loss.
- [ ] Saving marks `WorkbookState.isDirty` as false and removes the dirty dot from the title bar.
- [ ] Attempting to close or open another file with unsaved changes prompts the user.
- [ ] Simulating a crash and restarting Grid Sheet detects the recovery journal and restores unsaved changes.
- [ ] Zero static analysis errors or warnings.

---

## 11. Commands Needed for Verification
```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test test/unit/persistence/
```

---

## 12. Git & CI Requirements
- Feature Branch: `feature/phase-06-file-persistence`
- Base: Verified Phase 05 branch.

---

## 13. Known Risks & Rollback Considerations
- **Risk:** Partial file writes during disk full or abrupt termination.
- **Prevention:** Enforce atomic write-and-rename pattern (`write to .tmp`, rename to `.gsheet`).
- **Rollback:** `git revert <commit-sha>`.

---

## 14. Required Evidence for Completion
- 20+ persistence and recovery tests passing.
- 100% round-trip fidelity verified across test workbooks.
- Phase Execution Report filed.

---

## 15. Entry Gate
- Phase 05 verified and signed off.

## 16. Exit Gate
- All 6 acceptance criteria verified, persistence test suite green.

---

## 17. Status & Evidence Links
- Status: `NOT STARTED` ([`PHASE-STATUS.md`](../engineering/phase-control/PHASE-STATUS.md)).
