# AGENTS.md — Frontend Swift iOS

## Mission

This repository contains the Swift iOS application for Legitima.

The app helps users defend a non-linear, fragmented, or atypical career path in a specific interview, starting from the reframed narrative thread of their career.

The product model is a two-tier sequence (see docs/product-decision-v2.md, the product reference):
- **Free tier = diagnosis.** A lean analysis that demonstrates the mechanism: strategic reading, career logic, sensitive period reframing.
- **Paid tier = guided preparation.** The mechanism applied to the user's specific interview type: rich input collected step by step, real computation via the interview-preparation endpoints, exportable synthesis.

A purchase must always trigger real new computation. Never gate already-downloaded content behind the paywall.

## Product boundaries

The iOS app must support:
- lean free onboarding (target role, career path, optional sensitive point);
- strategic reframing display as the free diagnosis;
- premium purchase via StoreKit (simulated fallback for testing);
- guided premium preparation as a direct continuation of the free analysis (no re-entry of already-provided context);
- difficult question preparation and structured answers;
- exportable final preparation summary;
- interview date capture and interview-type-specific preparations.

The iOS app must not add without explicit human approval:
- subscription or recurring billing (one-shot purchase is the approved model);
- push or local notifications;
- social features;
- recruiter features;
- CV generation as the main product;
- complex account system;
- cloud sync;
- unrelated coaching modules.

## Technical rules

- Read docs/product-decision-v2.md before any product-facing change; it defines the free/paid split, the purchase moment, and the retention model.
- Use SwiftUI unless the existing codebase requires otherwise.
- Keep views small and readable.
- Separate View, ViewModel, Model, and API client logic.
- Run `./scripts/check-build.sh` before handing off build-related frontend changes when the environment allows it.
- Do not invent backend endpoints.
- Follow docs/api-contract.md.
- Handle loading, error, empty, and success states.
- Do not store sensitive data unnecessarily.
- Do not log user career data.
- Do not add dependencies without justification.

## UX rules

- The app must feel guided, not like a generic chatbot.
- Each screen must have one clear purpose.
- The user should understand why each question is asked.
- The tone must be reassuring, structured, and professional.
- Avoid overwhelming the user with too many fields at once.

## Definition of Done

A frontend task is complete only if:
- the screen or behavior is implemented;
- navigation still works;
- the project still builds through `./scripts/check-build.sh` when the environment allows it;
- API contract is respected;
- main states are handled;
- no unrelated feature is added;
- documentation is updated if needed;
- the PR explains what changed and how to test it.
