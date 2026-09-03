# AGENTS.md — Frontend Swift iOS

## Mission

This repository contains the Swift iOS application for Legitima.

The app prepares someone for the interview ahead of them. The mechanism is a
**hand-written question bank, not generation**: you pick the interview type —
the only required answer — and get the eight questions most likely to come up,
each with a written answer whose blanks wait for your material. A blank fills
once, then everywhere.

The app is **free**, with no account, no in-app purchase, no ads and no
tracker. French only.

A single optional path calls a language model: the personalisation, which
adapts the preparation to a specific job offer. Its output is verified against
what the person wrote, in a separate pass that can only downgrade a claim,
never add one.

## Product boundaries

The iOS app must support:
- interview type as the entry point, with an optional date (local reminders),
  an optional métier, and an "I manage a team" switch;
- the eight bank questions with their fill-in-the-blank answers, served with no
  model call;
- the comfort filter: a question marked "I'm comfortable" folds away on screen
  and leaves the PDF;
- "Avant d'entrer" — the hand-written action plan for the interview type;
- optional personalisation from a job offer, a told achievement and a CV;
- PDF export of the preparation.

The iOS app must not add without explicit human approval:
- payment, subscription, or any paywall — the app ships free (see the StoreKit
  note below before touching that code);
- accounts, cloud sync, or server-side storage of user work;
- social or recruiter features;
- CV generation as the main product;
- push notifications (local interview reminders are supported and expected);
- third-party dependencies or analytics of any kind.

## Standing decisions

These were decided, not stumbled into. Re-open them with a reason, not by
tidying.

- **Nothing is asked before the questions appear.** Picking a type is enough to
  get a full, useful page. The per-type questionnaire — served by
  `GET /v3/interview/use-cases` — appears **only** inside the personalisation
  sheet, when the person asks for it. Asking it up front would trade the
  product's whole premise (a useful page for someone who typed nothing) for
  material that most people do not need.
- **StoreKit is kept under `#if DEBUG`**, deliberately. It is not dead code
  someone forgot to remove; see "Decisions worth explaining" in README.md.
- **The bank is hand-written for the main path; generation serves the
  personalisation only.** One prompt cannot reliably both authorise and forbid
  invention.
- **The métier applies only to interviews that assess a skill for a role.** The
  server says which, through `applies_to` in the métier catalog; never hardcode
  that list in the app.
- **Vouvoiement everywhere.** The word "objection" is banned from the
  interface.
- **A job offer is pasted as text**, never fetched from a URL.

## Technical rules

- Use SwiftUI unless the existing codebase requires otherwise.
- Keep views small and readable.
- Separate View, Model, local store, and API client logic. There is no
  `ViewModels/` directory — state lives in the views and in the stores under
  `Models/`.
- Run `./scripts/check-build.sh` before handing off build-related changes when
  the environment allows it.
- Tests are a standalone executable, not XCTest — see README.md for the exact
  invocation, and `rm -f` the target first: a stale binary prints "tests
  passed" for code that never built.
- Do not invent backend endpoints. Follow docs/api-contract.md, and let the
  server own what the server knows: prefer a served catalog over a list
  hardcoded here.
- Handle loading, error, empty, and success states.
- Do not store sensitive data unnecessarily. Do not log user career data —
  there is no `print`, `NSLog` or `debugPrint` anywhere in the target.
- Do not commit `CURRENT_PROJECT_VERSION`; it carries a local build number.

## UX rules

- The app must feel guided, not like a generic chatbot.
- Each screen must have one clear purpose.
- The user should understand why each question is asked.
- The tone must be serious and warm: someone is preparing for a stressful
  moment.
- Avoid overwhelming the user with too many fields at once — and prefer asking
  nothing at all until the answer is visibly needed.
- A control that promises an effect must have it. Two defects shipped from
  breaking that rule: an "I manage a team" switch that added nothing, and a
  métier chip offered where it changed no question.

## Definition of Done

A frontend task is complete only if:
- the screen or behavior is implemented;
- navigation still works;
- the project still builds through `./scripts/check-build.sh` when the
  environment allows it;
- API contract is respected;
- main states are handled;
- a UI change has been **looked at in the simulator**, not only compiled —
  several defects here were invisible to every test and obvious on screen;
- no unrelated feature is added;
- documentation is updated if needed;
- the PR explains what changed and how to test it.
