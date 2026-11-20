/**
 * /review-pr <n|url>: the repo's Ultimate reviews a pull request with its reviewer team and replies with a
 * verdict and a draft over the pi-bridge. Seth revises the draft (ask pi, or /review-pr edit), and only
 * /review-pr post, after his pick in a menu, posts it with `gh pr review`. Pi's own gh calls on a PR with a
 * pending draft are blocked, so nothing reaches GitHub without that pick.
 */
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { Check } from 'typebox/value';
import { readRegistry } from '../lib/registry.ts';
import { containingUltimate, registryTargets } from '../lib/tell-targets.ts';
import { originInfo, tellUltimate } from '../lib/tell-transport.ts';

const reviewSchema = Type.Object({
  key: Type.String(),
  repo: Type.String(),
  number: Type.Integer(),
  title: Type.String(),
  head: Type.String(),
  url: Type.String(),
  draft: Type.String(),
  verdict: Type.Optional(Type.Union([Type.Literal('APPROVED'), Type.Literal('NEEDS CHANGES')])),
});

export type Review = Type.Static<typeof reviewSchema>;

const stateFile = () =>
  path.join(
    process.env.PI_STATE_DIR || path.join(process.env.XDG_STATE_HOME || path.join(os.homedir(), '.local/state'), 'pi'),
    'review-pr.json',
  );

export const readReviews = (file = stateFile()): Review[] => {
  try {
    const value: unknown = JSON.parse(fs.readFileSync(file, 'utf8'));

    return Array.isArray(value) ? value.filter((item): item is Review => Check(reviewSchema, item)) : [];
  } catch {
    return [];
  }
};

const writeReviews = (reviews: Review[], file = stateFile()) => {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const temporary = `${file}.${process.pid}.tmp`;
  fs.writeFileSync(temporary, `${JSON.stringify(reviews, null, 2)}\n`, { mode: 0o600 });
  fs.renameSync(temporary, file);
};

/** Words that must never reach Strive's PR text: the harness, its agents, and conversation numbers. */
const HARNESS = /\b(ultimate|pi|claude|codex|subagents?|reviewer-[a-z]+|coding agents?|ai agents?)\b|#\d{5,}/gi;

export const harnessMentions = (text: string): string[] => [
  ...new Set([...text.matchAll(HARNESS)].map((match) => match[0])),
];

/** Ultimate's reply: a `Verdict:` line, the team report, then the draft after a line that says `DRAFT:`. */
export const parseReply = (text: string) => {
  const found = /^\s*Verdict:\s*(APPROVED|NEEDS CHANGES)\b/im.exec(text)?.[1];
  const verdict: Review['verdict'] = found === 'APPROVED' || found === 'NEEDS CHANGES' ? found : undefined;
  const marker = /^DRAFT:\s*$/m.exec(text);
  const draft = marker ? text.slice(marker.index + marker[0].length).trim() : '';

  return { verdict, draft: draft || undefined };
};

export const requestText = (review: Pick<Review, 'repo' | 'number' | 'title' | 'head' | 'url'>, cwd: string) =>
  [
    `Review pull request ${review.repo}#${review.number} ("${review.title}"), ${review.url}, at head ${review.head}, for Seth's pi in ${cwd}.`,
    "Start one branch for it (skip this if one already runs for the same PR and head). It checks out the head detached in its own worktree, runs `reviewer` on `<merge base with the PR's base branch>..<head>` so the project's reviewer team reviews it read-only, and drafts the review comment for the PR author. It never comments, reviews, approves or pushes on GitHub: Seth posts from pi.",
    'The draft opens with what blocks merge, then what is good to have, then the rest; no greeting, thanks or praise; one bullet per item with `path:line`; it never mentions Ultimate, pi, Claude, agents, reviewers by name or conversation numbers, and it is written as Seth.',
    'When the branch finishes, answer with reply_pi: a line `Verdict: APPROVED` or `Verdict: NEEDS CHANGES`, the merged team report, then a line containing only `DRAFT:`, then the draft and nothing after it.',
  ].join('\n\n');

export const reviewArgs = (action: Action, review: Pick<Review, 'repo' | 'number'>, file: string) => [
  'pr',
  'review',
  String(review.number),
  '--repo',
  review.repo,
  { comment: '--comment', 'request changes': '--request-changes', approve: '--approve' }[action],
  '--body-file',
  file,
];

type Action = 'comment' | 'request changes' | 'approve';

export const actionsFor = (verdict: Review['verdict']): Action[] =>
  verdict === 'APPROVED' ? ['comment', 'request changes', 'approve'] : ['comment', 'request changes'];

/**
 * While any review draft is pending, pi's own gh posting commands are blocked whatever their flags, order or
 * target (an implicit PR, a URL, another repo): only /review-pr post posts. A guard against slips, not a sandbox.
 */
/** Shell words per simple command: quotes group, unquoted `;`, `&`, `|`, newlines and `$(`/backticks split. */
export const shellCommands = (command: string): string[][] => {
  const commands: string[][] = [[]];
  let word: string | undefined;
  let quote: string | undefined;

  const end = () => {
    if (word !== undefined) commands.at(-1)?.push(word);
    word = undefined;
  };

  for (let index = 0; index < command.length; index += 1) {
    const char = command.charAt(index);

    if (char === '\\' && command.charAt(index + 1) === '\n' && quote !== "'") {
      index += 1; // a line continuation joins the lines: no character, no word break
    } else if (quote) {
      if (char === quote) quote = undefined;
      else if (char === '\\' && quote === '"') word += command.charAt((index += 1));
      else word += char;
    } else if (char === "'" || char === '"') {
      quote = char;
      word ??= '';
    } else if (char === '$' && command.charAt(index + 1) === "'") {
      quote = "'"; // $'…' (escapes inside are not decoded; enough to see plain words)
      word ??= '';
      index += 1;
    } else if (char === '\\') {
      word = (word ?? '') + command.charAt((index += 1));
    } else if (/[;&|\n`()]/.test(char)) {
      end();
      commands.push([]);
    } else if (/\s/.test(char)) {
      end();
    } else {
      word = (word ?? '') + char;
    }
  }

  end();

  return commands.filter((words) => words.length);
};

const GH_VALUE_FLAGS = new Set(['-R', '--repo', '--hostname']);

const API_POSTING = /\/(?:reviews|comments)\b|addPullRequestReview|addComment|submitPullRequestReview/;

/**
 * Every way `words` could run gh: the arguments after each `gh` word. Wrappers (`env`, `command --`, `mise exec … --`,
 * `nice`, `xargs`, `sudo`, absolute paths) are not enumerated, so none can hide it; a `gh` that is only an argument
 * (`echo gh pr review`) also counts, which merely blocks while a draft is pending.
 */
const ghCalls = (words: string[]): string[][] =>
  words.flatMap((word, index) => (/(?:^|\/)gh$/.test(word) ? [words.slice(index + 1)] : []));

/** An inline read-only GraphQL query (`-f query='{ … }'` or `query Name { … }`), never a file, stdin or mutation. */
const READ_ONLY_QUERY = /^(?:-[fF]|--(?:raw-)?field=)?query=\s*(?:\{|query\b)/;

/**
 * True for a `gh pr review|comment` or a `gh api` call to a review or comment endpoint, whatever its flags or wrappers.
 * A `gh api graphql` call counts too unless its query is an inline read-only one: a file, stdin or mutation body can
 * post without naming an endpoint, so it fails closed.
 */
export const ghPosts = (words: string[]): boolean => ghCalls(words).some(ghCallPosts);

const ghCallPosts = (rest: string[]): boolean => {
  const subcommands = rest.filter((word, index) => !word.startsWith('-') && !GH_VALUE_FLAGS.has(rest[index - 1] ?? ''));

  if (subcommands[0] === 'pr') return ['review', 'comment'].includes(subcommands[1] ?? '');

  if (subcommands[0] !== 'api') return false;

  if (rest.some((word) => API_POSTING.test(word))) return true;

  if (!subcommands.includes('graphql')) return false;

  return (
    rest.some((word) => word === '--input' || word.startsWith('--input=') || /=@|\bmutation\b/.test(word)) ||
    !rest.some((word) => READ_ONLY_QUERY.test(word))
  );
};

/** Bodies of `$(…)` and backtick substitutions outside single quotes: they run even inside double quotes. */
export const substitutions = (command: string): string[] => {
  const bodies: string[] = [];

  /** Scans from `start` until an unquoted `)` closes a `$(` (when `nested`); returns that index. */
  const scan = (start: number, nested: boolean): number => {
    let quote: string | undefined;
    let depth = 0;

    for (let index = start; index < command.length; index += 1) {
      const char = command.charAt(index);

      if (quote === "'") {
        if (char === "'") quote = undefined;
      } else if (char === '\\') index += 1;
      else if (char === '"') quote = quote ? undefined : '"';
      else if (char === "'" && !quote) quote = "'";
      else if (char === '`') {
        const close = command.indexOf('`', index + 1);
        const stop = close < 0 ? command.length : close;

        bodies.push(command.slice(index + 1, stop));
        index = stop;
      } else if (char === '$' && command.charAt(index + 1) === '(') {
        const stop = scan(index + 2, true);

        bodies.push(command.slice(index + 2, stop));
        index = stop;
      } else if (nested && !quote && char === '(') depth += 1;
      else if (nested && !quote && char === ')' && (depth -= 1) < 0) return index;
    }

    return command.length;
  };

  scan(0, false);

  return bodies;
};

/** Strings a shell runs as code: `eval …` and the argument after `-c` of a shell (`bash -c`, `sh -lc`, `zsh -c`). */
const SHELL = /(?:^|\/)(?:ba|z|da|k|fi)?sh$/;

const nestedScripts = (words: string[]): string[] =>
  words.flatMap((word, index) => {
    if (word === 'eval') return [words.slice(index + 1).join(' ')];

    return /^-\w*c\w*$/.test(word) && words.slice(0, index).some((w) => SHELL.test(w))
      ? words.slice(index + 1, index + 2)
      : [];
  });

const posts = (command: string): boolean =>
  shellCommands(command).some((words) => ghPosts(words) || nestedScripts(words).some(posts)) ||
  substitutions(command).some(posts);

export const blockedPost = (command: string, reviews: Review[]): boolean => reviews.length > 0 && posts(command);

/** `owner/repo` of a pull request URL. */
export const urlRepo = (url: string) => /github\.com\/([^/]+\/[^/]+)\/pull\/\d+/.exec(url)?.[1];

const prSchema = Type.Object({
  number: Type.Integer(),
  title: Type.String(),
  headRefOid: Type.String(),
  url: Type.String(),
});

export default function (pi: ExtensionAPI) {
  const gh = async (args: string[], cwd: string) => {
    const result = await pi.exec('gh', args, { cwd, timeout: 60_000 });

    if (result.code !== 0) throw new Error(`gh ${args.slice(0, 2).join(' ')} failed: ${result.stderr.trim()}`);

    return result.stdout;
  };

  const docsDir = (repo: string) => path.join(os.homedir(), '.local/share/pi/docs', path.basename(repo));

  const showStatus = (ctx: ExtensionContext) => {
    const waiting = readReviews().filter((review) => !review.verdict);
    ctx.ui.setStatus(
      'review-pr',
      waiting.length ? `Waiting for review of ${waiting.map((review) => `#${review.number}`).join(', ')}` : undefined,
    );
  };

  const pick = async (ctx: ExtensionContext, arg: string): Promise<Review | undefined> => {
    const reviews = readReviews().filter((review) => review.verdict);
    const number = Number(arg.replace(/.*\/pull\//, ''));
    const found = arg ? reviews.filter((review) => review.number === number) : reviews;

    if (!found.length) {
      ctx.ui.notify(arg ? `No review draft for #${arg}.` : 'No review draft yet.', 'error');

      return undefined;
    }

    if (found.length === 1) return found[0];
    const label = (review: Review) => `${review.repo}#${review.number} ${review.title}`;
    const choice = await ctx.ui.select('Which review?', found.map(label));

    return found.find((review) => label(review) === choice);
  };

  const request = async (ctx: ExtensionContext, arg: string) => {
    const target = containingUltimate(registryTargets(readRegistry()), ctx.cwd);

    if (!target) throw new Error(`No Ultimate runs for ${ctx.cwd}. Review locally with /code-review ${arg}.`);
    const pr = JSON.parse(await gh(['pr', 'view', arg, '--json', 'number,title,headRefOid,url'], ctx.cwd));

    if (!Check(prSchema, pr)) throw new Error('gh pr view returned an unexpected shape');
    const repo = urlRepo(pr.url);
    const local = (await gh(['repo', 'view', '--json', 'nameWithOwner', '-q', '.nameWithOwner'], ctx.cwd)).trim();

    if (!repo || repo.toLowerCase() !== local.toLowerCase())
      throw new Error(`${pr.url} is not a pull request of ${local}, the repo this Ultimate reviews.`);
    const key = `review-pr-${pr.number}-${pr.headRefOid.slice(0, 12)}-${Date.now().toString(36)}`;
    const draft = path.join(docsDir(ctx.cwd), `${repo.replace('/', '-')}-pr-${pr.number}-review.md`);

    const review: Review = {
      key,
      repo,
      number: pr.number,
      title: pr.title,
      head: pr.headRefOid,
      url: pr.url,
      draft,
    };

    await tellUltimate(target, requestText(review, ctx.cwd), true, originInfo(ctx), key);
    writeReviews([
      ...readReviews().filter((item) => !(item.repo === review.repo && item.number === review.number)),
      review,
    ]);
    showStatus(ctx);
    ctx.ui.notify(`Ultimate is reviewing #${pr.number}; the result arrives here when it is done.`, 'info');
  };

  const post = async (ctx: ExtensionContext, review: Review) => {
    const text = fs.readFileSync(review.draft, 'utf8').trim();

    if (!text) throw new Error(`${review.draft} is empty.`);
    const mentions = harnessMentions(text);

    if (mentions.length)
      throw new Error(`Not posted: the draft mentions ${mentions.join(', ')}. Edit it with /review-pr edit.`);

    const actions = actionsFor(review.verdict);
    const choice = await ctx.ui.select(`Post this review to #${review.number}?\n\n${text}`, [...actions, 'cancel']);
    const action = actions.find((item) => item === choice);

    if (!action) return ctx.ui.notify('Not posted.', 'info');

    if (
      action === 'approve' &&
      !(await ctx.ui.confirm(`Approve PR #${review.number} as yourself?`, `${review.title}\n${review.url}`))
    )
      return ctx.ui.notify('Not posted.', 'info');

    // Post exactly the text that was checked and shown, never the draft file, which may change meanwhile.
    const snapshot = fs.mkdtempSync(path.join(os.tmpdir(), 'review-pr-'));
    const body = path.join(snapshot, 'body.md');

    try {
      fs.writeFileSync(body, `${text}\n`, { mode: 0o600 });
      await gh(reviewArgs(action, review, body), ctx.cwd);
    } finally {
      fs.rmSync(snapshot, { recursive: true, force: true });
    }

    writeReviews(readReviews().filter((item) => item.key !== review.key));
    showStatus(ctx);
    ctx.ui.notify(`Posted: ${action} on #${review.number}.`, 'info');
  };

  let current: ExtensionContext | undefined;

  pi.on('session_start', (_event, ctx) => {
    current = ctx;
    showStatus(ctx);
  });

  // The bridge emits every reply before delivering it as a follow-up, so pi also reads and summarises it.
  pi.events.on('tell:reply', (data) => {
    if (!Check(Type.Object({ replyTo: Type.String(), text: Type.String() }), data)) return;
    const reviews = readReviews();
    const review = reviews.find((item) => item.key === data.replyTo);

    // A redelivered reply never overwrites a draft Seth may already have edited.
    if (!review || review.verdict) return;
    const { verdict, draft } = parseReply(data.text);
    fs.mkdirSync(path.dirname(review.draft), { recursive: true });
    fs.writeFileSync(review.draft, `${draft ?? data.text.trim()}\n`);
    writeReviews(
      reviews.map((item) => (item.key === review.key ? { ...item, verdict: verdict ?? 'NEEDS CHANGES' } : item)),
    );

    if (current) showStatus(current);
  });

  pi.on('before_agent_start', (event) => {
    const ready = readReviews().filter((review) => review.verdict);

    if (!ready.length) return;
    event.systemPromptOptions.contextFiles.push({
      path: 'review-pr',
      content: `Pull request review drafts: ${ready.map((review) => `#${review.number} in ${review.draft}`).join('; ')}. Revise a draft by editing that file when Seth asks. Never post it yourself: Seth posts with /review-pr post; gh pr review/comment and gh api review or comment calls are blocked while drafts are pending.`,
    });
  });

  pi.on('tool_call', (event) => {
    if (!['bash', 'interactive_shell'].includes(event.toolName)) return;
    const command = Check(Type.Object({ command: Type.String() }), event.input) ? event.input.command : '';
    const reviews = readReviews();

    if (blockedPost(command, reviews))
      return {
        block: true,
        reason: `Review drafts are pending (${reviews.map((review) => `${review.repo}#${review.number}`).join(', ')}): only Seth posts to GitHub, with /review-pr post. Edit the draft file instead.`,
      };
  });

  pi.registerCommand('review-pr', {
    description: 'Have the repo’s Ultimate review a PR: /review-pr <n|url>, /review-pr edit [n], /review-pr post [n]',
    async handler(args, ctx) {
      const [verb = '', rest = ''] = args.trim().split(/\s+/, 2);

      try {
        if (verb === 'edit') {
          const review = await pick(ctx, rest);

          if (!review) return;
          const text = await ctx.ui.editor(`Review of #${review.number}`, fs.readFileSync(review.draft, 'utf8'));

          if (text !== undefined) fs.writeFileSync(review.draft, `${text.trim()}\n`);
        } else if (verb === 'post') {
          const review = await pick(ctx, rest);

          if (review) await post(ctx, review);
        } else if (verb) {
          await request(ctx, verb);
        } else {
          ctx.ui.notify('Usage: /review-pr <n|url> | edit [n] | post [n]', 'error');
        }
      } catch (error) {
        ctx.ui.notify(error instanceof Error ? error.message : String(error), 'error');
      }
    },
  });
}
