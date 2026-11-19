import { actionRef, cn, defineWebExtension, useAction, useConversation } from '@/sdk';

type Pr = {
  number: number;
  url: string;
  state: string;
  draft: boolean;
  review: string | null;
  checks: { pass: number; fail: number; pending: number };
  colour: 'yellow' | 'blue' | 'green' | 'red' | 'merged' | 'closed';
  stale: boolean;
};

const PrAction = actionRef<null, Pr | null>('pr-status', 'pr');

const COLOUR: Record<Pr['colour'], string> = {
  yellow: 'text-yellow-500',
  blue: 'text-blue-500',
  green: 'text-green-500',
  red: 'text-red-500',
  merged: 'text-purple-500',
  closed: 'text-muted-foreground',
};

const MEANING: Record<Pr['colour'], string> = {
  yellow: 'checks running',
  blue: 'waiting (draft or review)',
  green: 'ready to merge',
  red: 'failed checks or conflicts',
  merged: 'merged',
  closed: 'closed',
};

function PrChip() {
  const id = useConversation((c) => c.id);
  const busy = useConversation((c) => c.busy);
  // The action runs in this conversation's cwd; refresh after each run and every 2 min.
  const { data: pr } = useAction(PrAction, null, { on: `${id}:${busy}`, every: 120_000, focus: true, onError: () => {} });
  if (!pr) return null;
  const { pass, fail, pending } = pr.checks;
  return (
    <a
      href={pr.url}
      target="_blank"
      rel="noreferrer"
      className={cn('shrink-0 hover:underline', COLOUR[pr.colour], pr.stale && 'opacity-50')}
      title={`PR #${pr.number}: ${MEANING[pr.colour]}${pr.draft ? ' · draft' : ''} · checks ${pass}✓ ${fail}✗ ${pending}…${
        pr.review ? ` · ${pr.review.toLowerCase().replace('_', ' ')}` : ''
      }${pr.stale ? ' · offline, last known' : ''}`}
    >
      #{pr.number}
    </a>
  );
}

export default defineWebExtension({
  slots: { 'composer.status': [PrChip] },
});
