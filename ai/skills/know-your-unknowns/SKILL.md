---
name: know-your-unknowns
description: >-
  Surface hidden unknowns before, during, and after implementation using structured
  techniques — clickable mocks, intervention brainstorms, semantics maps, tweakable
  plans, implementation notes, buy-in docs, and more. Use PROACTIVELY when entering
  an unfamiliar codebase or domain, when a feature request is ambiguous or
  underspecified, when the user says
  "I'm not sure", "I'll know it when I see it", or has no design direction, when porting
  from a reference implementation, when writing an implementation plan, before merging a
  large diff, or when packaging work for reviewer sign-off. Also triggers on explicit
  asks: "blindspot pass", "interview me", "quiz me before I merge", "show me design
  directions", "teach me <domain>", "what am I missing?".
---

# Know Your Unknowns

The map is not the territory — the gap between them is your unknowns. Output quality
is now limited less by the model than by how well the prompt accounts for what the
prompter doesn't know. Specificity cuts both ways: too much detail and the model
rigidly follows instructions even when the territory says to change course; too little
and it fills gaps with industry defaults that don't fit. Either way, unaccounted
unknowns become rework. The cheapest place to find an unknown is before any code is
written; the most expensive is after someone else inherits it.

This skill is a menu of techniques for converting unknowns into decisions. Each
technique targets a specific quadrant of ignorance and ends by folding what it
surfaced back into a better prompt, plan, or sign-off.

## The four quadrants

| Quadrant | What it is | How to surface it |
| --- | --- | --- |
| Known knowns | Already stated in the prompt | Nothing to do |
| Known unknowns | Questions you know you haven't answered | Ask them, ordered by blast radius → **the interview** |
| Unknown knowns | Preferences too obvious to write down, but recognized on sight | Render options to react to → **design directions, mocks, brainstorm** |
| Unknown unknowns | Things nobody thought to consider | Scan the territory → **blindspot pass, teach-me, reference map** |

Reacting is easier than imagining: for unknown knowns, never ask the user to describe
what they want — show them concrete alternatives and let them point.

## Choosing a technique

| Situation | Technique | Output form |
| --- | --- | --- |
| Unfamiliar module/codebase, about to change it | Blindspot pass | Inline findings + improved prompt |
| Unfamiliar *domain* (no vocabulary to prompt with) | Teach me my unknowns | HTML explainer with vocabulary ladder |
| No visual direction, "no taste", greenfield UI | Design directions | HTML: 3–4 wildly different renderings |
| UI decisions pending, wiring not started | Mock before you wire | HTML clickable mock + A/B questions |
| Fuzzy problem, solution space unexplored | Brainstorm the intervention | Cost-sorted menu grounded in real code |
| Requirements ambiguous, architecture at stake | The interview | Inline Q&A → decisions table + prompt |
| A working reference implementation exists | Point at a reference | Semantics map + sign-off gate |
| Plan requested or implied before a build | The tweakable plan | Plan ordered by revision-likelihood |
| Mid-build, reality contradicts the plan | Implementation notes | Running markdown log of deviations |
| Shipped, needs reviewer/stakeholder approval | The buy-in doc | HTML pitch with pre-answered objections |
| Large diff about to merge | Quiz me before I merge | HTML report + gated quiz |

Details, prompt patterns, and required output elements:

- [references/pre-implementation.md](references/pre-implementation.md) — first eight techniques (read before running any of them)
- [references/during-and-post.md](references/during-and-post.md) — implementation notes, buy-in doc, change quiz

## Rules that apply to every technique

**Ground everything in the territory.** Findings, options, and questions must come
from scanning actual code, files, schemas, and history — cite real paths, functions,
and PRs. A blindspot card that says "auth can be tricky" is noise; one that says
"`SessionBridge.write()` also fires the audit webhook — skip it and SSO logins
silently vanish from compliance logs" changes the plan.

**End with an exportable decision.** The loop only closes when surfaced unknowns
become a better prompt. Interactive artifacts finish with reaction affordances
(steal/skip chips, "this resonates" checkboxes, A/B choices) that assemble into a
copyable reply. Conversational techniques finish with a decisions table and a
ready-to-paste implementation prompt that encodes every answer.

**Match the medium to the technique.** Techniques marked HTML above produce
self-contained artifacts — invoke the **html-artifacts skill** for format rules,
output paths (`docs/.ai/artifacts/` durable, `docs/.ai/tools/` throwaway), and the
quality checklist. Conversational techniques (blindspot pass, interview, brainstorm,
tweakable plan) stay inline as markdown unless their output outgrows it.
Implementation notes are a plain markdown file, not an artifact.

**Don't interrogate a known territory.** If the request is precise, the codebase is
familiar, and the change is mechanical, skip this skill entirely — running an
interview on a one-line fix is worse than the fix being slightly wrong. Scale the
ceremony to the blast radius of being wrong.

**One technique at a time.** These compose across a project's lifecycle (interview →
tweakable plan → implementation notes → buy-in doc), but pick the single technique
that targets the biggest current unknown rather than firing several at once.
