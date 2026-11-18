import { BACKGROUND_CONTEXT as context } from '@earendil-works/chord/context';
import { defineDoc, defineExtension, ROOT_CONVERSATION_ID } from '@earendil-works/pi-durable';
import type { Harness } from '@earendil-works/pi-durable';
import { addGate, confirmGate, DOCUMENT, initial, order, parseWorktrees, record, removeGate } from './lib.ts';
import type { Gates, GhPull, List } from './lib.ts';

type ActionContext = {
  host: { harness(): Harness; projectRoot: string };
  conversationId?: number;
  exec(command: string, args: string[], options?: { cwd?: string; timeout?: number }): Promise<{ stdout: string }>;
};

export const GatesDoc = defineDoc<Gates>({
  kind: DOCUMENT,
  checkpointWhen: () => false,
  version: 1,
  scope: 'conversation',
  history: 'latest',
  fork: 'initial',
  initial,
});
export const docs = [GatesDoc];

export default defineExtension({ name: 'spp-prs' });

const fields = [
  'number',
  'title',
  'url',
  'isDraft',
  'baseRefName',
  'headRefName',
  'headRefOid',
  'reviewDecision',
  'mergeStateStatus',
  'statusCheckRollup',
].join(',');

/** Read-only: one `gh pr list` and one `git worktree list`; nothing on GitHub or in the checkout changes. */
async function list(_args: unknown, { exec, host }: ActionContext): Promise<List> {
  let pulls: GhPull[];
  try {
    const { stdout } = await exec(
      'gh',
      ['pr', 'list', '--author', '@me', '--state', 'open', '--limit', '100', '--json', fields],
      {
        cwd: host.projectRoot,
      },
    );
    pulls = JSON.parse(stdout) as GhPull[];
  } catch (error) {
    const { code, stderr } = error as { code?: string; stderr?: string };
    if (code === 'ENOENT') return { status: 'setup', reason: 'gh is not on the PATH of this Ultimate.' };
    if (stderr?.includes('auth login')) return { status: 'setup', reason: 'gh is signed out: run `gh auth login`.' };
    throw error;
  }
  const trees = await exec('git', ['worktree', 'list', '--porcelain'], { cwd: host.projectRoot }).then(
    ({ stdout }) => parseWorktrees(stdout),
    // Rows without conversation links beat no rows.
    () => [],
  );
  return { status: 'ok', at: Date.now(), rows: order(pulls, trees) };
}

const change = <T>(host: ActionContext['host'], edit: (state: Gates) => T) =>
  host.harness().commit(async (tx) => edit(await tx.doc(GatesDoc, ROOT_CONVERSATION_ID)), context);

/** Only the panel confirms or removes a gate; agents may add them. */
export const userActions = ['confirmGate', 'removeGate'];
export const actions = {
  list,
  addGate: (args: unknown, { host, conversationId }: ActionContext) =>
    change(host, (state) => addGate(state, args, conversationId, Date.now())),
  confirmGate: (args: unknown, { host }: ActionContext) =>
    change(host, (state) => confirmGate(state, record(args).id, Date.now())),
  removeGate: (args: unknown, { host }: ActionContext) => change(host, (state) => removeGate(state, record(args).id)),
};
