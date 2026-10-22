#!/usr/bin/env bun
/**
 * tmux-golden-layout CLI.
 *
 *   gl event <hook-name> <window-id>   run by the plugin hooks; never fails
 *   gl resume <window-id>              resume a paused window (prefix + =)
 */

import { handleEvent, log, resumeWindow } from "./engine";

const WINDOW_ID = /^@\d+$/;
const [cmd, arg1 = "", arg2 = ""] = process.argv.slice(2);

if (cmd === "event" && WINDOW_ID.test(arg2)) {
  try {
    handleEvent(arg1, arg2);
  } catch (err) {
    // Never propagate failures into tmux from hook context.
    log(`event error: ${err instanceof Error ? (err.stack ?? err.message) : String(err)}`);
  }
} else if (cmd === "resume" && WINDOW_ID.test(arg1)) {
  try {
    resumeWindow(arg1);
  } catch (err) {
    process.stderr.write(`${err instanceof Error ? err.message : String(err)}\n`);
    process.exit(1);
  }
} else {
  process.stderr.write("usage: gl event <hook-name> <window-id> | gl resume <window-id>\n");
  process.exit(2);
}
