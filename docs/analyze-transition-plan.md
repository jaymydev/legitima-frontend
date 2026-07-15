# `/analyze` Transition Plan

This document explains how the current transitional `POST /analyze` contract can later evolve into more explicit business endpoints without making the iOS frontend agent-aware.

## Goal

The frontend should continue to talk to stable product endpoints.

The backend may later introduce orchestration or agentic internals, but that logic should remain invisible to the iOS app.

## Current state

Today, the iOS app relies on a single aggregated endpoint:

- `POST /analyze`

That endpoint currently covers several business responsibilities at once:

- strategic reading of the user's career path;
- sensitive-period identification and reframing;
- professional narrative construction support;
- difficult interview objection preparation;
- legitimacy anchoring.

The current premium UX now follows a two-step pattern:

1. the free user sees locked premium cards on the result screen;
2. once premium is unlocked, those cards are revealed immediately from the existing `AnalysisResponse`;
3. only after that reward does the user continue into the deeper premium journey.

This immediate unlock behavior should be preserved during any future migration because it reduces the feeling that premium starts with extra effort before visible value.

Within that premium journey, the frontend currently distinguishes two separate narrative moments:

1. `PreparationEntretienScreen` focuses on a local answer to one difficult question;
2. `FilConducteurScreen` is now a premium synthesis restitution screen that reuses the existing aggregated result instead of collecting new input or triggering a second AI call.

This distinction should also be preserved during future backend migration work because the objection-answer step and the final premium synthesis do not have the same product role.

## Why this should change later

`POST /analyze` is useful for near-term stabilization and end-to-end testing, but it combines multiple product steps into one backend call.

That makes it harder to:

- reason about step-by-step progress;
- test each business capability independently;
- evolve one step without affecting the others;
- introduce backend orchestration cleanly behind explicit product contracts.

## Frontend dependency map

Current frontend dependencies on the aggregated analysis flow:

- `LeanOnboardingScreen` triggers the main analysis request;
- `LeanOnboardingViewModel` builds the current request payload;
- `IAService` calls `POST /analyze`;
- `AppRouter` carries `AnalysisResponse` into the result flow;
- `LeanResultScreen` consumes the current aggregated result in the main user path;
- `PremiumPreparationDraft` retains the aggregated result for the guided premium flow;
- `FilConducteurScreen` consumes that retained aggregated result as a premium synthesis screen.

## Current business capabilities inside `/analyze`

The current response shape can be understood as five business capabilities:

| Current response area | Business responsibility | Current frontend use |
| --- | --- | --- |
| `analysis.strategic_reading` + `analysis.dominant_competencies` + `analysis.career_logic` | strategic reading of the career path | main result screen |
| `sensitive_reframing.*` | review and reframing of sensitive periods | main result screen |
| `narrative.*` | narrative thread and positioning support | main result screen, `FilConducteurScreen` |
| `interview_preparation.*` | difficult objection preparation | currently consumed structurally, partly locked in main result UX |
| `legitimacy_anchor.*` | final legitimacy anchoring | currently consumed structurally, partly locked in main result UX |

## Proposed target direction

Medium-term, the product should move toward explicit business endpoints rather than a single monolithic analysis endpoint.

Illustrative target shape:

- `POST /v1/strategic-reading`
- `POST /v1/sensitive-reframing`
- `POST /v1/narrative-construction`
- `POST /v1/interview-preparation`
- `POST /v1/preparation-summary`

These names are directional only and are not approved API routes yet.

They exist here to show the intended business split, not to authorize new frontend calls.

## Suggested screen-to-capability mapping

| Frontend area | Current source | Likely future capability |
| --- | --- | --- |
| onboarding result summary | `/analyze` | strategic reading |
| sensitive-period review | `/analyze` | sensitive reframing |
| premium synthesis / fil conducteur restitution | `/analyze` | narrative construction + preparation summary |
| difficult interview preparation | `/analyze` | interview preparation |
| final legitimacy / summary | `/analyze` | preparation summary |

## Migration principles

Any future migration away from `/analyze` should follow these rules:

1. Keep the frontend talking to product endpoints, not to multiple agents.
2. Introduce explicit backend business contracts before changing screen integrations.
3. Migrate one capability at a time instead of replacing the whole flow at once.
4. Preserve the main onboarding -> result path while intermediate endpoints are introduced.
5. Keep orchestration or agentic behavior behind the backend boundary.

## Recommended migration order

1. Keep `POST /analyze` stable for end-to-end validation.
2. Define backend business objects for each major capability.
3. Document explicit successor endpoints in the backend and frontend contracts.
4. Move one frontend surface at a time off the aggregated response.
5. Keep `/analyze` as a compatibility layer during the transition.
6. Deprecate `/analyze` only after the replacement flow is proven.

## What should not happen

The frontend should not:

- call multiple backend agents directly;
- depend on free-form conversational outputs as a primary product contract;
- start using undocumented successor routes before they are approved;
- split the current flow in a way that breaks the guided UX.

## Immediate next step

The next architecture step is not to implement agentic behavior in the frontend.

It is to use this document as a shared transition map between frontend and backend when defining the first explicit successor business endpoints to `POST /analyze`.
