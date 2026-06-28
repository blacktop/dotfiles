# Anthropic Claude Handoff Patterns (Fable 5 / Opus 4.8 / Claude 4.x)

Source snapshot: refreshed 2026-06-12 from official Anthropic docs

- [Prompting Claude Fable 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5)
- [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

## Model lineup

- **Fable 5** (`claude-fable-5`): flagship Mythos-class tier above Opus.
  Adaptive thinking only; effort levels low/medium/high (default)/xhigh.
- **Opus 4.8 / Sonnet 4.6 / Haiku 4.5**: the 4.x line; classic Claude 4.x
  guidance below applies unchanged.

## Start here (all Claude models)

- Be clear and direct. Claude follows what you ask for, not what you imply.
- State the desired depth, quality bar, and output format explicitly.
- Explain why unusual constraints matter when behavior depends on them.
- Use XML tags or clearly labeled sections to separate instructions, context,
  examples, and inputs; 3-5 short examples when format must match tightly.
- Tell Claude whether the task is to implement, suggest, review, or
  investigate, and whether independent tool calls should run in parallel.

## Fable 5 specifics

- **Dial prescription down.** Handoffs written for 4.x are often too
  prescriptive and can degrade Fable 5 output. One brief steering sentence
  replaces an enumerated behavior list; remove instructions whose default
  behavior is already right.
- **Give the reason, not only the request.** "I'm working on [X] for [who];
  they need [what it enables]. With that in mind: [task]." Intent context
  measurably improves results.
- **Hand it the hard version.** Start at the top of the difficulty range and
  let it scope. Expect longer turns (minutes at high effort, hours
  autonomous); prefer async check-ins over blocking on the run.
- **Ground progress claims** in long-run handoffs: "Before reporting
  progress, audit each claim against a tool result from this session; report
  only work you can point to evidence for."
- **State boundaries** to prevent unrequested actions: assessment-only vs
  apply-the-fix, and "before a state-changing command, check the evidence
  supports that specific action."
- **Autonomous handoffs** should say so: "You are operating autonomously; for
  reversible actions that follow from the request, proceed without asking;
  end your turn only when the task is complete or blocked on the user."
- **Verification**: fresh-context verifier subagents outperform self-critique;
  for long builds, instruct a self-check interval against the spec.
- Effort routing: high for most handoffs, xhigh only for capability-critical
  work, medium/low for routine slices (still strong).

## Runtime knobs

If the receiving harness exposes model settings, prefer these there instead
of spelling them out in prose:

- Effort: `--effort low|medium|high|xhigh|max` at launch or `/effort`
  in-session (`max` is a Claude Code harness value; the model's own effort
  levels are low through xhigh); `high` is the Fable 5 default, `xhigh` for
  capability-critical work. Fable 5 uses adaptive thinking only — there are
  no extended-thinking budget parameters to set.
- Model pinning: `--model fable|opus|sonnet|haiku` or full IDs; `[1m]` suffix
  for the 1M-token context window on supported models.
- Structured tool schemas when another system parses the result.

## Refusal hazards (Fable 5 only)

- Never instruct it to echo, transcribe, or explain its internal reasoning in
  the response — that phrasing triggers `reasoning_extraction` refusals.
  Audit handoffs for "show your thinking" instructions; ask for evidence,
  checklists, or findings instead.
- Offensive-cybersecurity and biology/life-science tasks can return
  `stop_reason: "refusal"` (benign security work may also trigger); plan an
  Opus 4.8 fallback lane for those handoffs.
- Avoid surfacing context-budget countdowns in the prompt; they can trigger
  premature wrap-up. If the harness shows them, add "You have ample context
  remaining; do not stop or summarize on account of context limits."

## Good shape

```xml
<context>
[Why this work matters and for whom; project slice; current state; files]
</context>

<task>
[Single explicit objective — the hard version, with success criteria]
</task>

<tool_use>
[Tools to prefer; whether to parallelize; subagent delegation guidance]
</tool_use>

<constraints>
[Scope limits, prohibitions, boundaries on unrequested actions]
</constraints>

<verification>
[Checks to run; evidence required before claiming progress or done]
</verification>

<output>
[Exact return format]
</output>
```

## Avoid

- enumerated behavior lists where one steering sentence works (Fable 5)
- show-your-reasoning instructions (refusal risk on Fable 5)
- vague requests like "be thorough" without defining the deliverable
- burying critical constraints in long prose
- mixing stable instructions with mutable project state in the same block
