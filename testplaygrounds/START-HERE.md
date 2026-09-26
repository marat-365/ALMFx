# START HERE — Read This First

Welcome! You've just received a complete PowerShell 5.1 & 7+ dual-version setup
for ALMFx. Here's where to begin based on your role.

═════════════════════════════════════════════════════════════════════════════

👨‍💼 PROJECT MANAGER / TEAM LEAD
────────────────────────────────────────────────────────────────────────────

Read (5 min):
  → This file (you're reading it!)
  → testplaygrounds/SETUP-SUMMARY.txt (visual overview)

Then:
  → testplaygrounds/INTEGRATION-GUIDE.md (full context)

Know:
  • Module now supports Windows PowerShell 5.1 + PowerShell Core 7+
  • Single codebase (shared helpers prevent duplication)
  • Tests run automatically on both versions via GitHub Actions
  • Ready for feature development immediately

═════════════════════════════════════════════════════════════════════════════

👨‍💻 DEVELOPER (Adding Features)
────────────────────────────────────────────────────────────────────────────

Read (10 min):
  → testplaygrounds/QUICK-REFERENCE.md (1-page cheat sheet)
  → testplaygrounds/PS5-PS7-COMPATIBILITY.md (safe/unsafe APIs)

Before Committing:
  ```powershell
  .\testplaygrounds\run-all-tests.ps1
  ```

Key Functions to Use:
  From Shared/Compatibility.ps1:
    • Get-PSVersionInfo() — Detect version safely
    • Test-PSVersionRequirement() — Check minimum version
    • Invoke-WithFallback() — Version-conditional code

Example (feature gate pattern):
  ```powershell
  if (Test-PSVersionRequirement -MinimumVersion '7.0') {
      # PS 7+ specific code
  } else {
      # PS 5.1 fallback
  }
  ```

═════════════════════════════════════════════════════════════════════════════

🔍 CODE REVIEWER (PR Review)
────────────────────────────────────────────────────────────────────────────

Read (15 min):
  → testplaygrounds/INTEGRATION-GUIDE.md (full overview)
  → testplaygrounds/PS5-PS7-COMPATIBILITY.md (API reference)

Before Approving:
  1. Verify: .\testplaygrounds\run-all-tests.ps1 passes locally
  2. Check: .github/workflows/test-multiversion.yml is configured
  3. Wait: GitHub Actions tests on PS 5.1 + 7.2/7.3/7.4/latest
  4. Only approve if all tests pass

Red Flags:
  ❌ Uses PS7-only APIs without fallback (e.g., $PSVersionTable.Platform)
  ❌ Feature gates missing for PS7-specific behavior
  ❌ No documentation of PS version requirements
  ❌ Uses hardcoded $PSVersionTable checks (should use helpers)

Green Flags:
  ✅ Uses Get-PSVersionInfo() / Test-PSVersionRequirement()
  ✅ Has Invoke-WithFallback() for conditional code
  ✅ Documents PS version requirements in .NOTES
  ✅ Tests pass on both versions

═════════════════════════════════════════════════════════════════════════════

🏛️  ARCHITECT (Design Decisions)
────────────────────────────────────────────────────────────────────────────

Read (30+ min):
  → testplaygrounds/CODEBASE-STRATEGY.md (current architecture)
  → testplaygrounds/FUTURE-MULTI-VARIANT.md (scaling plan)

Understand:
  • Why single source now? → Simplicity + no duplication
  • Why scalable? → Optional split to ALMFx-PS5/PS7 documented
  • When to split? → Only if code duplication warrants it

Key Decision:
  Current: One module supports both versions via feature gates
  Future: Can split into separate ALMFx-PS5 and ALMFx-PS7 if needed

═════════════════════════════════════════════════════════════════════════════

🧪 QA / TEST ENGINEER
────────────────────────────────────────────────────────────────────────────

Read (15 min):
  → testplaygrounds/README.md (test playground guide)
  → testplaygrounds/test-module.ps1 (test harness code)

Test Locally:
  ```powershell
  # Single version (current PowerShell)
  . .\testplaygrounds\test-module.ps1
  Test-ALMFxModule -Verbose

  # All versions (if available)
  .\testplaygrounds\run-all-tests.ps1
  ```

CI/CD:
  → .github/workflows/test-multiversion.yml
  (Runs automatically on push/PR)

What's Tested:
  ✓ Module loads correctly
  ✓ Manifest is valid
  ✓ Functions are exported
  ✓ Help is present & complete
  ✓ OutputType is declared
  ✓ Shared helpers load
  ✓ Core functionality works

═════════════════════════════════════════════════════════════════════════════

📖 ALL DOCUMENTATION FILES

Quick Reference:
  • QUICK-REFERENCE.md — 1-page cheat sheet (3 KB)
  • INDEX.md — Master index of all docs (4 KB)

Getting Started:
  • INTEGRATION-GUIDE.md — Full setup overview (8 KB)
  • README.md — Test playground usage (4 KB)

For Development:
  • PS5-PS7-COMPATIBILITY.md — Safe/unsafe APIs (6 KB)
  • CODEBASE-STRATEGY.md — Architecture rationale (2 KB)
  • AGENTS.md — PowerShell conventions (in repo root)

For Architecture:
  • FUTURE-MULTI-VARIANT.md — Scaling plan (4 KB)
  • SETUP-COMPLETE.md — Detailed setup info (8 KB)

Visual Summaries:
  • SETUP-SUMMARY.txt — Visual overview (4 KB)
  • COMMIT-MESSAGE-TEMPLATE.md — PR template (4 KB)

═════════════════════════════════════════════════════════════════════════════

🎯 WHAT YOU NEED TO KNOW

1. Module Works on Both Versions
   • PowerShell 5.1 (Windows PowerShell)
   • PowerShell 7+ (Core)
   • No breaking changes

2. Shared Codebase (No Duplication)
   • One ALMFx/ folder
   • Shared/Compatibility.ps1 has cross-version helpers
   • Public/Private functions use these helpers

3. Test Locally Before Committing
   ```powershell
   .\testplaygrounds\run-all-tests.ps1
   ```

4. GitHub Actions Tests Both Versions
   • PS 5.1 + PS 7.2/7.3/7.4/latest
   • Auto PR comments with results
   • Only allows merge if all pass

5. Use Shared Helpers for Version-Specific Code
   Instead of hardcoding version checks, use:
   • Get-PSVersionInfo() — Detect version
   • Test-PSVersionRequirement() — Check minimum version
   • Invoke-WithFallback() — Conditional execution

═════════════════════════════════════════════════════════════════════════════

📞 STILL NEED HELP?

Question Type                      → Go To
────────────────────────────────────────────────────────────
"What do I need to know?"          → This file (START HERE)
"Quick reference?"                 → QUICK-REFERENCE.md
"Full setup overview?"             → INTEGRATION-GUIDE.md
"Safe/unsafe PowerShell APIs?"     → PS5-PS7-COMPATIBILITY.md
"Test playground help?"            → README.md
"Architecture explanation?"        → CODEBASE-STRATEGY.md
"Scaling to separate modules?"     → FUTURE-MULTI-VARIANT.md
"All files & navigation?"          → INDEX.md

═════════════════════════════════════════════════════════════════════════════

Ready to get started? Pick your role above and follow the "Read" section.

Questions? Start with testplaygrounds/INDEX.md

═════════════════════════════════════════════════════════════════════════════
