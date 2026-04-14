/**
 * Task pipeline commands — /task and /plan backed by subagents
 *
 * These commands orchestrate the research → plan → tickets → work pipeline.
 * Research and planning phases use the subagent tool to run in isolated processes
 * with restricted tool access (read-only, no file mutations).
 *
 * The main agent's only job during /task and /plan is:
 *   1. Create/manage worktrees
 *   2. Invoke the subagent tool
 *   3. Save subagent output to plans/*.md files
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("task", {
    description:
      "Research a task using an isolated subagent (read-only, no mutations)",
    handler: async (args, _ctx) => {
      if (!args || !args.trim()) {
        pi.sendUserMessage(
          [
            "Read plans/task.md if it exists and continue research.",
            "If it doesn't exist, tell the user to provide a task description: /task <description>",
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
          "Steps:",
          "1. If plans/task.md already exists, read it first, then pass its contents as context to continue research",
          '2. Call subagent tool: { agent: "researcher", task: "<the research task with all context>" }',
          "3. Save the subagent output to plans/task.md (overwrite if exists)",
          "",
          "The researcher agent runs in isolation — it can read files, search code, and run read-only commands, but CANNOT edit, write, or modify anything.",
          "Its output will be the research findings. Save that output verbatim to the plans file.",
        ].join("\n"),
      );
    },
  });

  pi.registerCommand("plan", {
    description:
      "Create an implementation plan using an isolated subagent (read-only)",
    handler: async (_args, _ctx) => {
      pi.sendUserMessage(
        [
          "Create implementation plan from research findings.",
          "",
          "Use the subagent tool with the 'planner' agent to create an implementation plan.",
          "",
          "Steps:",
          "1. Read plans/task.md (the research findings) — if it doesn't exist, tell the user to run /task first",
          '2. Call subagent tool: { agent: "planner", task: "<the research findings from plans/task.md>" }',
          "3. Save the subagent output to plans/plan.md (overwrite if exists)",
          "",
          "The planner agent runs in isolation — it can read files but CANNOT edit or write anything.",
          "Its output will be the implementation plan. Save that output verbatim to the plans file.",
          "Present the plan to the user for review. Do NOT create tickets until explicitly approved.",
        ].join("\n"),
      );
    },
  });

  pi.registerCommand("tickets", {
    description:
      "Create tickets from the implementation plan using the ticket-creator skill",
    handler: async (_args, _ctx) => {
      pi.sendUserMessage(
        [
          "Create tickets from the implementation plan.",
          "",
          "Steps:",
          "1. Read plans/plan.md — if it doesn't exist, tell the user to run /plan first",
          "2. Explore the codebase for file hints and verification commands",
          "3. Seed plans/.ticket-context.md if it doesn't exist (see context seeding in ticket-creator skill)",
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
