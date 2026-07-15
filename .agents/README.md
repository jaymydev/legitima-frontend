# Agents Playbook

This directory contains dedicated stabilization agents for the Legitima iOS frontend.

The frontend is considered frozen on product scope for V1.

These agents exist to help with:
- build verification;
- API contract verification;
- sensitive-data auditing;
- release and QA coordination.

They do not exist to reopen product design, navigation, or feature scope.

## Available agents

### `frontend-build-guard`

Use this agent when you want to verify that the iOS frontend still compiles cleanly.

Primary responsibility:
- run `./scripts/check-build.sh`

Best moment to use it:
- before a PR;
- after a bug fix;
- after any frontend code edit that could affect compilation.

### `frontend-contract-auditor`

Use this agent when you want to verify that the frontend still matches the documented backend contract.

Primary responsibility:
- compare frontend code against `docs/api-contract.md`

Best moment to use it:
- after backend contract changes;
- before integration validation;
- before release if `/analyze` behavior changed.

### `frontend-sensitive-data-guard`

Use this agent when you want to check whether sensitive user data is exposed through logs or unnecessary storage.

Primary responsibility:
- detect unsafe logging and risky persistence patterns

Best moment to use it:
- before release;
- after service-layer changes;
- after onboarding or premium-flow changes.

### `frontend-release-coordinator`

Use this agent when you want a release-oriented summary and QA support.

Primary responsibility:
- prepare QA checklists, blocker summaries, PR text, and release notes

Best moment to use it:
- before opening a PR;
- before TestFlight;
- when preparing a stabilization checkpoint.

## Recommended order

For a normal V1 stabilization cycle, use the agents in this order:

1. `frontend-build-guard`
2. `frontend-contract-auditor`
3. `frontend-sensitive-data-guard`
4. `frontend-release-coordinator`

This keeps the sequence simple:
- first confirm the app still builds;
- then confirm it still talks to the backend correctly;
- then confirm it does not expose sensitive data;
- finally prepare QA and release material.

## Branch discipline

Keep agent work isolated from product work.

Recommended rule:
- finish the active product or UX branch first;
- commit it;
- push it;
- open or update its PR;
- only then create a new branch for agent, automation, or documentation work.

For example:

1. finish the premium UX simplification branch;
2. commit and push that branch;
3. open or update its PR;
4. create a separate branch for adding or updating agents.

This avoids mixing:
- SwiftUI product changes;
- release process changes;
- agent automation files.

## Current repository expectation

At this stage of the project:
- frontend UX is frozen for V1 unless a blocking bug appears;
- agent files should support stabilization, not reopen roadmap debates;
- any new automation should remain lightweight and safe.

## Important reminder

These agents should guide repetitive checks and coordination.

They should not:
- invent backend endpoints;
- redesign the app;
- add dependencies;
- create new product scope without explicit human approval.
