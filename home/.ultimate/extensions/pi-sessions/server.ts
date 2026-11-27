import { randomUUID } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { basename, join } from 'node:path';
import { BACKGROUND_CONTEXT } from '@earendil-works/chord/context';
import type { Context } from '@earendil-works/chord/context';
import type { JsonValue } from '@earendil-works/chord/json';
import {
  configure,
  defineDoc,
  defineExtension,
  defineTool,
  hook,
  ROOT_CONVERSATION_ID,
  ToolTask,
} from '@earendil-works/pi-durable';
import type { ConversationDocToken, ConversationId, Harness, Tx } from '@earendil-works/pi-durable';
import { bool, obj, opt, str } from '@earendil-works/pi-schema';
import { deliver } from '../pi-bridge/lib.ts';
import {
  branchOfUltimate,
  checkLand,
  landInput,
  drainHandoffs,
  returnBaton,
  withBatonLock,
  buildSession,
  sessionSections,
  chooseSession,
  dotfilesRoot,
  extractSession,
  framePickup,
  allowedUnderBaton,
  guardDecision,
  inside,
  listWorktrees,
  livePis,
  nearestBaton,
  piStateDir,
  readBaton,
  resolveWorktree,
  run,
  selectPi,
  sessionFiles,
  sessionsTable,
  spill,
  validateSessionFile,
  worktreeBaton,
  writeBaton,
} from './lib.ts';
import type { Baton, Exec, HandoffStore, Pi, Worktree } from './lib.ts';

export const Handoffs = defineDoc<HandoffStore>({
  kind: 'pi-sessions.handoffs',
  checkpointWhen: () => false,
  version: 1,
  scope: 'conversation',
  history: 'latest',
  fork: 'initial',
  initial: () => ({ items: {} }),
});
export const docs = [Handoffs];

/** The parts of Ultimate's core lineage and messages services pickup uses (`extensions/{lineage,messages}/api.ts`). */
type Lineage = {
  branch(
    input: {
      from: ConversationId;
      prompt: string;
      title?: string;
      isolated?: boolean;
      deliver?: false;
      by?: ConversationId;
    },
    ctx: Context,
  ): Promise<{ id: ConversationId }>;
  rootOf(id: ConversationId, ctx: Context): Promise<ConversationId | undefined>;
  leaveNote(to: ConversationId, text: string, source?: { from?: ConversationId }): Promise<unknown>;
};
type Messages = { started(tx: Tx, branch: ConversationId, by: ConversationId): Promise<void> };
type Landing = { submission: string; conversationId: ConversationId; sha: string; target: string; pushed?: string };
const landed = {
  name: 'workspaces.landed',
  kind: 'event.workspaces.landed',
  version: 1,
  is: (event: { kind?: string }) => event?.kind === 'event.workspaces.landed',
};
type Workspaces = {
  adopt(tx: Tx, id: ConversationId, path: string): Promise<unknown>;
  get(id: ConversationId, ctx: Context): Promise<{ path: string; branch: string; external?: true } | undefined>;
};
type Host = {
  react(
    name: string,
    tokens: (typeof landed)[],
    handler: (tx: Tx, event: { data: Landing }) => Promise<void>,
    options: { from: 'now' },
  ): void;
  notice(message: string): void;
  onOpen(callback: () => Promise<void>): void;
  resource<T>(key: string, create: () => T): T;
  projectRoot: string;
  harness(): Harness;
  need<S>(api: { name: string; service?: S }): S;
  system(): Promise<{ process: { url: string } }>;
  /** The core's `ultimate.metadata` document: `{ title?, label? }`, which the sidebar names a conversation by. */
  metadata: ConversationDocToken<{ title?: string; label?: string }>;
  invoke(name: string, action: string, args: JsonValue, signal: AbortSignal): Promise<JsonValue>;
};
type ActionContext = { host: Host; signal: AbortSignal; conversationId?: number; exec: Exec };
type Pickup = {
  cwd: string;
  sessionFile?: string;
  goal?: string;
  force?: boolean;
  land?: boolean;
  from?: { label?: string; sessionId?: string; socket?: string; pid?: number };
};
const pickups = new Set<string>();

function record(args: JsonValue): Record<string, JsonValue | undefined> {
  if (args === null) return {};
  if (typeof args !== 'object' || Array.isArray(args)) throw new Error('Expected an argument object');
  return args;
}
function stringArg(args: Record<string, JsonValue | undefined>, key: string, required = false): string | undefined {
  const value = args[key];
  if (value === undefined && !required) return undefined;
  if (typeof value !== 'string' || !value.trim() || value.includes('\0'))
    throw new Error(`${key} must be a non-empty string without NUL bytes`);
  return value;
}
function conversationId(value: number): ConversationId {
  if (!Number.isSafeInteger(value) || value < 1) throw new Error('Expected a positive conversation id');
  return value as ConversationId;
}
async function cwdFor(host: Host, id: number | undefined, ctx: Context = BACKGROUND_CONTEXT): Promise<string> {
  if (id === undefined) throw new Error('worktree is required outside a conversation');
  // Read every time, never cached: a pickup branch starts at the project root and moves to pi's worktree a commit
  // later, and a cached first read would point the guard and release at the wrong baton.
  const agent = await (await host.harness().conversation(conversationId(id), ctx))?.agent(ctx);
  if (!agent?.cwd) throw new Error(`No cwd for conversation #${id}`);
  return agent.cwd;
}
async function sessionRow(
  args: Record<string, JsonValue | undefined>,
  host: Host,
  exec: Exec,
  caller?: number,
  listed?: Worktree[],
): Promise<Worktree> {
  const sessionId = stringArg(args, 'sessionId');
  const sessionFile = stringArg(args, 'sessionFile');
  let worktree = stringArg(args, 'worktree');
  let file: string | undefined;
  if (sessionFile) {
    file = await validateSessionFile(sessionFile);
    const data = extractSession(await readFile(file, 'utf8'));
    worktree ??= data.cwd;
  }
  const rows = listed ?? (await listWorktrees(host.projectRoot, exec));
  if (sessionId && !worktree)
    worktree = rows.find(
      (row) => row.pis.some((pi) => pi.sessionId === sessionId) || row.sessionFile?.endsWith(`_${sessionId}.jsonl`),
    )?.path;
  // An offline session may not be the newest saved session in its worktree.
  if (sessionId && !worktree) {
    for (const row of rows) {
      const files = await sessionFiles(row.path);
      const match = files.find((path) => path.endsWith(`_${sessionId}.jsonl`));
      if (match) {
        worktree = row.path;
        file = match;
        break;
      }
    }
    if (!worktree) throw new Error(`No pi session ${sessionId} in this project`);
  }
  const path = await resolveWorktree(host.projectRoot, worktree || (await cwdFor(host, caller)), exec);
  const row = rows.find((item) => item.path === path);
  if (!row) throw new Error(`No pi session worktree ${path}`);
  if (sessionId && !file) {
    const chosen = await chooseSession(
      [
        ...new Set([
          ...(await sessionFiles(path)),
          ...(await Promise.all(row.pis.map((pi) => sessionFiles(pi.cwd)))).flat(),
        ]),
      ],
      sessionId,
    );
    if (!chosen?.sessionFile.endsWith(`_${sessionId}.jsonl`)) throw new Error(`No saved pi session ${sessionId}`);
    file = chosen.sessionFile;
  }
  if (file) {
    const data = extractSession(await readFile(file, 'utf8'));
    if (!data.cwd || !inside(path, data.cwd)) throw new Error('Session cwd does not belong to the selected worktree');
    row.sessionFile = file;
  }
  return row;
}
function parsePickup(args: JsonValue): Pickup {
  const input = record(args);
  const cwd = stringArg(input, 'cwd', true)!;
  if (input.force !== undefined && typeof input.force !== 'boolean') throw new Error('force must be a boolean');
  if (input.land !== undefined && typeof input.land !== 'boolean') throw new Error('land must be a boolean');
  const from = input.from === undefined ? undefined : record(input.from);
  if (from?.pid !== undefined && (typeof from.pid !== 'number' || !Number.isSafeInteger(from.pid) || from.pid < 1))
    throw new Error('from.pid must be a positive integer');
  return {
    cwd,
    sessionFile: stringArg(input, 'sessionFile'),
    goal: stringArg(input, 'goal'),
    force: input.force as boolean | undefined,
    land: input.land as boolean | undefined,
    from: from
      ? {
          label: stringArg(from, 'label'),
          sessionId: stringArg(from, 'sessionId'),
          socket: stringArg(from, 'socket'),
          pid: from.pid as number | undefined,
        }
      : undefined,
  };
}
async function currentUrl(host: Host): Promise<string> {
  // This process's own URL: a supervised host and an unsupervised preview both report it here.
  const url = (await host.system()).process.url;
  if (!url) throw new Error('This Ultimate instance has no URL');
  return url.replace(/\/$/, '');
}
async function pickup(input: Pickup, host: Host, exec: Exec, signal: AbortSignal, label: string) {
  const worktree = await resolveWorktree(host.projectRoot, input.cwd, exec);
  if (pickups.has(worktree)) throw new Error(`A pickup is already in progress for ${worktree}`);
  pickups.add(worktree);
  try {
    if (input.land) await checkLand(worktree, exec);
    const [rows, previous] = await Promise.all([listWorktrees(host.projectRoot, exec), readBaton(worktree)]);
    const local = rows.find((row) => row.path === worktree)?.pis ?? [];
    const working = local.find((pi) => pi.state === 'working' && pi.sessionId !== input.from?.sessionId);
    if (working)
      throw new Error(`pi ${working.label} (pid ${working.pid}) is working; wait for it or hand off from that pi`);
    if (previous?.holder === 'ultimate' && !input.force)
      throw new Error(
        `Ultimate #${previous.ultimate?.conversation ?? '?'} at ${previous.ultimate?.url ?? 'unknown URL'} already holds the baton; use force to take it`,
      );
    const row = await sessionRow(
      {
        worktree,
        ...(input.sessionFile ? { sessionFile: input.sessionFile } : {}),
        ...(input.from?.sessionId && !input.sessionFile ? { sessionId: input.from.sessionId } : {}),
      },
      host,
      exec,
      undefined,
      rows,
    );
    const [brief, goal, url] = await Promise.all([
      buildSession(row, exec).then((brief) => spill(brief)),
      // Without a goal, Seth drives the conversation: it must wait for him instead of releasing at once.
      spill(
        input.goal ||
          (input.land
            ? 'Land the committed worktree.'
            : 'None given. Summarize where pi stopped and ask Seth what to do next; release only when he asks or the work is done.'),
      ),
      currentUrl(host),
    ]);
    const framing = framePickup(input.from?.label || label, worktree);
    // A branch of the project's standing @ultimate, as its `branch` tool starts one: it shows in flight, and its reports
    // and answers wake @ultimate. Not isolated: it works in pi's own worktree.
    const lineage = host.need<Lineage>({ name: 'lineage' });
    const messages = host.need<Messages>({ name: 'messages' });
    const branched = await branchOfUltimate(
      {
        standing: async () => (await host.invoke('subagents', 'standing', { name: 'ultimate' }, signal)) as number,
        roots: async () => ((await host.invoke('lineage', 'info', null, signal)) as { roots: number[] }).roots,
        rootOf: (id) => lineage.rootOf(conversationId(id), BACKGROUND_CONTEXT),
        branch: (branch) =>
          lineage.branch(
            { ...branch, from: conversationId(branch.from), by: conversationId(branch.by) },
            BACKGROUND_CONTEXT,
          ),
      },
      input.land
        ? landInput(framing, worktree, goal, '')
        : `${framing}\n\nPick up pi's work in ${worktree}. Goal: ${goal}`,
      // Until its summary names it by its work; the `pi` label marks it.
      `Pick up pi in ${basename(worktree)}`,
    );
    const id = conversationId(branched.id);
    const ultimate = conversationId(branched.ultimate);
    const origin =
      local.find((pi) => pi.sessionId === input.from?.sessionId) || local.find((pi) => pi.rex?.block) || local[0];
    const baton: Baton = {
      v: 1,
      holder: 'ultimate',
      worktree,
      at: new Date().toISOString(),
      by: 'pickup',
      ultimate: { url, project: host.projectRoot, conversation: id },
      pi: {
        sessionId: input.from?.sessionId || origin?.sessionId,
        pid: input.from?.pid || origin?.pid,
        label: input.from?.label || origin?.label,
      },
    };
    await withBatonLock(worktree, () => writeBaton(baton));
    const harness = host.harness();
    const conversation = await harness.conversation(id, BACKGROUND_CONTEXT);
    if (!conversation) throw new Error(`Created #${id}, but it is unavailable; baton names it at ${url}`);
    const content = input.land
      ? landInput(framing, worktree, goal, brief)
      : `${framing}\n\nYou picked up this rex worktree from pi and hold its baton (pi cannot edit/write/bash until you release). Work in ${worktree} directly; pi's uncommitted work is there. Never workspace submit or push. When the goal is done, or Seth asks, finish with release and a summary for pi. You are a branch of @ultimate: your reports and answers reach it, and it weighs in on your decisions before you ask Seth them as a reply-expected message with questions.\n\nGoal: ${goal}\n\n${brief}`;
    await harness.commit(async (tx) => {
      if (input.land) await host.need<Workspaces>({ name: 'workspaces' }).adopt(tx, id, worktree);
      else await configure(tx, id, { cwd: worktree });
      (await tx.doc(host.metadata, id)).label = 'pi';
      await messages.started(tx, id, ultimate);
      await conversation.submit(tx, { type: 'input', content, whenBusy: 'followUp' });
    }, BACKGROUND_CONTEXT);
    await lineage.leaveNote(
      ultimate,
      `Picked up pi worktree ${worktree} into branch #${id}: ${url}/?conversation=${id}. It holds the baton and will release back to pi; its answers reach you.`,
      { from: id },
    );
    return { conversation: id, url: `${url}/?conversation=${id}`, worktree, baton };
  } finally {
    pickups.delete(worktree);
  }
}
async function tellPi(pi: Pi, text: string, host: Host, caller?: number, suffix = '') {
  return deliver(
    { label: pi.label || pi.sessionId || String(pi.pid), sessionId: pi.sessionId, socket: pi.socket },
    {
      type: 'tell',
      id: `tell-${randomUUID()}`,
      text: `${await spill(text)}${suffix}`,
      from: `@ultimate (${basename(host.projectRoot)}) #${caller ?? '?'}`,
      mode: 'follow_up',
    },
    piStateDir(),
  );
}
async function release(
  args: Record<string, JsonValue | undefined>,
  host: Host,
  exec: Exec,
  caller?: number,
  expect?: { conversation: number },
) {
  const worktree = await resolveWorktree(
    host.projectRoot,
    stringArg(args, 'worktree') || (await cwdFor(host, caller)),
    exec,
  );
  const { baton, moved } = await returnBaton(worktree, expect);
  if (!moved) return { worktree, baton, skipped: true };
  const summary = stringArg(args, 'text') || 'Continue your work in this worktree.';
  const text = `From @ultimate #${caller ?? baton?.ultimate?.conversation ?? '?'} (${basename(host.projectRoot)}): Ultimate handed this worktree back to you; you hold the baton again.\n\n${summary}`;
  return { worktree, baton, ...(await deliverWorktree(worktree, text, host, exec, caller)) };
}
async function deliverWorktree(worktree: string, text: string, host: Host, exec: Exec, caller?: number) {
  const previous = await readBaton(worktree);
  const pis = (await listWorktrees(host.projectRoot, exec)).find((row) => row.path === worktree)?.pis ?? [];
  const pi =
    pis.find((item) => item.sessionId === previous?.pi?.sessionId) || pis.find((item) => item.rex?.block) || pis[0];
  if (pi) return tellPi(pi, text, host, caller);
  const result = await exec(join(dotfilesRoot(), 'bin', 'rwt'), [
    'agent',
    worktree,
    '--prompt',
    await spill(text),
    '--json',
  ]);
  return { delivered: 'rwt', result: result.stdout.trim() };
}

export const userActions = ['pickup'];
export const actions = {
  async sessions(_args: JsonValue, { host, exec }: ActionContext) {
    return listWorktrees(host.projectRoot, exec);
  },
  async session(args: JsonValue, { host, exec, conversationId: caller }: ActionContext) {
    return { sections: await sessionSections(await sessionRow(record(args), host, exec, caller), exec) };
  },
  async pickup(args: JsonValue, { host, exec, signal }: ActionContext) {
    return pickup(parsePickup(args), host, exec, signal, 'web UI');
  },
  async release(args: JsonValue, { host, exec, conversationId: caller }: ActionContext) {
    return release(record(args), host, exec, caller);
  },
  async baton(args: JsonValue, { host, exec, conversationId: caller }: ActionContext) {
    const input = record(args);
    const id = input.conversation;
    if (id !== undefined && typeof id !== 'number') throw new Error('conversation must be a number');
    return worktreeBaton(host.projectRoot, stringArg(input, 'worktree') || (await cwdFor(host, id ?? caller)), exec);
  },
};

const output = (value: unknown) => ({
  output: [{ type: 'text' as const, text: typeof value === 'string' ? value : JSON.stringify(value) }],
});
export default function piSessions(host: Host) {
  // Reload-stable: an old facet's drain and its replacement's share one chain, so they never deliver concurrently.
  const queue = host.resource('pi-sessions.handoff-drain', () => ({ draining: Promise.resolve() }));
  const drain = () => {
    queue.draining = queue.draining
      .then(() =>
        drainHandoffs({
          pending: async () =>
            structuredClone(
              (await host.harness().snapshot(Handoffs, ROOT_CONVERSATION_ID, BACKGROUND_CONTEXT))?.items ?? {},
            ),
          returnBaton,
          batonDone: async (submission) => {
            await host.harness().commit(async (tx) => {
              const item = (await tx.doc(Handoffs, ROOT_CONVERSATION_ID)).items[submission];
              if (item) item.batonDone = true;
            }, BACKGROUND_CONTEXT);
          },
          deliver: (item, text) => deliverWorktree(item.worktree, text, host, run, item.conversationId),
          remove: async (submission) => {
            await host.harness().commit(async (tx) => {
              delete (await tx.doc(Handoffs, ROOT_CONVERSATION_ID)).items[submission];
            }, BACKGROUND_CONTEXT);
          },
          notice: (message) => host.notice(message),
        }),
      )
      .catch((error: unknown) => host.notice(`Landed worktree handoff drain failed: ${String(error)}`));
    return queue.draining;
  };
  host.onOpen(drain);
  host.react(
    'return-landed-baton',
    [landed],
    async (tx, { data }) => {
      const workspace = await host
        .need<Workspaces>({ name: 'workspaces' })
        .get(data.conversationId, BACKGROUND_CONTEXT);
      if (workspace?.external) {
        const baton = await readBaton(workspace.path);
        if (baton?.holder === 'ultimate' && baton.ultimate?.conversation === data.conversationId) {
          const state = await tx.doc(Handoffs, ROOT_CONVERSATION_ID);
          state.items[data.submission] ??= {
            conversationId: data.conversationId,
            worktree: workspace.path,
            branch: workspace.branch,
            sha: data.sha,
            target: data.target,
            batonDone: false,
          };
          if (data.pushed) state.items[data.submission].pushed = data.pushed;
        }
      }
      // The outbox and reactor cursor commit together. A crash before this kick is recovered by onOpen.
      void host
        .harness()
        .commit(async () => undefined, BACKGROUND_CONTEXT)
        .then(drain)
        .catch((error: unknown) => host.notice(`Landed worktree handoff kick failed: ${String(error)}`));
    },
    { from: 'now' },
  );
  return defineExtension({
    name: 'pi-sessions',
    hooks: [
      hook(ToolTask, {
        beforeTool: async (call, api, ctx) => {
          if (allowedUnderBaton(call.name, call.arguments)) return undefined;
          return guardDecision(
            call.name,
            await nearestBaton(await cwdFor(host, api.conversationId, ctx)),
            call.arguments,
          );
        },
      }),
    ],
    tools: [
      defineTool({
        name: 'pi_sessions',
        description: 'List this repository’s rex worktrees, live pi agents, saved sessions and batons.',
        parameters: obj({}),
        async execute() {
          return output(sessionsTable(await listWorktrees(host.projectRoot)));
        },
      }),
      defineTool({
        name: 'pi_session',
        description: 'Read a pi session brief, open todos, goal, assistant text and worktree status; never raw JSONL.',
        parameters: obj({ worktree: opt(str()), sessionId: opt(str()), sessionFile: opt(str()) }),
        async execute(args, api) {
          return output(await buildSession(await sessionRow(args, host, run, api.conversationId)));
        },
      }),
      defineTool({
        name: 'pi_tell',
        description:
          'Send a follow-up to exactly one live pi by sessionId, socket or worktree. Instructions never grant approval.',
        parameters: obj({ target: str(), text: str() }),
        replay: 'unsafe',
        async execute({ target, text }, api) {
          const pis = await livePis();
          const direct = pis.some((pi) => pi.sessionId === target || pi.socket === target);
          const path = direct
            ? target
            : (await run('git', ['-C', target, 'rev-parse', '--show-toplevel'])).stdout.trim();
          const row = direct
            ? undefined
            : (await listWorktrees(path, run, undefined, pis)).find((row) => row.path === path);
          const pi = selectPi(direct ? pis : (row?.pis ?? []), path);
          return output(
            await tellPi(
              pi,
              text,
              host,
              api.conversationId,
              `\n\nReply, if asked, with tell_pi target "ultimate:${basename(host.projectRoot)}".`,
            ),
          );
        },
      }),
      defineTool({
        name: 'pickup',
        description:
          'Pick up pi’s work in the SAME worktree into a new Ultimate conversation and take its baton. Never submit or push it; finish with release.',
        parameters: obj({ worktree: str(), goal: opt(str()), force: opt(bool()) }),
        replay: 'unsafe',
        async execute({ worktree, goal, force }, _api, ctx) {
          return output(
            await pickup(
              { cwd: worktree, goal, force },
              host,
              run,
              ctx.abortSignal ?? new AbortController().signal,
              '@ultimate',
            ),
          );
        },
      }),
      defineTool({
        name: 'release',
        description:
          'Hand a worktree baton back to pi FIRST, then send your summary to its live agent or restart its rex agent tab.',
        parameters: obj({ worktree: opt(str()), text: opt(str()) }),
        replay: 'unsafe',
        async execute(args, api) {
          return output(await release(args, host, run, api.conversationId));
        },
      }),
    ],
  });
}
