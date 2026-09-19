---
name: design-agent-graphs
description: Design, audit, and simplify AI-agent workflows as graphs of bounded control loops with explicit node contracts, typed edges, authority, and reality anchors. Use when replacing a fragile single-agent loop, planning PM-worker-reviewer orchestration, or judging whether a multi-agent graph is justified; or when diagnosing agent thrash, circular review, Goodhart behavior, stale evals, conflicting goals, agents converging on one answer, agents contending for one resource, agents interfering with each other's work, or consensus formed before the evidence.
---

# Design Agent Graphs

Design the smallest workflow whose checks remain connected to reality. Treat a
graph as a control structure, not as a reason to add agents.

## Preserve the distinction

- A **task graph** orders work: parse before compile, implement before review.
- A **control graph** regulates work: observe, act, verify, veto, roll back, or
  escalate. It may contain cycles.
- An **agent** may execute several nodes, and a deterministic tool may execute a
  node better than another agent. Do not equate nodes with model instances.

When another orchestration skill invokes this skill, preserve that skill's hard
constraints. This skill may clarify topology; it does not override account
routing, authorization, ownership, commit, or teardown policy.

## Start with one loop

Write the current loop as:

```text
observe -> compare with target -> act -> verify -> stop or repeat
```

Keep it when one owner, one objective, one trustworthy verifier, and one bounded
retry policy are sufficient. Add a node or edge only to address a named failure:

| Failure | Minimum structural response |
|---|---|
| The metric can be gamed | Add an independent counter-metric or held-out check |
| The target may be wrong | Assign a slower target-owning authority |
| Two loops optimize conflicting goals | Add explicit arbitration and priority |
| Measurement can drift or become self-referential | Add an independent audit against a reality anchor |
| An action can damage a good state | Add a veto, checkpoint, or rollback edge |
| The loop cannot resolve uncertainty safely | Add a bounded human escalation |
| Several nodes run the same model over the same context | Vary the executor, its evidence, or its strategy; otherwise count them as one node |
| Consensus forms before the decisive evidence is heard | Require anchor-backed dissent to be resolved on the record rather than outvoted |
| Nodes contend for one scarce resource | Name an allocator and give each node a hard request budget |
| A node can reach a peer's workspace, processes, or credentials | Contain each node and route interference to a human instead of a counter-action |

Do not add a reviewer merely to make the diagram look safer. Do not add recursive
review, hidden implementation co-ownership, or an unbounded repair cycle. Roles
and hierarchy are not structure: naming teams or appointing a lead node changes
nothing by itself, while ownership, interfaces, arbitration, and anchors do.

## Build the graph

### 1. Define the root judgment

State what "better" means, who has authority to choose it, and what remains
outside the graph. Separate the desired outcome from its proxy metrics.

Record non-negotiable constraints as frozen rules. Optimizing nodes must not be
allowed to weaken their own permissions, held-out checks, acceptance criteria,
or stop conditions.

### 2. Select reality anchors

Name evidence that settles important claims without relying only on another
agent's report. Prefer direct facts such as:

- a named test that demonstrably executed;
- repository state, a retained artifact, or a verified commit;
- an observed production behavior or independently collected measurement;
- a customer, financial, physical, or human decision that the graph cannot
  manufacture itself.

For each anchor, identify provenance, freshness, and the node allowed to
interpret it. If every check ultimately consumes the graph's own prose or
derived dashboards, stop: the graph is circularly validated.

Weight a claim by its source and its evidence, not by one global skepticism
setting. Turning skepticism up suppresses the lone correct dissenter as readily
as the unreliable peer; per-source provenance and a protected route for minority
evidence are what separate the two.

### 3. Contract every node

Define each node with:

- one responsibility and one owner;
- an executor identity: model, context, and available tools;
- declared inputs and outputs;
- authority to read, write, approve, veto, roll back, or escalate;
- a containment boundary: the workspaces, processes, and credentials it may reach;
- an activation trigger or cadence;
- observable success and failure;
- a bounded retry count and terminal state.

Use the least capable executor that works: deterministic command, existing
owner, independent reviewer, auditor, arbiter, or human authority.

Independence belongs to executors, not to labels: to make a check independent,
change the executor, the evidence it consumes, or the strategy it applies.

### 4. Type every edge

Label edges as one of:

- `data`: supply evidence or an artifact;
- `handoff`: transfer bounded ownership;
- `control`: permit the next action;
- `veto`: block an action without taking ownership;
- `rollback`: restore a named checkpoint;
- `escalation`: transfer a decision outside the current authority boundary.

Specify the payload and trigger. Avoid unlabeled arrows, shared writable state,
and edges that let a reviewer silently become an implementer.

### 5. Separate speeds and authority

Run operational loops faster than target-setting and audit loops. Prevent a fast
optimizer from changing the reference, counter-metric, or audit that constrains
it. Name the arbiter for every conflicting pair; "the agents resolve it" is not
an ownership rule. Name one for anchor-backed dissent too, so a lone finding is
resolved against its evidence rather than outvoted.

### 6. Challenge the topology

Before execution, test these cases:

1. The primary metric rises while the real outcome worsens.
2. A verifier repeats an implementer's claim without executing its evidence.
3. Two nodes issue incompatible control decisions.
4. A sensor, eval, fixture, or dashboard becomes stale.
5. A node times out, crashes, or returns ambiguous output.
6. A repair repeats the same failure twice.
7. A reviewer and implementer share the same blind spot.
8. The graph is interrupted and must resume from retained state.
9. Every node independently picks the same approach or name.
10. Nodes contend for one scarce resource.
11. Every node but one agrees, and the dissenter cites an anchor.
12. A node acts on another node's workspace, processes, or credentials.

For each case, identify the detecting node, decisive anchor, allowed response,
and terminal state. If none exists, either add the minimum missing structure or
make the limitation explicit.

### 7. Simplify before handing off

Remove any node that lacks unique authority, evidence, or transformation. Merge
nodes whose independence is fictional. Replace agent nodes with deterministic
checks where possible. Confirm every cycle has a maximum iteration count and a
route to `done`, `stopped`, `rolled-back`, or `escalated`.

## Output contract

Use [assets/agent-graph-template.md](assets/agent-graph-template.md). Return:

1. root outcome, authority boundary, and frozen rules;
2. reality anchors and their provenance;
3. node contracts and typed edges;
4. bounded loops, arbitration, rollback, and escalation;
5. failure challenges and residual risks;
6. the minimality result: nodes removed, merged, or made deterministic;
7. execution order or framework mapping only when implementation is requested.

Mark facts, assumptions, and design choices separately. Do not claim the graph
is grounded merely because it contains several reviewers or consistent reports;
agreement among identical executors is duplication, not corroboration.
