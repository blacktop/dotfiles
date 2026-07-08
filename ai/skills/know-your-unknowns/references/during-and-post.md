# During- and post-implementation techniques

No matter how much planning happened, unknowns lurk in the territory. During the
build, log every place the code forces a deviation. After the build, remember that
shipping means other people inheriting your unknowns — pre-answer their objections
and verify your own understanding before merging.

## 9. Implementation notes

**When:** Any non-trivial build, especially one executing a plan. Start the file
when the build starts; don't wait for the first surprise.

**Procedure:** Keep a running markdown log (e.g., `docs/.ai/notes/<feature>-implementation-notes.md`)
updated *at the moment of discovery*, not reconstructed afterward. When an edge case
forces a deviation from the plan, pick the conservative option, log it, and keep
going — don't stall the build waiting for a human unless the decision is
irreversible.

Organize entries under three headings:
- **Deviations** — plan assumed X, implementation revealed Y, conservative call
  made, revisit-point flagged.
- **Discoveries** — useful intel that didn't require plan changes (existing
  utilities found, conventions learned).
- **Needs human judgment** — decisions deliberately deferred (permissions,
  retention windows), each with the conservative interim choice.

End the file with **"lines to paste into the next plan"** — two or three concrete
bullets so attempt #2 starts smarter. This is the payoff: scattered surprises
become institutional knowledge.

**Prompt pattern:** "Keep an implementation-notes file as you build [feature]. If
you hit an edge case that forces a deviation from the plan, pick the conservative
option, log it under 'Deviations', and keep going."

**Output must contain:** entries logged at the moment of discovery under
Deviations / Discoveries / Needs human judgment → closing "lines to paste into
the next plan".

## 10. The buy-in doc

**When:** Work is done and needs stakeholder or reviewer approval. The remaining
unknown is organizational: what objections will reviewers raise, and who actually
has to say yes?

**Procedure:** One skimmable HTML artifact (via html-artifacts) that moves
*show → tell → defend*:
1. **Show:** demo first — an animated/clickable walkthrough of the feature, not a
   wall of text.
2. **Tell:** compact spec summary with cross-references to fuller docs; risk and
   rollback assessment (ideally "one toggle to revert").
3. **Defend:** pre-answer the 4–6 objections reviewers were about to raise (data
   leakage, performance, design rationale, infra cost, compliance) with evidence —
   drawn from the spec, the prototype, and the implementation notes.
4. **Close:** named sign-offs — who must approve *which specific decision*, and by
   when. Not "please review" but "Dana signs off on the retention window".

**Prompt pattern:** "Package the prototype, the spec, and the implementation notes
into a single doc I can drop in Slack to get buy-in on shipping [feature]."

**Output must contain:** demo up top → compact spec summary with risk/rollback →
pre-answered objections backed by evidence → named sign-offs tied to specific
decisions, with a deadline.

## 11. Quiz me before I merge

**When:** A large diff (agent-written or inherited) is about to merge and the human
merging it has only skimmed it. The unknown is the gap between "I skimmed it" and
"I understand it".

**Procedure:** An HTML report (via html-artifacts) on the diff, ending in a gate:
1. **Mental model:** before/after architecture diagram of what changed and why.
2. **Non-obvious behaviors:** the deliberate design decisions a skimmer would miss
   (recovery semantics, expiry windows, what renders from what source), each with
   its reasoning.
3. **The quiz:** ~6 questions targeting those decisions — understanding gaps, not
   trivia. Wrong answers link back to the exact report section that explains it.
   The artifact shouldn't let the reader feel done until they actually are.

**Prompt pattern:** "Give me an HTML report on this diff — context, intuition, what
was done — with a quiz at the bottom that I must pass before merging."

**Output must contain:** before/after mental model → non-obvious behaviors with
their reasoning → ~6-question quiz targeting those decisions, wrong answers
linking back to the explaining section.
