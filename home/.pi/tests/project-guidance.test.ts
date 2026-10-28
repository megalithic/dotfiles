import { afterEach, expect, test } from "bun:test";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import type { BeforeAgentStartEventResult, ExtensionAPI } from "@earendil-works/pi-coding-agent";
import projectGuidance from "../agent/extensions/project-guidance.ts";

type ContextFile = { path: string; content: string };

type PromptEvent = { systemPromptOptions: { cwd: string; contextFiles: ContextFile[] } };

type Handler = (event: PromptEvent) => BeforeAgentStartEventResult | void;

function run(cwd: string) {
  const handlers: Handler[] = [];

  const pi = { on: (name: string, handler: Handler) => {
    expect(name).toBe("before_agent_start");
    handlers.push(handler);
  } };

  // SAFETY: the extension only registers one before_agent_start handler.
  projectGuidance(pi as ExtensionAPI);
  const contextFiles: ContextFile[] = [{ path: path.join(cwd, "AGENTS.md"), content: "repo" }];

  expect(handlers).toHaveLength(1);
  expect(handlers[0]({ systemPromptOptions: { cwd, contextFiles } })).toBeUndefined(); // never forces the prompt

  return contextFiles;
}

function checkout(guidance?: string) {
  const cwd = fs.mkdtempSync(path.join(os.tmpdir(), "pi-project-guidance-"));

  if (guidance !== undefined) {
    fs.mkdirSync(path.join(cwd, ".pi"));
    fs.writeFileSync(path.join(cwd, ".pi/AGENTS.md"), guidance);
  }

  return cwd;
}

afterEach(() => {
  delete process.env.PI_PROJECT_GUIDANCE_DISABLE;
});

test("adds .pi/AGENTS.md after the repo context file", () => {
  const cwd = checkout("generated guidance\n");
  expect(run(cwd)).toEqual([
    { path: path.join(cwd, "AGENTS.md"), content: "repo" },
    { path: path.join(cwd, ".pi/AGENTS.md"), content: "generated guidance\n" },
  ]);
});

test("adds nothing without .pi/AGENTS.md", () => {
  expect(run(checkout())).toHaveLength(1);
});

test("PI_PROJECT_GUIDANCE_DISABLE=1 turns it off", () => {
  process.env.PI_PROJECT_GUIDANCE_DISABLE = "1";
  expect(run(checkout("generated guidance\n"))).toHaveLength(1);
});
