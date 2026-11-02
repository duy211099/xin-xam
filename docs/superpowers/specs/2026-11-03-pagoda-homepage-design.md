# Homepage as a pagoda scene: design

## Intent

Today `/` (the gate, `GateController` + `gate_html/home.html.heex` + `priv/static/css/gate.css`) is a red arch with two thumbnail cards. The new homepage should impress in the first second and get people into a machine in the second. It is one hand-inked isometric pagoda courtyard, and the two real machines (Xin xăm, Giải nghiệp) stand in it. You click a machine and you're in.

The user's longer brief ("Chùa Máy": 8 machines, rotate/x-ray modes, túi nhỏ diary, sound, React app) is the long-term direction. This round only uses its look (palette, type, ink style) and its overview scene, with the machines that exist today.

## Goals

- One isometric diorama on desktop, roughly 3:2, that reads as a real Vietnamese chùa courtyard.
- The two machines are the stars: drawn larger than the buildings around them, and clickable.
- Clicking a machine opens it (`/xin-xam`, `/giai-nghiep`) with no extra step.
- Quiet idle life so the scene feels lived in.
- Works on a phone.

## Non-goals (this round)

- túi nhỏ / any saved record, sound, the mute toggle, rotate / x-ray / run modes on the homepage, new machines, English copy.
- Rebuilding anything in React/Vite.
- Changing the machine pages themselves.

## Anti-goals (would make this a failure even if it works)

- "Coming soon", locked or dead-looking halls. The other buildings are scenery, not promises.
- Glass UI, neon, zen minimalism, kawaii, rounded drop-shadow cards.
- Invented history about the temple or the machines in any copy (project rule).
- Machines that only work with JavaScript. They must be plain links.
- Machines lost in the scene, too small to notice.

## Agreed with the user

Layout, as shown in the sketch (`.superpowers/brainstorm/55289-1793641008/content/diorama-machines-v2.html`):

- **Gate (cổng tam quan)** at the front. In true 30° isometric that means front-left. It has three openings, the middle one taller, and a brass title plaque.
- **Courtyard (sân chùa)** with the lư hương (incense burner) in the middle, a lotus pond, and two stone lions by the gate. A paved path runs from the gate to the main hall.
- **Main hall (chính điện)** raised on a platform at the back, with red columns.
- **Memorial hall (nhà thờ vong)** far back right, drawn dimmer.
- **No wing halls.** Xin xăm stands in the courtyard on the left and Giải nghiệp on the right, each on a small low wooden base, one each side of the incense burner. Each is the real machine figure, not a new drawing.
- Only the two machines are interactive. Hover lifts the machine 4px and shows a paper label with its name. Nothing else is clickable.
- **Machine images** are captured from the machine figure pages **without the blue cast shadow** and **centred** (the current `priv/static/images/machines/*.png` have the shadow and sit off-centre). They need a transparent background so they stand on the courtyard.
- **Phone:** the scene turns into a vertical walk from the gate inward, with the two machines as the stops you can enter.
- Palette, locked. Define these as CSS variables in the gate stylesheet:
  `--paper #E8D7B8`, `--card #F5EBDD`, `--lacquer #B84B32`, `--brass #D5A64B`, `--jade #536C56`, `--ink #49372E`, `--glaze #2E4A5C` (water and ceramic only).
- Type: Lora for display, Be Vietnam Pro for body and labels. Labels use letter-spaced small caps in ink on `--card`. Check that every Vietnamese diacritic renders.
- Rendering: one ink outline about 1.5px, flat fills, one shadow tone per colour, gradients only for smoke and candlelight, a 4–6% paper-grain overlay, light from the upper left.
- Idle life: smoke from the lư hương, a ripple on the pond, a lantern sway. No animation loop shorter than 8s. Everything is still under `prefers-reduced-motion`.

## Calls I made (the user hasn't confirmed these)

- **Stack:** stays in the existing Phoenix app. The scene is inline SVG in the gate template (or an SVG partial it includes), styled by `gate.css`, with a small amount of inline JS at most. No React, no Vite, no build step: the project has no asset pipeline and the machines are already single HTML files.
- **Art:** I draw the scene as inked SVG in code, matching the ink and flat-band style of the machine figures. The first version should already look finished, not like blocks. Detailing can improve later.
- **Plaque text:** the user approved "Chùa Máy" from their brief. The page `<title>`/SEO (`ChuaTauWeb.Seo.gate/0`) stays as is.
- **Click:** each machine is an `<a href>` around its image. With JS and motion allowed, the click zooms toward the machine for about 300ms and then navigates. Without JS, or under reduced motion, it navigates straight away. This stands in for the brief's "focus view", since the machines live on their own pages.
- **Keyboard:** a focused machine gets the same lift and label as hover, plus a visible focus ring. The link's accessible name is the machine name.
- **Machine list:** `ChuaTauWeb.Machines` stays the source of names, taglines, paths and image paths. Each machine gets a scene position. The template places machines from that list, not from hard-coded markup.
- **Phone layout (under ~700px):** a vertical column. At the top is an inked vignette of the gate with the plaque. Below it is a small courtyard vignette (incense burner, pond) that is scenery only. Then come the two machines, each a large centred machine image with its name and tagline as a plaque button that links in. The main hall vignette closes the column. Vignettes can be crops of the same SVG.
- **Capturing machine images:** must be repeatable, not a one-off. Commit a small script, or a documented procedure in the repo, that renders each figure page in a headless browser with the cast shadow turned off, trims to the machine and centres it, and writes a transparent PNG at 2× display size. The figure pages draw the shadow via something named `castShadow`. Find a way to turn it off without editing the figure files, since those get replaced by newer builds (see CLAUDE.md). If that's impossible, say so before editing them.
  - **How:** a capture script may rewrite the figure page *in memory* before it renders, for example a Playwright route that rewrites the response or an init script that turns the shadow draw call into a no-op. The files on disk stay untouched. As a last resort, key out the shadow's blue pixels in post-processing. The sketch did this in-browser and it came out clean.
  - **Tooling:** a dev-only Node script using Playwright under `scripts/capture-machines/` with its own `package.json`, run by hand with `npx`. It is not part of `mix setup` or the runtime. Document the command in its README.
  - **Pose:** the figure's default load state and angle, the same as today's thumbnails (doors closed, see-through off). Only the shadow and the framing change.
  - **Output:** overwrite `priv/static/images/machines/<slug>.png` in place, so `Machines.thumb` keeps its paths.
- **Fonts:** load Lora and Be Vietnam Pro from Google Fonts with the `vietnamese` subset, on the gate page only. Self-hosting can come later.
- **Scene position:** add one field to `ChuaTauWeb.Machines`, `scene: {x, y}`. It holds the machine's foot point in the scene SVG's coordinates, as a percentage of the scene box, so HTML can place it.
- **Markup:** draw the scene once, as a decorative `aria-hidden` SVG holding the buildings, courtyard and vignettes. Render the machines once as an HTML list of `<a class="machine">` links. On desktop each link is absolutely positioned over the SVG at its `scene` point. On a phone CSS reflows the same links into the column between the vignettes. Each machine link exists exactly once in the DOM, and no machine is duplicated for the two layouts.
- **Sketch status:** the sketch is a guide for composition, not a coordinate spec. Keep the relationships: gate at the front, main hall at the back, machines either side of the incense burner, memorial hall dimmed at the far back right, machines larger than the buildings.
- **Zoom-on-click:** plain click only. Modifier and middle clicks fall through to the browser. Scale the scene toward the machine's point with a CSS transform, then `location.assign` after about 300ms. Reset the transform on `pageshow` so the back button never shows a zoomed scene.
- **Tests:** update `test/chua_tau_web/controllers/gate_test.exs` to the new markup. Keep checking that each machine is a link to `Machines.path/1` in list order, carries its name and uses its image. Keep the redirect and SEO tests unchanged.
- **Mockup files** under `.superpowers/` are for reference only and aren't shipped.

## Left to the builder

- Exact proportions, building details (roof curls, columns, lanterns, trees), and the placement of idle animations, within the rules above.
- Whether smoke is CSS-animated SVG or a tiny canvas. Keep it light.
- How the paper-grain overlay is made (an SVG noise filter or a small tiled image).
- Scene scaling between phone and desktop widths.

## Done means

- `/` shows the scene on desktop and the walk on a phone. Both machines are visible without scrolling on desktop and are clickable through to their pages.
- Machine images have no blue shadow and are centred.
- Reduced motion turns off all animation and the zoom.
- `mix compile --warnings-as-errors` and `mix test` pass.
- Checked in a real browser at desktop and phone widths, with screenshots.
