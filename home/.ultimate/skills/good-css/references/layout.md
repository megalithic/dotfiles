<!-- Generated from PRACTICES.md by scripts/build-skill.js. Do not edit. -->

## Content grid with breakouts

Use it as the container of every page, whether or not anything on it goes wider than the content. A centered `max-width` wrapper is the sign, such as `.container`, `.wrapper` or Tailwind's `mx-auto max-w-*`. One grid on the section replaces the `section > .container` wrapper pair and costs no more than it, and any child can be content width, wider, or edge to edge. Put it on `main` for a page of flowing content, or on each section. A band, a figure or a block that an editor later wants wider then takes one class, with no negative margin and no new wrapper.

The container defines three nested widths with named grid lines:

```css
.content-grid {
  --gutter: 1.5rem;
  --content: 64rem;
  --breakout: 80rem;

  display: grid;
  grid-template-columns:
    [full-width-start] minmax(var(--gutter), 1fr)
    [breakout-start] minmax(0, calc((var(--breakout) - var(--content)) / 2))
    [content-start] min(100% - var(--gutter) * 2, var(--content)) [content-end]
    minmax(0, calc((var(--breakout) - var(--content)) / 2)) [breakout-end]
    minmax(var(--gutter), 1fr) [full-width-end];
}
```

Each child picks a width with `grid-column`. Content is the default:

```css
:is(.content-grid, .full-width) > * { grid-column: content; }
:is(.content-grid, .full-width) > .breakout { grid-column: breakout; }
:is(.content-grid, .full-width) > .full-width {
  grid-column: full-width;
  display: grid;
  grid-template-columns: inherit;
}
```

Rules:

- Every child must be placed. An unplaced child of the grid lands in the gutter track.
- Every direct child is a grid item. Wrap a run of inline elements in one element.
- Change a width by overriding `--content`, not by writing a new column template.
- In a pass over existing CSS, replace each centered `max-width` wrapper with the grid, and keep the wrapper's width as `--content` on its section.

In other systems: the column template goes wherever the project defines reusable styles. Where child selectors are not available, as in StyleX or Tailwind without a custom variant, each child sets its own `grid-column` to `content`, `breakout` or `full-width`.

## Intrinsic grid

Use it for any set of equal cards or tiles. It replaces a column count per breakpoint.

```css
.grid {
  display: grid;
  gap: 1rem;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 16rem), 1fr));
}
```

Rules:

- `auto-fit` stretches a short row to fill the width. Use `auto-fill` when the item count changes, such as a filtered list, so cards keep their size.

Support: Chrome 79, Firefox 76, Safari 11.1.

## Subgrid rows shared across cards

Use it when cards in a row have parts that should line up, such as title, body and footer, whatever the length of their content.

```css
.cards {
  display: grid;
  gap: 1.5rem;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 16rem), 1fr));
}

.card {
  display: grid;
  grid-row: span 3;
  grid-template-rows: subgrid;
  row-gap: 0.5rem;
}
```

Rules:

- The span must equal the number of parts in the card. Without `grid-row: span N` every part piles into one row.
- Set `row-gap` on the card, or it inherits the parent's gap between its parts.

Support: Chrome 117, Firefox 71, Safari 16.

## Sidebar that wraps on its own

Use it for any pair where one side has an ideal width and the other takes the rest, such as a media object, an input with a button, or a page with an aside.

```css
.with-sidebar {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
}

.sidebar {
  flex-basis: 20rem;
  flex-grow: 1;
}

.main {
  flex-basis: 0;
  flex-grow: 999;
  min-inline-size: 50%;
}
```

Rules:

- The wrap point is a share of the container, not a length. Change `min-inline-size` to move it.
- Drop the sidebar's `flex-basis` for a sidebar sized by its content.
- For a sticky sidebar, add `align-self: start` beside `position: sticky` and its inset. The two sides stretch to the same height, and a stretched sidebar has no room to stick.
- A bare `img` or `video` as one of the sides stretches to the height of the row and distorts. Set `align-items: start` on the container.

Support: Chrome 84, Firefox 63, Safari 14.1.

## Container queries with container units

Use it for any component that appears in slots of different widths. The component responds to the space it is given, where a media query only knows the viewport.

```css
.slot { container-type: inline-size; }

.card h2 { font-size: clamp(1.25rem, 1rem + 2cqi, 2rem); }

@container (width > 30rem) {
  .card {
    display: grid;
    grid-template-columns: 12rem 1fr;
  }
}
```

Rules:

- The container must be an ancestor. An element cannot query itself.
- A container cannot take its width from its content. Never put `container-type` on a shrink-to-fit element, or it collapses to zero.
- With no container ancestor the query never matches. Kevin Powell makes `header`, `main` and `footer` containers in his reset, so most components need none of their own.
- A container cannot also be a subgrid. "Subgrid rows shared across cards" and this entry need separate elements.
- Container units are different from queries. With no container above the element, `cqi` measures the viewport, so one token written with `cqi` serves the page and every slot.
- Never register a fluid token that uses `cqi` with `@property`. A registered length computes once on `:root`, where there is no container, and every slot then gets the viewport's value.

Support: Chrome 105, Firefox 110, Safari 16.

## Stack layers with grid

Use it whenever things sit on top of each other, such as text over an image, a badge on a card, or two icons that swap. It replaces `position: absolute` with its offsets, sizes and transforms.

```css
.stack { display: grid; }
.stack > * { grid-area: 1 / 1; }

.stack > .title { place-self: center; }
.stack > .badge { place-self: start end; }
```

Rules:

- A layer later in the DOM paints on top. Use `z-index` only to change that order.
- Keep `position: absolute` for a layer that must not affect the container's size.

## Safe alignment

Use it wherever content is centered or end-aligned in a container that can become too small, such as a tab row, a toolbar or a vertically centered modal.

```css
.tabs {
  display: flex;
  overflow-x: auto;
  justify-content: safe center;
}
```

Rules:

- It works on every `align-*`, `justify-*` and `place-*` property.
- Auto margins on the item center it the same way and are safe in every browser that has flexbox. "Push one item away with an auto margin" (`spacing-and-shape.md`) has them.

Support: Chrome 115, Firefox 63, Safari 17.6.

## `overflow: clip` over `hidden`

Use it whenever you want to cut off overflow and do not need scrolling.

```css
.hero { overflow-x: clip; }
```

Rules:

- Put it on the element that overflows, not on `html` or `body`.
- Keep `hidden` or `auto` for elements a script scrolls. `clip` blocks that too.
- Keep `hidden` or `auto` on an element with `resize`. With `clip` the browser draws no resize handle.

Support: Chrome 90, Firefox 81, Safari 16.
