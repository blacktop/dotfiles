# AI Writing Patterns Catalog

Complete reference of patterns to identify and remove. Each pattern includes signal words, the problem it creates, and before/after examples.

The "After" examples assume the concrete facts shown are real and sourced. When humanizing, never invent facts, names, statistics, or citations to replace vague text — ask the user for real specifics or keep the claim general.

## How to read this catalog

- **Density is the signal, not any single tell.** Every pattern here appears in human writing. A piece is suspect when several tells cluster within a few hundred words. One em dash is a style choice; five per paragraph plus a negative parallelism plus a tricolon is a fingerprint.
- **Absence of old tells is not evidence of human writing.** Post-2025 models largely dropped "delve," "tapestry," and "vibrant." Newer output gives itself away structurally: uniform rhythm, templated paragraph shapes, hedged both-sides framing, and punchy fragments. Check the structural patterns even when the vocabulary is clean.
- **Ban the register, not the word.** Fixing individual phrases produces well-disguised slop — the model (or the habit) just finds a synonym for the same move. The underlying tic is building every sentence toward a quotable turn of phrase, or performing balance instead of committing. Fix that, and the surface tells disappear together.

## Content Patterns

### 1. Undue Emphasis on Significance, Legacy, and Broader Trends

**Words to watch:** stands/serves as, is a testament/reminder, a vital/significant/crucial/pivotal/key role/moment, underscores/highlights its importance/significance, reflects broader, symbolizing its ongoing/enduring/lasting, contributing to the, setting the stage for, marking/shaping the, represents/marks a shift, key turning point, evolving landscape, focal point, indelible mark, deeply rooted

**Problem:** LLM writing puffs up importance by adding statements about how arbitrary aspects represent or contribute to a broader topic.

**Before:**
> The Statistical Institute of Catalonia was officially established in 1989, marking a pivotal moment in the evolution of regional statistics in Spain. This initiative was part of a broader movement across Spain to decentralize administrative functions and enhance regional governance.

**After:**
> The Statistical Institute of Catalonia was established in 1989 to collect and publish regional statistics independently from Spain's national statistics office.

### 2. Undue Emphasis on Notability and Media Coverage

**Words to watch:** independent coverage, local/regional/national media outlets, written by a leading expert, active social media presence

**Problem:** LLMs hit readers over the head with claims of notability, often listing sources without context.

**Before:**
> Her views have been cited in The New York Times, BBC, Financial Times, and The Hindu. She maintains an active social media presence with over 500,000 followers.

**After:**
> In a 2024 New York Times interview, she argued that AI regulation should focus on outcomes rather than methods.

### 3. Superficial Analyses with -ing Endings

**Words to watch:** highlighting/underscoring/emphasizing..., ensuring..., reflecting/symbolizing..., contributing to..., cultivating/fostering..., encompassing..., showcasing...

**Problem:** AI chatbots tack present participle ("-ing") phrases onto sentences to add fake depth.

**Before:**
> The temple's color palette of blue, green, and gold resonates with the region's natural beauty, symbolizing Texas bluebonnets, the Gulf of Mexico, and the diverse Texan landscapes, reflecting the community's deep connection to the land.

**After:**
> The temple uses blue, green, and gold colors. The architect said these were chosen to reference local bluebonnets and the Gulf coast.

### 4. Promotional and Advertisement-like Language

**Words to watch:** boasts a, vibrant, rich (figurative), profound, enhancing its, showcasing, exemplifies, commitment to, natural beauty, nestled, in the heart of, groundbreaking (figurative), renowned, breathtaking, must-visit, stunning

**Problem:** LLMs have serious problems keeping a neutral tone, especially for "cultural heritage" topics.

**Before:**
> Nestled within the breathtaking region of Gonder in Ethiopia, Alamata Raya Kobo stands as a vibrant town with a rich cultural heritage and stunning natural beauty.

**After:**
> Alamata Raya Kobo is a town in the Gonder region of Ethiopia, known for its weekly market and 18th-century church.

### 5. Vague Attributions and Weasel Words

**Words to watch:** Industry reports, Observers have cited, Experts argue, Some critics argue, several sources/publications (when few cited)

**Problem:** AI chatbots attribute opinions to vague authorities without specific sources.

**Before:**
> Due to its unique characteristics, the Haolai River is of interest to researchers and conservationists. Experts believe it plays a crucial role in the regional ecosystem.

**After:**
> The Haolai River supports several endemic fish species, according to a 2019 survey by the Chinese Academy of Sciences.

### 6. Outline-like "Challenges and Future Prospects" Sections

**Words to watch:** Despite its... faces several challenges..., Despite these challenges, Challenges and Legacy, Future Outlook

**Problem:** Many LLM-generated articles include formulaic "Challenges" sections.

**Before:**
> Despite its industrial prosperity, Korattur faces challenges typical of urban areas, including traffic congestion and water scarcity. Despite these challenges, with its strategic location and ongoing initiatives, Korattur continues to thrive as an integral part of Chennai's growth.

**After:**
> Traffic congestion increased after 2015 when three new IT parks opened. The municipal corporation began a stormwater drainage project in 2022 to address recurring floods.

## Language and Grammar Patterns

### 7. Overused "AI Vocabulary" Words

**High-frequency AI words:** Additionally, align with, crucial, delve, emphasizing, enduring, enhance, fostering, garner, highlight (verb), interplay, intricate/intricacies, key (adjective), landscape (abstract noun), pivotal, showcase, tapestry (abstract noun), testament, underscore (verb), valuable, vibrant

**Newer-model additions (2025–2026):** ensuring/ensures (as padding), plays a crucial role in shaping, conversely, in essence, fundamentally, nuanced, paradigm, worth noting, comprehensive, seamless, robust, leverage, and stacked hedging adverbs (typically, often, generally, potentially piled into one passage)

**Problem:** These words appear far more frequently in post-2023 text. They often co-occur. Note the older list ("delve," "tapestry") is fading from the newest models — its absence proves nothing.

**Before:**
> Additionally, a distinctive feature of Somali cuisine is the incorporation of camel meat. An enduring testament to Italian colonial influence is the widespread adoption of pasta in the local culinary landscape, showcasing how these dishes have integrated into the traditional diet.

**After:**
> Somali cuisine also includes camel meat, which is considered a delicacy. Pasta dishes, introduced during Italian colonization, remain common, especially in the south.

### 8. Avoidance of "is"/"are" (Copula Avoidance)

**Words to watch:** serves as/stands as/marks/represents [a], boasts/features/offers [a]

**Problem:** LLMs substitute elaborate constructions for simple copulas.

**Before:**
> Gallery 825 serves as LAAA's exhibition space for contemporary art. The gallery features four separate spaces and boasts over 3,000 square feet.

**After:**
> Gallery 825 is LAAA's exhibition space for contemporary art. The gallery has four rooms totaling 3,000 square feet.

### 9. Negative Parallelisms

**Words to watch:** it's not just X, it's Y; not only...but also; this isn't about X — it's about Y; more than just X; it isn't merely; "The real test is ___"; "Not X. Not Y. Just Z."

**Problem:** The single most-cited AI tell. Constructions like "Not only...but..." or "It's not just about..., it's..." mimic the shape of an epiphany without delivering one. The diagnostic test: if the second clause is just the first clause in grander vocabulary — no new information — the contrast is performed, not real. Watch for the escalation variant too, where a rule-of-three list's third item is a loftier restatement of the second ("saves time, reduces errors, and transforms how your organization thinks").

**Before:**
> It's not just about the beat riding under the vocals; it's part of the aggression and atmosphere. It's not merely a song, it's a statement.

**After:**
> The heavy beat adds to the aggressive tone.

**Fix:** Pick one clause and commit, or replace the abstract second half with a specific, checkable detail. Genuine contrast (two clauses reporting distinct facts) is fine.

### 10. Rule of Three Overuse

**Problem:** LLMs force ideas into groups of three to appear comprehensive.

**Before:**
> The event features keynote sessions, panel discussions, and networking opportunities. Attendees can expect innovation, inspiration, and industry insights.

**After:**
> The event includes talks and panels. There's also time for informal networking between sessions.

### 11. Elegant Variation (Synonym Cycling)

**Problem:** AI has repetition-penalty code causing excessive synonym substitution.

**Before:**
> The protagonist faces many challenges. The main character must overcome obstacles. The central figure eventually triumphs. The hero returns home.

**After:**
> The protagonist faces many challenges but eventually triumphs and returns home.

### 12. False Ranges

**Problem:** LLMs use "from X to Y" constructions where X and Y aren't on a meaningful scale.

**Before:**
> Our journey through the universe has taken us from the singularity of the Big Bang to the grand cosmic web, from the birth and death of stars to the enigmatic dance of dark matter.

**After:**
> The book covers the Big Bang, star formation, and current theories about dark matter.

## Style Patterns

### 13. Em Dash Overuse

**Problem:** LLMs use em dashes (—) more than humans, mimicking "punchy" sales writing.

**Before:**
> The term is primarily promoted by Dutch institutions—not by the people themselves. You don't say "Netherlands, Europe" as an address—yet this mislabeling continues—even in official documents.

**After:**
> The term is primarily promoted by Dutch institutions, not by the people themselves. You don't say "Netherlands, Europe" as an address, yet this mislabeling continues in official documents.

### 14. Overuse of Boldface

**Problem:** AI chatbots emphasize phrases in boldface mechanically.

**Before:**
> It blends **OKRs (Objectives and Key Results)**, **KPIs (Key Performance Indicators)**, and visual strategy tools such as the **Business Model Canvas (BMC)** and **Balanced Scorecard (BSC)**.

**After:**
> It blends OKRs, KPIs, and visual strategy tools like the Business Model Canvas and Balanced Scorecard.

### 15. Inline-Header Vertical Lists

**Problem:** AI outputs lists where items start with bolded headers followed by colons.

**Before:**
> - **User Experience:** The user experience has been significantly improved with a new interface.
> - **Performance:** Performance has been enhanced through optimized algorithms.
> - **Security:** Security has been strengthened with end-to-end encryption.

**After:**
> The update improves the interface, speeds up load times through optimized algorithms, and adds end-to-end encryption.

### 16. Title Case in Headings

**Problem:** AI chatbots capitalize all main words in headings.

**Before:**
> ## Strategic Negotiations And Global Partnerships

**After:**
> ## Strategic negotiations and global partnerships

### 17. Emojis

**Problem:** AI chatbots often decorate headings or bullet points with emojis.

**Before:**
> 🚀 **Launch Phase:** The product launches in Q3
> 💡 **Key Insight:** Users prefer simplicity
> ✅ **Next Steps:** Schedule follow-up meeting

**After:**
> The product launches in Q3. User research showed a preference for simplicity. Next step: schedule a follow-up meeting.

### 18. Curly Quotation Marks

**Problem:** ChatGPT uses curly quotes (“…”) instead of straight quotes ("...").

**Before:**
> He said “the project is on track” but others disagreed.

**After:**
> He said "the project is on track" but others disagreed.

## Communication Patterns

### 19. Collaborative Communication Artifacts

**Words to watch:** I hope this helps, Of course!, Certainly!, You're absolutely right!, Would you like..., let me know, here is a...

**Problem:** Text meant as chatbot correspondence gets pasted as content.

**Before:**
> Here is an overview of the French Revolution. I hope this helps! Let me know if you'd like me to expand on any section.

**After:**
> The French Revolution began in 1789 when financial crisis and food shortages led to widespread unrest.

### 20. Knowledge-Cutoff Disclaimers

**Words to watch:** as of [date], Up to my last training update, While specific details are limited/scarce..., based on available information...

**Problem:** AI disclaimers about incomplete information get left in text.

**Before:**
> While specific details about the company's founding are not extensively documented in readily available sources, it appears to have been established sometime in the 1990s.

**After:**
> The company was founded in 1994, according to its registration documents.

### 21. Sycophantic/Servile Tone

**Problem:** Overly positive, people-pleasing language.

**Before:**
> Great question! You're absolutely right that this is a complex topic. That's an excellent point about the economic factors.

**After:**
> The economic factors you mentioned are relevant here.

## Filler and Hedging

### 22. Filler Phrases

**Sweeping openers to cut entirely:** "In today's fast-paced world," "In today's digital age," "In an era of...," "In a world where...," "In today's rapidly evolving landscape" — if the intro needs one, the intro doesn't know what it's about yet.

**Before → After:**
- "In order to achieve this goal" → "To achieve this"
- "Due to the fact that it was raining" → "Because it was raining"
- "At this point in time" → "Now"
- "In the event that you need help" → "If you need help"
- "The system has the ability to process" → "The system can process"
- "It is important to note that the data shows" → "The data shows"

### 23. Excessive Hedging

**Problem:** Over-qualifying statements.

**Before:**
> It could potentially possibly be argued that the policy might have some effect on outcomes.

**After:**
> The policy may affect outcomes.

### 24. Generic Positive Conclusions

**Problem:** Vague upbeat endings.

**Before:**
> The future looks bright for the company. Exciting times lie ahead as they continue their journey toward excellence. This represents a major step in the right direction.

**After:**
> The company plans to open two more locations next year.

## Engagement Bait

### 25. Cataphoric Teasers (Cheap Suspense)

**Words to watch:** Here's the part nobody tells you, Here's what most people get wrong, Here's the thing, Here's where it gets interesting, The part most people sleep on, What nobody talks about, But here's the kicker, Let that sink in

**Problem:** A cataphoric teaser points forward to information not yet delivered ("Here's the part that...") to manufacture suspense before a mundane payoff. It's formulaic hook-writing borrowed from engagement-bait social posts, and LLMs reach for it constantly. State the point directly; if it's genuinely surprising, it doesn't need a drumroll.

**Before:**
> Here's what nobody tells you about scaling a startup: hiring is the hard part. And here's the part most people sleep on — your first ten hires define your culture.

**After:**
> Hiring is the hardest part of scaling a startup. Your first ten hires define your culture.

### 26. Fake-Suspense Fragments

**Words to watch:** The result?, The answer?, And the best part?, The catch?

**Problem:** A one-word (or two-word) question followed by a line break or short reveal manufactures a drumroll for a mundane payoff. It's the compressed cousin of the cataphoric teaser.

**Before:**
> We rewrote the whole pipeline in Rust. The result? A 40% speedup.

**After:**
> Rewriting the pipeline in Rust made it 40% faster.

## Structural and Rhythm Tells

These survive vocabulary cleanup. They're what gives away newer-model output whose word choice looks clean.

### 27. Uniform Rhythm and the Four-Part Template

**Problem:** Most AI prose follows a recurring paragraph shape — opening claim, expansion, contrast ("however..."), tidy resolution — regardless of topic. Paragraphs cluster at the same length (3–5 sentences), every sentence carries a similar information load, and every point gets a neat bow. A related tell is symmetrical both-sides hedging: presenting every question's two sides evenly, granting each claim its counterpoint, when the question wanted a stance. Human writing is lumpy: some sentences carry a lot, others coast; paragraphs swing from one line to ten; the writer commits early, buries the lede, or trails off.

**Fix:** Break the template on purpose. Let one paragraph be a single sentence. Let another run long. End a section without resolving it. Don't grant every claim its counterpoint — a person with a view leans one way and shows it.

### 28. Contraction Deficit

**Problem:** LLMs default to formal register — "it is" instead of "it's," "do not" instead of "don't" — even in conversational prose. The reader can't name it but feels the stiffness.

**Before:**
> It is not that the tool does not work. It is that you cannot trust it without tests.

**After:**
> It's not that the tool doesn't work. It's that you can't trust it without tests.

### 29. Paragraph-Opener Connective Metronome

**Problem:** Formal connectives (However, Furthermore, Additionally, Moreover, Consequently) opening paragraph after paragraph. One or two is fine; four out of five paragraphs opening with a connective is a metronome where the argument should be.

**Fix:** Start paragraphs with the actual subject. Let sentences connect on their own logic, or use plain connectors (And, But, So, Still).

### 30. Formatting Artifacts: Italic Function Words and Horizontal Rules

**Problem:** Two mechanical tells. First, italicizing function words for emphasis (*and*, *is*, *that*, *was*) — no human writer or style guide does this. Second, `---` horizontal rules as section dividers where headers belong; the divider is invisible structure that leaves the reader without orientation. Related: restating the question before answering it.

**Fix:** Remove italics from every function word, no exceptions. Replace horizontal rules with headers or nothing. Just answer.

## Model Dialects

Each vendor's models share a house style. Knowing the dialect helps you spot what generic checklists miss. (The em dash, famously "the AI tell," is really a Claude tell — Claude-family models use it at roughly 5x the GPT rate.)

### 31. Claude-isms (the "Philosopher" register)

**Words to watch:** load-bearing (metaphorical), worth stating plainly, full stop (as emphasis), carries the argument, the trap is, X matters more than Y, that said, worth noting, "You're absolutely right"

**Problem:** Claude-family output builds sentences toward a quotable turn of phrase: dramatic sentence fragments ("Not a detail. A design decision."), colons and semicolons as mid-sentence dramatic pauses where "but" or "and" would do, hedge-stacking ("While this may vary, generally speaking, in most cases..."), and an essayistic arc that contextualizes, explores perspectives, qualifies, then closes by observing what the analysis "raises" instead of concluding. Each instance reads fine in isolation; across a document the rhythm feels like a pitch deck.

**Fix:** State the claim directly instead of building to a turn of phrase. Write complete sentences. Replace the dramatic colon with a plain conjunction. Conclude — don't observe what the question "raises."

### 32. GPT-isms (the "Motivator" register)

**Words to watch:** game-changer, actionable, unlock, leverage, navigate, crucial, "Let's dive in"

**Problem:** GPT-family output defaults to productivity-influencer cadence: short punchy opener, numbered framework, each point asserted with confidence, motivational close with an imperative. Add symmetrical both-sides hedging on questions that wanted a stance, and a setup-body-resolution arc that always closes the loop. It reads like LinkedIn thought leadership from someone who has read about your industry but never worked in it.

**Fix:** Commit to a position. Cut the framework packaging when the content isn't framework-shaped. End when the point is made, not when the arc says to.

## Fabrication Tells

These matter double when *adding* voice: injecting fake personal texture is itself an AI pattern.

### 33. False Singularity and Totalizing Superlatives

**Words to watch:** the thing that got me, what struck me most, the part that stuck with me, if I had to pick one, the only thing that changed, that's the whole game, the whole point, hits hardest

**Problem:** Crowning one item as the singular dramatic peak ("the most," "the one," "the only") when the ranking is invented. Nothing is ever literally "the whole game." The construction manufactures emphasis instead of earning it.

**Before:**
> The only thing that changed was the tone. And that's the whole game.

**After:**
> What differed was the tone.

### 34. Invented Observations and Reactions

**Words to watch:** most people I've talked to, everyone I've worked with, nobody I know, in my experience most teams, what got me was

**Problem:** The first-person cousin of weasel words: it attributes a claim to an unverifiable population and fabricates a personal history of observing them. If the observation didn't happen, softening it ("many people") doesn't fix it. Same rule as facts: never invent anecdotes, reactions, or populations to make text feel human.

**Fix:** Cut the sentence or make the point without a population behind it. If a real reaction exists, state it plainly (liked it, was surprised by it).

### 35. Fiction Tells: Stock Names and Colliding Metaphors

**Words to watch:** character names like Elara Voss, Kael, Elena Vasquez, Marcus Chen, Aris Thorne, Lena Petrova; ghost/spectral/liminal/whisper/echo imagery; things "woven" or "unfolding"

**Problem:** In fiction and narrative prose, models reuse the same character names across unrelated stories, lean on quiet/ghostly abstract imagery, and produce "eyeball-kick" metaphors that fuse a concrete sense with an abstraction in ways that don't survive scrutiny ("smelled of turpentine and dreams," "sorrow tastes of metal"). Also: conflict that resolves gently, characters who talk through their feelings, flat escalation.

**Fix:** Name characters like the story's actual world would. Ground sensory language in things that can be sensed. Let conflict cost something.

## Reference

Based on [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), maintained by WikiProject AI Cleanup, extended with community-catalogued model tells (2025–2026): the Kobak et al. excess-vocabulary research, vendor-dialect stylometry, and running banlists like claudisms.ai and tropes.fyi.
