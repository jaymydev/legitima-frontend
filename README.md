# Legitima — iOS client

Legitima helps someone defend a non-linear career path in a job interview.

The product mechanism is **narrative → answers**, never generic advice. You
describe your path in a few lines; the app returns a strategic reading of it,
names the objection an interviewer is likely to raise, and builds the answer
you can actually say out loud. A guided preparation then adapts that material
to the specific conversation ahead — recruitment, internal mobility, annual
review, and three more.

SwiftUI, iOS 26.2+, French only. Free, with no account and no in-app purchase.

The backend lives in a separate repository and is documented in
[docs/api-contract.md](docs/api-contract.md).

## How it fits together

```
WelcomeScreen ──▶ LeanOnboardingScreen ──▶ LeanResultScreen
                   (career text, CV import)   (the full analysis)
                                                    │
                                    PremiumKickoffScreen ── shown once
                                    (first defensible answer)
                                                    │
                                    PremiumInterviewEntryScreen
                                    (questionnaire → guided preparation)
```

Everything the user writes and everything the backend returns is stored on the
device, in Application Support, as JSON written with
`completeFileProtectionUntilFirstUserAuthentication`. There is no account, no
sync and no server-side storage of user work. Closing the app mid-questionnaire
and coming back a week later resumes where it stopped, including the step.

| Layer | Where |
| --- | --- |
| Screens | `legitima-frontend/Views/` |
| View models | `legitima-frontend/ViewModels/` |
| Models and local stores | `legitima-frontend/Models/` |
| Backend calls | `legitima-frontend/Services/` |
| Design tokens, colours, motion | `legitima-frontend/Theme/` |

## Running it

Open `legitima-frontend.xcodeproj` in Xcode, pick a simulator, run the
`legitima-frontend` scheme.

To check that the project still compiles without opening Xcode:

```sh
./scripts/check-build.sh
```

That builds for a generic device without code signing. To build for a
simulator instead, pass any destination `xcodebuild` accepts:

```sh
BUILD_DESTINATION='platform=iOS Simulator,name=iPhone 16' ./scripts/check-build.sh
```

## Tests

There is no XCTest target. The logic worth testing is Foundation-only — local
persistence, the reminder schedule, the loading estimate, routing — so it is
covered by two standalone executables compiled directly:

```sh
SRC=(legitima-frontend/Models/LocalPreparationStore.swift \
     legitima-frontend/Models/AnalysisResponse.swift \
     legitima-frontend/Models/InterviewPreparation.swift \
     legitima-frontend/Models/InterviewReminderPlan.swift \
     legitima-frontend/Models/LoadingProgressEstimate.swift \
     legitima-frontend/Models/PremiumEntryRouting.swift \
     legitima-frontend/Models/PremiumKickoff.swift \
     legitima-frontend/Models/InterviewDebrief.swift \
     legitima-frontend/Models/PreparationExportContent.swift \
     legitima-frontend/Services/IAService.swift \
     legitima-frontend/Services/JSONBuilder.swift \
     legitima-frontend/Navigation/AppRouter.swift)

rm -f /tmp/lst /tmp/ipt
swiftc -parse-as-library -o /tmp/lst Tests/LocalStateTests.swift "${SRC[@]}" && /tmp/lst
swiftc -parse-as-library -o /tmp/ipt Tests/InterviewPreparationStateTests.swift "${SRC[@]}" && /tmp/ipt
```

**`rm -f` the target first.** If compilation fails and an older binary is still
there, it runs and prints `tests passed` — a green result for code that never
built.

## Backend

One deployed service: `https://legitima-backend.onrender.com`.

The client calls five routes, all documented in
[docs/api-contract.md](docs/api-contract.md):

| Route | Used for |
| --- | --- |
| `POST /analyze` | the strategic reading of a career path |
| `POST /cv/parse` | extracting experience from a CV, PDF or photo |
| `GET /v2/interview-preparation/use-cases` | the questionnaire catalog |
| `POST /v2/interview-preparation/kickoff` | the first defensible answer |
| `POST /v2/interview-preparation/analyze` | the guided preparation |

Output is French only: `input.meta.language` must be `"fr"`, and the backend
rejects anything else. Update the contract before changing endpoint usage.

Rate limiting is per IP on the backend. It is deliberately not in the client —
see below.

## Decisions worth explaining

Some of what is in this repository looks odd without the reasoning.

**StoreKit is present but excluded from the Release binary.** Legitima was
built with a paywall and now ships free. Rather than delete that work,
`PremiumPurchaseManager`, `SimulatedPremiumUnlockStore` and `PremiumUnlockCard`
are wrapped in `#if DEBUG`. Nothing in the app calls them, and the Release
binary contains none of their symbols and does not link StoreKit — checked with
`nm` and `otool` rather than assumed. The implementation stays readable here
and runnable from the Xcode preview of `PremiumUnlockCard`. This is
intentional, not code someone forgot to remove.

`StoreKit/Products.storekit` lives outside `legitima-frontend/` on purpose, and
that detail matters. A `.storekit` file is JSON: no preprocessor directive can
exclude it. `legitima-frontend/` is a file-system-synchronized group, so
everything inside it is copied into the app bundle as a resource — and a
Release build was shipping a file declaring a 4.99 product, inside an app
submitted as free with no in-app purchase. Moving it out fixes that. The scheme
still points at it, so the Debug demo works unchanged.

**There is no quota in the client.** There used to be one, in `UserDefaults`.
It protected nothing — reinstalling reset it — and its real purpose was
conversion, which disappeared with the paywall. A limit that only inconveniences
honest users is worse than no limit. The real one is per IP on the backend.

**The loading indicator is calibrated against measurements, not guesses.** It
was tuned when the backend slept between requests and paid a 32-second cold
start. On a warm service `/analyze` answers in 8–9 s, so the old settings made
every normal wait look stalled and announced "this is taking longer than usual"
at 12 seconds — before a normal request had even finished. See
`LoadingProgressEstimate`.

**Progress is estimated, and says so.** The backend reports no progress; a
generation is one request that answers when it is done. The bar follows a
decelerating curve with a hard ceiling below 100 %, never moves backwards, and
derives its wording from the same value so the words and the number cannot
disagree.

## Sensitive data

CV content, career history, sensitive periods, interview answers and generated
analysis are all sensitive. The app never logs them — there is no `print`,
`NSLog` or `debugPrint` anywhere in the target — and never stores more than it
needs.

The free-text field asking what a user needs to explain in an interview
deliberately gives employment examples and not health ones. It is the only
channel for a difficulty a timeline cannot show, so it stays; but inviting
health data into it would be inviting a GDPR special category.

What the user writes is sent to the backend and from there to OpenAI. The
welcome screen says so before anything is typed.

## Conventions

One `codex/<topic>` branch per change, one pull request, squash-merge. CI runs
on pull requests only — macOS runners are billed at ten times the Linux rate,
and a push trigger rebuilt the same tree twice. Markdown-only changes skip the
build.

`legitima-frontend.xcodeproj/project.pbxproj` carries a local build-number bump
that is not committed.

## Licence

Code under the [MIT licence](LICENSE) — read it, change it, reuse it, keep the
copyright line. The name Legitima and the visual identity are not covered: the
licence grants the code, not the right to ship an app under this name.

[AGENTS.md](AGENTS.md) holds the product boundaries. The short version: keep
the app guided and grounded, do not invent backend endpoints, do not add
payment, accounts, cloud sync or social features, and follow
[docs/api-contract.md](docs/api-contract.md).
