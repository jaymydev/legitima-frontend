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

## Local backend

The frontend currently expects a local backend at:

- iOS Simulator: `http://127.0.0.1:8000`
- Physical iPhone on the same Wi-Fi: `http://192.168.1.43:8000`

For physical-device testing, start the backend with network exposure, for example:

```sh
uvicorn app.minimal_ai:app --host 0.0.0.0 --port 8000 --reload
```

The currently documented integration surface is:

- `GET /health`
- `POST /analyze` as a transitional V1 endpoint for the current onboarding -> analysis -> result flow

Before changing any endpoint usage, update the API contract first.

## API contract

The frontend repository source of truth for backend integration is:

[docs/api-contract.md](/Users/milehanalivecomm/Documents/Developer/new/legitima-frontend/docs/api-contract.md)

Do not add or call backend endpoints that are not documented there.

## Current Premium Flow

The current premium behavior is intentionally split in two steps:

- after a successful free analysis, locked premium cards are visible as teasers;
- when premium is unlocked, those cards are revealed immediately on the result screen without a separate upsell screen;
- only after that immediate reward does the user continue into the deeper premium preparation flow.

This keeps the premium transition rewarding before it becomes more effortful.

Inside the guided premium journey:

- `Préparer une réponse forte` is used for a single difficult question or objection;
- `Clarifier votre fil conducteur` is used afterwards for the global story that connects the full career path;
- these two screens should stay distinct in purpose even if both collect short-form narrative input.

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
