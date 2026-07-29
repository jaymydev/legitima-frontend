# Legitima Frontend API Contract

This document is the frontend repository source of truth for backend integration work.

All frontend integration work must also respect [AGENTS.md](/Users/milehanalivecomm/Documents/Developer/new/legitima-frontend/AGENTS.md), especially the product-boundary, UX, and sensitive-data handling rules.

For the medium-term migration path beyond the transitional `/analyze` endpoint, see [docs/analyze-transition-plan.md](/Users/milehanalivecomm/Documents/Developer/new/legitima-frontend/docs/analyze-transition-plan.md).

## Status

The backend contract is documented here for the current frontend/backend integration surface.

`POST /analyze` is now officially supported as a transitional V1 endpoint to stabilize the current onboarding -> analysis -> result flow.

It is not the long-term target architecture and should be treated as a temporary compatibility contract until the product migrates to more explicit business endpoints.

## Base URL

Current frontend target backends:

- analyze backend: `https://legitima-backend.onrender.com`
- CV parse backend: `https://legitima-backend-ocr.onrender.com`

The iOS frontend should now point to the public Render deployment for real-device testing and TestFlight preparation.

No loopback, localhost, or local network machine IP should remain active in the shipped frontend configuration for the current V1 flow.

## Currently expected backend surface

The frontend currently expects the backends to expose:

- `GET https://legitima-backend-ocr.onrender.com/health`
- `POST https://legitima-backend.onrender.com/analyze`
- `POST https://legitima-backend-ocr.onrender.com/cv/parse`
- `GET https://legitima-backend.onrender.com/v2/interview-preparation/use-cases`
- `POST https://legitima-backend.onrender.com/v2/interview-preparation/analyze`

No other V1 integration route should be consumed by the frontend unless it is explicitly documented here.

## Interview preparation V2

The premium preparation entry opens directly on the recruitment preparation as a continuation of the free analysis. The backend-owned, versioned catalog of six use cases remains available as a secondary path ("Préparer un autre entretien"):

- recruitment;
- internal mobility;
- role evolution;
- mid-year review;
- annual review;
- performance review.

`GET /v2/interview-preparation/use-cases` returns the display metadata and ordered
questions. The frontend renders these questions through one generic SwiftUI screen and
caches the last valid catalog locally. The freemium LeanOnboarding remains separate and
continues to collect only the target role, career experiences, and optional sensitive
point before calling `POST /analyze`.

`POST /v2/interview-preparation/analyze` accepts the selected `use_case_id`, the
catalog-provided `questionnaire_version`, and non-empty answers keyed by `question_id`.
It returns a generic preparation result containing a summary, titled sections, talking
points, and an action plan.

For recruitment, the premium flow reuses the target role, experiences, optional
sensitive point, and freemium analysis through the request `context`. It must not ask
the user to import the CV again. The premium screens collect only the interview stage,
strengths and proof, difficult question, desired takeaway, and optional refinements.
Only the final premium generation action sends a V2 analysis request.
Free-text questions display backend-provided answer suggestions. Answers shorter than
four trimmed characters show a non-blocking quality warning; they remain submittable.

The existing recruitment flow continues to use `POST /analyze`. The V2 integration does
not change the request or response contract of that endpoint.

## `POST /cv/parse`

`POST /cv/parse` is the current backend endpoint for CV parsing prefill.

It is used by the iOS frontend to upload a CV document, receive structured professional experiences, and prefill the guided onboarding flow before user review.

### Request

- method: `POST`
- content type: `multipart/form-data`
- field name: `file`

Supported file types:

- `application/pdf`
- `image/jpeg`
- `image/png`

Max file size:

- `10 MB`

Current backend limitation:

- text-based PDFs are supported;
- JPEG photos and PNG screenshots are supported;
- HEIC and HEIF are not accepted directly by the backend and must be converted by iOS to JPEG before upload;
- the frontend must not run OCR locally and must delegate image parsing to the backend OCR service.

### Response

The backend officially supports the following response shape:

```json
{
  "experiences": [
    {
      "title": "string",
      "company": "string",
      "period": "string"
    }
  ]
}
```

Contract rules:

- only `experiences` is returned;
- each item contains exactly `title`, `company`, and `period`;
- all values are strings;
- empty strings are allowed if a field cannot be extracted;
- the backend must not invent experiences.

### Error handling

The frontend should expect:

- `415` for unsupported file type;
- `413` for files larger than `10 MB`;
- `422` for malformed multipart data or missing file;
- `422` for files that are readable but contain no exploitable professional experience;
- `500` for backend failures.

### Frontend integration behavior

The current frontend integration is backend-first and backend-owned:

- the app should upload the selected text-based PDF, JPEG photo, or PNG image to `POST /cv/parse`;
- if iOS provides HEIC or HEIF data, the frontend must convert it to JPEG before upload;
- if the backend returns a valid `experiences` response, the frontend should use it;
- the same `experiences` response shape is reused for PDF and image imports;
- no local OCR or local CV parsing should be used in the nominal flow;
- the long-term target remains backend-owned CV parsing, with the frontend limited to upload, display, and user correction.

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

The premium flow follows docs/product-decision-v2.md: a purchase must trigger real new computation, never reveal already-downloaded content.

- the free result screen is populated by `POST /analyze` and shows only the free diagnosis sections (strategic reading, career logic, sensitive reframing);
- the remaining `AnalysisResponse` fields (`interview_preparation`, `legitimacy_anchor`, `narrative.positioning_statement`) are no longer displayed directly; the locked cards on the result screen are teasers describing the premium preparation to be generated;
- a successful purchase routes the user directly into the guided recruitment preparation as a continuation of the free analysis (context preserved, no use-case re-selection);
- the premium preparation result comes from `POST /v2/interview-preparation/analyze`; the undisplayed `AnalysisResponse` fields are passed to the backend inside the free-text `context.freemium_analysis` string, which requires no contract change;
- use-case selection remains available as a secondary path ("Préparer un autre entretien") from the premium result screen.

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
