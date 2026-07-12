# AGENTS.md — Frontend Swift iOS

## Mission

This repository contains the Swift iOS application for Legitima.

The app provides a guided interview preparation journey for users who need to explain and assume a non-linear or fragmented career path with legitimacy.

## Product boundaries

The iOS app must support:
- guided onboarding;
- target role input;
- career path input;
- sensitive period review;
- strategic reframing display;
- professional narrative construction;
- difficult question preparation;
- final preparation summary.

The iOS app must not add without explicit human approval:
- payment;
- subscription;
- social features;
- recruiter features;
- CV generation as the main product;
- complex account system;
- cloud sync;
- unrelated coaching modules.

## Technical rules

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
