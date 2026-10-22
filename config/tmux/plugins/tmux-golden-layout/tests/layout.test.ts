import { describe, expect, test } from "bun:test";

import { leafPanes, parseLayout, samePaneSet, serializeLayout, shape } from "../src/layout";

// Captured from a real tmux 3.8 server (200x50 window).
const NESTED =
  '{"V":2,"L":{"t":"h","w":200,"h":50,"x":0,"y":0,"c":[{"t":"p","w":100,"h":50,"x":0,"y":0,"l":1,"i":0,"I":"%0"},{"t":"v","w":99,"h":50,"x":101,"y":0,"c":[{"t":"p","w":99,"h":25,"x":101,"y":0,"l":0,"i":1,"I":"%1"},{"t":"p","w":99,"h":24,"x":101,"y":26,"a":true,"i":2,"I":"%2"}]}]}}';
const GRID =
  '{"V":2,"L":{"t":"v","w":200,"h":50,"x":0,"y":0,"c":[{"t":"h","w":200,"h":25,"x":0,"y":0,"c":[{"t":"p","w":100,"h":25,"x":0,"y":0,"l":2,"i":0,"I":"%2"},{"t":"p","w":99,"h":25,"x":101,"y":0,"l":0,"i":1,"I":"%4"}]},{"t":"h","w":200,"h":24,"x":0,"y":26,"c":[{"t":"p","w":100,"h":24,"x":0,"y":26,"l":1,"i":2,"I":"%3"},{"t":"p","w":99,"h":24,"x":101,"y":26,"a":true,"i":3,"I":"%5"}]}]}}';
const SINGLE = '{"V":2,"L":{"t":"p","w":374,"h":93,"x":0,"y":0,"a":true,"i":1,"I":"%35"}}';
const SINGLE_FLOAT =
  '{"V":2,"L":{"t":"v","w":200,"h":50,"x":0,"y":0,"c":[{"t":"p","w":200,"h":50,"x":0,"y":0,"a":true,"i":0,"I":"%0"},{"t":"p","w":100,"h":12,"x":4,"y":2,"i":1,"z":0,"I":"%1"}]}}';
const FLOATS_BETWEEN =
  '{"V":2,"L":{"t":"h","w":200,"h":50,"x":0,"y":0,"c":[{"t":"p","w":100,"h":50,"x":0,"y":0,"l":0,"i":0,"I":"%6"},{"t":"p","w":100,"h":12,"x":8,"y":4,"i":3,"z":0,"I":"%9"},{"t":"p","w":100,"h":12,"x":4,"y":2,"i":2,"z":1,"I":"%8"},{"t":"p","w":99,"h":50,"x":101,"y":0,"a":true,"i":1,"I":"%7"}]}}';

describe("parse/serialize round-trip", () => {
  for (const [name, layout] of Object.entries({ NESTED, GRID, SINGLE, SINGLE_FLOAT, FLOATS_BETWEEN })) {
    test(name, () => {
      expect(serializeLayout(parseLayout(layout))).toBe(layout);
    });
  }
});

describe("structure", () => {
  test("tiled leaf panes in tree order", () => {
    expect(leafPanes(parseLayout(GRID))).toEqual([2, 4, 3, 5]);
  });

  test("floating panes are set aside, not tiled", () => {
    const root = parseLayout(FLOATS_BETWEEN);
    if (root.type !== "split") throw new Error("expected split");
    expect(leafPanes(root)).toEqual([6, 7]);
    expect(root.floating.map((f) => f.index)).toEqual([1, 2]);
  });

  test("separator accounting", () => {
    const root = parseLayout(NESTED);
    if (root.type !== "split") throw new Error("expected split");
    const widths = root.children.map((c) => c.width);
    expect(widths.reduce((a, b) => a + b, 0) + root.children.length - 1).toBe(root.width);
  });

  test("samePaneSet ignores order", () => {
    const a = parseLayout(GRID);
    const swapped = parseLayout(GRID.replace('"%2"', '"%X"').replace('"%5"', '"%2"').replace('"%X"', '"%5"'));
    expect(samePaneSet(a, swapped)).toBe(true);
    expect(samePaneSet(a, parseLayout(NESTED))).toBe(false);
  });

  test("shape ignores focus and floating panes", () => {
    const refocused = NESTED.replace('"l":1,', '"a":true,').replace('"a":true,"i":2', '"l":0,"i":2');
    expect(shape(parseLayout(refocused))).toBe(shape(parseLayout(NESTED)));
    expect(shape(parseLayout(SINGLE_FLOAT))).toBe("200x50,0,0v(200x50,0,0,0)");
  });

  test("shape without panes ignores placement", () => {
    const swapped = parseLayout(GRID.replace('"%2"', '"%X"').replace('"%5"', '"%2"').replace('"%X"', '"%5"'));
    expect(shape(swapped)).not.toBe(shape(parseLayout(GRID)));
    expect(shape(swapped, false)).toBe(shape(parseLayout(GRID), false));
  });
});

describe("malformed layouts", () => {
  const bad = [
    "",
    "21be,200x50,0,0,0", // tmux <= 3.7 format
    '{"V":1,"L":{"t":"p","w":1,"h":1,"x":0,"y":0,"i":0,"I":"%0"}}',
    '{"V":2,"L":{"t":"p","w":1,"h":1,"x":0,"y":0,"i":0,"I":"0"}}',
    '{"V":2,"L":{"t":"h","w":10,"h":1,"x":0,"y":0,"c":[]}}',
    '{"V":2,"L":{"t":"q","w":10,"h":1,"x":0,"y":0}}',
    '{"V":2,"L":{"t":"p","w":"1","h":1,"x":0,"y":0,"i":0,"I":"%0"}}',
    '{"V":2,"L":null}',
  ];
  for (const layout of bad) {
    test(JSON.stringify(layout), () => {
      expect(() => parseLayout(layout)).toThrow();
    });
  }
});
