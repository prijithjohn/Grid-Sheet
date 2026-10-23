<#
.SYNOPSIS
    Repeatable validation script for Grid Sheet development phases.

.DESCRIPTION
    Executes mandatory phase quality gates:
    - Dart formatting check
    - Flutter static analysis
    - Unit, widget, and integration tests
    - Optional Windows desktop release compilation

.PARAMETER BuildWindows
    When specified, attempts to build the native Windows release executable.

.PARAMETER TestTarget
    Optional path to a specific test file or directory (defaults to all tests).

.EXAMPLE
    .\scripts\validate_phase.ps1
    .\scripts\validate_phase.ps1 -BuildWindows
    .\scripts\validate_phase.ps1 -TestTarget test/unit/
#>

[CmdletBinding()]
param (
    [switch]$BuildWindows,
    [string]$TestTarget = ""
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       GRID SHEET PHASE VALIDATION PIPELINE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Working Directory: $(Get-Location)`n"

$results = @{
    "Dependencies" = "NOT RUN"
    "Formatting"   = "NOT RUN"
    "Analysis"     = "NOT RUN"
    "Tests"        = "NOT RUN"
    "WindowsBuild" = "NOT RUN"
}

$hasFailure = $false

# 1. Dependency Resolution
Write-Host "--> [1/5] Resolving dependencies (flutter pub get)..." -ForegroundColor Yellow
$pubOutput = flutter pub get 2>&1
if ($LASTEXITCODE -eq 0) {
    $results["Dependencies"] = "PASS"
    Write-Host "[PASS] Dependencies resolved cleanly." -ForegroundColor Green
} else {
    $results["Dependencies"] = "FAIL"
    $hasFailure = $true
    Write-Host "[FAIL] Dependency resolution failed." -ForegroundColor Red
    Write-Host $pubOutput
}

# 2. Dart Formatting Validation
Write-Host "`n--> [2/5] Validating Dart formatting (dart format)..." -ForegroundColor Yellow
$formatOutput = dart format --output=none --set-exit-if-changed . 2>&1
if ($LASTEXITCODE -eq 0) {
    $results["Formatting"] = "PASS"
    Write-Host "[PASS] All files formatted according to Dart conventions." -ForegroundColor Green
} else {
    $results["Formatting"] = "FAIL"
    $hasFailure = $true
    Write-Host "[FAIL] Formatting violations detected:" -ForegroundColor Red
    Write-Host $formatOutput
}

# 3. Flutter Static Analysis
Write-Host "`n--> [3/5] Running static analysis (flutter analyze)..." -ForegroundColor Yellow
$analyzeOutput = flutter analyze --no-fatal-infos 2>&1
if ($LASTEXITCODE -eq 0) {
    $results["Analysis"] = "PASS"
    Write-Host "[PASS] Zero static analysis issues found." -ForegroundColor Green
} else {
    $results["Analysis"] = "FAIL"
    $hasFailure = $true
    Write-Host "[FAIL] Static analysis issues found:" -ForegroundColor Red
    Write-Host $analyzeOutput
}

# 4. Automated Tests
Write-Host "`n--> [4/5] Executing automated tests (flutter test)..." -ForegroundColor Yellow
$testCmd = if ($TestTarget) { "flutter test $TestTarget" } else { "flutter test" }
$testOutput = Invoke-Expression $testCmd 2>&1
if ($LASTEXITCODE -eq 0) {
    $results["Tests"] = "PASS"
    Write-Host "[PASS] All automated tests passed." -ForegroundColor Green
    Write-Host ($testOutput | Select-String -Pattern "All tests passed" -SimpleMatch)
} else {
    $results["Tests"] = "FAIL"
    $hasFailure = $true
    Write-Host "[FAIL] Automated tests failed:" -ForegroundColor Red
    Write-Host $testOutput
}

# 5. Windows Native Release Build (Optional / Environment Aware)
if ($BuildWindows) {
    Write-Host "`n--> [5/5] Building Windows release executable (flutter build windows)..." -ForegroundColor Yellow
    # Pre-check Visual Studio C++ toolchain availability
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $hasMsvc = $false
    if (Test-Path $vsWhere) {
        $installed = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64
        if ($installed) { $hasMsvc = $true }
    }

    if (-not $hasMsvc) {
        $results["WindowsBuild"] = "BLOCKED (Missing Visual Studio Desktop C++ workload)"
        Write-Host "[BLOCKED] Local build skipped: MSVC C++ build tools are not installed locally." -ForegroundColor DarkYellow
        Write-Host "          Note: Native Windows compilation runs remotely in GitHub Actions on windows-latest." -ForegroundColor Gray
    } else {
        $buildOutput = flutter build windows --release 2>&1
        if ($LASTEXITCODE -eq 0) {
            $results["WindowsBuild"] = "PASS"
            Write-Host "[PASS] Windows desktop release built successfully." -ForegroundColor Green
        } else {
            $results["WindowsBuild"] = "FAIL"
            $hasFailure = $true
            Write-Host "[FAIL] Windows build failed:" -ForegroundColor Red
            Write-Host $buildOutput
        }
    }
} else {
    $results["WindowsBuild"] = "NOT RUN (Use -BuildWindows to enable)"
}

# Summary Table
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "                PHASE VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
foreach ($key in @("Dependencies", "Formatting", "Analysis", "Tests", "WindowsBuild")) {
    $status = $results[$key]
    $color = switch -wildcard ($status) {
        "PASS*"    { [ConsoleColor]::Green }
        "FAIL*"    { [ConsoleColor]::Red }
        "BLOCKED*" { [ConsoleColor]::DarkYellow }
        default    { [ConsoleColor]::Gray }
    }
    Write-Host ("{0,-15} : {1}" -f $key, $status) -ForegroundColor $color
}
Write-Host "==========================================================`n" -ForegroundColor Cyan

if ($hasFailure) {
    Write-Host "Phase validation completed with FAILURES." -ForegroundColor Red
    exit 1
} else {
    Write-Host "Phase validation completed SUCCESSFULLY." -ForegroundColor Green
    exit 0
}
