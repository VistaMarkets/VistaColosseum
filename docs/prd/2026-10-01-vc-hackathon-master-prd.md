# VistaColosseum — master hackathon PRD

**Version:** 0.4 · **Planning date:** October 1, 2026 · **Updated:** October 2, 2026 · **Status:** proposed demo scope, ready for implementation-spec decomposition; Figma access rechecked, design reconciliation pending.

**Deadline:** the user stated 10 days. The planning target is **October 11, 2026, America/Los_Angeles**; the exact submission time, official timezone and submission requirements are unconfirmed. This document proposes priorities and acceptance criteria, not staffing or delivery commitments.

Read with the [product roadmap](2026-10-01-vc-hackathon-roadmap.md) and [evidence register](2026-10-01-vc-hackathon-evidence.md). Requirement IDs are stable: retain them when moving requirements into specs; mark removed requirements deferred or superseded rather than renumbering them.

## 1. Product goal and demo promise

Demonstrate a mobile social-trading experience in which a viewer can understand a trader's call, explore opposing views in Arena, inspect a trader's performance market, and see how participation affects a simulated portfolio. A creator can configure and open a **demo** market on their record. The product story connects calls, public records and trader markets; all money, market data, fills, outcomes and fee credits may be simulated.

The 10-day deliverable is a coherent, repeatable interactive demo and recording. It is not a production trading platform. Success means the demonstrated paths work together and the presenter can explain which parts are simulated. Production deployment of VMBE, a validated TPX index, real custody and live trade execution are outside scope.

**Confirmed presentation target:** a PC running a simulated iOS device, clarified by the user on October 2 ([E-U01](2026-10-01-vc-hackathon-evidence.md#e-u01)). Plan a portrait iPhone-style experience operated and recorded on the PC. A desktop browser with a phone viewport/frame is the proposed implementation approach; the specific simulation tool, PC operating system and browser remain unspecified. The clarification establishes the presentation target, not a native iOS runtime or verified device compatibility.

**Primary demo roles:** a seeded creator, a seeded spectator/participant, and a presenter who can reset the scenario. These are proposed demo personas, not researched customer segments. Use one simulated device on the PC with a persona switch.

### Verified starting point

**October 2 integration update:** VC main now contains a Flutter app at `ddcfaa350890864b8726732837629bd237a0d603`. The initial October 1 no-app baseline is historical. [E-C03](2026-10-01-vc-hackathon-evidence.md#e-c03) records a bounded source check; existing screens must be assessed against these criteria before scheduling new implementation. No acceptance criterion is marked passed by source presence alone.

| Area | Current evidence | Planning consequence |
|---|---|---|
| VC | Initial review was documentation/assets only (E-C01). Fetched main now has a Flutter shell, feature directories and design assets (E-C03). | Reuse the existing VC app; classify each requirement as verified, partial, missing or untested before estimating remaining work. |
| FMA | Source-backed feed, charts, profiles, order review and paper portfolio; fixtures and local persistence. Not runtime-tested in this review. [E-F02–E-F05](2026-10-01-vc-hackathon-evidence.md#e-f02) | Reference interaction patterns and test cases; do not claim live integration. |
| FMA Arena/Clash | No implementation found on current main; its plan explicitly says Arena has no code. [E-F01](2026-10-01-vc-hackathon-evidence.md#e-f01) | The user's reported frontend baseline is not verified and is contradicted on this branch. Current VC has Arena source (E-C03); assess its coverage independently of the FMA gap. |
| VMBE Arena/Clash | No source domain/routes/migrations found; planned contracts only. [E-B01](2026-10-01-vc-hackathon-evidence.md#e-b01) | Mock formation, participants, clocks, outcomes and records locally. No dependency on finishing a backend. |
| VMBE adjacent services | Price/history, suggestion and account routes exist in source; trading handoff/executor gaps remain. [E-B02](2026-10-01-vc-hackathon-evidence.md#e-b02), [E-B03](2026-10-01-vc-hackathon-evidence.md#e-b03) | Use shapes and boundaries as references; do not rely on deployment or fill execution. |
| Video / Figma | Video inspected. October 2 recheck confirms the Figma plugin is installed/enabled, but its design-reading tools are unavailable in this chat; browser access to the exact node still stops at a WebGL error. No canvas content inspected. [E-V01](2026-10-01-vc-hackathon-evidence.md#e-v01), [E-D01](2026-10-01-vc-hackathon-evidence.md#e-d01) | Behavioral coverage can be planned from the video; Figma-specific requirements and exact design fidelity remain provisional. Plugin installation alone does not close the evidence gap. |

### Evidence vocabulary

- **Observed:** visible in the video, without implying its backend works.
- **Implemented/client-mock:** a concrete source path exists, with local/synthetic data. Runtime success is not claimed here.
- **Specified:** repository prose describing intended behavior, with no corresponding implementation established.
- **Proposed:** desired VC demo behavior in this PRD. Requirements define acceptance targets; existing VC source may already cover some of them, subject to verification against E-C03.
- **Provisional:** affected by a missing reference or unresolved product choice. It may use a stated demo assumption; it must not be represented as verified fidelity.

## 2. Planning assumptions and scope boundaries

| ID | Assumption used to keep work moving | Consequence if wrong |
|---|---|---|
| A-01 | No live integration is mandatory; use mocks especially for VMBE. This follows the user's explicit direction. | A mandatory live sponsor/API requirement needs a bounded replacement plan and a scope cut. It cannot silently expand P0. |
| A-02 | Team capacity is unknown. Plan one sequential delivery stream with optional independent work only after interfaces are fixed. | Capacity validation at the first milestone may reduce features; no person-days or staffing promise is inferred. |
| A-03 | Target confirmed: PC with a simulated iOS device. Proposed runtime: desktop browser with a portrait phone viewport/frame. Exact host OS, browser and simulation tool remain open. | M0/SP-00 records the actual run environment; M1 proves launch and mouse/keyboard operation there. A requirement for a specific native simulator would require a setup/feasibility check before changing the runtime plan. |
| A-04 | “x” in the request has no supplied meaning. | Keep it open; do not turn it into a feature or metric. |
| A-05 | Use current TPX's no-issued-token vocabulary while retaining the video's listing, record-chart and two-sided-market story. | Exact reproduction of token/supply/market-cap copy requires an explicit product choice. See O-05. |
| A-06 | Reuse means reference-guided lightweight implementation under VC's current CONTEXT.md, not wholesale source migration. | A source transplantation strategy would need explicit reconsideration; it is not assumed to save time. |
| A-07 | Reference video length does not establish the hackathon's allowed submission length. | Confirm the official brief before recording. |

**P0 — essential connected demo:** resettable shell; Home call browsing/replay; portfolio entry into market listing; listing acknowledgments and success; market/portfolio chart views and simulated creator fees; Arena cards, sorting and crowd-split filter; one shared simulated order-review path; clear simulation disclosure and a rehearsed recording.

**P1 — only after P0 is stable:** public first-call composition, scripted challenge-to-clash-to-result progression, a separate TPX position ticket, two-person manual copy/payment story, real sharing. P1 work may be omitted without claiming it was implemented.

**Deferred:** production auth/wallet onboarding, funding/withdrawals, live VMBE deployment, real exchange orders, payouts, on-chain programs, settlement oracle, calibrated TPX scoring, production market matching/liquidity, push notifications, AI recommendation/answer engines, moderation infrastructure, broad asset catalogs and app-store release. No production architecture rewrite is necessary for this demo.

## 3. Demo journeys and evidence coverage

| Journey | Sequence and visible result | Basis | Priority / completion boundary |
|---|---|---|---|
| J1 — discover a call | Enter seeded Home → change feed → browse a call → inspect its chart/context → open details or trader record. | Video V01/V09; FMA feed/profile/replay code. | P0; small curated data set, no ranking service. |
| J2 — become a listed creator | Wallet → listing entry → choose ticker/pitch → acknowledge market behavior → create demo market → success → view own market. | Video V02–V06. | P0; local registry and illustrative record. First-call composer is P1 because the video explicitly leaves it unfinished. |
| J3 — understand a clash | Arena → inspect opposing theses → change sort and crowd-split range → view matching cards/count → inspect more opinions. | Video V07/V08; opinion opening is proposed completion of a visible control. | P0; seeded discussions, no posting/moderation backend. |
| J4 — participate deliberately | Call or Arena side → prefilled asset/direction → adjust demo size → review → confirm → simulated position appears in Wallet and Arena participation updates. | Visible entry controls plus FMA order flow; resulting Arena membership is proposed. | P0, one minimal shared ticket; cancel must leave state unchanged. |
| J5 — explain outcomes | View a seeded settled call/record and corresponding illustrative index; distinguish event verdict, trading P&L and market-fee income. | TPX/Arena plans and video narration; dynamic settlement is not demonstrated. | P0 read-only fixtures; P1 adds presenter-controlled progression. |
| J6 — share an order and receive a copy credit | Creator publishes → another persona chooses it → reviews/places their own simulated order → creator sees one illustrative credit. | VC's earlier brief, E-C02; absent from supplied video. | P1 provisional extension, behind a defined reward rule and P0 exit. |

The [evidence register's V01–V09 coverage table](2026-10-01-vc-hackathon-evidence.md#e-v01) accounts for every sampled core surface. No observed feature is silently presented as backend-complete. Minor visible utilities such as deposit, notifications, settings and share may give an explicit demo-only explanation; the main journey controls must function.

## 4. Feature requirements

Each acceptance criterion is a future verification obligation. None is marked passed by authoring this document. P0 criteria apply to the selected demo target; optional criteria apply only when their feature is included.

### S01. Demo foundation and shared state

**Basis:** E-C01; video navigation; FMA shell E-F01; confirmed PC/simulated-iOS target E-U01. **Status:** VC now has a shell (E-C03); shared-state and target-runtime acceptance remain untested. **Dependencies:** runtime and fixture decisions at M0.

| ID | Priority | Requirement and acceptance criteria |
|---|---|---|
| VC-DEM-001 | P0 | Provide one runnable demo on the presenter's PC inside a portrait simulated iOS device, with Home, Arena and Wallet reachable, plus market/profile drill-downs. Mouse clicks, scrolling/dragging and keyboard text entry support every core journey; paging or swipe interactions have a usable PC input equivalent. Back returns to the prior surface; changing sections preserves selected call/filter state. Any fourth navigation item must have a defined destination or be omitted under the agreed shell decision. Exact tab order remains provisional because video and FMA plans differ. |
| VC-DEM-002 | P0 | Use a single scenario store for identities, calls, prices, listing status, positions and fee entries. The same entity has the same identity/value on feed, detail, Arena and Wallet. A reset restores a known fixture version and clock; two consecutive runs after reset produce the same balances and results. |
| VC-DEM-003 | P0 | Display a persistent, concise simulation indicator and identify synthetic financial results at review/confirmation. The default build completes P0 without credentials, signing, RPC or VMBE. With external network unavailable, all bundled demo journeys remain usable; no external financial write occurs. |
| VC-DEM-004 | P0 | Give presenter controls for reset, persona and scenario phase outside the normal product journey. Every optional visible control has a working local result or a clear demo-unavailable explanation; no success notification may imply an action that did not occur. |

### S02. Home / Tradefeed, call detail and trader context

**Basis:** video V01/V09; E-F02/E-F04/E-F05; Maker shape E-B02. **Status:** client patterns exist in FMA and Home source now exists in VC (E-C03); requirement coverage remains untested.

| ID | Priority | Requirement and acceptance criteria |
|---|---|---|
| VC-FED-001 | P0 | Browse at least three seeded calls spanning long/short and two traders. Cards show author, asset, direction, thesis, entry/time, current demo mark and change. Following and discovery views contain intentionally different content. Swiping and returning to a card do not duplicate actions or reset its state unexpectedly. These fixture counts are proposed minimum coverage, not product limits. |
| VC-FED-002 | P0 | Show a deterministic price replay anchored to the saved call entry and timestamp, with a small set of scripted activity markers. Detail and ticket read the same price source. Restarting replay reproduces the path; missing history gives an explicit missing-data state rather than fabricated provenance. All history is identified as simulated. |
| VC-FED-003 | P0 | Details opens the same call; a trader link opens that trader's small record panel with sample size and settled examples. Like/follow change local state and survive section navigation. Sharing may display a local preview; external posting is not required. Empty-following and unavailable-call states have a route back to the feed. |
| VC-FED-004 | P0 | Include a clearly attributed Maker-style suggestion among the curated content or in a small Tradefeed segment. Show its rationale, asset, direction, expiry and availability. An expired example cannot confirm a trade. The mock Aggro→Maker input is internal to the scenario; viewing a suggestion never creates an order. This connects VC's README architecture to the demo without pretending the video's user calls are Maker outputs. |

### S03. Creator market listing

**Basis:** video V02–V05; E-F07. **Status:** observed prototype; VC main now includes a make-market flow (E-C03), with acceptance coverage still untested. **Dependencies:** S01 and a draft demo listing record. **Provisional:** exact Figma styling and economic labels.

| ID | Priority | Requirement and acceptance criteria |
|---|---|---|
| VC-LST-001 | P0 | Wallet exposes market creation before listing. Form includes identity preview, proposed ticker, ticker suggestions/availability and short pitch. Demo validation covers blank input, one available ticker and one duplicate; entering an invalid value prevents continuation and preserves other fields. Exact character limits are set in the listing spec, not inferred from blurred video text. |
| VC-LST-002 | P0 | Show a before-listing explanation: others can take either side, records remain visible, own-market trading is unavailable, and any fee share is illustrative. Required demo acknowledgment controls begin unchecked; creation remains disabled until all are checked. Closing returns without creating a market. The screen is a demonstration, not actual acceptance of production financial/legal terms or real eligibility verification. |
| VC-LST-003 | P0 | Confirming creates one local demo market with a stable ID and a success state linking to its market view. Repeated confirmation cannot create duplicates. Wallet replaces creation entry with own-market access; returning to the form or changing tabs preserves the listing until reset. |
| VC-LST-004 | P0 | Preserve the first-call entry shown after success. If S07 is not included, it explains that public call composition is outside this demo and offers a seeded call to inspect. Do not claim a call was published. If S07 is included, it opens that composer with the current creator identity. |

### S04. Trader market, record and Wallet

**Basis:** video V06, performance narration, E-F03/E-F05/E-F07. **Status:** FMA paper-portfolio patterns and VC market/portfolio source exist (E-C03); production TPX economics remain specification-only. **Dependencies:** S01/S03; S06 for newly created positions.

| ID | Priority | Requirement and acceptance criteria |
|---|---|---|
| VC-MKT-001 | P0 | Own-market access shows creator identity, an illustrative performance-index series and settled-call examples. Wallet can switch between its portfolio series and trader-market series as in the video's two views. Each has a distinct title, unit and legend; switching back restores the right series. Do not label index points as market cap, portfolio cash or a token price. |
| VC-MKT-002 | P0 | Make performance explanation capital-independent: two fixture traders with identical call results but different paper trade sizes receive the same illustrative record metrics. Display sample count, as-of time and “illustrative index” explanation. Zero settled calls shows unavailable/insufficient history. The index is fixture-driven; no claim of validated production scoring is made. |
| VC-MKT-003 | P0 | Wallet shows paper cash/equity, positions and an open-orders view. A confirmed simulated order adds exactly one position and updates cash consistently; cancellation does not. At least two chart ranges show the appropriate fixture windows. Seeded open orders or an honest empty state are sufficient; editing and limit-order execution are deferred. Deposit/withdraw entries explain the demo boundary and do not imply funding. |
| VC-MKT-004 | P0 | Show creator fee income with an inspectable illustrative ledger separate from trading P&L. Each credit identifies its demo market/event. Total equals the ledger sum. If illustrating the video's 40% share, label it a demo assumption and show a consistent example fee/share calculation; do not equate it with asset-copy rewards or guarantee income. |
| VC-MKT-005 | P1 | Add a simulated trader-index Long/Short ticket only after S06 is stable. It clearly identifies the index instrument and illustrative mark; it does not route to an asset-perp ticket accidentally. A creator cannot take either side of their own market, including through an alternate entry. No leverage/funding/venue engine is required. |

### S05. Arena and Clash discovery

**Basis:** video V07/V08; plans E-F06. **Status:** VC Arena/opinions/filter source now exists (E-C03); coverage remains untested. FMA and VMBE lacked implemented Arena/Clash support at their reviewed revisions. **Dependencies:** S01, call/trader fixtures. **Provisional:** actual ask/opinions behavior beyond the visible controls.

| ID | Priority | Requirement and acceptance criteria |
|---|---|---|
| VC-ARN-001 | P0 | Render a scrollable seeded Clash feed. Each live card shows a specific event, asset/mark, deadline/countdown, bull and bear identities, short rationales, sample-backed demo record, participant counts and side actions. All displayed participants reference the same scenario entities. At least one second card makes scrolling/filtering meaningful. |
| VC-ARN-002 | P0 | Implement the visible volume/change/funding sort choices and crowd-split histogram/range filter using fixture fields. Changing sort produces a predictable order; selecting a range changes the matching card set and count; reset restores all cards. Include a no-match state. Histogram counts and range counts derive from the same fixture collection. Do not retain the video's arbitrary battle totals as disconnected decoration. |
| VC-ARN-003 | P0 | Opening more opinions shows the named sides' seeded rationales and participants; closing returns to the same card. The ask field filters a small known set of assets/events or presents a clearly labeled canned response. Unsupported input explains available examples. This local completion is proposed; there is no AI/forum backend requirement. |
| VC-ARN-004 | P0 | Side selection passes clash ID, asset and direction into S06. Only a confirmed simulated fill registers participation, once per demo action. Cancel, failure and insufficient paper funds leave counts unchanged. The chosen side and resulting position agree across Arena and Wallet. |
| VC-ARN-005 | P0 | Separate crowd split, any illustrative odds, call/event verdict and position P&L. A scripted settled example can show a winning event prediction with losing paper P&L. Changing the display filter cannot change a verdict, record or index. If odds are omitted, label the displayed percentages as crowd split rather than probability. |
| VC-ARN-006 | P1 | Add open-challenge, live-clash and settled states with a presenter-controlled clock and exact fixture pairing. One eligible opposite call joins the seeded event; duplicate input cannot create a second clash. After deadline, new participation is disabled and the scripted verdict links to its saved event rule. No generalized matching or live settlement algorithm is implied. |

### S06. Shared simulated order review and confirmation

**Basis:** visible trade/side controls, E-F03, VMBE execution limitations E-B03. **Status:** proposed integration; VC now includes trade-ticket source (E-C03), whose state/receipt invariants remain untested. **Dependencies:** S01, S02/S05 context, S04 portfolio model.

| ID | Priority | Requirement and acceptance criteria |
|---|---|---|
| VC-ORD-001 | P0 | A call, Maker suggestion or Arena side opens one minimal ticket with correct instrument, direction, reference price and editable paper size. Review shows the chosen values, paper funds required and simulation status. No state mutation occurs merely by opening the ticket. Simple market-style orders suffice; advanced tickets are deferred. |
| VC-ORD-002 | P0 | Cancel is side-effect free. Confirm validates positive size, available demo funds and usable/unexpired price context, then creates one simulated order/position and a receipt. Disable duplicate submission and preserve a stable action ID; retry does not double-debit or double-join Arena. Return offers the originating surface and Wallet. |
| VC-ORD-003 | P0 | Include one explicit failure scenario with a retry/recovery path and no phantom position. Use a shared decimal/fixed-unit representation for balances, fees and review values, with specified rounding in the detailed spec. Review, receipt and Wallet totals must reconcile. Reuse VMBE's financial-string vocabulary where serialized; do not transplant the FMA `double` model into a claimed VMBE-compatible API. |

### S07. Calls, results and demo receipts

**Basis:** video first-call gap and performance narrative; Arena/TPX plans E-F06/E-F07. **Status:** proposed; no verified production settlement backend. **Dependencies:** shared IDs and record projections.

| ID | Priority | Requirement and acceptance criteria |
|---|---|---|
| VC-REC-001 | P0 | Seed call receipts containing author, asset, direction, fixed entry/time, event rule or declared claim, result/time and fixture provenance. Record panels resolve to these examples. A saved call entry is not labeled an executed fill; paper order receipts remain separately identifiable. Missing evidence is marked unavailable. |
| VC-REC-002 | P1 | First-call composer captures a short thesis and explicit asset/direction/event/deadline; review identifies that publishing is public within the demo. Confirm publishes one local call and adds it to the right creator/feed; cancelling creates none. A private position note does not automatically become a public call. |
| VC-REC-003 | P1 | Advancing the scripted scenario settles a defined event once and updates the linked illustrative record/market series consistently. Repeating the advance cannot double-count. Store the result and reason separately from position closure/P&L. Do not invent a production score formula or claim a calibrated oracle. |

### S08. Optional Social Market copy/payment extension

**Basis:** E-C02, VC README; not observed in the supplied video. **Status:** provisional P1. **Dependencies:** stable S06/S07; explicit demo reward rule O-06.

| ID | Priority | Requirement and acceptance criteria |
|---|---|---|
| VC-CPY-001 | P1 | A second persona selects a public copyable call and chooses to place their own simulated order through review. Viewing/following/liking never submits it. Retain source-call attribution and separate creator/copier positions. Use a persona switch within the same simulated device on the PC. |
| VC-CPY-002 | P1 | If this extension is selected, first define the illustrative payer, amount/unit, completion trigger and duplicate rule. Only the chosen successful-copy event produces one creator credit; failure/cancel produces none. The balance/ledger identifies a simulated direct-copy credit, distinct from TPX market fees. No real payment, fee percentage or reward budget is inferred. |

### S09. Demo quality, accessibility and delivery

**Basis:** user's hackathon deadline and mock-first goal; FMA visual patterns. **Status:** proposed acceptance gates. **Dependencies:** all included sections.

| ID | Priority | Requirement and acceptance criteria |
|---|---|---|
| VC-QA-001 | P0 | Adopt the video's dark, mobile layout and consistent Vista styling with readable bull/bear labels beyond color alone. Verify the simulated phone on the PC at a proposed primary content viewport of 390×844 logical pixels and a smaller 375×667 viewport, with increased text size (target 1.3×) and usable touch targets (target 44 logical pixels). Device chrome/safe-area styling must not cover navigation, form fields or action buttons; resizing the desktop window preserves a usable portrait presentation. All J1–J5 controls work with mouse/keyboard, including scroll/paging and range filters. These dimensions are planning defaults, not verified Figma measurements or a native iOS certification. Exact Figma comparison remains unverified until E-D01 closes. |
| VC-QA-002 | P0 | Core list/data surfaces have an intentional loading, empty, failed and loaded presentation where relevant. A seeded failure can recover; no unhandled screen blocks the main route. Asset/history fixtures are bundled so the rehearsal does not require a live data service. |
| VC-QA-003 | P0 | Run J1–J5 twice from reset, including cancellation, one error, duplicate confirmation and filter reset. Capture the requirement checklist against a fixed build/fixture version. Exit requires no unresolved defect that prevents a core journey or misrepresents a financial action. Report untested targets explicitly. |
| VC-QA-004 | P0 | Produce PC setup/run/reset instructions identifying the tested OS, browser/simulation tool and viewport; a short demo script; a PC screen recording of the simulated device; and fallback local build/artifacts in the chosen submission format. Verify the actual hackathon length, link visibility and deadline before submission. The script names simulated components; submission remains a separate execution step, not something this PRD claims completed. |

## 5. Migration and reuse matrix

All implementation lands in VC. No source-repo changes are required by this plan. “Adapt” below means write a small VC implementation informed by the cited source, consistent with E-C01; it does not mean a ready-to-copy module exists.

| Capability / VC destination | Source and evidence | Existing reality | Reuse approach | New/mocked work and dependency |
|---|---|---|---|---|
| Existing VC app → S01–S06/S09 | VC app shell and feature paths, E-C03 | Source now present; no runtime acceptance audit in this update | Assess and extend current VC screens/design system before building replacements | Identify missing state integration and acceptance gaps; do not equate assets with exact-node Figma verification. |
| Product vocabulary, branding, component roles → S01/S02 | VC README/CONTEXT/ARCH, E-C01 | Documentation and logo assets | Retain vocabulary and advisory→review→simulated action story | Adapt existing shell for the PC-hosted simulated-phone target; confirm runtime. |
| Navigation and visual tokens → S01/S09 | FMA shell/theme, E-F01/E-F05 | Implemented client patterns | Adapt persistent navigation, tokens and layouts | New VC routes; Arena tab differs from checked main. |
| Home/feed/cards → S02 | FMA feed/card/repository, E-F02 | Interactive fixture-backed client | Adapt card hierarchy, repository seam and paging | Curated cross-screen scenario; no recommendation service. |
| Charts/prices/replay → S02/S04 | FMA price/replay code, E-F04 | Synthetic history and marks | Adapt one-source rendering and replay behavior | Deterministic clock and bundled scenario history. |
| Profiles/basic record → S02/S04 | FMA trader repository/record, E-F05 | Fixture-backed profiles, local aggregates | Adapt record detail and sample-count presentation | Shared receipts; no claim that FMA record equals TPX index. |
| Order review/paper portfolio → S04/S06 | FMA OrderScreen/PortfolioStore, E-F03 | Implemented local flow/persistence | Adapt candidate-review-confirm pattern and acceptance scenarios | Shared action IDs, demo receipts and Arena attribution. |
| Source/freshness data → S01/S02 | VMBE PriceEvent, E-B02 | Backend model/source code | Reference venue/timestamp/staleness vocabulary | Mock Aggro adapter; do not deploy aggregators. |
| Maker suggestion → S02 | VMBE feed DTOs, E-B02 | Backend suggestion model/routes | Reference rationale/expiry/availability shape | Fixture generator/adaptor; no Maker→Merchant automatic handoff. |
| Account/terms concepts → S03 | VMBE Gateway/accounts, E-B02 | Implemented routes, no verified host | Reference field and consent-state separation | Seeded persona + demo acknowledgments; no Privy setup. |
| Merchant action → S06 | VMBE wiring, E-B03 | Source exists; no working app execution path | Retain deliberate user intent and clear failure states | New local simulator; never count VMBE dry-run rejection as a successful fill. |
| Arena/Clash → S05/S07 | FMA Arena plan, E-F06; VMBE gap E-B01 | Specification only | Reference card vocabulary and event-versus-P&L distinction | New cards, filters, participant projection; scripted lifecycle if selected. |
| Listing/TPX market → S03/S04 | Video V03–V06; FMA TPX docs, E-F07 | Video mock + specification only | Adapt visual journey and no-supply index concept | Local ticker registry, listing state, index fixtures and fee ledger. |
| Public calls/copy credit → S07/S08 | VC earlier brief E-C02; FMA thesis/record patterns | No evidenced complete publication/copy-payment system | Reference manual intent and attribution | New local publication/credit rules; optional after core demo. |

**Compatibility traps:** FMA mock doubles do not satisfy VMBE's decimal-string contract; user calls are not Maker suggestions; an account handle is not a TPX ticker; portfolio trade wins are not Arena event verdicts; a graph of returns is not a validated TPX index; local persistence is not multi-device synchronization.

## 6. Proposed demo architecture and dependencies

Use one small application and one local scenario store in the PC-hosted simulated device. The proposed runtime is a desktop browser with a portrait phone viewport/frame; framework selection belongs to SP-00/SP-01. Interfaces may be ordinary in-process modules; no separate backend servers, queues, databases or WebSockets are required. A local static development/preview server may serve the app. Persona switching keeps both demo roles in the same state store.

```mermaid
flowchart LR
    FX[Versioned fixtures and demo clock] --> ST[Shared scenario store]
    ST --> FE[Home and Maker-style suggestions]
    ST --> AR[Arena and opinions]
    ST --> MK[Creator listing and market]
    FE --> RV[Shared order review]
    AR --> RV
    RV --> SIM[Local order simulator]
    SIM --> ST
    ST --> WA[Wallet and receipts]
    FX --> REC[Scripted settled calls and illustrative index]
    REC --> ST
```

These are proposed responsibilities, not a verified map of the current VC modules. Reconcile them with the existing app before choosing module boundaries. Keep the following contracts small enough to specify independently:

| Data / responsibility | Minimum relationship | Downstream consumers |
|---|---|---|
| DemoSession / Clock | fixture version, persona ID, scenario phase, reset | Every screen and countdown |
| Trader / MarketListing | trader ID, demo ticker, pitch, listing status | Listing, profiles, market, Wallet |
| PriceSnapshot / CandleSeries | asset ID, time, source label, decimal values | Feed, ticket, charts, P&L |
| Call / Suggestion | distinct IDs/types; author or Maker attribution, asset, direction, entry, expiry | Feed, details, optional publication |
| Clash / Participation | event ID and fixed rule/deadline; linked calls and participant side | Arena, ticket context, results |
| DemoOrder / Position | action ID, owner, instrument kind, review values, simulated outcome | Wallet, Arena membership, receipts |
| CallReceipt / IndexSnapshot | settled-call references, result explanation, fixture provenance | Trader record and illustrative market chart |
| FeeEntry / CopyCredit | separate event types and source IDs | Creator income/Wallet; optional copy extension |

S01 contracts precede screen implementation. S02 and S03 can then progress independently if capacity exists. S04 depends on shared financial state and listing; S05 depends on shared calls/traders; S06 joins them. P1 publication and settlement require their IDs/relationships to be stable. S08 comes last. QA begins with the first vertical slice, rather than being postponed entirely to the final day.

## 7. Risks and mitigations

| Risk | Impact | Mitigation / trigger |
|---|---|---|
| Demo branch is missing; frontend reuse was overstated | Underestimated Arena/listing effort | VC now has related source (E-C03); inspect its acceptance coverage before estimating remaining Arena/listing effort. |
| Capacity and exact PC runtime unknown | Ten-day plan may exceed available work or setup may delay rehearsal | Target is PC with simulated iOS presentation; M0 records host/runtime and a realistic core slice. M1 proves launch and input support. Cut P1 first; record any P0 removal as an explicit coverage gap. |
| Figma design-reading tools unavailable despite installed/enabled plugin; browser blocked by WebGL | Cannot inspect the requested node or certify layout fidelity | Restore callable Figma access or obtain an accessible export of node 1325-7814. Record frame IDs, visible states and video differences before changing affected specs. Use video/FMA references provisionally; limit late visual changes to core-flow defects. |
| Video copy conflicts with TPX model | Incoherent market-cap/supply/index story | Use explicit units and A-05; retain the journey, record changed labels. No production economics commitment. |
| Fixture values disagree across screens | Demo loses credibility | One scenario store, fixed clock, linked receipts and arithmetic reconciliation. Do not repeat the unexplained $10K→$44M transition. |
| VMBE integration consumes the schedule | Missed demo and safety regressions | No VMBE runtime on the critical path. An unavoidable live requirement must replace scope and preserve existing gates. |
| Mock outcomes appear like real transactions | Misleading demonstration | Persistent simulation label, honest confirmations, no keys or financial writes. |
| Simulated-phone controls do not translate to PC input | Presenter cannot complete mobile gestures or recording clips controls | Require mouse/keyboard equivalents and viewport checks in VC-DEM-001/VC-QA-001; rehearse on the actual PC. |
| Deadline/submission rules unknown | Wrong format or late submission | Confirm at M0; reserve final day for packaging/upload issues, with recording already available. |
| Scope grows into social platform/production scoring | Unfinishable project | Canned ask responses, seeded opinions/receipts, bounded fixture index; no AI/forum/settlement platform. |

## 8. Open decisions

Decision owners are **unassigned**. Assign at M0; the suggested decision role is product lead/presenter for scope and implementation lead for target/runtime. These are roles, not claims about team membership.

| ID | Decision | Interim planning treatment | Needed by |
|---|---|---|---|
| O-01 | Exact deadline time/timezone, hackathon rules, required technologies and format | Target Oct 11; all backend mocked; no sponsor requirement inferred | M0 / before any live integration work |
| O-02 | Team size, available hours and builder skills | One sequential stream, P1 uncommitted | M0 |
| O-03 | Meaning of “x” | No scope inferred | When clarified; does not block independent work |
| O-04 | Partially resolved October 2: PC with simulated iOS device. Remaining: host OS, runtime/tool and run/record route | Proposed desktop browser with portrait phone viewport/frame; record exact environment and verify on presenter PC | M0/SP-00; launch proof at M1 |
| O-05 | Reproduce video economic copy or use current index-market language? | Recommend A-05: no supply/market-cap fiction; label illustrative index | Before S03/S04 wording freeze |
| O-06 | Include direct-copy payment story? If yes, what demo payer/amount/trigger? | P1; omit until rule is explicit; distinct from TPX fee share | P1 selection gate |
| O-07 | Which, if any, behavior must become live? | None; use mocks, especially VMBE | M0; later changes require a scope tradeoff |
| O-08 | How much of the newly merged VC app covers the video and PRD? | VC source is now present (E-C03); exact design provenance and runtime/requirement coverage remain unverified | Before reuse estimates are revised |
| O-09 | Read Figma node 1325-7814 through callable plugin tools or an accessible export | October 2: plugin installed/enabled confirmed; design tools unavailable in this chat, browser still blocked by WebGL. No node inspection completed; E-D01 remains open | Before visual requirements are finalized and fidelity is signed off |
| O-10 | Does the demo need public composition/dynamic settlement or only seeded examples? | P0 seeded receipts and honest unfinished composer; P1 interactive progression | After P0 integration is stable |
| O-11 | Final shell order and asset permission/font choices | Follow core video journeys; use permitted/locally available assets | S01 spec |

## 9. Master acceptance and decomposition check

- **Coverage:** J1–J5 and the V01–V09 table cover observed Home, creation, Wallet/market and Arena/filter surfaces. Outcomes not exercised in the video are identified as proposed.
- **Baseline correction:** Arena/Clash are missing from inspected VMBE and FMA main; plans and adjacent mock client behavior are separately classified.
- **Reuse:** every source-repo claim has an evidence entry and an explicit adaptation boundary. VC remains the implementation destination.
- **Mock completeness:** fixtures cover identity, market data, suggestions, listing, orders, portfolio, Arena and fee/record displays; no backend deployment is necessary.
- **Provisional work:** Figma fidelity, demo-branch reuse, exact economics, copy rewards, capacity and live requirements remain open rather than invented.
- **Spec readiness:** S01–S09 have stable requirement IDs, dependencies and observable acceptance criteria. The roadmap assigns each section to a milestone/spec boundary.
- **Delivery readiness:** this planning check is complete; implementation, runtime validation, recording and hackathon submission are future work.
