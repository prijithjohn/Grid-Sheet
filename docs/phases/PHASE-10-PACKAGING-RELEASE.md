# Phase 10 — Windows Packaging & CI/CD Release

## 1. Phase Metadata
- **Phase Number:** `10`
- **Phase Name:** Windows Packaging & Release
- **Status:** `NOT STARTED`
- **Prerequisites:** All previous phases (Phase 00 through Phase 09) verified and signed off.
- **Implementation Branch:** `feature/phase-10-packaging-release`
- **Remote CI Run:** Pending tagged release trigger.

---

## 2. Purpose & Expected User-Visible Outcome
- **Purpose:** Package Grid Sheet into a production-ready, distributable Windows desktop installer / portable executable bundle, generate cryptographic integrity checksums (`SHA-256`), and automate release publishing via GitHub Actions with signed artifacts.
- **Expected Outcome:** Users and enterprise administrators can download a verified Windows installer (`.msix` or `.exe`), install Grid Sheet with zero dependency prerequisites, launch the application from the Windows Start menu, and receive a secure, digitally verified spreadsheet application.

---

## 3. Verified Starting State
- Complete application features and performance optimizations verified across Phases 00 through 09.
- Existing GitHub Actions release workflow at `.github/workflows/release-windows.yml`.

---

## 4. Scope Included
- **Windows Release Build Optimization:**
  - Build flags and tree-shaking for Windows desktop x64.
  - App metadata, product versioning (`pubspec.yaml`), company info, and desktop icon embedding (`windows/runner/resources/app_icon.ico`).
- **Installer Packaging:**
  - Inno Setup or MSIX packaging script bundling executable, Flutter engine DLLs, and asset files.
  - Desktop shortcut, Start Menu entry, and `.gsheet` file extension association.
- **Checksum & Integrity Verification:**
  - Automatic SHA-256 checksum generation for release binaries (`checksums.txt`).
- **Automated GitHub Actions Release Pipeline (`release-windows.yml`):**
  - Triggered on Git tags (`v*.*.*`).
  - Automated runner compiling on `windows-latest`.
  - Packaging installer, calculating checksums, and creating a GitHub Draft Release with downloadable assets attached.
- End-to-end release smoke verification testing clean install, launch, new workbook, save, and exit.

---

## 5. Explicit Out-of-Scope Items
- macOS / Linux / Web desktop packaging (Grid Sheet is strictly Windows-first desktop).
- Microsoft Store submission fees/account publishing (commercial operations out of scope).

---

## 6. Dependencies on Earlier Phases
- All earlier phases (Phase 00 through Phase 09).

---

## 7. Relevant Architecture & Existing Files
- `.github/workflows/release-windows.yml`: Release pipeline workflow.
- `windows/runner/Runner.rc`: Windows executable version and icon resource.
- `pubspec.yaml`: App version string (`version: 1.0.0+1`).

---

## 8. Proposed Implementation Steps
1. Configure Windows runner application metadata, display name, and executable properties.
2. Author packaging script (`scripts/package_windows.ps1` or Inno Setup `.iss`).
3. Integrate `.gsheet` Windows file type association in runner registry.
4. Update and test `.github/workflows/release-windows.yml`.
5. Execute full end-to-end integration test of packaged installer.
6. Verify release artifact checksum generation.

---

## 9. Required Tests & Verification
- Packaging & Release Verification:
  - `flutter build windows --release` (executed on CI runner)
  - Package integrity check (verifying all DLLs and data assets present in output bundle)
  - Windows clean-install smoke test (launching packaged app, creating sheet, saving file, exiting)
  - SHA-256 checksum verification
- Target: 100% automated release verification.

---

## 10. Exact Acceptance Criteria
- [ ] Windows release binary compiles cleanly without warnings or missing assets.
- [ ] Installer or portable bundle packages all required Flutter DLLs, ICUs, and data assets into a standalone distribution.
- [ ] Packaged application launches cleanly on Windows without requiring a developer environment or Flutter SDK.
- [ ] Double-clicking a `.gsheet` file opens Grid Sheet with that file loaded.
- [ ] Release pipeline generates valid SHA-256 checksum file matching the binary output.
- [ ] GitHub Actions release workflow successfully creates a tagged release with downloadable artifacts.

---

## 11. Commands Needed for Verification
```powershell
flutter build windows --release
powershell -File scripts/package_windows.ps1
Get-FileHash -Algorithm SHA256 build/windows/x64/runner/Release/grid_sheet.exe
```

---

## 12. Git & CI Requirements
- Feature Branch: `feature/phase-10-packaging-release`
- Release Tag: `v1.0.0`
- GitHub Actions: `.github/workflows/release-windows.yml` run completed with release published.

---

## 13. Known Risks & Rollback Considerations
- **Risk:** Missing Visual C++ redistributable on target user machines.
- **Mitigation:** Package static VC++ runtime or bundle MSVC redistributable installer.
- **Rollback:** Delete drafted release tag on GitHub.

---

## 14. Required Evidence for Completion
- Verified Windows release build artifact on GitHub Actions.
- Valid `checksums.txt` file.
- Clean installation smoke test report.
- Phase Execution Report filed.

---

## 15. Entry Gate
- All phases (00 through 09) verified, approved, and merged to `main`.

## 16. Exit Gate
- Packaged release artifact tested, checksums verified, GitHub release published.

---

## 17. Status & Evidence Links
- Status: `NOT STARTED` ([`PHASE-STATUS.md`](../engineering/phase-control/PHASE-STATUS.md)).
- Workflow: [`.github/workflows/release-windows.yml`](../../.github/workflows/release-windows.yml).
