---
name: tech-patterns
description: API endpoints, UI screens, architecture patterns, gotchas
metadata:
  type: reference
---

## Backend API Endpoints

### CV Parsing (Stable)
- `POST /cv/parse` → returns `Experience[]` (max 5, chronological order)
  - Input: file (PDF/JPEG/PNG, ≤10MB)
  - Output: `[{company, role, startDate, endDate}, ...]`
  - OCR: French lang model (CV_PARSE_OCR_LANG=fra)

### Interview Preparation (New)
- `POST /interview-preparation/use-cases` → interview scenarios
- `POST /interview-preparation/context` → premium context (recruitment flow)
- `POST /interview-preparation/suggestions` → answer suggestions for questions
- `POST /interview-preparation/analyze-paragraph` → (high-risk, see gotchas)

### Sensitive Analysis (Stable)
- `POST /analyze` — **HIGH-RISK** endpoint for sensitive period reframing
  - Never modify without validation
  - Powers premium recruitment flow

## Frontend Screens (SwiftUI)

### Freemium Path
- `OnboardingView` → short guided flow
- `TargetRoleScreen` → input target job
- `ExperienceListScreen` → input career experiences
- `SensitiveZoneReview` → optional sensitive periods
- `LeanResultScreen` → analysis results

### Premium Path
- `PremiumInterviewEntryScreen` → entry to premium
- `RecruitmentPremiumFlowScreen` → 4-step recruitment prep (NEW: editable target role)
- `InterviewQuestionnaireScreen` → question guidance (with answer suggestions)
- `RecruitmentPremiumQuestionCards` → question card display with guidance

### Components
- `PremiumUnlockCard` → StoreKit purchase UI (simulé in test)
- `AnswerGuidanceView` → guidance text for answers
- `PremiumPurchaseManager` → handles StoreKit transactions

## Architecture Patterns

### State Management
- `LocalPreparationStore` — holds interview prep state (freemium + premium)
- `InterviewPreparationViewModel` — interview flow state
- `InterviewUseCasesViewModel` — use cases data

### Navigation
- `AppRouter` — main navigation logic (can open premium directly)
- Routes to premium prep directly without re-entering CV

## Common Gotchas

### Frontend
1. **project.pbxproj CURRENT_PROJECT_VERSION=20** — Local user env, never stage unless intentional
2. **Screenshot UI changes** — Always use `xcrun simctl io <ID> screenshot /tmp/name.png` with simulator `385A1A68-A173-4DBE-A6FC-2DDA83D59E10`
3. **Swift main actor warnings** — Use `@MainActor` on iOS 17+, test on simulator
4. **StoreKit in simulator** — Uses Products.storekit file for test purchases (not real)

### Backend
1. **POST /analyze is high-risk** — Powers sensitive period reframing, validate before changes
2. **/cv/parse returns chronological only** — Always 5 experiences max, sorted by date
3. **OCR language is French** — Set CV_PARSE_OCR_LANG=fra for deployment
4. **Test payload** — test_payload.json is for manual testing, ignore in commits
5. **Interview prep is new** — Added use cases, context, suggestions (just merged)

### Integration
1. **No invented endpoints** — Frontend only calls documented /cv/parse, /analyze, /interview-preparation/*
2. **API contract** — See docs/api-contract.md for request/response schemas
3. **Deployment** — Backend on Render (temp), frontend on TestFlight/App Store

## Testing

### Frontend
- Run `./scripts/check-build.sh` before commit
- Test on simulator `385A1A68-A173-4DBE-A6FC-2DDA83D59E10`
- Take screenshots for UI changes

### Backend
- Run `pytest` before commit
- Test /cv/parse with French CV samples
- Test /analyze on sensitive paragraphs
- Test /interview-preparation/* routes
