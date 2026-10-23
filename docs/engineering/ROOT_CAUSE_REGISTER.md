# Grid Sheet — Root Cause Register (RCA)

This document details root-cause investigations, confirmed defects, systemic architectural issues, fixes, and long-term prevention strategies.

---

## Confirmed Root Causes

### RCA-001: Missing Visual Studio Desktop C++ Workload for Local Windows Builds
- **Date Recorded:** 2026-10-23
- **Associated Error ID:** `ERR-001`
- **Symptom:** Running `flutter build windows --release` locally fails immediately with `Unable to find suitable Visual Studio toolchain. Please run flutter doctor for more details.`
- **Investigation / Evidence:**
  `flutter doctor -v` reported that Visual Studio was located at `C:\Program Files\Microsoft SQL Server Management Studio 22\Release` with version `22.4.11612.150`, but components `MSVC v142/v143`, `C++ CMake tools for Windows`, and `Windows 10 SDK` are absent.
- **Root Cause:**
  Windows desktop builds in Flutter require the native MSVC C++ toolchain and CMake. The workstation only has SQL Server Management Studio (which registers as a Visual Studio shell in registry), not the actual Visual Studio C++ desktop development workload.
- **Resolution / Fix:**
  1. Updated `scripts/validate_phase.ps1` to detect MSVC presence before attempting build, reporting `BLOCKED` rather than failing the validation script.
  2. Directed native binary compilation to `.github/workflows/ci.yml` and `.github/workflows/release-windows.yml` on `windows-latest` runners, which have the complete MSVC workload installed by default.
- **Prevention Strategy:**
  Never assume developer machine toolchain parity. Keep domain and calculation logic strictly pure Dart so that 95%+ of testing can run headless without invoking native platform compilers.
