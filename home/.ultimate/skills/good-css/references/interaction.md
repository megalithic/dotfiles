<!-- Generated from PRACTICES.md by scripts/build-skill.js. Do not edit. -->

## One focus ring with `:focus-visible`

Use it as the focus style for every interactive element. Never write `outline: none`.

```css
:focus-visible {
  outline: max(2px, 0.08em) solid currentColor;
  outline-offset: 0.25em;
}
```

Rules:

- On a filled button `currentColor` can fail contrast. Set the outline to the button's background color there.
- A component that draws its ring with `box-shadow` keeps `outline-color: transparent`, never `outline: none`, so forced-colors mode can repaint it.

Support: Chrome 86, Firefox 85, Safari 15.4.

## Hover styles only where hover exists

Use it on every `:hover` rule, so a tap on a touch screen does not leave the hover state stuck.

```css
@media (hover: hover) and (pointer: fine) {
  .button:hover { background: var(--primary-hover); }
}
```

Rules:

- Tailwind v4's `hover:` variant wraps itself in `(hover: hover)` only. Write the full query by hand everywhere else.
- Touch users still need feedback on press. Give it with `:active`, which works for every input.

Support: Chrome 38, Firefox 64, Safari 9.

## Press feedback

Use it on every button and anything else that can be pressed.

```css
.button:active { transform: scale(0.97); }

@media (prefers-reduced-motion: no-preference) {
  .button { transition: transform 160ms var(--ease-out, ease-out); }
}
```

Rules:

- Keep the scale between 0.95 and 0.98.
- "The reset" (`foundations.md`) removes the browser's tap highlight. Without this entry a tap gives no feedback at all.
- When feedback needs a script, listen for `pointerdown`, not `click`.

Support: every browser.

## Hit area larger than the visual

Use it on icon buttons, close buttons and any target that looks smaller than 44px.

```css
.icon-button { position: relative; }

.icon-button::after {
  content: "";
  position: absolute;
  inset: min(0px, (100% - 44px) / 2);
}
```

Rules:

- `overflow: hidden` or `clip` on the button cuts the area off.
- It does not work on `<input>`, which has no pseudo-elements. Wrap it in a `<label>`.

Support: Chrome 87, Firefox 66, Safari 14.1.

## Whole card clickable from one link

Use it for cards, list rows and tiles where the whole area should navigate. It replaces an `<a>` wrapped around the card, which makes a screen reader read every word as the link text, and it replaces a click handler on a `div`.

```html
<article class="card">
  <h3><a class="card-link" href="/reports/q3">Quarterly report</a></h3>
  <p>Revenue grew in every region.</p>
  <button type="button">Save</button>
</article>
```

```css
.card { position: relative; }

.card-link::after {
  content: "";
  position: absolute;
  inset: 0;
}

.card-link:focus-visible { outline: 2px solid transparent; }

.card:has(.card-link:focus-visible) {
  outline: 2px solid currentColor;
  outline-offset: 2px;
}

.card :is(button, a:not(.card-link)) {
  position: relative;
  z-index: 1;
}
```

Rules:

- No element between the card and the link may be positioned. The overlay would size itself to that element.
- The link's own ring is made transparent, never removed, as "One focus ring with `:focus-visible`" requires. Write the full `2px solid transparent`. Safari ignores `outline-color` on its default ring.
- Text under the overlay cannot be selected. Accept it.
- Put hover styles on `.card:hover`, inside the query from "Hover styles only where hover exists".

Support: Chrome 105, Firefox 121, Safari 15.4.

## `:has()` for parent and page state

Use it wherever a script adds a class to a parent because of what it contains or what state a child is in.

```css
article:has(img) { grid-column: span 2; }
h2:has(+ p) { margin-block-end: 0; }
form:has(:focus-visible) { background: var(--surface-raised); }

html { scrollbar-gutter: stable; }
html:has(dialog:modal) { overflow: hidden; }
```

Rules:

- `:modal` matches `showModal()` only, so a non-modal dialog does not lock the page.
- Keep `scrollbar-gutter: stable` with the scroll lock. Without it the page shifts sideways when the scrollbar disappears. "The reset" (`foundations.md`) sets it.
- `:has()` cannot be nested inside `:has()`.

Support: Chrome 105, Firefox 121, Safari 15.4.

## Form feedback with `:user-invalid`

Use it for inline form validation, in place of blur listeners and a "touched" class.

```css
input:user-invalid { border-color: var(--danger); }
input:user-valid { border-color: var(--success); }
```

```html
<input type="password" required minlength="8">
```

Rules:

- Color alone is not enough feedback. Pair it with text or an icon.
- The server still validates.

Support: Chrome 119, Firefox 88, Safari 16.5.

## Textarea that grows with its content

Use it for any multi-line input, such as a chat composer or a comment box. `field-sizing: content` sizes the textarea to its text, so there is no auto-grow script and no hidden mirror element.

```css
textarea {
  field-sizing: content;
  min-height: 3lh;
  max-height: 12lh;
  resize: none;
}
```

The height snaps to each new line. To animate it, wrap the textarea and let a `ResizeObserver` copy its height onto the wrapper. The wrapper transitions.

```html
<div class="field"><textarea></textarea></div>
```

```css
.field {
  box-sizing: content-box;
  overflow: clip;
}

@media (prefers-reduced-motion: no-preference) {
  .field { transition: height 0.2s var(--ease-out, ease-out); }
}
```

```js
const textarea = document.querySelector(".field textarea");

new ResizeObserver(([entry]) => {
  textarea.parentElement.style.height = `${entry.borderBoxSize[0].blockSize}px`;
}).observe(textarea);
```

Rules:

- Bound it with `min-height` and `max-height`. A fixed `height` brings the fixed size back. Past `max-height` the textarea scrolls.
- Put the border and background on the wrapper and leave the textarea bare. The box the user sees must be the one that animates.
- Keep the wrapper `content-box`. The observer writes the textarea's full height, and a `border-box` wrapper would subtract its own border from it.
- Write no fallback. A browser without `field-sizing` shows a fixed textarea that scrolls.

Support: Chrome 123, Safari 26.2, Firefox 152. Baseline newly available since June 2026.
