# Legitima Frontend

Legitima Frontend is the SwiftUI iOS client for Legitima, a guided interview preparation app for people who need to explain a non-linear, fragmented, or atypical career path with legitimacy.

V1 scope stays limited to:

- guided onboarding;
- target role input;
- career path input;
- sensitive period review;
- strategic reframing display;
- professional narrative construction;
- difficult interview question preparation;
- final preparation summary.

## Open the project in Xcode

1. Open Xcode.
2. Choose `File` -> `Open...`.
3. Select [legitima-frontend.xcodeproj](/Users/milehanalivecomm/Documents/Developer/new/legitima-frontend/legitima-frontend.xcodeproj).
4. Pick an iOS Simulator and run the `legitima-frontend` app target.

## Automated build check

Before opening Xcode, you can validate that the project still compiles with:

```sh
./scripts/check-build.sh
```

This performs a simulator-targeted `xcodebuild` compile check without requiring code signing.

The repository also includes a GitHub Actions workflow at [.github/workflows/ios-build.yml](/Users/milehanalivecomm/Documents/Developer/new/legitima-frontend/.github/workflows/ios-build.yml) so pull requests and pushes to `main` automatically run the same build verification.

## Backend base URL

The frontend targets a single deployed Render backend:

- `https://legitima-backend.onrender.com`

CV parsing used to point at a second service, `legitima-backend-ocr`. Both ran
the same image and answered the same routes, so it was a duplicate; the client
now sends everything to `legitima-backend`. Keep the OCR service alive until
installed builds have updated, then remove it.

No local backend URL should remain active in the iOS app configuration.

The currently documented integration surface is:

- `GET /health`
- `POST /analyze` as a transitional V1 endpoint for the current onboarding -> analysis -> result flow

`POST /analyze` currently supports only French output. The frontend must continue to send `input.meta.language = "fr"` and should not assume support for any other language until the contract changes.

Before changing any endpoint usage, update the API contract first.

## API contract

The frontend repository source of truth for backend integration is:

[docs/api-contract.md](/Users/milehanalivecomm/Documents/Developer/new/legitima-frontend/docs/api-contract.md)

Do not add or call backend endpoints that are not documented there.

## The app is free, and the StoreKit code is deliberate

Legitima has no in-app purchase. Every part of the product — the analysis, the
kickoff, the guided preparation, the debrief, the PDF export — is available to
everyone, and there is no per-device quota.

The StoreKit integration that used to gate the guided preparation is still in
the repository, wrapped in `#if DEBUG`:

- `Services/PremiumPurchaseManager.swift`
- `Services/SimulatedPremiumUnlockStore.swift`
- `Views/Components/PremiumUnlockCard.swift`
- `Products.storekit`

**It is not dead code left behind by accident.** `#if DEBUG` excludes it from
the Release binary, so the shipped app contains no purchase surface at all,
while the implementation stays readable here and runnable from the Xcode
preview of `PremiumUnlockCard` against the local `Products.storekit`
configuration. Nothing in the app calls it. Delete the four items above if you
ever want the repository to stop carrying it.

The user-facing flow is now:

- onboarding → analysis;
- the result screen shows the whole analysis, unlocked;
- one kickoff screen, shown exactly once, builds the first defensible answer;
- then the guided preparation for the interview type the user is preparing.

Rate limiting lives on the backend (per IP), not in the client. A quota held in
`UserDefaults` protected nothing against abuse and only punished honest users.

## Agent rules

This repository includes [AGENTS.md](/Users/milehanalivecomm/Documents/Developer/new/legitima-frontend/AGENTS.md), and contributors and agents should follow it strictly.

At a minimum:

- follow the product boundaries defined in `AGENTS.md`;
- do not invent backend endpoints;
- follow [docs/api-contract.md](/Users/milehanalivecomm/Documents/Developer/new/legitima-frontend/docs/api-contract.md);
- keep the app guided, structured, and professionally reassuring;
- avoid unrelated features, dependencies, and sensitive-data logging.

## Changes that require explicit human approval

Do not add any of the following without explicit human approval:

- payment, premium billing, or subscription logic;
- social features;
- recruiter features;
- CV generation as the main product;
- complex account systems;
- authentication or account-management flows;
- cloud sync;
- unrelated coaching modules;
- new screens, screen redesigns, or navigation changes for this task;
- backend endpoints that are not documented in [docs/api-contract.md](/Users/milehanalivecomm/Documents/Developer/new/legitima-frontend/docs/api-contract.md);
- dependencies or architecture changes unrelated to the documented V1 scope.

## Sensitive data handling

Treat CV content, career history, sensitive periods, interview answers, and AI-generated career analysis as sensitive. Do not log raw backend responses or user career/interview data to the console, and do not store sensitive data unnecessarily.
