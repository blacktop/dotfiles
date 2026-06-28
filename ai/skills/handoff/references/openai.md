# OpenAI GPT-5.x / Codex Handoff Patterns

Source snapshot: refreshed 2026-06-12 from official OpenAI docs

- [Prompt guidance (GPT-5.5)](https://developers.openai.com/api/docs/guides/prompt-guidance)
- [Using GPT-5.5](https://developers.openai.com/api/docs/guides/latest-model)
- [Codex prompting guide](https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide)

## Model lineup

- **GPT-5.5**: current flagship; strongest agentic coding line. Reasoning
  effort defaults to `medium`; levels none/low/medium/high/xhigh.
- **gpt-5.3-codex**: Codex-tuned variant for agentic coding via API; the
  Codex CLI ships its own tuned defaults.

## Start here

- Outcome-first, shorter prompts beat process-heavy prompt stacks: define the
  target outcome, success criteria, constraints, and available evidence, then
  let the model choose the path.
- Migrating a handoff from an older GPT? Start from a fresh minimal prompt
  that preserves the contract — do not carry the old instruction stack over.
- Reserve `ALWAYS`/`NEVER`/`must` for true invariants (safety rules, required
  output fields). For judgment calls (when to search, ask, iterate), write
  decision rules instead.
- Ask for structured outputs or strict schemas when another system parses the
  result.

## Handoff emphasis

- For coding agents, be explicit about: code reuse expectations, subagent
  delegation, test expectations, acceptance criteria, and when to continue vs
  ask for help.
- Give retrieval budgets — stopping rules for search: what needs supporting
  evidence, what counts as enough, and what to do when evidence is missing
  (absence of evidence is not a factual "no").
- For long or tool-heavy tasks, ask for a short preamble (acknowledge + first
  step) and progress preambles with tool calls.
- Give concrete stop rules for destructive, broad, or expensive actions.

## Runtime knobs

If the receiving harness exposes model settings, prefer these there instead
of spelling them out in prose:

- `reasoning.effort`: `medium` is the balanced default; `low` often suffices
  and should be evaluated before escalating; `high`/`xhigh` only for the
  hardest agentic work where evals justify the latency. Higher effort is not
  automatically better — with conflicting instructions or weak stopping
  criteria it produces overthinking and unnecessary searching.
- `text.verbosity`: low/medium/high controls response length without
  rewriting the prompt.
- Responses API with `previous_response_id` preserves reasoning state across
  tool calls; if replaying assistant items manually, preserve `phase` values.

## Good shape

```text
Context
[Only facts the agent needs, plus why the work matters]

Task
[Single concrete outcome with acceptance criteria]

Tool use
- [Which tools/files to use; delegation and reuse expectations]
- [Retrieval budget: when enough evidence is enough]

Constraints
- [True invariants only; decision rules for judgment calls]

Verification
- [Checks to run; test expectations]

Output contract
- [Exact format to return; artifacts to write]
```

## Avoid

- carrying over instruction stacks written for older GPT versions
- absolute rules (`ALWAYS`/`NEVER`) for judgment calls
- vague goals like "improve this" or hidden completion criteria
- escalating reasoning effort without a measured quality gain
- asking for internal reasoning when findings or evidence summaries suffice
