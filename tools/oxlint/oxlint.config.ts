// Vendored anti-slop ruleset (https://github.com/dmmulroy/anti-slop, see
// anti-slop/UPSTREAM_REV). Full generic rule set as errors — code is fixed to
// comply; rules are not relaxed to accommodate existing style. The Effect
// rule group is intentionally not registered (no Effect usage).
//
// The oxlint binary is mise-managed (repo-local mise.toml, pinned to the
// vendored @oxlint/plugins version). No package.json / node_modules: the
// plugin API is vendored at vendor/oxlint-plugins and anti-slop imports it
// relatively. Run via `mise run lint:ts`.
//
// Plain object export (no `import { defineConfig } from "oxlint"`) so the
// config has zero resolvable-package requirements.

export default {
  ignorePatterns: ["tools/oxlint/**"],
  jsPlugins: [{ name: "anti-slop", specifier: "./anti-slop/index.ts" }],
  rules: {
    "oxc/no-accumulating-spread": "error",
    "anti-slop/no-array-filter-map": "error",
    "anti-slop/no-reduce-accumulator-copy": "error",
    "anti-slop/no-chained-type-assertions": "error",
    "anti-slop/no-conditional-empty-object-spread": "error",
    "anti-slop/no-known-value-widening": "error",
    "anti-slop/no-module-mocking": "error",
    "anti-slop/no-object-parameters": "error",
    "anti-slop/no-reflect-apply": "error",
    "anti-slop/no-reflect-get": "error",
    "anti-slop/no-runtime-typeof": "error",
    "anti-slop/no-shape-in-symbol-names": "error",
    "anti-slop/no-unknown-parameters": "error",
    "anti-slop/no-unknown-returns": "error",
    "anti-slop/no-unknown-type-aliases": "error",
    "anti-slop/no-unsafe-dictionary-type": "error",
    "anti-slop/no-widen-then-assert": "error",
    "anti-slop/require-readable-spacing": "error",
    "anti-slop/require-safety-comment-for-type-assertion": "error",
  },
};
