# VistaColosseum hackathon evidence register

Repository/video review: **October 1, 2026 (America/Los_Angeles)**. User target clarification and Figma access recheck: **October 2, 2026**. Companion to the [master PRD](2026-10-01-vc-hackathon-master-prd.md) and [roadmap](2026-10-01-vc-hackathon-roadmap.md).

## Subsequent user clarification

### E-U01

On **October 2, 2026**, the user specified the target as a **PC with a simulated iOS device**. This establishes the presentation target. A desktop browser with a portrait phone viewport/frame is the PRD's proposed implementation approach; the user has not specified the host OS, browser, simulation tool or a native iOS runtime. Primary/smaller viewport dimensions are proposed acceptance defaults, not measurements from the design references. Repository and design findings below retain their October 1 review date; no additional runtime verification is implied.

## Review method and limits

Read repository source, wiring, public contracts, relevant tests, and product plans. Inspected the supplied video through the browser at specific playback positions and read its automatically generated English captions. A video demonstrates visible prototype behavior, not its implementation, server connections, or economic correctness. Captions are supporting narration, not exact specifications.

No VC application existed at the initial October 1 revisions below. A subsequent main update adds the app; see E-C03 for the bounded October 2 check. FMA was not launched and its tests were not run; `flutter` was unavailable on PATH. VMBE was not started and its build/tests were not run. Accordingly, **implemented** below means source-backed implementation, not newly verified runtime success. Existing test files are evidence of intended coverage, not a passing result from this review. No live deployment was verified.

| Repository | Local HEAD inspected | Remote main checked | Consequence |
|---|---|---|---|
| VC | `b8c0fec04b5b44962072a59f74478ba2cdee7a00` | `7e91c70b2adcbd369b4f5f8fb49f21b0252eff23` | Remote changes only reference links in CONTEXT.md; both trees contain documentation, hooks and logo assets, no app. |
| FMA | `6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713` | Same SHA | Main does not contain the Arena or market-listing screens in the video. Other branches have not been exhaustively audited. |
| VMBE | `fa467975cad3d9256a0b138af4a517ae4a69aa54` | `6117e23fd28fce61265ce2b0da7aa59a317e118f` | Remote adds Merchant error-redaction work. Changed-path inspection and a remote-main source search show no Arena/Clash addition; the cited Gateway and app wiring is unchanged. |

Remote references were read/fetched without checking out, merging, or changing application files. Pre-existing untracked prompt files in VC and review notes in VMBE were left intact. Findings do not cover private deployments, unprovided demo branches, or uncommitted work outside these checkouts.

## External references

### E-V01

**Video:** [supplied Short](https://www.youtube.com/shorts/at8PYElTbAE), also inspected through the [same video's standard player](https://www.youtube.com/watch?v=at8PYElTbAE), duration approximately 2:26. Web fetching was throttled; browser playback succeeded. Times below are sampled observations, not exact scene boundaries.

| Observation | Time | Visible evidence | What remains unproved | PRD coverage |
|---|---|---|---|---|
| V01 | [0:15–0:26](https://www.youtube.com/watch?v=at8PYElTbAE&t=15s) | Home call card, chart, trader context, social controls and directional trade entry. | Trade execution and server-fed data. | S02, S06 |
| V02 | [0:31](https://www.youtube.com/watch?v=at8PYElTbAE&t=31s) | Wallet/portfolio with chart, positions and market-creation entry. | Funding and persisted balances. | S03, S04 |
| V03 | [0:35–0:40](https://www.youtube.com/watch?v=at8PYElTbAE&t=35s) | Listing form with ticker suggestions/availability, identity and pitch. | Real uniqueness checks or upload service. | S03 |
| V04 | [0:45–0:50](https://www.youtube.com/watch?v=at8PYElTbAE&t=45s) | Two-sided market explanation, creator fee share, self-trading restriction, acknowledgments and create action. | Actual consent enforcement or live market deployment. | S03, S04 |
| V05 | [0:55](https://www.youtube.com/watch?v=at8PYElTbAE&t=55s) | Creation success; first-call action produces an unfinished-feature notice. | Call creation is explicitly incomplete in the shown prototype. | S03; optional S07 |
| V06 | [1:00, 1:20, 1:49](https://www.youtube.com/watch?v=at8PYElTbAE&t=60s) | Portfolio and trader-market chart views, time ranges, positions/open-order tabs and market-fee total. | Valid index computation, fee attribution or consistent economic units. | S04 |
| V07 | [1:54–2:01](https://www.youtube.com/watch?v=at8PYElTbAE&t=114s) | Arena cards: event, time remaining, opposing traders/theses, records, side controls, more opinions, sort chips, ask field. | Side selection, opinions and ask-field outcomes are not demonstrated. | S05, S06 |
| V08 | [2:11](https://www.youtube.com/watch?v=at8PYElTbAE&t=131s) | Crowd-split histogram/range changes with the shown battle count. | Distribution calculation, matching and settlement. | S05 |
| V09 | [2:18](https://www.youtube.com/watch?v=at8PYElTbAE&t=138s) | Return to Home and a different short call with chart replay. | Personalized ranking algorithm. | S01, S02 |

Narration around 1:07–1:23 describes percentage/performance-based comparison independent of capital size. This is **intent**, not proof of a validated TPX scoring formula. Narration also proposes market income, requests/discussion in Arena, and future algorithmic discovery; their backend mechanics are not demonstrated.

**Material discrepancies:** the video combines ticker/token, supply and market-cap language, while the current TPX documents describe an index market without issued supply. The listing success displays $10,000 and a later wallet market view displays $44.0M without an evidenced transition explaining the difference. These are prototype fixtures, not values or economics to import as requirements. The 40% creator share shown in the listing explanation concerns market trading fees; it does not establish a reward for copying an asset trade.

### E-D01

**Target:** [exact supplied node 1325-7814](https://www.figma.com/design/i42FmXt8hR6GS7wUKQ1fmL/Vista-Mobile-app?node-id=1325-7814&t=BZqMOsHCRRwSaJbv-4), file key `i42FmXt8hR6GS7wUKQ1fmL`, API node ID `1325:7814`.

| Check | Date | Observed result | Evidence limit |
|---|---|---|---|
| Initial web/browser access | Oct 1 | Web retrieval failed; browser reached the file title but reported WebGL unsupported or disabled. | No canvas/frame content inspected. |
| Installed plugin discovery | Oct 2 | Plugin registry returned Figma with `installed: true` and `status: ENABLED`; Figma skill files are available locally. | Confirms installation/enabled status, not authenticated file access or callable design tools. |
| Callable-tool discovery | Oct 2 | No Figma tools were exposed in this chat's available tool inventory, including design context, metadata, screenshot or file-context execution. | No Figma design read could be issued through the plugin. The cause is not established; no permission denial is inferred. |
| Exact-node browser retry | Oct 2 | The requested URL again reached “Vista Mobile app – Figma” and displayed the WebGL unsupported/disabled error. | No canvas, frame hierarchy or interactions inspected. |

**Gap remains open:** exact frame hierarchy, typography, spacing, component variants, assets, interactions and the relationship between this node and the video remain unverified. Video layout is usable provisional guidance; FMA theme code is a separate reference, not evidence that this Figma node matches it. Plugin installation alone does not justify changing feature requirements or marking Figma fidelity verified. No Figma file was modified.

**Closure evidence needed:** a successful read/render of the specified node, its relevant child-frame IDs and screen inventory, visible copy/control states, and a comparison against video V01–V09. Record design observations separately from inferred behavior or prototype connections, and map any changes to the existing PRD IDs/spec packages. Callable plugin access, an accessible node export, or a supported browser can supply this evidence. Until then, the proposed PC viewport sizes and video-derived visual guidance remain planning assumptions; the functional mock-first demo can still proceed.

## Repository evidence

### E-C01

VC's [README](https://github.com/VistaMarkets/VistaColosseum/blob/b8c0fec04b5b44962072a59f74478ba2cdee7a00/README.md), [architecture overview](https://github.com/VistaMarkets/VistaColosseum/blob/b8c0fec04b5b44962072a59f74478ba2cdee7a00/ARCH.md) and `git ls-files` establish a documentation/assets baseline. The overview explicitly describes future components. The README requires simulated financial actions.

The [reference policy](https://github.com/VistaMarkets/VistaColosseum/blob/7e91c70b2adcbd369b4f5f8fb49f21b0252eff23/CONTEXT.md) calls for original lightweight implementations using FMA/VMBE as references, rather than source-file transplantation. Therefore the PRD's **reuse** means concepts, interface vocabulary, interaction patterns and test scenarios unless a later decision changes that policy. Existing logo permission specifically covers README use; app-asset selection remains a small implementation decision.

### E-C02

VC's [earlier social-market demo prompt](https://github.com/VistaMarkets/VistaColosseum/blob/b8c0fec04b5b44962072a59f74478ba2cdee7a00/docs/prompts/social-market-demo-brief-prompt.md) proposes a two-phone manual-copy story and a direct payment to the original trader after successful copying. It expressly says the payment mechanism is proposed and cannot be inferred from TPX fee sharing. This is background scope, not behavior observed in the current video or an automatic P0 commitment.

### E-C03

During October 2 PR preparation, `origin/main` advanced to **`ddcfaa350890864b8726732837629bd237a0d603`** (merge of the demo design-system/features branch). The tracked tree now includes `app/`, Flutter platform scaffolding, tests, Figma-named SVG assets and feature directories for Home, Arena/opinions/crowd filtering, make-market, market, portfolio and trade tickets.

The [app shell](https://github.com/VistaMarkets/VistaColosseum/blob/ddcfaa350890864b8726732837629bd237a0d603/app/lib/app_shell.dart) was read: it instantiates Home, Explore/Markets, Arena and Wallet/Portfolio and mounts the crowd-filter panel. This supersedes the initial **VC has no app** finding. The [architecture map](https://github.com/VistaMarkets/VistaColosseum/blob/ddcfaa350890864b8726732837629bd237a0d603/ARCH.md) describes design provenance from a different Figma file key, `yIxjFkwJAwBa07RgSmVv1D`; that repository claim does not close access to the user's specified file/node in E-D01.

**Limits:** this was a tracked-tree and shell-source check, not an audit or execution of every feature. No PRD criterion or milestone is marked passed. FMA/VMBE findings remain tied to their original revisions. Before implementation estimates are used, inspect the current VC feature code and record each requirement as verified, partial, missing or untested; extend existing work rather than assuming a fresh build.

### E-F01

FMA's actual [shell](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/app/app_shell.dart#L68-L73) instantiates Home, Discover, People and Portfolio. Its [Arena plan](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/docs/BATTLEGROUND_PLAN.md#L1-L27) labels Arena as having no code. [FRONTEND_PLAN](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/docs/FRONTEND_PLAN.md#L24-L47) corrects the stale shell description in APP_FLOW.

Case-insensitive searches for whole-word `arena`, `clash`, `battleground`, `tpx` across `lib/` and `test/` returned only two Flutter gesture-arena comments. File-name searches found no domain Arena/Clash implementation. People is a social timeline, not a Clash engine. **The assertion that most Arena/Clash functionality exists in current FMA main is not supported.** A different demo branch may exist; no matching source was supplied.

### E-F02

The [Home screen](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/features/home/presentation/home_screen.dart#L229) implements vertical paging. [TradeIdeaCard](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/features/home/presentation/widgets/trade_idea_card.dart#L997-L1039) routes to details and order entry. [FeedRepository](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/features/home/data/feed_repository.dart) is an injectable seam; [MockFeedRepository](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/features/home/data/mock_feed_repository.dart#L15-L39) returns fixtures with loading/error/empty controls. This is interactive client implementation with mock content, not a live social feed or Maker connection.

### E-F03

[OrderScreen](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/features/order/presentation/order_screen.dart#L278-L382) validates, presents a candidate for review, opens a local position only after confirmation, and stores an optional thesis. [PortfolioStore](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/features/portfolio/domain/portfolio_store.dart#L23-L187) owns paper cash, positions, P&L and record derivation; persistence is implemented [later in the same file](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/features/portfolio/domain/portfolio_store.dart#L424-L561), despite its older in-memory-only comment. [Storage](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/core/storage/key_value_store.dart#L14-L18) is device-local.

Existing [order review tests](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/test/order_review_test.dart#L86) and [portfolio tests](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/test/portfolio_functional_test.dart) offer scenarios to adapt. This is paper trading, not wallet custody, real fills, Arena participation, or public call publication. The current client uses `double`; it is not directly compatible with VMBE's decimal-string financial contract.

### E-F04

[MockPriceRepository](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/core/markets/mock_price_repository.dart#L9-L69) contains seeded marks and simulated movement. [MockReplayRepository](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/features/replay/data/mock_replay_repository.dart#L7-L29) generates synthetic history behind a repository interface. Reuse the single-price-source and chart/replay interaction patterns, not these figures as real market evidence.

### E-F05

[TraderRepository and MockTraderRepository](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/features/caller/data/trader_repository.dart#L18-L89) supply profiles and social fixtures. [TraderRecord](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/core/social/trader_record.dart#L28-L96) computes counts, win rate and unleveraged average return. This is **not** the proposed difficulty-adjusted TPX index or an Arena threshold-verdict engine. In particular, a nonnegative trading move counting as a win is not proof that an Arena claim came true.

[App colors](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/core/theme/app_colors.dart), [spacing](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/core/theme/app_spacing.dart) and [type](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/lib/core/theme/app_type.dart) provide implementation-backed visual references. [pubspec.yaml](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/pubspec.yaml) and source inspection show no app API/auth/trading-network integration; `dart:io` is used for profile image files, and sharing links are not backend integration.

### E-F06

[BATTLEGROUND_PLAN](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/docs/BATTLEGROUND_PLAN.md#L50-L160) proposes open challenges, opposed calls, matching by event, and threshold/deadline outcomes distinct from trading profit. [Its later sections](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/docs/BATTLEGROUND_PLAN.md#L173-L244) separate display odds from scoring odds and describe entering via a trade. These are design references only. VC can illustrate them with explicitly scripted states; a validated matching/scoring backend is new work outside this hackathon scope.

### E-F07

[TPX README](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/tpx/README.md#L1-L27) declares specification status. [ECONOMICS](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/tpx/ECONOMICS.md#L1-L5) describes index markets without issuance; [§2D](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/tpx/ECONOMICS.md#L112-L150) leaves scoring calibration details unresolved. [UX listing](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/tpx/UX.md#L92-L117) describes fee sharing and the prohibition on trading one's own market, but says real listing cannot complete before an index exists. [Manual replication](https://github.com/VistaMarkets/Flutter-mobile-app/blob/6dd5e8e6cc4f591fcb3cf7e2f1c801aff9e48713/tpx/UX.md#L154-L166) is distinct from automatic copy trading.

These support demo vocabulary and explanatory scenarios only. Conflicts within evolving production plans are not resolved by this PRD, and their production launch prerequisites are not hackathon tasks.

### E-B01

VMBE's [build modules](https://github.com/VistaMarkets/VistaMobileBE/blob/fa467975cad3d9256a0b138af4a517ae4a69aa54/settings.gradle.kts#L7-L21), [actual Gateway route declarations](https://github.com/VistaMarkets/VistaMobileBE/blob/fa467975cad3d9256a0b138af4a517ae4a69aa54/gateway/src/main/kotlin/com/vista/gateway/routes/V1Routes.kt#L96-L161), and whole-word source searches establish **no implemented Arena/Clash domain, routes or database migrations found** at the reviewed local and remote-main revisions. Searches covered Kotlin, SQL and Gradle source; docs do contain Arena/TPX plans.

[ADR-0021](https://github.com/VistaMarkets/VistaMobileBE/blob/fa467975cad3d9256a0b138af4a517ae4a69aa54/docs/adr/0021-retained-client-surfaces-and-delivery-boundaries.md#L21-L55) records future lifecycle, settlement and scoring contracts. A planned Social domain is not an implemented Arena backend. This supports the VMBE half of the user's baseline, with the revision limits above.

### E-B02

The [served public contract](https://github.com/VistaMarkets/VistaMobileBE/blob/fa467975cad3d9256a0b138af4a517ae4a69aa54/docs/api/gateway-openapi.yaml#L75-L89) and [source routes](https://github.com/VistaMarkets/VistaMobileBE/blob/fa467975cad3d9256a0b138af4a517ae4a69aa54/gateway/src/main/kotlin/com/vista/gateway/routes/V1Routes.kt#L96-L161) cover prices/history, suggestions and accounts/terms/delegation. The [contract guide](https://github.com/VistaMarkets/VistaMobileBE/blob/fa467975cad3d9256a0b138af4a517ae4a69aa54/docs/api/frontend-api-contract.md#L32-L66) distinguishes served routes from staged APIs and reports no deployed host. The example host is a placeholder, not an integration endpoint.

[PriceEvent](https://github.com/VistaMarkets/VistaMobileBE/blob/fa467975cad3d9256a0b138af4a517ae4a69aa54/core/src/main/kotlin/com/vista/core/PriceEvent.kt) carries source/freshness concepts; [Maker feed DTOs](https://github.com/VistaMarkets/VistaMobileBE/blob/fa467975cad3d9256a0b138af4a517ae4a69aa54/Maker/src/main/kotlin/com/vista/maker/routes/FeedDtos.kt#L21-L44) carry asset, direction, reference price, rationale, expiry and availability. These are useful mock-contract references. An account handle check is not a trader-market ticker registry, and a suggestion is not a public user call.

### E-B03

[Merchant app composition](https://github.com/VistaMarkets/VistaMobileBE/blob/fa467975cad3d9256a0b138af4a517ae4a69aa54/app/src/main/kotlin/com/vista/app/Main.kt#L506-L569) has no live signer factory and an empty venue-executor map; passing order validation does not produce a fill. [Maker's handoff port](https://github.com/VistaMarkets/VistaMobileBE/blob/fa467975cad3d9256a0b138af4a517ae4a69aa54/Maker/src/main/kotlin/com/vista/maker/ports/HandoffEnqueuerPort.kt) and [accept response](https://github.com/VistaMarkets/VistaMobileBE/blob/fa467975cad3d9256a0b138af4a517ae4a69aa54/Maker/src/main/kotlin/com/vista/maker/routes/AcceptRoutes.kt#L180-L193) preserve unavailable behavior. Treating those paths as working demo trade execution would be incorrect.

VC should implement its own simulated order outcome, without weakening VMBE gates. If a future scope decision requires VMBE, its [public decimal-string contract](https://github.com/VistaMarkets/VistaMobileBE/blob/fa467975cad3d9256a0b138af4a517ae4a69aa54/docs/api/gateway-openapi.yaml#L12-L20), authentication and public Gateway boundary remain relevant.

## Verification verdict

Document validation found **35 unique requirement IDs (29 P0, 6 P1)**, no undefined explicit requirement references, and no broken companion-document links/anchors. All **45 distinct pinned repository links** resolve to files and valid line locations in the inspected Git objects. The 10-day date calculation resolves to October 11. These checks validate the planning artifacts; they do not establish runtime acceptance.

| Claim | Verdict |
|---|---|
| Arena/Clash are unimplemented in VMBE | Supported for reviewed source revisions; planned contracts exist. |
| Most Arena/Clash functionality is implemented in FMA | Contradicted on current main. Adjacent client features and extensive plans exist; matching demo branch remains unknown. |
| FMA already supplies live trading/social data | Unsupported; inspected flows use local stores and fixtures. |
| VC can migrate an already working backend to cover the video | Unsupported as a working-backend claim. VC now has demo client source (E-C03); this does not establish live backend support or passing acceptance criteria. |
| A mock-first demo can use these repositories as references | Supported as a planning approach, with the existing VC app to assess/extend and the scoped acceptance criteria in the PRD. The target is now PC with simulated iOS presentation (E-U01); feasibility still depends on capacity and runtime setup. |
| Figma installation resolves the design evidence gap | Not established. Installation/enabled status was confirmed October 2, but no Figma tools were callable in this chat and the browser retry remained blocked by WebGL. |
| Proposed scope completely matches the specified Figma node | Unverified. No canvas/frame content has been inspected; exact visual fidelity remains provisional. |
