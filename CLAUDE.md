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
- `ChuaTauWeb.Seo` renders head tags for both the figure and the share pages. Share pages with `sample == true` are `noindex` and left out of the sitemap.
- `ChuaTauWeb.Machines` is the machine list. `/` is the gate (`GateController`, styled by `priv/static/css/gate.css`). The fortune figure lives at `/xin-xam` and gets a back link spliced in before `</body>`. Old `/?col=…` style links redirect there.
- Share page styling is plain CSS in `priv/static/css/share.css`.

## Rules

- Do not invent history facts about the temple or the machine in copy.
- Placeholder PNGs in `priv/static/images/` are to be replaced by real ones.
