/**
 * Task pipeline commands — /task, /plan, /tickets, /continue, /retrieve
 *
 * Thin runtime: registers commands, emits minimal context to the agent.
 * All workflow knowledge (slug resolution, file formats, phase rules,
 * VCS conventions) lives in the task-pipeline skill.
 *
 * The agent loads the task-pipeline skill on-demand for detailed instructions.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const DIR_HINT = "Dir = ~/.local/share/pi/plans/$(basename $PWD)/";
const SKILL_REF =
  "Load the task-pipeline skill for slug resolution rules and workflow details.";
const GRILL_HINT =
  "Treat <Dir>/{slug}_GRILL.md and <Dir>/{slug}_grill.md as pre-research context. GRILL-only means next step is /task {slug}.";

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
            SKILL_REF,
            `  ${DIR_HINT}`,
            `  ${GRILL_HINT}`,
            "",
            "Resolve slug per skill rules, then read <Dir>/{slug}_TASK.md and continue research.",
            "If TASK is missing but GRILL exists, read GRILL as context and start research for that slug.",
            "If no slug can be resolved, tell the user to provide a description: /task <description>",
          ].join("\n"),
        );
        return;
      }

      pi.sendUserMessage(
        [
          `Research task: ${args.trim()}`,
          "",
          SKILL_REF,
          `  ${DIR_HINT}`,
          `  ${GRILL_HINT}`,
          "",
          "Steps:",
          "1. Resolve slug and ensure Dir exists (mkdir -p). If {slug}_TASK.md exists, read it first as context. Else if {slug}_GRILL.md or {slug}_grill.md exists, read it as context.",
          '2. Call subagent: { agent: "researcher", task: "<research task + context>" }',
          "3. Save subagent output to <Dir>/{slug}_TASK.md",
        ].join("\n"),
      );
    },
  });

  pi.registerCommand("plan", {
    description:
      "Create an implementation plan using an isolated subagent (read-only)",
    handler: async (args, _ctx) => {
      const slug = args?.trim();
      pi.sendUserMessage(
        [
          "Create implementation plan from research findings.",
          "",
          SKILL_REF,
          `  ${DIR_HINT}`,
          `  ${GRILL_HINT}`,
          slug ? `  Slug = ${slug} (explicit)` : "",
          "",
          "Steps:",
          "1. Resolve slug and read <Dir>/{slug}_TASK.md — if missing but GRILL exists, tell user to run /task {slug} first.",
          '2. Call subagent: { agent: "planner", task: "<research findings + context>" }',
          "3. Save subagent output to <Dir>/{slug}_PLAN.md",
          "4. Present plan for review. Do NOT create tickets until user approves.",
        ]
          .filter(Boolean)
          .join("\n"),
      );
    },
  });

  const continueHandler = async (args: string | undefined) => {
    const slug = args?.trim();
    pi.sendUserMessage(
      [
        "Resume the task pipeline. Determine next phase and tell the user the equivalent command — do NOT auto-invoke.",
        "",
        SKILL_REF,
        `  ${DIR_HINT}`,
        `  ${GRILL_HINT}`,
        slug ? `  Slug = ${slug} (explicit)` : "",
        "",
        "Resolve slug, check which files exist (GRILL/TASK/PLAN/context), emit the next-phase suggestion per skill rules.",
      ]
        .filter(Boolean)
        .join("\n"),
    );
  };

  pi.registerCommand("continue", {
    description: "Resume the task pipeline from wherever you left off",
    handler: async (args, _ctx) => continueHandler(args),
  });

  pi.registerCommand("cont", {
    description: "Alias for /continue",
    handler: async (args, _ctx) => continueHandler(args),
  });

  pi.registerCommand("retrieve", {
    description: "List or look up past GRILL/TASK/PLAN combos",
    handler: async (args, _ctx) => {
      const slug = args?.trim();
      pi.sendUserMessage(
        [
          slug
            ? `Retrieve plan info for slug: ${slug}`
            : "List past GRILL/TASK/PLAN combos in the current repo's plans dir.",
          "",
          SKILL_REF,
          `  ${DIR_HINT}`,
          `  ${GRILL_HINT}`,
          "",
          slug
            ? "Check which files exist for this slug, report phase + next command."
            : "Scan Dir, group by slug, report phases + next commands per skill rules.",
          "Do NOT auto-invoke any subagent or slash command.",
        ].join("\n"),
      );
    },
  });

  pi.registerCommand("tickets", {
    description: "Create tickets from the implementation plan",
    handler: async (args, _ctx) => {
      const slug = args?.trim();
      pi.sendUserMessage(
        [
          "Create tickets from the implementation plan.",
          "",
          SKILL_REF,
          `  ${DIR_HINT}`,
          `  ${GRILL_HINT}`,
          slug ? `  Slug = ${slug} (explicit)` : "",
          "",
          "Steps:",
          "1. Resolve slug and read <Dir>/{slug}_PLAN.md — if missing, tell user to run /plan first (or /task {slug} when only GRILL exists).",
          "2. Explore codebase for file hints and verification commands.",
          "3. Seed <Dir>/{slug}.ticket-context.md if missing (see ticket-creator skill).",
          "4. Create one ticket per plan step using ticket-creator skill Mode 3.",
          "5. Self-validate: tk list, tk show each, tk dep cycle, tk ready.",
          "6. Report what was created.",
        ]
          .filter(Boolean)
          .join("\n"),
      );
    },
  });
}
