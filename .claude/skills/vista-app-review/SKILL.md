---
name: vista-app-review
description: Multi-agent review of the VistaColosseum Flutter app — renders every main screen, runs parallel reviewers (visual/type, spacing, motion, consistency & copy, UX flow, a professional mobile developer, and a role-played first-time user) and merges their findings into one ranked plan with scores. Use whenever the user asks to review, audit or critique the app or its screens, asks "is the app premium / easy to use / easy to understand / good enough to demo", wants "a review sesh", "multi-agent review", "what needs fixing", "how's the user flow", or wants feedback from a designer, developer or new-user point of view — even if they don't say "multi-agent".
---

# VistaColosseum app review

A review is only as good as what the reviewers can see. So the flow is: render
the current build, hand every reviewer the same renders plus the code, let them
work in parallel, then merge what they say into one plan the user can act on.
Reviewing is read-only — nothing in the repo changes during a review.

## 1. Pick the panel

Default to all eight lenses in `references/reviewers.md`:

| Lens | Answers |
|---|---|
| Visual UI & typography | Does it look premium? Type, colour, contrast, surfaces |
| Spacing & layout | Rhythm, alignment, dead space, small phones, tap targets |
| Motion & interaction | Press feedback, transitions, haptics, jank on live ticks |
| Consistency & copy | Same thing done two ways, tokens bypassed, weak wording |
| Page content | What each page shows vs what a user wants there |
| UX & flow | Core loop, dead ends, order-entry safety, feedback |
| Professional mobile developer | Navigation map; reach / use / understand scores |
| First-time user | Where a newcomer gets confused, nervous or quits |

Narrow the panel when the request is narrow — "how's the flow / is it easy to
use" → UX & flow, page content, professional developer, first-time user; "does it look
premium" → visual, spacing, motion, consistency. If the user names reviewers,
use exactly those. Seven parallel agents is expensive, so don't run lenses
the question doesn't need.

The app runs on mock data. Reviews are about the design and what each page
should show, not whether the sample numbers are correct — the backend will
replace them. Keep "this mock value is wrong / mismatched" findings out of the
synthesis entirely unless the user asks about data.

## 2. Render the current build

Run the bundled renderer into a fresh folder in the scratchpad:

```bash
.claude/skills/vista-app-review/scripts/render_screens.sh <scratchpad>/review-<date>
```

It copies a temporary widget test into `app/test/`, renders 22 screens at
iPhone size (plus one 375×667 small phone) with the app's real fonts, and
deletes the test afterwards. Each screen is its own test, so one broken path
doesn't stop the rest; file names say how each screen was reached (e.g.
`03_home_card_long_opens_order_ticket.png`).

Then open two or three of the PNGs yourself before spawning anyone — a render
that came out blank, wrong or on the wrong screen poisons every reviewer.
If a screen failed or looks wrong (the app's navigation changed), fix the
path in `scripts/render_screens_test.dart.tmpl` and rerun rather than sending
reviewers a broken set. Add a screen there when the user asks about one the
set doesn't cover.

## 3. Run the reviewers in parallel

Spawn one agent per lens in a single message so they run at the same time.
Build each prompt from `references/reviewers.md`: the shared header plus that
lens, with `{SCREENS}`, `{APP}` (`app/lib`), `{ROOT}` (repo root) and
`{FOCUS}` filled in. Good agent types: `ui-ux-designer` for visual, spacing
and UX lenses and the first-time user; `mobile-developer` for the
professional developer; `general-purpose` for motion and consistency (they
grep code heavily).

Tell the user the panel is running and what each reviewer is looking at.
Don't predict results; as each report lands, a one-line note is plenty.

## 4. Merge into one plan

When all reports are in, write a single synthesis — the user should never have
to read seven reports. Merge, don't concatenate:

- **Lead with the answer** to what they asked (e.g. "Reachable and usable,
  not yet understandable"), then the scores side by side if the developer
  and first-time-user lenses ran.
- **Dedupe across reviewers.** When two lenses flag the same thing, say so —
  agreement is the strongest signal of a real problem.
- **Rank by impact on the demo**, in groups:
  1. Must fix before demoing — trust breakers: wrong data, dead ends on core
     actions, money that looks real, order flows that don't finish.
  2. Premium feel — visual and motion.
  3. Consistency — feels like one product.
  4. Smaller items, in one short list.
- Each item: what's wrong in plain words, where (screen, `file:line` when
  known), and the concrete fix.
- **Verify before you repeat.** Reviewers can be wrong or stale; spot-check
  any High item against the code or a render before putting it at the top.
- **Filter against the user's own decisions.** Drop or flag suggestions that
  contradict choices already made (a naming they picked, a design they
  approved, brand colours awaiting a founder pick) — mention them under
  "I'd skip" with the reason instead of re-litigating.
- End with **what to do first** (2–4 items) and offer to build or mock them.
  Don't start fixing until the user picks — a review is a planning step.

Keep the synthesis in chat, as a ranked list with short headers. Translate
jargon the reviewers used (assertions, tokens, `ValueListenableBuilder`) into
what the user sees on screen.

## Notes

- The renderer needs the app to build; if `flutter test` fails to compile,
  report that first — a review of a broken build isn't useful.
- Renders are static. Motion and haptics come from reading code, so say so
  when a motion finding hasn't been seen running.
- Reviewers see the demo's mock data. Drop findings about mock values being
  wrong or inconsistent — the user wants the design and the page content
  judged, not the placeholder data.
