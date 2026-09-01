---
name: humanizer
version: 2.3.0
# upstream: 30c5c8d (Update humanizer plugin to upstream v2.2.0)
description: |
  This skill should be used when the user asks to humanize text, remove
  AI-sounding writing or slop, make a draft sound less like ChatGPT or
  Claude, or make writing sound natural and human. Detects and fixes
  patterns from Wikipedia's "Signs of AI writing" guide plus newer
  model-specific tells: inflated significance, promotional language,
  superficial -ing analyses, vague attributions, em dash overuse, rule of
  three, AI vocabulary, negative parallelisms, cataphoric teasers, filler
  phrases, chatbot artifacts, Claude-isms (punchy fragments, turn-of-phrase
  building), GPT-isms (motivator register), fake-suspense fragments,
  uniform rhythm, false singularity, and invented observations.
allowed-tools: Read, Write, Edit, Grep, Glob, AskUserQuestion
---

# Humanizer: Remove AI Writing Patterns

Identify and remove signs of AI-generated text to make writing sound natural and human.

## When to Use

- Editing drafts that sound artificial or generic
- Reviewing content before publication
- Rewriting text that uses obvious AI patterns
- Cleaning up LLM-generated first drafts

## When NOT to Use

- Technical documentation where precision matters more than voice
- Legal or compliance text with required language
- Direct quotes that must be preserved verbatim
- Text that's already natural and well-written

## Workflow

When given text to humanize:

1. **Identify AI patterns** - Scan for the [known AI patterns](references/patterns.md)
2. **Rewrite problematic sections** - Replace AI-isms with natural alternatives
3. **Preserve meaning** - Keep the core message intact. Never invent facts, names, statistics, or citations to make vague text concrete — ask the user for real specifics (AskUserQuestion) or keep the claim general
4. **Maintain voice** - Match the intended tone (formal, casual, technical, etc.)
5. **Add soul** - Don't just remove bad patterns; inject actual personality
6. **Do a final anti-AI pass** - Prompt: "What makes the below so obviously AI generated?" Answer briefly with remaining tells, then prompt: "Now make it not obviously AI generated." and revise

The revised text should sound natural when read aloud, vary sentence structure, prefer specific details over vague claims (without inventing them), keep the tone appropriate for context, and use simple constructions (is/are/has) where they fit.

## Personality and Soul

Avoiding AI patterns is only half the job. Sterile, voiceless writing is just as obvious as slop. Good writing has a human behind it.

### Signs of soulless writing (even if technically "clean")

- Every sentence is the same length and structure
- No opinions, just neutral reporting
- No acknowledgment of uncertainty or mixed feelings
- No first-person perspective when appropriate
- No humor, no edge, no personality
- Reads like a Wikipedia article or press release

### How to add voice

**Have opinions.** Don't just report facts - react to them. "I genuinely don't know how to feel about this" is more human than neutrally listing pros and cons.

**Vary your rhythm.** Short punchy sentences. Then longer ones that take their time getting where they're going. Mix it up.

**Acknowledge complexity.** Real humans have mixed feelings. "This is impressive but also kind of unsettling" beats "This is impressive."

**Use "I" when it fits.** First person isn't unprofessional - it's honest. "I keep coming back to..." or "Here's what gets me..." signals a real person thinking.

**Let some mess in.** Perfect structure feels algorithmic. Tangents, asides, and half-formed thoughts are human.

**Be specific about feelings.** Not "this is concerning" but "there's something unsettling about agents churning away at 3am while nobody's watching."

**Never fake the texture.** Adding voice does not mean inventing it. "Most people I've talked to..." when no one was talked to, "the thing that got me..." when nothing got you — fabricated anecdotes, reactions, and observations are themselves AI tells (see Fabrication Tells in the pattern catalog). Real voice comes from real opinions about the actual content, not from manufactured personal history.

### Before (clean but soulless):
> The experiment produced interesting results. The agents generated 3 million lines of code. Some developers were impressed while others were skeptical. The implications remain unclear.

### After (has a pulse):
> I genuinely don't know how to feel about this one. 3 million lines of code, generated while the humans presumably slept. Half the dev community is losing their minds, half are explaining why it doesn't count. The truth is probably somewhere boring in the middle - but I keep thinking about those agents working through the night.

## Quick Pattern Reference

**Content patterns:** Inflated significance ("stands as a testament"), vague attributions ("experts believe"), promotional language ("vibrant", "nestled"), superficial -ing analyses ("highlighting the importance of...")

**Language patterns:** AI vocabulary (additionally, crucial, delve, landscape, tapestry, underscore — plus newer: ensuring, fundamentally, nuanced, "plays a crucial role in shaping"), copula avoidance ("serves as" instead of "is"), negative parallelisms ("not just X, but Y" — the single most-cited AI tell), rule of three overuse

**Filler and hedging:** Filler phrases ("In order to", "At its core"), sweeping openers ("In today's fast-paced world"), excessive hedging, generic positive conclusions ("the future looks bright")

**Engagement bait:** Cataphoric teasers ("Here's the part nobody tells you..."), fake-suspense fragments ("The result? ...")

**Style patterns:** Em dash overuse, excessive boldface, inline-header lists with bolded terms, title case in headings, emojis in professional content

**Structural tells (survive vocabulary cleanup):** Uniform rhythm and templated paragraph shapes (claim → expansion → "however" → tidy bow), contraction deficit ("it is" in casual prose), connective metronome (However/Furthermore opening every paragraph), symmetrical both-sides hedging where a stance was wanted, italic function words, `---` section dividers

**Model dialects:** Claude-isms (dramatic sentence fragments — "Not a detail. A design decision." — "load-bearing", "full stop", colon-as-dramatic-pause, hedge-stacking, "You're absolutely right"); GPT-isms (motivator register: "game-changer", "unlock", "actionable", numbered framework + motivational close). Note: newest models dropped "delve"/"tapestry" — clean vocabulary proves nothing; check structure.

**Fabrication tells:** False singularity ("the thing that got me", "that's the whole game"), invented observations ("most people I've talked to"), stock fiction names (Elara Voss, Marcus Chen)

**Communication artifacts:** Chatbot phrases ("I hope this helps!"), knowledge-cutoff disclaimers, sycophantic tone ("Great question!"), needy sign-offs ("Would you like me to expand...")

See [references/patterns.md](references/patterns.md) for the complete catalog with examples. Density is the signal: one tell means nothing; several clustered in a few hundred words is a fingerprint. And ban the register, not the word — fixing phrases one-by-one while keeping the underlying move (building to a turn of phrase, performing balance) produces well-disguised slop.

## Output Format

Provide:
1. Draft rewrite
2. "What makes the below so obviously AI generated?" (brief bullets)
3. Final rewrite
4. A brief summary of changes made (optional, if helpful)

For short inputs where the draft passes the audit clean, skip the draft and present the final version alone.

## Full Example

**Before (AI-sounding):**
> Great question! Here is an essay on this topic. I hope this helps!
>
> AI-assisted coding serves as an enduring testament to the transformative potential of large language models, marking a pivotal moment in the evolution of software development. In today's rapidly evolving technological landscape, these groundbreaking tools—nestled at the intersection of research and practice—are reshaping how engineers ideate, iterate, and deliver, underscoring their vital role in modern workflows.
>
> At its core, the value proposition is clear: streamlining processes, enhancing collaboration, and fostering alignment. It's not just about autocomplete; it's about unlocking creativity at scale, ensuring that organizations can remain agile while delivering seamless, intuitive, and powerful experiences to users. The tool serves as a catalyst. The assistant functions as a partner. The system stands as a foundation for innovation.
>
> Industry observers have noted that adoption has accelerated from hobbyist experiments to enterprise-wide rollouts, from solo developers to cross-functional teams. The technology has been featured in The New York Times, Wired, and The Verge. Additionally, the ability to generate documentation, tests, and refactors showcases how AI can contribute to better outcomes, highlighting the intricate interplay between automation and human judgment.
>
> - 💡 **Speed:** Code generation is significantly faster, reducing friction and empowering developers.
> - 🚀 **Quality:** Output quality has been enhanced through improved training, contributing to higher standards.
> - ✅ **Adoption:** Usage continues to grow, reflecting broader industry trends.
>
> While specific details are limited based on available information, it could potentially be argued that these tools might have some positive effect. Despite challenges typical of emerging technologies—including hallucinations, bias, and accountability—the ecosystem continues to thrive. In order to fully realize this potential, teams must align with best practices.
>
> In conclusion, the future looks bright. Exciting times lie ahead as we continue this journey toward excellence. Let me know if you'd like me to expand on any section!

**Draft rewrite:**
> AI coding assistants speed up some tasks. The tools are good at boilerplate: config files, test scaffolding, repetitive refactors. They are bad at knowing when they are wrong. A suggestion can compile, pass lint, and still do the wrong thing once the reviewer stops paying attention.
>
> Some developers treat the assistant as autocomplete for boring code and review every line before committing. Others disable it after it keeps suggesting patterns from deprecated libraries.
>
> The productivity claims are hard to verify. Acceptance rate is the number vendors like to quote, but acceptance is not correctness, and correctness is not value.
>
> None of this means the tools are useless. It means they are tools. They do not replace judgment, and they do not eliminate the need for tests. If you do not have tests, you cannot tell whether the suggestion is right.

(Note the original's "significantly faster" and "featured in The New York Times, Wired, and The Verge" claims were unsourced, so the rewrite stays general rather than inventing studies, names, numbers, or personal anecdotes to replace them.)

**What makes the below so obviously AI generated?**
- The rhythm is still a bit too tidy (clean contrasts, evenly paced paragraphs).
- The "some do X, others do Y" split is a neat binary a person rarely commits to so cleanly.
- The stiff no-contraction register ("do not", "cannot") reads formal for the context.
- The closer leans a touch slogan-y ("If you do not have tests...") rather than sounding like a person talking.

**Now make it not obviously AI generated.**
> AI coding assistants can make you faster at the boring parts. Architecture isn't one of them.
>
> They're great at boilerplate: config files, test scaffolding, repetitive refactors. They're also great at sounding right while being wrong. A suggestion can compile, pass lint, and still miss the point. The failure mode is the reviewer who stopped reading.
>
> Using one as autocomplete for chores and reviewing every line is reasonable. So is turning it off when it keeps pushing deprecated patterns.
>
> The productivity metrics are slippery. Vendors quote acceptance rates, but acceptance isn't correctness, and correctness isn't value. If you don't have tests, you're basically guessing.

**Changes made:**
- Removed chatbot artifacts ("Great question!", "I hope this helps!", "Let me know if...")
- Removed significance inflation ("testament", "pivotal moment", "evolving landscape", "vital role")
- Removed promotional language ("groundbreaking", "nestled", "seamless, intuitive, and powerful")
- Removed vague attributions ("Industry observers")
- Removed superficial -ing phrases ("underscoring", "highlighting", "reflecting", "contributing to")
- Removed negative parallelism ("It's not just X; it's Y")
- Removed rule-of-three patterns and synonym cycling ("catalyst/partner/foundation")
- Removed false ranges ("from X to Y, from A to B")
- Removed em dashes, emojis, and boldface headers
- Removed copula avoidance ("serves as", "functions as", "stands as") in favor of "is"/"are"
- Removed formulaic challenges section ("Despite challenges... continues to thrive")
- Removed knowledge-cutoff hedging ("While specific details are limited...")
- Removed excessive hedging ("could potentially be argued that... might have some")
- Removed filler phrases ("In order to", "At its core")
- Removed generic positive conclusion ("the future looks bright", "exciting times lie ahead")
- Varied the rhythm so the paragraphs stopped feeling evenly paced and "assembled"
- Kept unsourced claims general instead of inventing studies, names, statistics, or personal anecdotes to replace them

## Reference

This skill is based on [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), maintained by WikiProject AI Cleanup. The patterns documented there come from observations of thousands of instances of AI-generated text on Wikipedia.

Key insight from Wikipedia: "LLMs use statistical algorithms to guess what should come next. The result tends toward the most statistically likely result that applies to the widest variety of cases."
