import { defineExtension } from '@earendil-works/pi-durable';
import { homedir } from 'node:os';
import { join } from 'node:path';

type Exec = (command: string, args: string[], options?: { timeout?: number }) => Promise<{ stdout: string }>;
type ActionContext = { exec: Exec };

/** The shown conversation's worktree PR from `rwt pr` (cached 60 s there), or null. */
async function pr(_args: unknown, { exec }: ActionContext) {
  try {
    const { stdout } = await exec(join(homedir(), 'bin', 'rwt'), ['pr', '.'], { timeout: 10_000 });
    return (JSON.parse(stdout) as { pr: unknown }).pr ?? null;
  } catch {
    // Not a git checkout, no gh, offline with nothing cached: no chip.
    return null;
  }
}

export const actions = { pr };
export const pollActions = ['pr'];
export default defineExtension({ name: 'pr-status' });
