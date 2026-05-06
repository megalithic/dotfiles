/**
 * Task pipeline commands — /task and /plan backed by subagents
 *
 * These commands orchestrate the research → plan → tickets → work pipeline.
 * Research and planning phases use the subagent tool to run in isolated processes
 * with restricted tool access (read-only, no file mutations).
 *
 * The main agent's only job during /task and /plan is:
 *   1. Resolve slug + paths (see below)
 *   2. Invoke the subagent tool
 *   3. Save subagent output to the resolved paths
 *
 * Paths: ~/.local/share/pi/plans/$(basename $PWD)/
 *   {slug}_TASK.md           research output
 *   {slug}_PLAN.md           plan output
 *   {slug}.ticket-context.md per-ticket context (created by /tickets)
 *
 * {slug} = ${TICKET_ID}-<kebab> if a tk ticket is in progress, else <kebab>
 * derived from the user's prompt (3–5 words).
 *
 * Slug resolution when not passed explicitly:
 *   1. If $TICKET_ID is set or exactly one tk ticket is in_progress for the
 *      repo, derive slug from it
 *   2. Else scan the plans dir for orphan *_TASK.md (no matching *_PLAN.md):
 *      0 → fall through to recent-items scan; 1 → use silently; 2+ → list + ask
 *   3. Recent-items fallback (when orphan-scan returns 0): scan the plans dir
 *      for all *_TASK.md / *_PLAN.md, group by slug, sort by mtime; 0 → tell
 *      user to run /task first; 1 → use silently; 2-3 → list with phase + ask;
 *      >3 → show top 3 + 'and N more, use /retrieve <slug>'
 *
 * Note: the upstream examples this pipeline was adapted from assume a
 * git-worktree-per-feature layout. We are NOT currently using worktrees;
 * paths are repo-basename + slug scoped so concurrent tasks don't collide.
 * A later migration to jj workspaces will be tracked separately.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

/**
 * Shared slug-resolution instructions emitted to the agent when no slug arg
 * was passed. Used by /task (no-args), /plan, and /tickets.
 *
 * The agent is responsible for performing the scans and listings — the
 * extension API has no list-pick UI; we instruct via message text.
 */
const SLUG_FALLBACK_INSTRUCTIONS = [
  "Slug resolution (no arg passed):",
  "  1. If $TICKET_ID is set or exactly one tk ticket is in_progress for the repo, derive slug from it.",
  "  2. Else orphan-scan: list *_TASK.md in Dir with no matching *_PLAN.md.",
  "     - 1 orphan → use silently.",
  "     - 2+ orphans → list with mtime, ask user to pick.",
  "     - 0 orphans → fall through to recent-items scan (step 3).",
  "  3. Recent-items scan: list all *_TASK.md and *_PLAN.md in Dir, group by",
  "     slug (strip _TASK.md / _PLAN.md suffix), sort by most recent mtime",
  "     across each slug's files. Determine phase per slug:",
  "       TASK only            → 'research'",
  "       TASK + PLAN          → 'planning-complete'",
  "       TASK + PLAN + ticket-context.md → 'tickets-seeded'",
  "     Then:",
  "       0 results       → tell user to run /task <description> first.",
  "       1 result        → use silently.",
  "       2-3 results     → list each as `<slug>  [<phase>]  <mtime>` and ask user to pick.",
  "       >3 results      → list top 3 + 'and N more, use /retrieve <slug> for a specific one'.",
].join("\n");

export default function (pi: ExtensionAPI) {
  pi.registerCommand("task", {
    description:
      "Research a task using an isolated subagent (read-only, no mutations)",
    handler: async (args, _ctx) => {
      if (!args || !args.trim()) {
        pi.sendUserMessage(
          [
            "Resume research for an existing task.",
            "",
            "Paths:",
            "  Dir = ~/.local/share/pi/plans/$(basename $PWD)/",
            "",
            SLUG_FALLBACK_INSTRUCTIONS,
            "",
            "Once the slug is resolved, read <Dir>/{slug}_TASK.md and continue research.",
            "If no slug can be resolved (recent-items scan returns 0), tell the user to provide a task description: /task <description>",
          ].join("\n"),
        );
        return;
      }

      const input = args.trim();

      pi.sendUserMessage(
        [
          `Research task: ${input}`,
          "",
          "Use the subagent tool with the 'researcher' agent to research this task in an isolated process.",
          "",
          "Paths:",
          "  Dir  = ~/.local/share/pi/plans/$(basename $PWD)/",
          "  Slug = ${TICKET_ID}-<kebab> if a tk ticket is in progress, else <kebab> derived from the prompt (3–5 words). Announce the slug you picked.",
          "  Task file = <Dir>/{slug}_TASK.md",
          "",
          "Steps:",
          "1. Resolve slug and ensure Dir exists (mkdir -p). If {slug}_TASK.md already exists, read it first, then pass its contents as context to continue research",
          '2. Call subagent tool: { agent: "researcher", task: "<the research task with all context; include the resolved slug and task file path so the researcher can reference it>" }',
          "3. Save the subagent output to <Dir>/{slug}_TASK.md (overwrite if exists)",
          "",
          "The researcher agent runs in isolation — it can read files, search code, and run read-only commands, but CANNOT edit, write, or modify anything.",
          "Its output will be the research findings. Save that output verbatim to the task file.",
          "",
          "Note: worktree-based isolation is not in use; slug + basename scoping prevents collisions between concurrent tasks.",
        ].join("\n"),
      );
    },
  });

  pi.registerCommand("plan", {
    description:
      "Create an implementation plan using an isolated subagent (read-only)",
    handler: async (args, _ctx) => {
      const explicitSlug = args?.trim();
      const slugBlock = explicitSlug
        ? `  Slug = ${explicitSlug} (passed explicitly, skip orphan scan)`
        : SLUG_FALLBACK_INSTRUCTIONS;
      pi.sendUserMessage(
        [
          "Create implementation plan from research findings.",
          "",
          "Use the subagent tool with the 'planner' agent to create an implementation plan.",
          "",
          "Paths:",
          "  Dir  = ~/.local/share/pi/plans/$(basename $PWD)/",
          slugBlock,
          "  Task file = <Dir>/{slug}_TASK.md   Plan file = <Dir>/{slug}_PLAN.md",
          "",
          "Steps:",
          "1. Resolve slug and read <Dir>/{slug}_TASK.md (the research findings) — if it doesn't exist, tell the user to run /task first",
          '2. Call subagent tool: { agent: "planner", task: "<the research findings from the task file; include slug + task file path so the planner can reference it>" }',
          "3. Save the subagent output to <Dir>/{slug}_PLAN.md (overwrite if exists)",
          "",
          "The planner agent runs in isolation — it can read files but CANNOT edit or write anything.",
          "Its output will be the implementation plan. Save that output verbatim to the plans file.",
          "Present the plan to the user for review. Do NOT create tickets until explicitly approved.",
        ].join("\n"),
      );
    },
  });

  pi.registerCommand("retrieve", {
    description:
      "List or look up past TASK/PLAN combos in the current repo's plans dir",
    handler: async (args, _ctx) => {
      const explicitSlug = args?.trim();
      if (explicitSlug) {
        pi.sendUserMessage(
          [
            `Retrieve plan info for slug: ${explicitSlug}`,
            "",
            "Paths:",
            "  Dir = ~/.local/share/pi/plans/$(basename $PWD)/",
            `  TASK file    = <Dir>/${explicitSlug}_TASK.md`,
            `  PLAN file    = <Dir>/${explicitSlug}_PLAN.md`,
            `  Context file = <Dir>/${explicitSlug}.ticket-context.md`,
            "",
            "Steps:",
            "1. Check which of the three files above exist (ls / test -f).",
            "2. Determine phase:",
            "     TASK only                       → 'research'",
            "     TASK + PLAN                     → 'planning-complete'",
            "     TASK + PLAN + ticket-context.md → 'tickets-seeded'",
            "     None                            → emit 'No files found for slug X. Start with /task <description>' and stop.",
            "3. Report to the user a one-line phase summary + the suggested next command:",
            `     research            → /plan ${explicitSlug}`,
            `     planning-complete   → /tickets ${explicitSlug}`,
            "     tickets-seeded      → work-tickets (pickup or new ticket-worker session)",
            "4. Do NOT auto-invoke any subagent or run any other slash command.",
          ].join("\n"),
        );
        return;
      }
      pi.sendUserMessage(
        [
          "List past TASK/PLAN combos in the current repo's plans dir.",
          "",
          "Paths:",
          "  Dir = ~/.local/share/pi/plans/$(basename $PWD)/",
          "",
          "Steps:",
          "1. Scan Dir for all *_TASK.md and *_PLAN.md.",
          "2. Group by slug (strip _TASK.md / _PLAN.md suffix). For each slug,",
          "   determine phase from file existence:",
          "     TASK only                       → 'research'",
          "     TASK + PLAN                     → 'planning-complete'",
          "     TASK + PLAN + ticket-context.md → 'tickets-seeded'",
          "3. Sort slugs by most recent mtime across each slug's files.",
          "4. Emit results:",
          "     0 results   → 'No plans found in <Dir>. Start with /task <description>'.",
          "     1 result    → auto-select silently: emit slug + phase summary + suggested next command (same mapping as /retrieve <slug>).",
          "     2-3 results → list each as `<slug>  [<phase>]  <mtime>` and ask user to pick (suggest /retrieve <slug>).",
          "     >3 results  → list top 3 + 'and N more, use /retrieve <slug> for a specific one'.",
          "5. Do NOT auto-invoke any subagent or run any other slash command.",
        ].join("\n"),
      );
    },
  });

  pi.registerCommand("tickets", {
    description:
      "Create tickets from the implementation plan using the ticket-creator skill",
    handler: async (args, _ctx) => {
      const explicitSlug = args?.trim();
      const slugBlock = explicitSlug
        ? `  Slug = ${explicitSlug} (passed explicitly, skip orphan scan)\n  Plan file = <Dir>/{slug}_PLAN.md   Context file = <Dir>/{slug}.ticket-context.md`
        : `${SLUG_FALLBACK_INSTRUCTIONS}\n  Plan file = <Dir>/{slug}_PLAN.md   Context file = <Dir>/{slug}.ticket-context.md`;
      pi.sendUserMessage(
        [
          "Create tickets from the implementation plan.",
          "",
          "Paths:",
          "  Dir  = ~/.local/share/pi/plans/$(basename $PWD)/",
          slugBlock,
          "",
          "Steps:",
          "1. Resolve slug and read <Dir>/{slug}_PLAN.md — if it doesn't exist, tell the user to run /plan first",
          "2. Explore the codebase for file hints and verification commands",
          "3. Seed <Dir>/{slug}.ticket-context.md if it doesn't exist (see context seeding in ticket-creator skill)",
          "4. Create one ticket per plan step using ticket-creator skill Mode 3",
          "5. Self-validate (mandatory):",
          "   - tk list — check all tickets are open",
          "   - For each ticket: tk show <id> - verify description has file hints, acceptance criteria are numbered and independently verifiable",
          "   - Refine any weak tickets immediately",
          "   - tk dep cycle — no cycles allowed",
          "   - tk ready -T ready-for-development - each ticket needs to be unblocked. If ticket needs another ticket to unblock it, another ticket should have it explicitly stated in that ticket.",
          "6. Report what was created",
        ].join("\n"),
      );
    },
  });
}
