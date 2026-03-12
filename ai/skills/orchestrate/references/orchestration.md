# Orchestration Patterns

Source snapshot: refreshed 2026-03-12 from official Anthropic and OpenAI material

- Claude Code best practices
- Claude Code subagents docs
- Claude Code hooks docs
- Claude prompt engineering best practices
- OpenAI multi-agent orchestration and eval best practices

## Core principles

### Keep the critical path local

Do locally:

- architecture and sequencing decisions
- acceptance criteria
- integration and merge decisions
- final verification

Delegate:

- research that can be summarized
- repetitive mechanical edits
- bounded implementation slices
- first-pass docs and boilerplate

### Bound every delegated task

Each worker should have:

- one objective
- a clear owned write scope
- files to avoid
- exact verification commands
- a strict return format

If the task cannot be described that way, it is not ready to delegate.

### Context isolation beats giant prompts

Modern Claude and Codex guidance converges on the same point: large contexts rot. Keep main-thread context focused and let delegated workers rebuild only the context they need.

Practical rules:

- delegate file exploration and implementation separately when possible
- do not dump massive repo summaries into every worker prompt
- point workers to files and commands, not long narrative history
- prefer fresh sessions for new sub-tasks

### Parallelize only independent work

Run workers in parallel only if:

- the next local step does not depend on them immediately
- their outputs do not race on the same files
- their verification can run independently

Good parallel pairs:

- codebase exploration in separate areas
- docs plus tests
- two implementation slices with disjoint ownership

Bad parallel pairs:

- two workers editing the same module
- one worker producing an interface while another consumes the unsettled design

### Give workers a way to verify themselves

Verification is the highest-leverage accelerant in agentic coding workflows.

Always include one or more of:

- unit or integration test commands
- lint or typecheck commands
- expected output or behavior
- screenshot or UI expectations
- explicit “done means” criteria

### Use deterministic infrastructure for deterministic rules

If something should always happen, do not rely on the worker to remember it.

Promote repeated rules into:

- `.claude/agents/` for reusable specialized workers
- project or local `.claude` settings for shared configuration
- hooks for formatting, notifications, command blocking, or post-edit checks

### Evaluate the orchestration, not just the result

Modern skill and eval guidance is clear: measure process, not vibes.

For an orchestration pattern, success includes:

- did the lead delegate the right slices?
- did workers stay within scope?
- did they return the requested format?
- did the lead verify before accepting?
- did the workflow avoid unnecessary thrash?

## Delegation rubric

Delegate when the task is:

- repetitive
- local in scope
- easy to verify
- separable from architectural choices

Keep local when the task is:

- ambiguous
- architecture-defining
- safety-critical
- hard to verify automatically
- needed immediately for the next decision

## Handoff template

Use a short, explicit brief:

```text
You are working as a bounded implementation worker.

Goal:
- [single concrete outcome]

Read first:
- [file paths]

Ownership:
- edit: [files or directories]
- avoid: [files or directories]

Constraints:
- [repo rules, language rules, no-go areas]

Verification:
- run: [commands]
- done means: [observable result]

Return:
- [diff summary | JSON | patch | checklist]
```

Add examples only when the format is strict enough to warrant them.

## Review loop

Do not accept delegated work blindly.

Review in this order:

1. Did the worker stay in scope?
2. Did it satisfy the contract?
3. Are there obvious logic or edge-case failures?
4. Did verification actually run and pass?
5. Does the change still make sense in the broader architecture?

If not, send a targeted revision request instead of a full restatement.
