import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { Value } from 'typebox/value';

const commandSchema = Type.Object({ command: Type.String() });

const configSchema = Type.Object({
  action: Type.Object({
    commandRules: Type.Array(
      Type.Object({
        id: Type.String(),
        pattern: Type.String(),
        severity: Type.String(),
        caseSensitive: Type.Optional(Type.Boolean()),
      }),
      { minItems: 1 },
    ),
  }),
});

export default function (pi: ExtensionAPI) {
  pi.on('tool_call', async (event, ctx) => {
    if (event.toolName !== 'interactive_shell' || !Value.Check(commandSchema, event.input)) return;
    const command = event.input.command;

    const configPath = join(
      process.env.PI_CODING_AGENT_DIR ?? join(homedir(), '.pi', 'agent'),
      'pi-warden',
      'config.json',
    );

    try {
      const config: unknown = JSON.parse(readFileSync(configPath, 'utf8'));

      if (!Value.Check(configSchema, config)) {
        return { block: true, reason: `prod-guard: invalid production rules in ${configPath}.` };
      }

      // Warden enforces its other severities on bash; this guard only asks.
      const matches = config.action.commandRules.filter(
        (rule) => rule.severity === 'confirm' && new RegExp(rule.pattern, rule.caseSensitive ? '' : 'i').test(command),
      );

      if (matches.length === 0) return;
      const names = matches.map((rule) => rule.id).join(', ');

      if (!ctx.hasUI) {
        return { block: true, reason: `prod-guard: ${names} requires explicit approval; no UI is available.` };
      }

      const allowed = await ctx.ui.confirm(`Allow production access? (${names})`, command);

      if (!allowed) {
        return { block: true, reason: `prod-guard: user declined ${names}. Do not retry without approval.` };
      }
    } catch {
      return { block: true, reason: `prod-guard: could not verify production approval using ${configPath}.` };
    }
  });
}
