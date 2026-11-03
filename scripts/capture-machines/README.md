# Machine images

Renders the machine figure pages and writes the images the homepage stands in the courtyard: `priv/static/images/machines/<slug>.png`. They have no cast shadow and a transparent background, are trimmed to the machine and are 520px tall.

The figure files are not edited. The script removes the shadow in memory while the page loads, and it fails loudly if a newer figure build has changed the `castShadow` declaration it looks for.

```
mix phx.server                      # in another terminal
cd scripts/capture-machines
npm install
npx playwright install chromium
node capture.mjs                    # or: node capture.mjs http://localhost:4001
```

Re-run it after replacing `priv/figure/index.html` or `priv/giai-nghiep/index.html`.
