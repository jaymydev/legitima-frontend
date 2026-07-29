---
name: project-state
description: Current Legitima product state, active features, deployment status
metadata:
  type: project
---

## Product Status

### Backend (FastAPI)
- **CV Parse:** Working, OCR français (CV_PARSE_OCR_LANG=fra), PDF/JPEG/PNG, 10MB limit, returns max 5 experiences chronologically sorted
- **Interview Prep:** Use cases, premium context, answer suggestions (just merged)
- **Deployment:** Render (temporary, before VPS migration)
- **Branch:** main (stable)

### Frontend (iOS SwiftUI)
- **Freemium Flow:** Onboarding (short) → target role input → career experiences → optional sensitive zone → analysis results
- **Premium Flow:** StoreKit simulé en test, CTA clair, can now edit target role (just merged 462622a)
- **Parcours Recrutement:** 4 steps, suggestions de réponses, warnings qualité (non-blocking)
- **Deployment:** TestFlight (testing), App Store (production)
- **Branch:** main (stable)

## Recent Merges (today)
- **Frontend:** PR #34 `462622a` — "Allow editing the premium target role" (squashed 4 commits)
- **Backend:** PR #26 `e1f74d3` — "Add interview answer suggestions" (squashed 13 commits)

## Local State Warnings
- **Frontend:** `project.pbxproj` has local CURRENT_PROJECT_VERSION=20 (don't commit unless intentional)
- **Backend:** `test_payload.json` untracked (ignore in commits)

## Next Steps
- Create project memory documentation (current task)
- Monitor backend /analyze for stability (high-risk)
- Plan VPS migration from Render
