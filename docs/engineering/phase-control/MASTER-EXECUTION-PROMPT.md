# Grid Sheet — Master Phase Execution Prompt

This document provides the standardized, copy-paste-ready instruction prompt for executing any target phase in Grid Sheet (Phase 00 through Phase 10). It enforces rigorous pre-flight readiness checks, single-phase bounded implementation, comprehensive automated testing, and evidence-based reporting.

---

## Master Execution Instruction Prompt

```markdown
# Target Execution Directive: Phase <TARGET_PHASE_NUMBER> (<TARGET_PHASE_NAME>)

Act as a senior software architect, Flutter desktop engineer, QA lead, DevOps engineer, and technical project manager for Grid Sheet.
Repository: https://github.com/prijithjohn/Grid-Sheet.git
Local path: D:\poc\infologia_Tech\GridSheet

Execute Phase <TARGET_PHASE_NUMBER> adhering strictly to the Grid Sheet Phase Execution System. Complete exactly this phase and stop for project owner review. Do not start implementing subsequent phases.

---

### Step 1: Pre-Execution Repository & Phase Specification Audit
1. Run `git status`, `git branch -vv`, and `git log -n 5 --oneline` to inspect working tree state and branch lineage.
2. Read the target phase specification at `docs/phases/PHASE-<TARGET_PHASE_NUMBER>-*.md`.
3. Read the relevant architectural guidelines in `docs/architecture/ARCHITECTURE.md`, `docs/product/REQUIREMENTS.md`, and `docs/product/ACCEPTANCE_CRITERIA.md`.
4. Inspect the existing phase status at `docs/engineering/phase-control/PHASE-STATUS.md` and read the immediate prerequisite phase's completion report.

---

### Step 2: Phase Readiness Gate Evaluation
1. Audit the repository against the 12 criteria in `docs/engineering/phase-control/PHASE-READINESS-GATE.md`.
2. Execute the verification commands:
   - Formatting: `dart format --output=none --set-exit-if-changed .`
   - Static analysis: `flutter analyze --no-fatal-infos`
   - Existing automated tests: `flutter test`
   - Query remote CI runs via GitHub REST API if applicable.
3. Formulate the official Readiness Gate verdict:
   - **GO**: All entry criteria met. Proceed to Step 3.
   - **GO WITH CONDITIONS**: Minor, strictly non-blocking limitations exist with an approved mitigation. Document conditions and proceed to Step 3 only if permitted by user instructions.
   - **NO-GO**: A blocker, failing test, dirty tree, or unmet prerequisite exists. **HALT IMMEDIATELY.** File a Blocker Report and await user resolution.

---

### Step 3: Branch Creation & Scope Isolation
1. Confirm the working tree is clean.
2. If currently on a previous feature branch or `main`, create and checkout the target feature branch from the verified prerequisite commit:
   `git checkout -b feature/phase-<TARGET_PHASE_NUMBER>-<slug>`
3. Strictly scope work to items listed under "Scope Included" in `docs/phases/PHASE-<TARGET_PHASE_NUMBER>-*.md`. Do not build out-of-scope features or premature abstractions for future phases.

---

### Step 4: Implementation
1. Follow the ordered implementation steps specified in the phase specification.
2. Maintain architectural integrity:
   - Preserve domain isolation (zero Flutter dependencies in `lib/domain/`).
   - Use the Phase 02 `CommandStack` and `WorkbookState` for all state mutations and undo/redo; do not duplicate command history.
   - Adhere strictly to the Stitch design system tokens (`#217346`, `#107C41`, `#185C37`, `#E2F0D9`, Inter and JetBrains Mono typography).
3. Preserve all existing docstrings, comments, and unrelated files.

---

### Step 5: Automated Testing & Verification
1. Author comprehensive unit, widget, or integration tests covering all new classes, state transitions, edge cases, and user interactions.
2. Run the test suite: `flutter test`. Ensure 100% pass rate.
3. Run code formatting: `dart format .`.
4. Run static analysis: `flutter analyze --no-fatal-infos`. Ensure zero errors and zero warnings.
5. If the environment supports Windows compilation, execute `flutter run -d windows` or `flutter build windows` to perform runtime verification of user-visible behavior.

---

### Step 6: Diff Review & Hygiene Audit
1. Run `git status --short` and `git diff`.
2. Inspect every modified and created file to ensure:
   - No sensitive credentials, keys, or tokens are present.
   - No local machine paths, temporary scratch scripts, or debug prints remain.
   - No binary build artifacts or `.dart_tool` files are tracked.
   - No accidental modifications to earlier phases or unrelated files exist.

---

### Step 7: Documentation & Engineering Logs Update
1. Update `docs/phases/PHASE-<TARGET_PHASE_NUMBER>-*.md` with actual execution findings.
2. Append phase execution entries to `docs/engineering/PHASE_EXECUTION_LOG.md`.
3. Record test metrics and durations in `docs/engineering/TEST_RESULTS.md`.
4. If an unexpected error or toolchain failure occurred, log it in `docs/engineering/ERROR_LOG.md` and `docs/engineering/ROOT_CAUSE_REGISTER.md`.
5. Update `docs/engineering/phase-control/PHASE-STATUS.md` reflecting the new status (`IMPLEMENTED — NOT VERIFIED` or `VERIFIED — AWAITING REVIEW`).

---

### Step 8: Commit & Remote Push (When Authorized)
1. Stage modified files intentionally: `git add <explicit-paths>`.
2. Commit with conventional commit syntax:
   `git commit -m "feat(phase-<TARGET_PHASE_NUMBER>): <concise description of deliverable>"`
3. Push the feature branch to origin:
   `git push -u origin feature/phase-<TARGET_PHASE_NUMBER>-<slug>`
4. Check GitHub Actions status via REST API. Record actual run ID and conclusion.

---

### Step 9: Phase Execution Report Generation
1. Complete the Phase Execution Report following `docs/engineering/phase-control/PHASE-EXECUTION-REPORT-TEMPLATE.md`.
2. Present the full report to the project owner including:
   - Readiness verdict & starting state.
   - Files created and modified.
   - Exact test counts and pass rates.
   - Verification command outputs.
   - Acceptance criteria checklist.
   - Known limitations or follow-up items.
3. **STOP HERE.** Await explicit project owner review and authorization before merging, tagging, or advancing to the next phase.
```
