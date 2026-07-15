# Legitima Frontend API Contract

This document is the frontend repository source of truth for backend integration work.

All frontend integration work must also respect [AGENTS.md](/Users/milehanalivecomm/Documents/Developer/new/legitima-frontend/AGENTS.md), especially the product-boundary, UX, and sensitive-data handling rules.

For the medium-term migration path beyond the transitional `/analyze` endpoint, see [docs/analyze-transition-plan.md](/Users/milehanalivecomm/Documents/Developer/new/legitima-frontend/docs/analyze-transition-plan.md).

## Status

The backend contract is documented here for the current frontend/backend integration surface.

`POST /analyze` is now officially supported as a transitional V1 endpoint to stabilize the current onboarding -> analysis -> result flow.

It is not the long-term target architecture and should be treated as a temporary compatibility contract until the product migrates to more explicit business endpoints.

## Base URL

Local development backend:

- iOS Simulator: `http://127.0.0.1:8000`
- Physical iPhone on the same Wi-Fi: `http://192.168.1.43:8000`

For physical-device testing, the backend should be started so it is reachable on the local network, not only on loopback.

## Currently expected backend surface

The frontend currently expects the backend to expose:

- `GET /health`
- `POST /analyze`

No other V1 integration route should be consumed by the frontend unless it is explicitly documented here.

## `POST /analyze`

`POST /analyze` is the currently supported transitional V1 endpoint for the iOS app.

It is used as a single all-in-one analysis step for the guided preparation flow. The frontend sends a narrative-positioning payload and expects a structured response containing:

- strategic reading of the user's career path;
- identification and reframing of sensitive periods or fragilities;
- narrative construction support;
- difficult interview objection preparation;
- final legitimacy anchoring.

In other words, `/analyze` transforms the user's career summary and positioning inputs into the main preparation outputs currently shown in the app.

### Request

All fields below are currently required by the backend:

```json
{
  "input": {
    "meta": {
      "version": "1.0",
      "language": "fr",
      "target_market": "US",
      "interview_type": "recruitment"
    },
    "narrative_positioning": {
      "short_summary": "<parcoursResume>",
      "current_positioning": "<posteVise>",
      "evolution_logic": "<zoneSensible>"
    }
  }
}
```

Constraints:

- `input.meta` is required;
- `input.narrative_positioning` is required;
- all documented fields above are required;
- `input.meta.language` is currently officially supported only with the value `fr`;
- the frontend must not send undocumented extra fields without explicit backend alignment.

Language rule:

- the backend now treats French output as a hard contract requirement for `/analyze`;
- the frontend must continue to send `input.meta.language = "fr"`;
- the frontend should keep its defensive French-only textual instruction in addition to `meta.language`;
- unsupported languages must be treated as invalid requests unless the contract is updated.

### Response

The backend officially supports the following aggregated response shape:

```json
{
  "analysis": {
    "strategic_reading": "string",
    "dominant_competencies": "string",
    "career_logic": "string"
  },
  "sensitive_reframing": {
    "identified_fragilities": "string",
    "strategic_reinterpretation": "string",
    "rational_reframing": "string"
  },
  "narrative": {
    "core_thread": "string",
    "positioning_statement": "string"
  },
  "interview_preparation": {
    "probable_objections": "string",
    "structured_answers": "string"
  },
  "legitimacy_anchor": {
    "objective_strength": "string",
    "final_alignment_statement": "string"
  }
}
```

### Error handling

The frontend must continue to support backend errors such as:

- FastAPI validation responses shaped like `{"detail":[...]}`
- backend errors shaped like `{"detail":"..."}`
- generic non-200 responses when no structured backend message is available

That means:

- the frontend may officially rely on `POST /analyze` for the current V1 stabilization flow;
- the frontend must not call undocumented endpoints;
- the frontend must not invent new backend routes during integration work;
- any future V1 route must be documented here before the frontend relies on it.

More specifically, the frontend should expect:

- `422` if the payload is invalid or if a non-supported language is requested;
- `500` if the backend fails to obtain a compliant French-only output or if model generation fails.

## Frontend integration notes

The current service layer is now aligned in principle with the documented transitional contract for `POST /analyze`.

The current premium unlock flow does not require a second backend endpoint:

- the free result screen is populated by `POST /analyze`;
- premium unlock immediately reveals additional sections from the same aggregated `AnalysisResponse`, directly from the result experience;
- the premium guided flow currently continues from that same payload;
- the current premium synthesis screen also reuses the same aggregated `AnalysisResponse` and must not trigger a second undocumented AI route.

Remaining caution:

- treat `docs/api-contract.md` as authoritative;
- follow `AGENTS.md` alongside this contract;
- keep `/analyze` scoped to the current onboarding -> analysis -> result stabilization flow;
- avoid expanding the service layer around undocumented endpoints;
- coordinate the future migration to more explicit business endpoints by updating this document first.

## Change policy

Before adding, renaming, or removing any backend endpoint used by the iOS app:

1. Update this contract.
2. Confirm the backend implementation matches it.
3. Align the frontend code in a separate, explicit integration task.
