---
name: workflow-rules
description: Strict workflow rules for Legitima repos (frontend + backend)
metadata:
  type: feedback
---

## Global Rules (both repos)

**Rule 1:** Always create a new branch for each task — never work on main
**Why:** Clean history, easy to review, reversible
**How to apply:** `git checkout -b codex/<task-name>` before coding

**Rule 2:** One PR = one commit
**Why:** Clean history, easy to revert if needed
**How to apply:** Before push: verify with `git log main..HEAD --oneline`, squash if needed

**Rule 3:** Always verify commit count before creating PR
**Why:** Catch multi-commit branches before pushing
**How to apply:** `git log main..HEAD --oneline` — must show exactly 1 commit

**Rule 4:** Never work directly on main
**Why:** Prevents accidental commits to main
**How to apply:** Always branch first, PR for review

**Rule 5:** Always read AGENTS.md before modifying a repo
**Why:** Respects product boundaries and technical constraints
**How to apply:** Read AGENTS.md in the target repo before any changes

## Frontend-specific rules

**Rule 6:** Screenshot UI changes with simctl on simulator `385A1A68-A173-4DBE-A6FC-2DDA83D59E10`
**Why:** Visual proof of feature, reproducibility, testability
**How to apply:** When UI changes, capture with:
```bash
xcrun simctl io 385A1A68-A173-4DBE-A6FC-2DDA83D59E10 screenshot /tmp/screen.png
```

**Rule 7:** Never stage `project.pbxproj` CURRENT_PROJECT_VERSION changes unless intentional
**Why:** This is user's local environment setting (version=20), shouldn't be in commits
**How to apply:** Always `git diff` before staging, use specific file adds not `git add .`

**Rule 8:** Run `./scripts/check-build.sh` before commit (when environment allows)
**Why:** Catch Swift build errors early
**How to apply:** Always run before staging for iOS changes

## Backend-specific rules

**Rule 9:** Never modify `/analyze` endpoint without explicit validation
**Why:** High-risk endpoint, can break premium flow
**How to apply:** Always ask before touching analyze logic

**Rule 10:** Never log personal user data (CV content, career info)
**Why:** Privacy/compliance
**How to apply:** Review all logging statements for sensitive data

**Rule 11:** Run tests before commit (pytest available)
**Why:** Catch logic errors
**How to apply:** Always run before staging for backend changes

## Global Rules (Data/Integration)

**Rule 12:** Never invent backend endpoints
**Why:** Frontend can't call them; breaks contract
**How to apply:** Follow docs/api-contract.md strictly

**Rule 13:** Preserve unrelated local changes
**Why:** Don't accidentally commit something you weren't working on
**How to apply:** When branching, check `git status` first; stash unrelated changes if needed
