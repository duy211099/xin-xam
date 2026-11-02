# Xin xăm online

A small Phoenix 1.7 app that serves an interactive fortune machine (máy xin xăm ảo) with fortune data, SEO tags and a share page per fortune. Vietnamese UI, made for fun. No database.

## Run

```
mix setup
mix phx.server     # http://localhost:4000
mix test
```

## Routes

- `/` the figure page, with the fortune JSON and SEO tags injected. `?col=<id>` is handled by the page's own JS.
- `/que/:set/:n` a server-rendered share page for one fortune. 404 for an unknown set or a number outside `1..total`.
- `/api/fortunes`, `/sitemap.xml`, `/robots.txt`, `/manifest.webmanifest`.

## Add a fortune set

Drop a JSON file in `priv/fortunes/`. One file is one collection, sorted by `order` and then by filename. The files are read and validated at start, and a bad file stops the boot with a message naming it.

```json
{
  "collection": "quan-am",
  "order": 1,
  "name": "Quan Âm Linh Xăm",
  "total": 100,
  "sample": false,
  "fortunes": [
    {
      "number": 1,
      "title": "...",
      "category": "good",
      "poem": ["line 1", "line 2"],
      "interpretation": "...",
      "advice": "..."
    }
  ]
}
```

`collection` is the URL slug. `category` is `good`, `neutral`, `bad` or any other label. A number with no entry gets a deterministic generated sample marked `(mẫu)`. Entries with `sample: false` are listed in the sitemap and are indexable.

## The figure page

`priv/figure/index.html` is built from `../xin-xam/chua-tau/chua-tau.html`:

```
python3 ~/.claude-account2/skills/colorfigures/scripts/build.py chua-tau.html index.html
```

then copy `index.html` here. The server relies on only three markers, each exactly once: `</head>`, `<script id="ct-fortunes" type="application/json">...</script>` and `</body>`. It raises at boot if one is missing or duplicated. In dev the file is re-read on every request.

## Images

Replace the placeholders in `priv/static/images/`: `icon-192.png`, `icon-512.png` and `og.png` (1200x630).

## Deploy

The root `Dockerfile` builds a release (Elixir 1.18.4, OTP 27, Debian bookworm). The container listens on port 4000 and needs two environment variables:

- `SECRET_KEY_BASE`: generate one with `mix phx.gen.secret`.
- `PHX_HOST`: the public host name, used in canonical, Open Graph and sitemap URLs.

On Dokploy, create an application from this repository with build type Dockerfile, set those variables, and point a domain at port 4000.
