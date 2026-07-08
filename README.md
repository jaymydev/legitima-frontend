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

## Local backend

The frontend currently expects a local backend at:

`http://127.0.0.1:8000`

Before changing any endpoint usage, update the API contract first.

## API contract

The frontend repository source of truth for backend integration is:

[docs/api-contract.md](/Users/milehanalivecomm/Documents/Developer/new/legitima-frontend/docs/api-contract.md)

Do not add or call backend endpoints that are not documented there.

## Agent rules

This repository is expected to carry an `AGENTS.md` file and any future agent must follow it strictly when it is present.

No `AGENTS.md` file was present in this checkout on July 8, 2026, so contributors must not invent missing agent rules. Until that file is restored, use this README and [docs/api-contract.md](/Users/milehanalivecomm/Documents/Developer/new/legitima-frontend/docs/api-contract.md) as the minimum operational guardrails.

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
