---
name: good-css
description: Modern CSS techniques that replace breakpoint ladders, wrapper elements and scripts. Use whenever you write, edit or review styles in any form, including plain CSS, Tailwind classes, StyleX, CSS-in-JS and inline styles, and whenever you build or restyle a page or component, even if the user never mentions CSS.
---

# Good CSS

One declaration that adapts on its own beats a set of breakpoints, and a CSS feature beats a script. Use JavaScript only where it makes a result nicer that already works without it.

Each technique is a set of properties and values, so it works in any authoring system. Class names in the examples are placeholders. Write the declarations in what the project already uses, whether that is a stylesheet, Tailwind utilities or StyleX objects. Where that system has no shorthand for a declaration, write it the long way, as a Tailwind arbitrary property or a rule in the project's CSS file. Do not swap the technique for a breakpoint.

## In all CSS

These need no file.

- Write `inline` and `block` properties in place of left, right, top and bottom. Tailwind has them too, as in `mbs-`, `pe-` and `inset-bs-`, so never write `mt-`, `pr-` or `top-`. The block ones need Tailwind 4.2. Below it, write them as arbitrary properties, as in `[margin-block-start:theme(spacing.4)]`.
- Write colors in `oklch()`, with `none` as the hue of a gray, white or black. Derive a hover, tint or transparent version with `color-mix(in oklch, …)`.
- Put sizes that grow with the screen in one `clamp()` token.
- Put every `:hover` rule inside `@media (hover: hover) and (pointer: fine)`.
- Style focus with `:focus-visible` and `outline`. Never write `outline: none`.
- Give everything pressable an `:active` state.
- Put a transition that moves or scales something inside `@media (prefers-reduced-motion: no-preference)`. Name its properties, never `all`, and never use `ease-in`.
- Cut off overflow with `overflow: clip`. Keep `hidden` for an element a script scrolls.

## Read the entry before you write

Each file holds entries with the CSS and its rules. The rules are the conditions the CSS needs to work, so keep all of them. Read only the files whose row matches what you are about to write. One component matches two or three, and a whole page matches most of them.

| Read | Before you write |
| --- | --- |
| `references/foundations.md` | a reset or base stylesheet, a set of color tokens, dark mode, a type or spacing scale |
| `references/layout.md` | a page or section container or any centered `max-width` wrapper, whether or not anything goes edge to edge, a grid of cards, cards whose parts line up, a sidebar, a component placed in slots of different widths, overlapping layers, centered content that can overflow |
| `references/spacing-and-shape.md` | spacing between sections, elements stacked one above another, one item pushed to the far end of a row or column, nested rounded corners |
| `references/text-and-media.md` | text or images that come from a user or a CMS, such as names, titles, excerpts, thumbnails, avatars and embeds, an icon next to a label, a label that looks off-center, numbers in a column |
| `references/interaction.md` | the focus, hover and press states of a button, link, input or card, a small tap target, a clickable card, form validation, a textarea, a parent styled by what it contains, page scroll locked behind a modal |
| `references/motion.md` | easing and duration tokens, one state change that drives several values, a shadow that changes on hover, a transition between pages, the indicator under an active tab |
| `references/show-and-hide.md` | a dialog, popover, dropdown menu or accordion |
| `references/scroll-and-viewport.md` | a carousel, a row that may overflow, a modal body, chat list or drawer that scrolls between a header and a footer, in-page links under a sticky header, an app shell on desktop or on a phone |

## Left out on purpose

Never add `text-box` trim on `*`, `text-rendering: optimizeLegibility`, or a reset that puts `display: contents` or one shared grid cell on every element. `references/foundations.md` has the reasons.

## Browser support

Most entries end with a `Support:` line. This skill sets no browser floor. Weigh the line against the browsers the project targets, and tell the user when something you used is missing from one of them.

## Motion

Whether something should animate, the design or review of motion, springs, gestures and drag, and checks on a real phone belong to Emil Kowalski's skills `animate`, `review-animations`, `improve-animations`, `find-animation-opportunities` and `mobile-native`. When they are installed, use them for those jobs, and where one disagrees with a value here, use its value. When they are not, use the entries as written and add no motion beyond what an entry or the task calls for.
