// Minimal shims for the few Bun globals used, so `tsc --noEmit` works
// without adding a bun-types dependency. `bun test`/`bun run` provide the
// real implementations.
declare const Bun: {
  stdin: { stream(): ReadableStream<Uint8Array> };
  sleep(ms: number): Promise<void>;
};

declare module "bun:test" {
  export const test: (name: string, fn: () => unknown | Promise<unknown>) => void;
  export const describe: (name: string, fn: () => void) => void;
  export const expect: any;
  export const beforeAll: (fn: () => unknown | Promise<unknown>) => void;
  export const afterAll: (fn: () => unknown | Promise<unknown>) => void;
}

interface ImportMeta {
  dir: string;
}
