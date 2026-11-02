# Pagoda Homepage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the card-list gate at `/` with one hand-inked isometric pagoda courtyard where the two real machines (Xin xăm, Giải nghiệp) stand and click through to their pages.

**Architecture:**
- The scene is a decorative inline SVG rendered by a function component in `ChuaTauWeb.GateHTML`.
- The machines are one list of plain `<a class="machine">` links. On desktop each link is absolutely positioned over the SVG at its `Machines.scene` point. On a phone CSS reflows the same links into a column between the SVG vignettes.
- Machine images are transparent, shadowless PNGs. A dev-only Playwright script makes them from the live figure pages.

**Tech Stack:** Phoenix 1.7 HEEx, plain CSS (`priv/static/css/gate.css`), inline JS (no build step), Node + Playwright (capture script only, dev-only), ExUnit + Floki.

**Spec:** `docs/superpowers/specs/2026-11-03-pagoda-homepage-design.md`

## Global Constraints

- **Palette:** `--paper #E8D7B8`, `--card #F5EBDD`, `--lacquer #B84B32`, `--brass #D5A64B`, `--jade #536C56`, `--ink #49372E`, `--glaze #2E4A5C`.
  - Define these as CSS variables in `gate.css`.
  - Use `--glaze` for water and ceramic only.
- **Type:**
  - Lora for display, Be Vietnam Pro for body and labels, from Google Fonts with the `vietnamese` subset, on the gate page only.
  - Labels are letter-spaced small caps in ink on `--card`.
- **Ink:**
  - One outline about 1.5px. Flat fills with one shadow tone per colour.
  - Gradients only for smoke and candlelight.
  - A 4–6% paper-grain overlay, with light from the upper left.
- **Motion:**
  - No animation loop shorter than 8s.
  - `prefers-reduced-motion: reduce` turns off all animation, the hover lift transition and the click zoom.
- **Links:**
  - Machines must be plain `<a href>` links that work without JS.
  - Each machine link appears exactly once in the DOM.
- **Don't edit these:** `priv/figure/index.html` and `priv/giai-nghiep/index.html` (CLAUDE.md: they get replaced by newer builds).
- **Plaque text:** `Chùa Máy`.
- **Unchanged:** `Seo.gate/0`, the redirects of old `/?col=…` links, and `Machines.path/1`.
- **No `coming soon`**, locked halls or dead links. Only the machines are interactive.
- **Copy:** no invented history about the temple or the machines.
- **Done means:** `mix compile --warnings-as-errors` and `mix test` pass.

## Review Focus

1. **Narrow phones (320px wide):** no horizontal page scroll, and both machines are reachable with a "Vào" plaque. *Task 4, browser check at 320px.*
2. **Keyboard-only visitor:** Tab reaches each machine, and focus shows the same lift and label as hover plus a visible ring. *Task 4, browser check.*
3. **Back button after a zoom-click** (bfcache restore): the scene shows unzoomed. *Task 5, browser check.*
4. **Ctrl/Cmd/Shift/middle-click** on a machine opens a new tab normally, with no zoom and no navigation of the current tab. *Task 5, browser check.*
5. **A third machine added to `Machines`** renders at its own `scene` point with no template change. *Task 2, test: each link's `style` carries that machine's `--x`/`--y`.*

---

### Task 1: Shadowless, centred machine images

**Files:**
- Create: `scripts/capture-machines/package.json`, `scripts/capture-machines/capture.mjs`, `scripts/capture-machines/README.md`
- Modify: `priv/static/images/machines/xin-xam.png`, `priv/static/images/machines/giai-nghiep.png` (overwritten)
- Modify: `.gitignore` (add `/scripts/capture-machines/node_modules/`)

**Interfaces:**
- Produces: `priv/static/images/machines/<slug>.png`, with transparent background, trimmed to the machine, the machine centred horizontally, the foot of the machine on the bottom edge, and 520px tall. Later tasks display these at about 260px tall and anchor them at bottom centre.

- [ ] **Step 1: Write `capture.mjs`.** Usage is `node capture.mjs [baseUrl=http://localhost:4000]`. For each `{slug, path}` in `[{xin-xam, /xin-xam}, {giai-nghiep, /giai-nghiep}]`:
  - Load `baseUrl + path + "?welcome=0"`.
  - Use a `page.route` that rewrites the HTML response in memory. It replaces the exact text `const castShadow = (pts3, z0=0, clip=null) => {` with `const castShadow = () => ''; const __castShadow = (pts3, z0=0, clip=null) => {`. Throw if the text isn't found, so a newer figure build fails loudly instead of capturing with shadows.
  - Inject CSS that makes `html`, `body` and `#fig` backgrounds transparent, and hides everything except `#fig` and its descendants (`body *{visibility:hidden} #fig, #fig *{visibility:visible}`).
  - Wait for fonts and two animation frames, then take a screenshot of `#fig` with `omitBackground: true`.
  - Trim fully transparent margins in the page with a canvas (send the PNG back as a data URL, compute the alpha bounding box). Scale to 520px tall, centre horizontally, and write `../../priv/static/images/machines/<slug>.png`.
  - Log `slug width×height`.
- [ ] **Step 2: Add `package.json`** (`"type": "module"`, devDependency `playwright`) and a README with these commands: `mix phx.server` in another terminal, then `cd scripts/capture-machines && npm install && npx playwright install chromium && node capture.mjs`.
- [ ] **Step 3: Run it.** Expected: two log lines with heights of 520.
- [ ] **Step 4: Check the output.**
  - Open both PNGs (Read tool).
  - Expected: no blue `#41538f` shadow, transparent background, the machine centred, and doors closed in the default pose.
  - `sips -g hasAlpha priv/static/images/machines/*.png` shows `hasAlpha: yes`.
- [ ] **Step 5: Run `mix test`.** Expected: PASS (paths unchanged).
- [ ] **Step 6: Commit** with `git add scripts/capture-machines .gitignore priv/static/images/machines && git commit -m "Machine images: shadowless, centred, transparent"`.

### Task 2: Scene positions and the new gate markup

**Files:**
- Modify: `lib/chua_tau_web/machines.ex`
- Modify: `lib/chua_tau_web/controllers/gate_html.ex`, `lib/chua_tau_web/controllers/gate_html/home.html.heex`
- Test: `test/chua_tau_web/controllers/gate_test.exs`, `test/chua_tau_web/machines_test.exs` (create)

**Interfaces:**
- Produces: `%Machines{scene: {x :: number, y :: number}}`. This is the machine's foot point as a percentage (0–100) of the scene box's width and height. Add it to `@enforce_keys` and the type. Starting values are xin-xam `{27, 62}` and giai-nghiep `{73, 62}`. Task 3 may tune them to the art.
- Produces: `GateHTML.scene(assigns)`, a function component that renders `<svg class="scene" viewBox="0 0 1200 800" aria-hidden="true" focusable="false"><g id="scene-art">…</g></svg>`. In this task it is a placeholder: a ground diamond plus one group per vignette with ids `v-gate`, `v-court`, `v-hall`. Task 3 fills it.
- Produces: `GateHTML.vignette(assigns)` with attr `part` (one of `"gate"`, `"court"`, `"hall"`). It renders `<svg class={"vignette vignette-" <> @part} viewBox={crop} aria-hidden="true" focusable="false"><use href="#scene-art" /></svg>`. The crop viewBoxes are module attributes, set to placeholders here and tuned in Task 3. Vignettes reuse the art and duplicate no links.
- Produces: this markup, which Tasks 4–5 style and script:
  ```heex
  <main class="gate">
    <h1 class="sr-only">Chùa Máy</h1>
    <div class="stage">
      <.scene />
      <.vignette part="gate" />
      <.vignette part="court" />
      <ul class="machines">
        <li :for={m <- @machines}>
          <a class="machine" href={Machines.path(m)} style={"--x: #{elem(m.scene, 0)}%; --y: #{elem(m.scene, 1)}%; --accent: #{m.accent}"}>
            <img src={m.thumb} alt="" width="390" height="520" />
            <span class="machine-name">{m.name}</span>
            <span class="machine-tagline">{m.tagline}</span>
          </a>
        </li>
      </ul>
      <.vignette part="hall" />
    </div>
  </main>
  ```
  - The DOM order is the phone walk order. Desktop hides the vignettes, and the phone shows them while hiding the full scene.
  - Image `width` is the real PNG width at 520px tall. Read it from the Task 1 output and use each machine's own value. If they differ, add a `thumb_size: {w, h}` field rather than hard-coding one value.

- [ ] **Step 1: Write failing tests.**
  - `machines_test.exs`: `"every machine has a scene point inside the box"`. For each `m` in `Machines.all()`, assert `{x, y} = m.scene`, then `for v <- [x, y], do: assert(is_number(v) and v >= 0 and v <= 100)`.
  - `gate_test.exs`: keep the four existing tests, which still select `a.machine`. Add `"each machine is placed at its scene point"`: for each `{link, m}`, `[style] = Floki.attribute(link, "style")`, then assert `style =~ "--x: #{elem(m.scene, 0)}%"` and `style =~ "--y: #{elem(m.scene, 1)}%"`.
  - Add `"the scene is decorative and holds no links"`: `[svg] = Floki.find(doc, "svg.scene")`, assert `Floki.attribute(svg, "aria-hidden") == ["true"]` and `Floki.find(svg, "a") == []`. Also `assert ["true", "true", "true"] == doc |> Floki.find("svg.vignette") |> Floki.attribute("aria-hidden")`.
  - Add `"each machine link appears once"`: `Floki.find(doc, ~s(a[href="/xin-xam"]))` has length 1, and the same for `/giai-nghiep`.
- [ ] **Step 2: Run `mix test test/chua_tau_web`.** Expected: FAIL (no `scene` key, no `svg.scene`).
- [ ] **Step 3: Implement** the `scene` field and values, `scene/1` (placeholder), and the template above.
- [ ] **Step 4: Run `mix compile --warnings-as-errors && mix test`.** Expected: PASS.
- [ ] **Step 5: Commit** with `git commit -am "Gate: scene markup and machine scene points"` (plus `git add` for the new test).

### Task 3: The inked pagoda scene

**Files:**
- Modify: `lib/chua_tau_web/controllers/gate_html.ex` (fill `scene/1`, or move the SVG body to `gate_html/scene.html.heex` and call it from `scene/1`)
- Modify: `lib/chua_tau_web/machines.ex` (tune `scene` values only)

**Interfaces:**
- Consumes: the `scene/1` contract from Task 2 (viewBox `0 0 1200 800`, `aria-hidden`, groups `v-gate`, `v-court`, `v-hall`).
- Produces: final crop viewBoxes for `vignette/1` (`gate`, `court`, `hall`), each framing that part of the scene at about 3:2.
- Produces: inside the SVG, ids that Task 4 animates: `#smoke` (group of smoke puffs above the lư hương), `#ripple` (pond ripple ellipse(s)), `#lantern` (a hanging lantern group, pivot at its hook). It also produces a `<filter id="grain">` that Task 4 applies site-wide on the gate.

Draw in true 30° isometric (screen x = (gx−gy)·cos30, y = (gx+gy)·sin30 − z), with light from the upper left. Follow the sketch (`.superpowers/brainstorm/55289-1793641008/content/diorama-machines-v2.html`) for relationships, not coordinates:

- `v-gate`: cổng tam quan at the front (front-left in iso). It has three openings, the middle one taller, with tiled curved roofs and upturned eave tips, and a brass plaque reading `Chùa Máy` in Lora. Two stone lions sit just inside.
- `v-court`: the paved courtyard and path from the gate to the hall. It holds a large bronze lư hương on a stone pedestal at the centre, a lotus pond (`--glaze` water, `--jade` pads, a few lacquer/pink lotus) and moss edges. Leave two open flagstone spots either side of the lư hương where the machines stand. Each spot gets a low teak base (`--ink`-toned wood) drawn under the machine's foot point.
- `v-hall`: chính điện raised on a stone platform with steps, with red (`--lacquer`) columns, a hoành phi board and a double-eave roof. Nhà thờ vong sits far back right at about 55% opacity. Lanterns hang from the hall eaves (`#lantern`).
- Machines must read larger than the gate. Keep buildings low enough that the machines (about 260px tall at a 1200px-wide scene) dominate.

- [ ] **Step 1: Draw the scene** in the SVG with hand-authored paths. One 1.5px `--ink` stroke, `stroke-linejoin: round`, flat fills and one darker tone per face. A light `feTurbulence`/`feDisplacementMap` "hand" wobble on the outline group is allowed (the figures use `filter="url(#hand)"`).
- [ ] **Step 2: Tune `Machines.scene`** so each machine's foot lands on its teak base.
- [ ] **Step 3: Check it.** Run `mix phx.server`, open `http://localhost:4000/` at 1440×960, and take a screenshot.
  - Expected: it reads as a Vietnamese chùa courtyard, both machines stand on their bases, and nothing overlaps them.
  - Expected: Vietnamese diacritics render on the plaque.
- [ ] **Step 4: Run `mix compile --warnings-as-errors && mix test`.** Expected: PASS.
- [ ] **Step 5: Commit** with `git commit -am "Gate: inked pagoda scene"`.

### Task 4: Layout, phone walk, hover/focus and idle life

**Files:**
- Modify: `priv/static/css/gate.css` (rewrite)

**Interfaces:**
- Consumes: the markup from Task 2 (`.stage`, `.scene`, `.machines`, `.machine`, `--x`, `--y`, `.machine-name`, `.machine-tagline`), and from Task 3 the ids `#smoke`, `#ripple`, `#lantern` and the filter `#grain`.

- [ ] **Step 1: Write `gate.css`.**
  - **Top:** `@import` Google Fonts `Lora:wght@500;600` and `Be+Vietnam+Pro:wght@400;600` with `&subset=vietnamese` (css2 API: `display=swap`). Then the palette variables, `body{background:var(--paper)}`, and an `.sr-only` utility.
  - **Desktop (≥ 700px):** `.stage` is `position:relative; aspect-ratio:3/2; max-width:1200px; margin:auto`, and `.scene` fills it.
    - `.machine` is absolutely positioned with its bottom centre at `left:var(--x); top:var(--y)` (`transform:translate(-50%,-100%)`). Its height is about 32% of the stage, and the image fills that height.
    - `.machine-name` is a paper label (`--card` fill, 1.5px `--ink` border, small caps, letter-spaced) above the machine. It is hidden until `:hover` or `:focus-visible`. `.machine-tagline` is hidden on desktop.
    - On hover or focus the machine lifts `translateY(-4px)` over about 180ms. `:focus-visible` adds a 2px `--brass` outline offset 4px.
  - **Phone (< 700px):** `.stage` is a flex column, and the scene vignettes become separate crops.
    - Hide the full `.scene` with `position:absolute; width:0; height:0; overflow:hidden`, not `display:none`, because `<use>` and filters break when the source SVG is `display:none` in some browsers. Show the `.vignette`s at full width. On desktop, `.vignette{display:none}`.
    - The DOM order already gives the walk: gate → court → `.machines` → hall.
    - Each `.machine` is a static block: the centred image about 220px tall, `.machine-name` in Lora, `.machine-tagline` below, and a brass plaque "Vào". The plaque comes from CSS `::after{content:"Vào"}` so no copy is added to the DOM.
    - Plaque press state: `:active` drops it 2px and shrinks its shadow.
  - **Idle life:**
    - `#smoke` puffs rise and fade on staggered 9–12s loops, with a radial gradient fill allowed.
    - `#ripple` scales and fades on a 10s loop.
    - `#lantern` sways ±2° about its hook on a 9s alternate loop.
  - **Grain:** the `#grain` filter on a `body::after` overlay at 5% opacity, with `pointer-events:none`.
  - **`@media (prefers-reduced-motion: reduce)`:** `animation:none` and `transition:none` on everything above.
- [ ] **Step 2: Check it in a browser** at 1440×960, 768×1024, 390×844 and 320×640.
  - Expected desktop: both machines are visible without scrolling, and a hover shows the label and lifts the machine.
  - Expected phone: walk order gate → court → machines → hall, with no horizontal scroll at 320px (`document.documentElement.scrollWidth <= innerWidth`).
  - Tab through: each machine shows its label and ring.
  - With reduced motion emulated, nothing moves.
  - Save screenshots to `.playwright-mcp/`.
- [ ] **Step 3: Run `mix test`.** Expected: PASS.
- [ ] **Step 4: Commit** with `git commit -am "Gate: layout, phone walk and idle life"`.

### Task 5: Zoom-on-click

**Files:**
- Modify: `lib/chua_tau_web/controllers/gate_html/home.html.heex` (append one inline `<script>`)
- Modify: `priv/static/css/gate.css` (`.stage.zooming` transition)

**Interfaces:**
- Consumes: `.stage`, `a.machine`, and the `--x`/`--y` inline vars from Task 2.

- [ ] **Step 1: Write the script** (about 25 lines, an IIFE, no globals):
  - On `click` of `a.machine`, skip and let the browser handle it if any of these hold: `e.defaultPrevented`, `e.button !== 0`, any of `metaKey/ctrlKey/shiftKey/altKey`, `matchMedia('(prefers-reduced-motion: reduce)').matches`, or the phone layout (`matchMedia('(max-width: 699px)').matches`).
  - Otherwise call `preventDefault()`. Set `.stage` `transform-origin` to the link's `--x --y`, add the class `zooming` (CSS: `transform:scale(1.8)` and `filter:blur(2px)` on `.scene` over 300ms ease-in), and `setTimeout(() => location.assign(a.href), 300)`.
  - On `pageshow`, remove `zooming` so a bfcache restore shows the scene unzoomed.
- [ ] **Step 2: Check it in a browser.**
  - Plain click: zooms, then lands on `/xin-xam`.
  - Back: the scene is unzoomed.
  - Cmd-click: a new tab opens and the current page stays unzoomed.
  - Reduced motion: navigates straight away.
  - With JS disabled: the links still navigate.
- [ ] **Step 3: Run `mix compile --warnings-as-errors && mix test`.** Expected: PASS.
- [ ] **Step 4: Commit** with `git commit -am "Gate: zoom toward the machine on click"`.

### Task 6: Final pass

- [ ] **Step 1:** Check `CLAUDE.md`'s gate line. Update it to say `/` is the pagoda scene, and point to `scripts/capture-machines/README.md` for re-rendering machine images.
- [ ] **Step 2:** Run `mix compile --warnings-as-errors && mix test`. Expected: PASS.
- [ ] **Step 3:** Take final screenshots at desktop and phone widths and show them to the user.
- [ ] **Step 4: Commit** with `git commit -am "Docs: gate is the pagoda scene"`.
