# CLAUDE.md

## What this is

Chùa Tàu fortune machine: Phoenix 1.7 (Bandit, no DB, no asset pipeline) serving an existing single-file figure page plus server-rendered share pages. Vietnamese UI.

## Commands

```
mix setup
mix phx.server                     # http://localhost:4000 (PORT env var sets the dev port)
mix compile --warnings-as-errors
mix test
```

## Architecture

- `ChuaTau.Fortunes` loads `priv/fortunes/*.json` at application start into `:persistent_term`. Parsing and validation happen there and raise on bad data. `Collection` and `Fortune` are structs, written entries are in a map keyed by number. `Fortunes.Sample` generates deterministic `(mẫu)` text for numbers with no entry. The page JSON always contains every number `1..total` and sets `generateSamples: false`, so the browser never invents text.
- `ChuaTauWeb.FigurePage` splices the server into `priv/figure/index.html` at three markers only: `</head>`, the `ct-fortunes` script body and `</body>`. Do not rely on anything else in that file, it gets replaced by newer builds. Boot raises if a marker is missing or duplicated. The JSON is encoded with `escape: :html_safe`.
- `ChuaTauWeb.Seo` renders head tags for the gate, the figure and the share pages. Share pages with `sample == true` are `noindex` and left out of the sitemap.
- `ChuaTauWeb.Machines` is the machine list. `/` is the gate: an inline isometric pagoda scene (`GateController`, art in `gate_html/scene_art.html.heex`, styled by `priv/static/css/gate.css`) with each machine's image placed at its `scene` point. Phones get crops of the same art via `<use>`. Re-render the machine images with `scripts/capture-machines/` (see its README). The fortune figure lives at `/xin-xam` and gets a back link spliced in before `</body>`. Old `/?col=…` style links redirect there.
- `ChuaTauWeb.MachinePage` serves `priv/<slug>/index.html` for `giai-nghiep` and `cau-nang`. It splices SEO at the single `</head>` and strips the `<title>`. `ChuaTauWeb.Certificate` holds the three kinds (than, khau, y). `/giai-nghiep/:loai` is the certificate share page, styled by `priv/static/css/certificate.css`. `window.ctCertificate.draw` is the canvas contract that the OG images are rendered from.
- Cầu nắng (`/cau-nang`) is a shrine with no rain anywhere. Its slip always says "Trời sẽ nắng thôi", with no random number or poem. Source is `figures/cau-nang/`; rebuild with `python3 ~/.claude/skills/colorfigures/scripts/build.py figures/cau-nang/cau-nang.html priv/cau-nang/index.html`. `?backdrop=0` drops sky, ground and stones, which the machine capture uses.
- Share page styling is plain CSS in `priv/static/css/share.css`.

## Rules

- Do not invent history facts about the temple or the machine in copy.
- Placeholder PNGs in `priv/static/images/` are to be replaced by real ones.
