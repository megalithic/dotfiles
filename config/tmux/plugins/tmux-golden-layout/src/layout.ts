/**
 * tmux layout-string parsing and serialization.
 *
 * Layout strings look like:
 *   21be,200x50,0,0{100x50,0,0,0,99x50,101,0[99x25,101,0,1,99x24,101,26,2]}
 *
 * - 4-hex-digit checksum prefix (tmux layout_checksum, rotate-right-and-add)
 * - each cell: WxH,X,Y then either
 *     ,<pane-id-number>            leaf
 *     {child,child,...}            left-right split
 *     [child,child,...]            top-bottom split
 * - siblings are separated by a 1-cell border along the split axis, so
 *   sum(children) + (n-1) == parent size along the axis.
 */

export type Axis = "h" | "v"; // h = left-right `{}`, v = top-bottom `[]`

export interface Leaf {
  type: "leaf";
  width: number;
  height: number;
  x: number;
  y: number;
  /** numeric pane id (tmux `%12` -> 12) */
  paneId: number;
}

export interface Split {
  type: "split";
  axis: Axis;
  width: number;
  height: number;
  x: number;
  y: number;
  children: LayoutNode[];
}

export type LayoutNode = Leaf | Split;

/** tmux layout_checksum from layout-custom.c (16-bit rotate right + add). */
export function layoutChecksum(body: string): string {
  let csum = 0;
  for (let i = 0; i < body.length; i++) {
    csum = ((csum >> 1) | ((csum & 1) << 15)) & 0xffff;
    csum = (csum + body.charCodeAt(i)) & 0xffff;
  }
  return csum.toString(16).padStart(4, "0");
}

class Parser {
  private i = 0;
  constructor(private readonly s: string) {}

  private peek(): string {
    return this.s[this.i] ?? "";
  }

  private expect(ch: string): void {
    if (this.s[this.i] !== ch) {
      throw new Error(
        `layout parse error at ${this.i}: expected '${ch}', got '${this.s[this.i] ?? "<eof>"}' in ${this.s}`,
      );
    }
    this.i++;
  }

  private int(): number {
    const start = this.i;
    while (this.i < this.s.length && this.s[this.i] >= "0" && this.s[this.i] <= "9") this.i++;
    if (this.i === start) {
      throw new Error(`layout parse error at ${this.i}: expected digit in ${this.s}`);
    }
    return Number.parseInt(this.s.slice(start, this.i), 10);
  }

  cell(): LayoutNode {
    const width = this.int();
    this.expect("x");
    const height = this.int();
    this.expect(",");
    const x = this.int();
    this.expect(",");
    const y = this.int();

    const c = this.peek();
    if (c === "{" || c === "[") {
      const axis: Axis = c === "{" ? "h" : "v";
      const close = c === "{" ? "}" : "]";
      this.i++;
      const children: LayoutNode[] = [this.cell()];
      while (this.peek() === ",") {
        this.i++;
        children.push(this.cell());
      }
      this.expect(close);
      return { type: "split", axis, width, height, x, y, children };
    }

    this.expect(",");
    const paneId = this.int();
    return { type: "leaf", width, height, x, y, paneId };
  }

  done(): boolean {
    return this.i >= this.s.length;
  }
}

/** Parse a layout string, with or without its checksum prefix. */
export function parseLayout(layout: string): LayoutNode {
  const body = /^[0-9a-f]{4},/.test(layout) ? layout.slice(5) : layout;
  const p = new Parser(body);
  const root = p.cell();
  if (!p.done()) throw new Error(`layout parse error: trailing input in ${layout}`);
  return root;
}

function printCell(node: LayoutNode): string {
  const head = `${node.width}x${node.height},${node.x},${node.y}`;
  if (node.type === "leaf") return `${head},${node.paneId}`;
  const open = node.axis === "h" ? "{" : "[";
  const close = node.axis === "h" ? "}" : "]";
  return `${head}${open}${node.children.map(printCell).join(",")}${close}`;
}

/** Serialize a layout tree back to a full checksummed tmux layout string. */
export function serializeLayout(root: LayoutNode): string {
  const body = printCell(root);
  return `${layoutChecksum(body)},${body}`;
}

/** Leaf pane ids in tree order (matches tmux window pane order). */
export function leafPanes(node: LayoutNode): number[] {
  if (node.type === "leaf") return [node.paneId];
  return node.children.flatMap(leafPanes);
}

/** Count of leaf panes under a node. */
export function leafCount(node: LayoutNode): number {
  if (node.type === "leaf") return 1;
  return node.children.reduce((n, c) => n + leafCount(c), 0);
}

/** True when the pane id appears somewhere under the node. */
export function containsPane(node: LayoutNode, paneId: number): boolean {
  if (node.type === "leaf") return node.paneId === paneId;
  return node.children.some((c) => containsPane(c, paneId));
}

/** Two layouts hold the same pane set (order-insensitive). */
export function samePaneSet(a: LayoutNode, b: LayoutNode): boolean {
  const pa = leafPanes(a).slice().sort((x, y) => x - y);
  const pb = leafPanes(b).slice().sort((x, y) => x - y);
  return pa.length === pb.length && pa.every((v, i) => v === pb[i]);
}

/** Recompute x/y coordinates for the whole tree from node sizes. */
export function assignCoords(node: LayoutNode, x: number, y: number): void {
  node.x = x;
  node.y = y;
  if (node.type === "leaf") return;
  let cursor = node.axis === "h" ? x : y;
  for (const child of node.children) {
    if (node.axis === "h") {
      child.height = node.height;
      assignCoords(child, cursor, y);
      cursor += child.width + 1;
    } else {
      child.width = node.width;
      assignCoords(child, x, cursor);
      cursor += child.height + 1;
    }
  }
}
