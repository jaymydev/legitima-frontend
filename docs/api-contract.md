# Legitima Frontend API Contract

This document is the frontend repository source of truth for backend integration work.

## Status

The backend contract is not fully documented in this repository yet. Until it is, the frontend must stay conservative and only use endpoints explicitly documented here.

## Base URL

Local development backend:

`http://127.0.0.1:8000`

## Currently expected backend surface

The frontend currently expects the backend to expose:

- `GET /health`
- current V1 CRUD resources only if they are explicitly documented by the backend contract

At the time of this update, no additional V1 CRUD resources are documented in this repository as approved frontend integration targets.

## Unsupported or undocumented endpoints

There is currently no officially supported `POST /analyze` endpoint in this repository's backend contract.

That means:

- the frontend must not call undocumented endpoints;
- the frontend must not invent new backend routes during integration work;
- any V1 CRUD endpoint must be documented here before the frontend relies on it;
- `IAService` must be aligned with the backend contract in a separate follow-up task.

## Frontend integration warning

The current frontend service layer still contains integration assumptions that predate this contract cleanup. Those assumptions are not contract approval.

Until a follow-up aligns `IAService` with a documented backend route:

- treat `docs/api-contract.md` as authoritative;
- avoid expanding the service layer around undocumented endpoints;
- coordinate backend and frontend changes by updating this document first.

## Change policy

Before adding, renaming, or removing any backend endpoint used by the iOS app:

1. Update this contract.
2. Confirm the backend implementation matches it.
3. Align the frontend code in a separate, explicit integration task.
