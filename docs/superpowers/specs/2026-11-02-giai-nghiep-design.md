# Cổng chùa + Máy giải nghiệp: design

Date: 2026-11-02
Status: approved 2026-11-02

## Intent

The site currently has one thing: the fortune machine (máy xin xăm) at `/`. The owner wants a second toy machine, **máy giải nghiệp**, a deadpan joke vending machine for clearing karma. They also expect more machines later. So the site becomes a **pagoda gate (cổng chùa) with a growing row of machines**, and each machine gets its own page.

It's just for fun. Success means someone plays the machine, laughs at the see-through, and posts their certificate.

## Goals

1. A homepage at `/` showing a generic pagoda gate with a grid of machines under it. Each machine has a button, and tapping the machine or the button opens it.
2. Move the fortune machine from `/` to `/xin-xam`.
3. A new machine at `/giai-nghiep`: a colorfigures figure built to the owner's spec (below), as a single self-contained HTML file.
4. The giải nghiệp certificate can be **downloaded as a PNG** and **shared as a link** with a preview card.
5. Adding a third machine later means adding its figure file plus one entry in a machine list. Nothing else changes by hand.

## Non-goals

- Accounts, real payment, history, or anything saved on the server.
- Dated or personalised share links. Share pages are fixed per karma type.
- Live 3D figures on the homepage. Thumbnails are still images.

## Anti-goals (a failure even if it works)

- Breaking any `/que/...` fortune share link that's already out there.
- Making up history facts about the temple or the machines anywhere in the copy. The gate is a generic pagoda gate with no name or captions about the real place.
- Any outside request from a figure page (fonts, CDNs, analytics).
- Changing or paraphrasing the owner's Vietnamese strings. They must be exact, with diacritics.
- Breaking the deadpan tone of the see-through with winks or explanations.

## Constraints from the existing project

- Phoenix 1.7, Bandit, no DB, no asset pipeline. Static files are served from `priv/static` (`css`, `images`).
- `ChuaTauWeb.FigurePage` splices the xin xăm page at exactly three markers. Its source `priv/figure/index.html` gets replaced by newer builds from elsewhere, so don't edit that file. Relying only on the markers still holds.
- The xin xăm figure builds share URLs as `location.origin + '/que/' + set + '/' + n`. Those stay valid because `/que/...` stays.
- `ChuaTauWeb.Seo` renders head tags for every page. Today its site name and OG image are xin-xăm specific.

## Routes

| Path | What |
|---|---|
| `/` | Homepage: gate + machine grid (new) |
| `/xin-xam` | Fortune machine (moved from `/`; `?col=` etc. still work) |
| `/que/:set/:n` | Fortune share pages (unchanged path) |
| `/giai-nghiep` | Giải nghiệp machine (new) |
| `/giai-nghiep/:loai` | Certificate share page, `loai` ∈ `than`, `khau`, `y` (new) |
| `/sitemap.xml`, `/robots.txt`, `/manifest.webmanifest`, `/api/fortunes` | Unchanged paths. Sitemap gains `/xin-xam`, `/giai-nghiep` and the three certificate pages. |

The fortune share page's "Xin xăm" button changes from `/?col=…` to `/xin-xam?col=…`.

Old visitors with `/?col=…` bookmarks: `/` with any query parameter that the xin xăm page reads (`col`, `free`, `pal`, `labels`, `xr`, `welcome`, `phase`, `press`, `step`) redirects to `/xin-xam` with the same query. *(my call)*

The giải nghiệp page gets its head tags (title, OG, canonical) from the server at `</head>`, the same way `FigurePage` does, because absolute URLs depend on the endpoint. Its HTML file must therefore contain exactly one `</head>` and no `<title>` that the server can't strip. *(my call)*

## Machine list

One module (e.g. `ChuaTauWeb.Machines`) holds the list of machines in display order. Each entry has: slug, display name, short description (used for SEO and the homepage), thumbnail image path, accent colour, and how its page is served. The homepage grid, the routes' 404 handling, the sitemap and the back link all read from this list.

Routes for each machine can stay explicit in the router. "One entry" means one list entry plus the route line. *(my call; a builder can make it fully generic if it stays simple)*

## Homepage (`/`)

Layout B, chosen by the owner: you look *through* the gate, and the machines stand in a grid under the arch.

- Hand-inked isometric look matching the colorfigures style: warm paper, heavy ink outlines, flat colour bands.
- The gate is a big framed header at the top. The machine grid sits under the arch: 3–4 per row on desktop, wrapping; 2 per row on phones, scrolling. *(my call)* It must still look right with 2 machines and with about 8.
- Each machine is a still thumbnail with its name on a button. The whole card is one link.
- Server-rendered HEEx and plain CSS in `priv/static/css/`, like the share pages. No JS needed.
- Thumbnails start as placeholder PNGs in `priv/static/images/machines/`, to be replaced by real renders later (same convention as the existing placeholders).
- Each machine page gets a small "← Cổng chùa" link back to `/`. For the giải nghiệp page it goes in the HTML file itself. For the xin xăm page it is spliced in by `FigurePage` just before `</body>`, so no new marker is needed.

SEO: the site becomes a two-machine site, so `Seo` needs a site-level name and description for `/`. Each machine gets its own title/description, and the xin xăm title/description move to `/xin-xam`. The wording of the new site-level copy is left to the builder: plain, with no temple history.

## Máy giải nghiệp: the figure

Built with the **colorfigures** skill as one self-contained HTML file at `priv/giai-nghiep/index.html`: no outside requests, mobile-friendly, drag to turn all the way round, a See-through toggle, zoom. The owner's spec, verbatim in substance:

**Body.** A tall, slightly worn street vending machine, the kind outside a pagoda gate. Default body colour tomato red with mustard accents, and the usual colorfigures swatches. Slightly dented corner. One sticker on the side: "KHÔNG HOÀN TIỀN".

**Front panel.**
- Header sign "MÁY GIẢI NGHIỆP", subline "Nhanh · Gọn · Có hóa đơn".
- Glass window, three shelves with price tags:
  - Shelf 1 "THÂN" (red): small wax figures of a person
  - Shelf 2 "KHẨU" (yellow): paper tongues / little talk-bubble cards
  - Shelf 3 "Ý" (blue): tiny paper clouds
- Keypad: three big buttons THÂN / KHẨU / Ý, plus a small round button "NẶNG" that doubles the price.
- Coin slot labelled "NHÉT TIỀN VÀO ĐÂY", and a bill slot.
- LCD strip: "CHỌN NGHIỆP" at rest → price → "ĐANG GIẢI..." → "XONG!".
- Dispensing tray at the bottom labelled "HÓA ĐƠN".
- Small brass bell on the side.
- Incense-holder bracket on a top corner with one stick (optional).

**Interaction.**
1. Pressing THÂN / KHẨU / Ý lights that shelf's lamp, and the LCD shows the price: 50.000đ for each type, 100.000đ with NẶNG. *(The owner gave 50.000đ as an example. Using it for all three is my call.)*
2. Clicking the coin slot drops a coin with a clink, and a small counter on the LCD adds up. Coin value is the builder's call. Pick it so a normal purchase takes a few clicks, not twenty. The bill slot also takes a click and adds a bigger amount. *(my call)*
3. When enough money is in, the LCD shows "ĐANG GIẢI...", the chosen shelf glows and shakes for about 2s, the bell rings once, and a tiny puff of smoke comes from the top. Then the LCD shows "XONG!" and a receipt slides out of the tray.
4. The receipt reads: "GIẤY CHỨNG NHẬN ĐÃ GIẢI NGHIỆP — Loại: [THÂN/KHẨU/Ý] — Hiệu lực: đến lần sau." Clicking it takes it out of the tray.
5. Nothing on the shelves is ever dispensed. Only the receipt comes out.
6. A "HẾT TIỀN?" reset link clears the state.

Overpaying: the extra is kept, not returned, as the sticker says. *(my call)* Pressing NẶNG with no type chosen does nothing visible except the button press. *(builder's call)*

**See-through (deadpan).** Behind the busy front there is almost nothing. Labelled parts, each label lights while its part runs:
- "Hộp tiền": cash box. Coins fall straight into it. It's the largest part inside and gets fuller with each coin.
- "Máy in hóa đơn": small thermal printer with a paper roll, feeding the tray.
- "Búa chuông": tiny solenoid that taps the bell.
- "Bộ xịt khói": small bellows that puffs the smoke.
- "Đèn kệ": three LEDs, one per shelf.
- "Mô-tơ rung kệ": one wobbly little motor that shakes whichever shelf is chosen.
- "Thanh giữ hàng": fixed bar holding the shelf items so they can never drop.
- "Khoảng trống": lots of empty space, labelled once.

Sound (clink, bell) is made in the browser with Web Audio. No audio files. *(my call)*

## The certificate

Style **B**, chosen by the owner from mockups: a formal *giấy khen* look. Cream paper, double gold border, red serif heading "GIẤY CHỨNG NHẬN ĐÃ GIẢI NGHIỆP", "Loại: [type]", "Hiệu lực: đến lần sau.", a small "MÁY GIẢI NGHIỆP" line on top, a date line, and a tilted red round seal reading "ĐÃ GIẢI".

When the receipt is taken out of the tray, the certificate opens over the figure, with two buttons:
- **Lưu giấy**: draws the certificate to a `<canvas>` in the browser and downloads `giai-nghiep-<loai>.png`. It includes today's date (dd/mm/yyyy). *(my call)* The fonts must be ones available offline: system serif/sans. No web fonts.
- **Chia sẻ**: uses `navigator.share` when available, otherwise copies `location.origin + '/giai-nghiep/<loai>'` to the clipboard with a short "Đã chép link" note.
- Closing it returns to the machine.

## Certificate share pages (`/giai-nghiep/:loai`)

- Only `than`, `khau`, `y`. Anything else is a 404. NẶNG isn't part of the link.
- A server-rendered page in the style of the existing `/que` share page. It shows the certificate (same B design, without the date) and a "Giải nghiệp" button to `/giai-nghiep`.
- The OG image is a fixed 1200×630 PNG per type: `priv/static/images/giai-nghiep/<loai>.png`. These start as placeholders. Ideally they are produced once from the figure's own canvas renderer and committed. Generating images on the server is out of scope.
- `Seo` needs a per-page OG image instead of the single hard-coded `/images/og.png`.
- Indexable, and in the sitemap.

## Tests

Follow the existing test style (`test/chua_tau_web/...`):
- `/` lists every machine in the list, each linking to its path.
- `/xin-xam` serves the fortune figure with its JSON. `/` no longer does.
- `/giai-nghiep` serves the new figure. `/giai-nghiep/than|khau|y` render with the right OG image, and `/giai-nghiep/foo` is a 404.
- Fortune share page button points at `/xin-xam?col=…`.
- Sitemap contains the new paths.
- `/?col=x` redirects to `/xin-xam?col=x`.

The figure's own behaviour (buttons, coins, receipt, PNG export) is checked by driving it in a real browser, not by unit tests.

## Left to the builder

- Exact homepage art, spacing and CSS. Machine card proportions.
- Coin and bill values, animation timings other than "about 2s" shake, and sound design.
- The new site-level SEO copy (plain, factual, no temple history).
- Module and file names beyond those given here.
- How the xin xăm back link is styled.

## Owner decisions (recorded)

- New machine lives in the same Phoenix app.
- Certificate: both PNG download and share link.
- Certificate style B (formal, seal).
- Homepage: gate scene, layout B (machines under the arch), must grow into a grid of many machines, with buttons for easy picking.
- Fortune machine moves to `/xin-xam`.
- The CLAUDE.md rule "Never write into `../xin-xam/`" is wrong. Work happens in this repo. The build removes that line from CLAUDE.md and updates its Architecture section for the machine list, the homepage and the new routes.
