# Jevify

A prompt for investigating what Jev could make possible in an existing project. Paste the prompt below into your coding agent while it is working in your project.

---

I want you to deeply investigate what **Jev, TypeSafe’s structured decision model, could make possible in this project**.

My hypothesis is that this could be a big deal. It may substantially reduce cost and latency for work we already do. More interestingly, it may make semantic judgments cheap and fast enough to use throughout the application—in places where calling an LLM previously seemed too slow, expensive, or cumbersome to consider.

Take that possibility seriously. Be ambitious about what we could build and rigorous about what the evidence supports.

**Start by reading these sources and inspecting this project:**

- [TypeSafe introduction](https://docs.typesafe.ai/introduction)
- [Typed decision primitives](https://docs.typesafe.ai/primitives)
- [API reference](https://docs.typesafe.ai/api)
- [Documentation index](https://docs.typesafe.ai/llms.txt)
- [Jev architecture investigation](https://archerhume.com/posts/jevs-architecture-unmasked)—use this to generate hypotheses; its architectural deductions are not verified implementation details.

Follow relevant documentation links to verify current pricing, limits, batching behavior, and integration options. Separate vendor claims, independently measured results, and your own hypotheses.

The documented interface evaluates a shared state against multiple typed questions, returning choices, rubric scores, and yes/no probabilities. Questions in one request are evaluated independently; application code combines their answers. Understand this model before proposing integrations.

The broader idea I want you to explore is **using language understanding as a routine computational operation**. Read text or application state, evaluate many specific properties, and use those results directly in software. Think about the input-processing side of language models without assuming Jev exposes an encoder, embeddings, or arbitrary internal representations.

**1. Understand what this project is trying to accomplish.**

Inspect the actual code, architecture, data flows, prompts, tests, and available performance evidence. Identify the user outcomes that matter.

Find where we currently:

- Spend money or time on model calls.
- Generate text only to parse it into a decision.
- Repeatedly process the same context.
- Serialize judgments that could be independent.
- Use brittle rules because semantic understanding seemed impractical.
- Rely on manual review, coarse categories, sampling, or delayed batch processing.
- Discard information or limit coverage to stay within a budget.

Tie observations to concrete files and execution paths. Do not assume the project needs existing LLM calls to benefit.

**2. Reconsider the design from first principles.**

Ask: **If many useful semantic judgments were affordable within our application’s response-time budget, what would we design differently?**

Explore three kinds of opportunity:

- **Direct savings:** perform existing work with less cost or latency at acceptable quality.
- **Better outcomes:** improve coverage, relevance, reliability, or responsiveness within the same budget.
- **New capabilities:** enable useful behavior we currently do not attempt.

Give the third category substantial attention. Look beyond replacing individual model calls. Consider whether we could evaluate every event instead of sampling, assess many candidates or dimensions at once, react while a user is interacting, continuously reassess changing state, or combine fast judgments with slower reasoning in a better overall workflow.

Those are starting points. Develop ideas specific to this project rather than repeating a generic feature list.

Explicitly identify assumptions in the current architecture that exist because semantic computation was expensive. Explain which could change and what user-visible benefit follows.

**3. Make the strongest opportunities concrete.**

For each serious candidate, specify:

- The user problem and current behavior.
- The exact integration point and available input state.
- The specific questions Jev would answer and the appropriate primitives.
- Which questions can share a request and which genuinely depend on earlier results.
- How ordinary code would consume the answers.
- What still requires generation, deeper reasoning, retrieval, or deterministic logic.
- The expected benefit, implementation effort, and most consequential failure mode.

For the top candidates, include representative request shapes and consumer pseudocode grounded in the current API.

Do not hide a complex reasoning task inside a vaguely worded classification question. Show that the proposed decomposition preserves the information needed to make a good decision.

**4. Test the economics and performance assumptions.**

Estimate the complete workflow, including preparing inputs, network overhead, question tokens, downstream calls, retries, fallbacks, and mistakes that create extra work.

Distinguish lower latency per request from lower end-to-end latency. Identify the critical path. Do not assume that more questions are free, that batching scales indefinitely, or that provider-side parallelism eliminates client-visible costs.

Compare against the current implementation and credible simpler alternatives: deterministic code, caching, embeddings, conventional classifiers, or smaller generative models where appropriate.

When measurements are unavailable, provide explicit assumptions, plausible ranges, and break-even conditions. State what would have to be true for each proposal to be worthwhile.

**5. Design an evaluation that could prove us wrong.**

For the strongest opportunities, define:

- Representative inputs and held-out cases.
- Baselines and task-level success criteria.
- Relevant quality metrics, including asymmetric costs of false positives and false negatives.
- End-to-end cost, latency distributions, and throughput under realistic load.
- Tests for ambiguity, missing evidence, adversarial input, and sensitivity to question wording or batch composition.
- How thresholds, abstention, and fallback behavior would be validated.
- Clear go/no-go criteria.

Treat returned probabilities as signals whose calibration needs testing on our workload.

If credentials, suitable data, and an established experiment budget are available, run a small bounded experiment. Otherwise, produce a runnable evaluation plan and clearly identify what remains unmeasured. Continue the analysis without inventing results.

**6. Deliver a recommendation we can act on.**

Produce:

- A concise assessment of how consequential this could be for this particular project.
- A ranked opportunity table separating savings, quality improvements, and new capabilities.
- Detailed designs for the three strongest opportunities—or fewer if only fewer survive scrutiny.
- A first-principles sketch of how you would design the relevant parts of this product today with this capability available.
- The smallest experiment that would resolve the most important uncertainty.
- Ideas you rejected and the evidence or reasoning behind rejecting them.

Be explicit about what you inspected, what you measured, and what remains hypothetical. Keep exploration separate from production changes.

I want a serious investigation with imagination. Find the opportunities our existing architecture makes easy to overlook, then show which ones hold up.
