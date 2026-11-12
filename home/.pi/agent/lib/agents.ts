import { spawnSync } from 'node:child_process';
import { createInterface } from 'node:readline';
import { socketRequest } from './messaging.ts';
import { readRegistry, type Registry } from './registry.ts';

const pretty = (registry: Registry): void => {
  console.log(
    `${registry.machine} — ${registry.pis.length} pis, ${registry.apps.length} apps, ${registry.ultimates.length} ultimates`,
  );

  const rows = [
    ['KIND', 'PID', 'TARGET', 'STATE / PROJECT'],
    ...registry.pis.map((pi) => ['pi', String(pi.pid), pi.sessionName || pi.id, `${pi.state || '-'} ${pi.cwd}`]),
    ...registry.apps.map((app) => [
      'app',
      String(app.holder?.pid || '-'),
      app.origin || String(app.port),
      `${app.tabs.length} tabs ${app.root || ''}`,
    ]),
    ...registry.ultimates.map((instance) => [
      'ultimate',
      String(instance.pid),
      instance.url,
      `${instance.hub || '-'} ${instance.project}`,
    ]),
  ];

  const widths = [0, 1, 2].map((column) => Math.max(...rows.map((row) => row[column]!.length)));

  for (const row of rows) console.log(row.map((cell, column) => cell.padEnd(widths[column] || 0)).join('  '));
};

const main = async (): Promise<void> => {
  let human = false;
  let remote: string | undefined;
  const args = process.argv.slice(2);

  if (args[0] === 'send') {
    if (args.length !== 3 || args[1] !== '--socket' || !args[2]) throw new Error('Usage: agents send --socket <path>');
    const input = createInterface({ input: process.stdin });

    try {
      for await (const line of input) {
        JSON.parse(line);
        console.log(await socketRequest(args[2], line));

        return;
      }

      throw new Error('Expected one JSON line on stdin');
    } finally {
      input.close();
    }
  }

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    if (arg === '--pretty') human = true;
    else if (arg === '--json') human = false;
    else if (arg === '--remote') {
      remote = args[++i];

      if (!remote || remote.startsWith('-') || !remote.trim()) throw new Error('--remote requires an SSH host');
    } else throw new Error(`Unknown argument: ${arg}. Usage: agents [--json | --pretty] [--remote <host>]`);
  }

  if (remote) {
    const result = spawnSync(
      'ssh',
      ['-o', 'BatchMode=yes', '-o', 'ConnectTimeout=5', remote, '~/.dotfiles/bin/agents --json'],
      {
        encoding: 'utf8',
        timeout: 5000,
        killSignal: 'SIGKILL',
      },
    );

    if (result.error || result.status !== 0) {
      throw new Error(
        `Cannot read registry on ${remote}: ${result.error?.message || result.stderr.trim() || `ssh exited ${result.status}`}`,
      );
    }

    // Remote discovery always prints the other machine's JSON, unchanged.
    process.stdout.write(result.stdout);
  } else {
    const registry = readRegistry();

    if (human) pretty(registry);
    else console.log(JSON.stringify(registry));
  }
};

try {
  await main();
} catch (error) {
  console.error(`agents: ${error instanceof Error ? error.message : String(error)}`);
  process.exitCode = 1;
}
