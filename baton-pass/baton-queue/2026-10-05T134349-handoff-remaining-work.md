---
source: claude
scope: baton-queue
parent_session: f258dbad-9417-42a2-bb5c-ae5786580df0
date: 2026-10-05
---

# Baton pass: remaining work after the P0 runner

Read this cold. `main` @ 0c7402d has units 1-8 built, the roadmap and queue doc updated (#21), 289 tests, analyze clean. Nothing below is started.

## Decided
- Code on main is not a milestone exit. No milestone (M1-M5) has a verification record; none is claimed complete. Do not change that without the record (template in docs/prd/2026-10-01-vc-hackathon-roadmap.md, "Milestone verification record template").
- VC-DEM-004 persona switch lives in spec 09 and phase advance is P1 (O-10). Neither is built; never mark either Built.
- origin/feat/premium-feel stays parked (user: "ignore premium feel"). 62 commits, 23 files conflict with main. Landing it is a new branch `feat/premium-feel-rebased` rebased onto main, never a force-push, and only on the user saying "premium feel".
- Run rules carry forward to spec 09: no new pub dependency, money in int minor units, every success message describes something that actually happened, scripts/gate.sh must print GATE: PASS.
- Branch cleanup is finished for what was safe: origin/feat/design-system deleted. Left alone on purpose: origin/fix/portable-reference-paths (one unique commit), local feat/trade-feed-spec (codex worktree holds two untracked docs), local claude/project-testing-verification-c6c151 (another app session's worktree).

## New evidence
- /home/alex/Downloads/iphone-proof.mp4 (49.7 s, recorded Oct 5 06:40) shows the app launched on an iPhone-shaped target and walking Home, Explore, a trader market with its Record tab, Arena, a call detail with replay, Wallet, the full Make-a-market flow to "Your market is open", and the wallet with own-market cap and fees. This is M1's launch proof. It is not yet an M1 verification record: nobody has written run/reset notes or filled the template, and the recording does not show reset. Narration script: /home/alex/Downloads/iphone-proof-narration.md.
- Two visible inconsistencies worth knowing before anyone narrates or audits: the wallet at ~0:40 shows the demo trader's $44.0M cap, not the $10,000 market just created; the call detail at ~0:20 shows "Lost $3,000" (intended, the product grades losses in public).

## Remaining work, in dependency order
1. M1 verification record. Write run/reset notes, confirm reset on the presenter Mac, fill the template. Input: the video above plus a reset demonstration. Mac-only.
2. Build spec 09 (copy story: persona switch, copied order, one `copy` ledger credit). Command: `/ClaudesMods:baton-runner docs/specs/09-copy-story.md` (use baton-runner-managed if the classifier blocks Agent spawns again). Same gate, review, fix shape as units 1-8.
3. O-08 audit as M2-M4 verification records against every P0 ID, merged units included (VC-FED-001/002, VC-LST-001/003/004, VC-ARN-001 have no record at all).
4. Write two specs: VC-MKT-001 (own-market index series and labels, economic copy per O-05) and SP-07 (VC-DEM-001, VC-QA-001/003/004: Simulator run, viewport checks, rehearsals, run/reset notes, recording). Then run them.
5. Five design calls, user-owned, listed in baton-runner/br-2026-10-04-p0-queue/digest-phase-8.md: 30 px pill tap target; LiveFeed base-value drift after reset; Change/Funding sort label order unpinned by a test; Maker "Trade this" prices at live mark not reference price; Home Following tab never filters so Home cannot show its empty state.
6. Premium-feel fate (see Decided). Each merged PR widens the rebase.

## Where to look
- Plan of record: docs/prd/2026-10-01-vc-hackathon-roadmap.md (status paragraphs dated October 5). Queue: docs/specs/00-baton-queue.md.
- Drift report that drove #21: .drift-status/2026-10-05-2026-10-01-vc-hackathon-roadmap-drift.md (gitignored, primary checkout only).
- Run artefacts: baton-runner/br-2026-10-04-p0-queue/ (STATE.md DONE, log.md, digest-phase-1..8.md). Review records: docs/reviews/2026-10-04-dw-review-phase-*.md.
- Previous notes in this directory: 2026-10-05T085823-p0-runner-complete.md (run close), 2026-10-04T233424 (phase-3 pause).

## Next step
Write the M1 verification record from the iPhone recording plus a reset demonstration, then start spec 09.
