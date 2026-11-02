# Cổng chùa + Máy giải nghiệp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the single-machine site into a pagoda-gate homepage with a growing grid of machines, move the fortune machine to `/xin-xam`, and add the máy giải nghiệp figure with a certificate that can be downloaded and shared.

**Architecture:** `ChuaTauWeb.Machines` lists the machines, and the homepage, the sitemap and the redirect logic read from it. The xin xăm figure keeps its three-marker splice in `FigurePage`. The new figure is one self-contained HTML file, and a small splicer injects SEO head tags at its single `</head>`. Certificate share pages are server-rendered HEEx and plain CSS, like `/que`.

**Tech Stack:** Elixir, Phoenix 1.7 (Bandit, no DB, no asset pipeline), HEEx, plain CSS, Floki in tests. The figure is vanilla HTML/CSS/JS built with the **colorfigures** skill, using Canvas for the PNG and Web Audio for sound.

**Spec:** `docs/superpowers/specs/2026-11-02-giai-nghiep-design.md`

## Global Constraints

- The owner's Vietnamese strings are used exactly as written in the spec, with diacritics, stored as NFC.
- No outside requests from any page: no CDN, no web fonts, no analytics. Figure fonts are system serif/sans only.
- Never edit `priv/figure/index.html`. It is replaced by newer builds. Rely only on its three markers.
- `/que/:set/:n` paths do not move.
- No temple history or facts in any copy. The gate is generic, with no name and no captions about the real place.
- The see-through stays deadpan: labels name parts, with no jokes or explanations added.
- Mobile first: at 360px width there is no horizontal scroll on any page.
- `mix compile --warnings-as-errors` and `mix test` pass at the end of every task.

## Review Focus

1. **Old bookmarks:** `/?col=lu-to&free=1` redirects to `/xin-xam?col=lu-to&free=1` with the query unchanged. `/?utm_source=fb` stays on the gate. Covered by tests in Task 1.
2. **Clicks mid-run:** pressing a type, NẶNG or a coin while "ĐANG GIẢI..." runs is ignored. "HẾT TIỀN?" during the run cancels every pending timer, and no late receipt appears. Covered by browser checks in Task 2.
3. **Changing type or NẶNG after paying:** the LCD shows the new price. If the money already in covers it, the run starts at once. Covered by browser checks in Task 2.
4. **No clipboard and no `navigator.share`** (plain-http preview, older browsers): Chia sẻ shows the link as selectable text instead of failing silently. Covered by a browser check in Task 2.
5. **Diacritics in the PNG:** "KHẨU" and "Ý" render with their marks on the canvas using system fonts, not as boxes. Covered by a browser check in Task 2 and by the OG images in Task 4.

---

### Task 1: Gate homepage, machine list, fortune machine moves to `/xin-xam`

**Files:**
- Create: `lib/chua_tau_web/machines.ex`, `lib/chua_tau_web/controllers/gate_controller.ex`, `lib/chua_tau_web/controllers/gate_html.ex`, `lib/chua_tau_web/controllers/gate_html/home.html.heex`, `priv/static/css/gate.css`, `priv/static/images/machines/xin-xam.png`, `priv/static/images/machines/giai-nghiep.png`
- Modify: `lib/chua_tau_web/router.ex`, `lib/chua_tau_web/seo.ex`, `lib/chua_tau_web/figure_page.ex`, `lib/chua_tau_web/controllers/figure_controller.ex`, `lib/chua_tau_web/controllers/meta_controller.ex`, `lib/chua_tau_web/controllers/share_controller.ex`, `lib/chua_tau_web/controllers/share_html/show.html.heex`, `lib/chua_tau_web/components/layouts/root.html.heex`, `CLAUDE.md`
- Test: `test/chua_tau_web/controllers/pages_test.exs`, new `test/chua_tau_web/controllers/gate_test.exs`

**Interfaces:**
- Produces:
  - `%ChuaTauWeb.Machines{slug: String.t(), name: String.t(), tagline: String.t(), thumb: String.t(), accent: String.t()}`
  - `Machines.all() :: [t]` in display order: xin-xam first, then giai-nghiep. Both entries are listed from this task on. `/giai-nghiep` is a 404 until Task 3, which is acceptable mid-branch.
  - `Machines.path(t) :: String.t()`, which returns `"/" <> slug`.
  - `%ChuaTauWeb.Seo{}` gains `image: "/images/og.png"` (default). `head_tags` uses `@seo.image` for og:image and twitter:image.
  - `Seo.render(t) :: iodata()` replaces `render_home/0`. `Seo.gate/0` and `Seo.xin_xam/0` replace `home/0`.
  - The root layout reads a `:stylesheet` assign (a path string) instead of the hard-coded `/css/share.css`. `ShareController` passes `"/css/share.css"`.

Machine entries (exact):

| slug | name | tagline | thumb | accent |
|---|---|---|---|---|
| `xin-xam` | `Xin xăm` | `Thành tâm khấn nguyện, bỏ đồng xu, nhận quẻ.` | `/images/machines/xin-xam.png` | `#d6a53a` |
| `giai-nghiep` | `Giải nghiệp` | `Nhanh · Gọn · Có kết quả` | `/images/machines/giai-nghiep.png` | `#e5533d` |

- [ ] **Step 1: Write failing tests.** In `gate_test.exs`:
  - `GET /` renders one `a.machine` per `Machines.all()`, with hrefs `["/xin-xam", "/giai-nghiep"]` in that order. Each link contains its name and an `img` whose `src` is the thumb.
  - `GET /` contains no `ct-fortunes` script, has exactly one `<title>`, and has a canonical URL ending in `/`.
  - `GET /?col=lu-to&free=1` → 302 with `location` `/xin-xam?col=lu-to&free=1`. The same holds for each of `pal labels xr welcome phase press step`.
  - `GET /?utm_source=fb` → 200 gate.

  In `pages_test.exs`:
  - Change `describe "GET /"` to `GET /xin-xam`. The title stays `"Xin xăm online · Quan Âm Linh Xăm 100 quẻ"` and the canonical URL ends in `/xin-xam`.
  - Assert the page has `a[href="/"]` with text `← Cổng chùa`.
  - The share button href becomes `"/xin-xam?col=quan-am"`.
  - `/api/fortunes` is compared with the `/xin-xam` page.
  - Sitemap: 202 `<loc>`, containing `/` and `/xin-xam`. Add `/giai-nghiep` in Task 3.
  - Manifest: `name == Seo.site_name()`, `start_url == "/"`.
  - Static assets: the two machine thumbs and `/css/gate.css` return 200.
- [ ] **Step 2: Run `mix test`.** Expected: FAIL. `/` still serves the figure, and `Machines` is undefined.
- [ ] **Step 3: Implement.**
  - **Router:** `get "/", GateController, :home`, then `get "/xin-xam", FigureController, :xin_xam` (rename from `:home`).
  - **GateController.home/2:** if any of `~w(col free pal labels xr welcome phase press step)` is a key in `conn.query_params`, `redirect(to: "/xin-xam?" <> conn.query_string)`. Otherwise render `:home` with `machines: Machines.all()`, `seo: Seo.gate()`, `stylesheet: "/css/gate.css"`, using the root layout like ShareController.
  - **FigurePage.assemble:** use `Seo.render(Seo.xin_xam())`. Insert `<a class="ct-gate-link" href="/">← Cổng chùa</a>` plus a small inline `<style>` (fixed, top-left, small, paper and ink colours) just before `parts.tail` (the `</body>`).
  - **Seo:** `xin_xam/0` is the old `home/0` with `url: absolute("/xin-xam")`. `gate/0` has a new site-level title and description written by the builder. They must be plain and factual (a gate with toy machines: xin xăm and giải nghiệp), with no temple history. Change `@site_name` to match. The WebSite JSON-LD moves to `gate/0`.
  - **Manifest:** `name: Seo.site_name()` and `short_name: "Cổng chùa"`. Other fields are unchanged.
  - **Sitemap:** paths are `["/" | Enum.map(Machines.all(), &Machines.path/1)]` (filter to served machines until Task 3: `xin-xam` only) followed by the share paths.
  - **Homepage `home.html.heex`** (layout B from the spec): a hand-inked generic pagoda gate drawn as inline SVG framing the top. Under it, `<ul class="machines">` with one `<li><a class="machine" href=…><img src={thumb} alt=""><span class="machine-name">name</span><span class="machine-tagline">tagline</span></a></li>` per machine. The `--accent` CSS variable is set inline from `accent`. `gate.css`: CSS grid `repeat(auto-fill, minmax(150px, 1fr))` capped near 4 columns on desktop, 2 columns at 360px. Paper `#f3eee4`, ink `#2b1a10`, heavy ink borders, a flat button in the accent colour. It must look right with 2 and with 8 cards.
  - **Thumbs:** 300×400 placeholder PNGs, a solid accent colour with a darker border. Any method works, e.g. `python3 -I` with stdlib `zlib`/`struct`.
  - **CLAUDE.md:** delete the "Never write into `../xin-xam/`" rule. Under Architecture, add: `ChuaTauWeb.Machines` is the machine list; `/` is the gate (`GateController`); the fortune figure is at `/xin-xam` and gets a back link spliced before `</body>`; `/?col=…` style links redirect there.
- [ ] **Step 4: Run `mix compile --warnings-as-errors && mix test`.** Expected: PASS.
- [ ] **Step 5: Check in a browser.** Run `mix phx.server` and open `/`, `/xin-xam` and `/que/quan-am/1` at 360px and 1280px. Check: no horizontal scroll; both cards tap through; the back link shows on `/xin-xam` and doesn't cover the figure's own controls; the share page button goes to `/xin-xam?col=quan-am`.
- [ ] **Step 6: Commit.** `git add -A lib priv/static test CLAUDE.md && git commit -m "Gate homepage with machine list; fortune machine moves to /xin-xam"`

### Task 2: The máy giải nghiệp figure (colorfigures)

**Files:**
- Create: `priv/giai-nghiep/index.html`
- Test: `test/chua_tau_web/giai_nghiep_figure_test.exs`

**Interfaces:**
- Produces, inside `priv/giai-nghiep/index.html`:
  - Exactly one `</head>` and exactly one `<title>…</title>`. The server strips the title in Task 3.
  - `window.ctCertificate.draw(canvas, {loai, date})`. `loai` is `"than" | "khau" | "y"`, and `date` is a `"dd/mm/yyyy"` string or `null` (no date line). It draws the style-B certificate scaled to the canvas's current width and height, and must look right at 1200×630 (landscape) as well as the download size. Task 4 calls it.
  - Lưu giấy downloads `giai-nghiep-<loai>.png` (1200×630, today's date).
  - The Chia sẻ URL is `location.origin + '/giai-nghiep/' + loai`.
  - A link `<a href="/">← Cổng chùa</a>`.

- [ ] **Step 1: Write the failing test** `giai_nghiep_figure_test.exs`. Read the file as a UTF-8 binary and assert:
  - `String.normalize(html, :nfc) == html`.
  - It contains each of these exact strings: `MÁY GIẢI NGHIỆP`, `Nhanh · Gọn · Có kết quả`, `THÂN`, `KHẨU`, `Ý`, `NẶNG`, `NHÉT TIỀN VÀO ĐÂY`, `CHỌN NGHIỆP`, `ĐANG GIẢI...`, `XONG!`, `KẾT QUẢ`, `KHÔNG HOÀN TIỀN`, `GIẤY CHỨNG NHẬN ĐÃ GIẢI NGHIỆP`, `Hiệu lực: đến lần sau.`, `HẾT TIỀN?`, `Hộp tiền`, `Máy in kết quả`, `Búa chuông`, `Bộ xịt khói`, `Đèn kệ`, `Mô-tơ rung kệ`, `Thanh giữ hàng`, `Khoảng trống`, `Lưu giấy`, `Chia sẻ`, `← Cổng chùa`, `ctCertificate`.
  - Exactly one `</head>` and exactly one `<title>`.
  - No outside requests: refute `~r/(src|href)\s*=\s*["']\s*(https?:)?\/\//i`, `~r/url\(\s*["']?(https?:)?\/\//i`, `~r/@import/` and `~r/fetch\(|XMLHttpRequest/`.
- [ ] **Step 2: Run `mix test test/chua_tau_web/giai_nghiep_figure_test.exs`.** Expected: FAIL, file missing.
- [ ] **Step 3: Build the figure with the colorfigures skill.** Load the skill and follow it. The spec's "Máy giải nghiệp: the figure" and "The certificate" sections are the brief, word for word. Pinned values:
  - Price is 50.000đ for each type and 100.000đ with NẶNG. Formatting uses a dot as the thousands separator plus `đ`.
  - Coin = 10.000đ and bill = 50.000đ, so a plain purchase takes 5 coins or 1 bill.
  - The shelf glows and shakes for 2000ms. Then the bell rings, then the smoke puffs, then "XONG!" and the receipt slides out.
  - Overpay is kept, and the counter resets to 0 after the run.
  - State machine `idle → chosen → paying → running → done`. Input during `running` is ignored. "HẾT TIỀN?" goes back to `idle` from any state and clears all timers. The cash box keeps its fill level: money never leaves it.
  - A type change during `chosen`/`paying` re-prices. If paid ≥ the new price, go straight to `running`.
  - Each see-through label lights while its part runs: coin → Hộp tiền; type → Đèn kệ; run → Mô-tơ rung kệ, Búa chuông, Bộ xịt khói, Máy in kết quả. Thanh giữ hàng and Khoảng trống are static labels.
  - Clicking the receipt in the tray opens the certificate overlay. It has Lưu giấy, Chia sẻ and a close button. Close returns to `idle` with the tray empty.
  - Chia sẻ tries `navigator.share({url})`, then `navigator.clipboard.writeText(url)` with the note "Đã chép link". If neither works, it shows the URL in a read-only selectable `<input>`.
  - Body is tomato red `#e5533d` with mustard `#d6a53a` accents, plus the skill's usual swatches. The dented corner and the "KHÔNG HOÀN TIỀN" side sticker are as the spec says.
  - Clink and bell come from Web Audio oscillators. The AudioContext is created on first user input.
- [ ] **Step 4: Run the test.** Expected: PASS.
- [ ] **Step 5: Check in a browser** (open the file directly or with any static server; Playwright MCP at 390×844 and 1280×800). Each item needs to be confirmed by looking:
  1. At rest the LCD shows CHỌN NGHIỆP. Pressing KHẨU lights shelf 2 and shows 50.000đ. Pressing NẶNG shows 100.000đ.
  2. Coin clicks add 10.000đ each, and the cash box fills in see-through. At 100.000đ the run plays: shake about 2s, bell, smoke, XONG!, receipt.
  3. Clicking coins and THÂN during the run changes nothing. HẾT TIỀN? during the run → idle, and no receipt appears afterwards.
  4. Pay 50.000đ with no type chosen, then press Ý → the run starts at once.
  5. Clicking the receipt opens the certificate. Lưu giấy downloads `giai-nghiep-y.png`. Open the PNG and check that "Ý" and "KHẨU" (on a KHẨU run) show their diacritics.
  6. With `navigator.share` and `navigator.clipboard` deleted in the console, Chia sẻ shows the selectable URL.
  7. Drag rotates a full 360°, See-through shows every labelled part, and nothing on the shelves ever drops.
  8. There are no network requests other than the page itself (`browser_network_requests`).
- [ ] **Step 6: Commit.** `git add priv/giai-nghiep test/chua_tau_web/giai_nghiep_figure_test.exs && git commit -m "Máy giải nghiệp figure"`

### Task 3: Serve `/giai-nghiep` and the certificate share pages

**Files:**
- Create: `lib/chua_tau_web/giai_nghiep_page.ex`, `lib/chua_tau_web/certificate.ex`, `lib/chua_tau_web/controllers/giai_nghiep_controller.ex`, `lib/chua_tau_web/controllers/giai_nghiep_html.ex`, `lib/chua_tau_web/controllers/giai_nghiep_html/show.html.heex`, `priv/static/css/certificate.css`, `priv/static/images/giai-nghiep/{than,khau,y}.png` (placeholders)
- Modify: `lib/chua_tau_web/router.ex`, `lib/chua_tau_web/seo.ex`, `lib/chua_tau_web/controllers/meta_controller.ex`, `lib/chua_tau/application.ex`, `CLAUDE.md`
- Test: `test/chua_tau_web/giai_nghiep_page_test.exs`, `test/chua_tau_web/controllers/giai_nghiep_test.exs`, `test/chua_tau_web/controllers/pages_test.exs` (sitemap)

**Interfaces:**
- Consumes: `Seo.render/1`, `%Seo{image: _}`, `Machines`, the `:stylesheet` layout assign (Task 1). The figure contract (Task 2).
- Produces:
  - `ChuaTauWeb.Certificate.kinds() :: [{"than", "THÂN"}, {"khau", "KHẨU"}, {"y", "Ý"}]` and `label(String.t()) :: String.t() | nil`.
  - `ChuaTauWeb.GiaiNghiepPage.path/0`, `load!/0`, `parse!(binary) :: %{head: binary, tail: binary}` (raises `ArgumentError` unless exactly one `</head>`), and `render/0 :: iodata` (the head with its first `<title>…</title>` removed, then `Seo.render(Seo.giai_nghiep())`, then the tail). It follows `FigurePage`: `:persistent_term`, and the `:reload_figure` env re-reads the file.
  - `Seo.giai_nghiep/0` (url `/giai-nghiep`) and `Seo.certificate(loai, label)` (url `/giai-nghiep/<loai>`, image `/images/giai-nghiep/<loai>.png`).

- [ ] **Step 1: Write failing tests.**
  - `giai_nghiep_page_test.exs`: the same four cases as `figure_page_test.exs` but for `</head>` only. The shipped file parses.
  - `giai_nghiep_test.exs`:
    - `GET /giai-nghiep` → 200, one `<title>` that `Seo.giai_nghiep/0` sets, canonical URL ending `/giai-nghiep`, body contains `MÁY GIẢI NGHIỆP`.
    - For each `{loai, label}` in `Certificate.kinds()`: `GET /giai-nghiep/<loai>` → 200, contains `GIẤY CHỨNG NHẬN ĐÃ GIẢI NGHIỆP`, `Loại: <label>` and `Hiệu lực: đến lần sau.`; `og:image` ends with `/images/giai-nghiep/<loai>.png`; no robots meta; `a.cert-button` href is `/giai-nghiep`.
    - `GET /giai-nghiep/nang`, `/giai-nghiep/THAN` and `/giai-nghiep/x` → 404 with `KHÔNG TÌM THẤY`.
    - The three OG PNGs and `/css/certificate.css` return 200.
  - `pages_test.exs` sitemap: 206 `<loc>`, including `/giai-nghiep` and `/giai-nghiep/than|khau|y`.
- [ ] **Step 2: Run `mix test`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
  - **Router:** `get "/giai-nghiep", GiaiNghiepController, :machine` and `get "/giai-nghiep/:loai", GiaiNghiepController, :show`.
  - **Boot:** `ChuaTauWeb.GiaiNghiepPage.load!()` in `Application.start/2` after `FigurePage.load!()`.
  - **`show.html.heex`:** the style-B certificate in HTML/CSS with no date. It has a "MÁY GIẢI NGHIỆP" line, the red serif heading, `Loại: <label>`, `Hiệu lực: đến lần sau.`, and the tilted round "ĐÃ GIẢI" seal. Below it, `<a class="cert-button" href="/giai-nghiep">Giải nghiệp</a>` and a small "← Cổng chùa" link. `certificate.css`: cream paper, double gold border `#d6a53a`, red `#b3261e`.
  - **`Seo.certificate/2`:** title `"Giấy chứng nhận đã giải nghiệp · Loại <label> · Máy giải nghiệp"`. The description is written by the builder from the certificate text only.
  - **Sitemap:** drop the Task 1 `xin-xam`-only filter, then append `"/giai-nghiep/" <> loai` for each kind.
  - **OG placeholders:** 1200×630 cream PNGs. Task 4 replaces them.
  - **CLAUDE.md Architecture:** `ChuaTauWeb.GiaiNghiepPage` splices SEO at the single `</head>` of `priv/giai-nghiep/index.html` and strips its `<title>`. `ChuaTauWeb.Certificate` holds the three kinds. `window.ctCertificate.draw` is the canvas contract that the OG images are rendered from.
- [ ] **Step 4: Run `mix compile --warnings-as-errors && mix test`.** Expected: PASS.
- [ ] **Step 5: Check in a browser.** Open `/` → tap Giải nghiệp → play a full run → Chia sẻ copies `http://localhost:4000/giai-nghiep/<loai>` → open it → the share page shows → its button leads back to the machine.
- [ ] **Step 6: Commit.** `git commit -m "Serve máy giải nghiệp and certificate share pages"`

### Task 4: Certificate OG images from the figure's renderer

**Files:**
- Modify: `priv/static/images/giai-nghiep/{than,khau,y}.png`

- [ ] **Step 1: Render.** With `mix phx.server` running, use Playwright on `/giai-nghiep`. For each loai, run `const c = document.createElement('canvas'); c.width = 1200; c.height = 630; ctCertificate.draw(c, {loai, date: null}); return c.toDataURL('image/png')`. Decode the result and write it over the placeholder.
- [ ] **Step 2: Verify.** `file priv/static/images/giai-nghiep/*.png` reports `1200 x 630`. Open each PNG and check that the label and diacritics are correct and that nothing is clipped.
- [ ] **Step 3: Run `mix test`.** Expected: PASS.
- [ ] **Step 4: Commit.** `git commit -m "Certificate OG images rendered from the figure"`
