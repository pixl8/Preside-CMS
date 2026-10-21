# Editor harness

Boots **both** rich editors standalone — with Preside's server-side dependencies
mocked — so the CKEditor (current) and Tiptap (replacement) implementations can be
driven and screenshot-compared side by side without a full Preside boot.

## Run

```bash
cd harness
node server.mjs            # → http://localhost:8700   (optional: node server.mjs <port>)
```

- `http://localhost:8700/`             — side-by-side (CKEditor left, Tiptap right)
- `http://localhost:8700/ckeditor.html` — real Preside CKEditor 4 + ckeditorExtensions plugins
- `http://localhost:8700/tiptap.html`   — the Tiptap facade (`../dist/`)

Rebuild the Tiptap bundle first if you changed `src/`: `cd .. && npm run build`.

## What's mocked (no CFML / no DB / no Preside)

`mocks.js` supplies the client globals Preside would inject:
- `cfrequest` (the `ckEditorJs.cfm` `includeData` values; `bootstrapck` skin),
- `buildAdminLink` / `buildAjaxLink` / `buildLink`,
- `i18n.translateResource`, `presideJQuery`.

`custom-config-fixture.js` is a CKEditor-style custom config file (the
`settings.ckeditor.defaults.configFile` / per-field `customConfig` contract) for
exercising `src/customConfig.js`: mount a textarea with
`data-custom-config="/custom-config-fixture.js"` and (optionally)
`data-toolbar="harnessCustom"` to see file-driven named toolbars, `format_tags`,
numeric `enterMode` and `disallowedContent` applied.

`server.mjs` serves the real editor assets straight from the Preside tree
(`/ckeditor/*`, `/ckeditorExtensions/*`, `/vendor/*`) and stands in for the Preside
handlers the editor calls:
- `/mock/ajax?action=…` — the preview renderers (`renderEmbeddedImageForEditor`,
  `renderEmbeddedAttachmentForEditor`, `renderWidgetPlaceholder`),
- `/mock/admin/*` — the picker iframe pages (link / asset / widget) implementing the
  `onDialogEvent` contract, plus `ajaxhelper.temporarilyStoreData`. Each picker now
  offers a few selectable sample items (click to select, double-click or OK to
  commit; OK stays disabled until you pick). The preview renderers reflect the
  chosen asset/widget so different picks render differently.

Both editor pages use the **identical** `<textarea class="richeditor" data-toolbar=…>`
markup and sample content (headings, bold/italic, a `{{link:…}}` link, an
`{{image:…}}` token and a `{{widget:…}}` token) so output is directly comparable.

## Automated tests

- `node test-link-serialization.mjs` — pure-node unit tests for the link
  href ↔ `{{link|asset|custom}}` token contract.
- **`/test-realworld.html`** — self-running browser tests where every case is a
  CKEditor customisation pattern lifted verbatim from real Preside sites and
  extensions:
  - the `preside-ext-ready-membership-cms-basics` named toolbar
    (`Bold|Italic|PresideLink,PresideUnlink|Format`, as the server resolves it),
  - the `preside-ext-pdf-templating` toolbar, full of CKEditor buttons - the ones
    with no Tiptap analogue (`Scayt`, `SelectAll`, `CreateDiv`, `Language`, `Cut`,
    `Copy`) must be skipped gracefully with the editor still functional, while
    `Find`/`Replace`/`SpecialChar`/`BidiLtr`/`BidiRtl` must now render,
  - **Find and Replace, special characters and text direction** (T22/T23/T24):
    the search highlights without touching the document, never matches across a
    block boundary, honours match-case/whole-word/cyclic, replaces on the second
    click and Replace-All in one undo step; the character picker offers CKEditor's
    whole 210-entry list in 17 columns and inserts the CHARACTER (not the entity)
    with the caret's marks; `dir` is written or REMOVED per CKEditor's
    `useComputedState`, an inline `direction:` is stripped, and an existing `dir`
    round-trips. T22 also asserts **the dialog's shadow boundary**: the page
    injects the admin theme's own `!important` rules on `legend`/`label`/
    `fieldset`/`input`/`button` (what really mangled the light-DOM version in the
    admin — a 21px ruled legend, options forced onto one line, re-skinned
    checkboxes) and checks that none of them reach the dialog. Reaching into it
    from a test needs `host.shadowRoot` (`dlgHost()`/`dlg()`),
  - **the manual resize grip** (T25): CKEditor's `resize` plugin - vertical by
    default, the dragged height sticking (the frame stops auto-growing and scrolls
    instead), `resize_enabled:false` / `resize_dir:"both"` / min===max, hidden while
    maximized, and the min-lowering rule that stops a stock 300px-capped field
    jumping on the first pixel of drag. Driven with real PointerEvents, since the
    grip uses pointer capture,
  - **an embed's links do not navigate while the editor is open** (T27): the
    attachment preview's real download link is cancelled on click and middle click
    (it used to download the file from inside the editor), the click selects the
    embed instead, and an ordinary content link is left alone. The mock renders a
    genuine `/mock/asset/...` download href for this - with the `href="#"` it had
    before, the bug was invisible here,
  - **the embed bubble** (T21): the widget/attachment Edit+Remove bubble - the same
    chrome and placement as the image's, shared from `src/embedBubble.js` - shown on
    the selected chip only, flipped below when there is no room above, and Remove
    deleting just that embed,
  - **the source view** (T26): CKEditor's layout (blank line between top-level
    blocks, tab indents, inline content on one line, `<pre>` byte-for-byte), the
    highlight layer painting exactly the textarea's text at identical metrics, and
    the display-only contract — open-then-close is byte-identical, an edit applies
    and ONLY the edit (token, `<pre>` whitespace and `&amp;` all survive),
  - the **Styles / Format combos** (T3, T3b, T3c, T4, T4b): the cms-basics
    `defaultConfigs.stylesSet` append (`table.compact`) plus styles harvested from
    `content-sample.css` with CKEditor's stylesheetparser algorithm — that sheet
    deliberately carries Bootstrap-shaped descendant selectors
    (`table.table-ruled tbody tr td`), an attribute selector, skip-listed
    selectors, a `:where()` rule and an `@layer` block, so the assertions cover the
    junk entries the naive harvest produced *and* the two shapes the old scoped
    preview path could not style. Also: each combo renders as its own toolbar block
    with a `-` between two of them dropped; the combo disables when no style applies
    at the caret and re-enables inside a table; the panel is an iframe with the
    sheet linked unmodified and nothing leaked into the admin document; and inline
    styles round-trip as `<small class>` / `<strong class>` / `<em class>`,
  - a site-style **custom CKEditor config file** (`custom-config-fixture.js`:
    `toolbar_<name>` named toolbars, `format_tags`, numeric `CKEDITOR.ENTER_BR`,
    `disallowedContent`) with instance-over-file precedence asserted,
  - the stock core `/ckeditorExtensions/config.js` executing harmlessly,
  - **style isolation + content-CSS fidelity** (T19): the page's head carries a
    `<style>` block emulating what the real admin does to an in-page editable
    (`html{font-size:10px}`, a body font, bare `p`/`h2`/`ul`/`*` rules) **plus the
    two forms that defeat any specificity-based isolation** — an `!important`
    rule and a `(0,2,1)` selector. The editable is in an iframe
    (`src/editorFrame.js`), so the assertions check the boundary itself, that
    none of that leak reaches the content, that `rem` resolves against the
    frame's root (`1.5rem` = 24px, not the admin's 15px) and `em` chains off it
    (`1.25em` = 30px), that the site's stylesheet arrives **unmodified**, and
    that the editable is genuinely editable (`isContentEditable`, text
    insertable, `contenteditable=false` node views still not editable). **Run
    this page under WebKit as well as Chromium** — the previous approach failed
    only in WebKit (it maps `contenteditable` to `-webkit-user-modify` as a
    presentational hint), and Blink cannot see that class of bug,
  - the **opt-out contract** for the chrome this extension adds (`outline`,
    `darkMode`, `wordcount`): site-wide via
    `settings.ckeditor.defaults.defaultConfigs` (as `cfrequest`), per field via
    the control's `customDefaultConfigs`, and a field overriding the site in
    either direction.

  Results render on the page and are exposed as `window.__results` /
  `window.__done` for automation.
- **`/test-frontend-maximize.html`** — reproduces the hostile chrome around a
  **front-end** editor (`.content-editor-editor-container`: fixed,
  `max-width:810px`, `z-index:100`; the admin toolbar at `z-index:103`; the field
  rendered with `width=800`) so the Maximize command can be checked there. The
  instance is on `window.testEditor`; maximized, the container must be
  `document.body`'s child at the full viewport size and paint over the toolbar
  (see `src/maximize.js` for why the portal is needed).
- **`/test-frontend-inline.html`** — self-running tests for the frontend
  edit-mode dropdown (Off/Classic/Modern) and Modern inline editing. Backed by
  `mockFrontendEditors.js` (a faithful trimmed transcription of core's
  `frontendEditors.js` — the contract Modern mode composes with) and the
  `/mock/frontend/save|publishPrompt|publish` endpoints in `server.mjs`.
  Covers: the dropdown replacing the quick-edit switch, Modern availability
  (exactly one rich region), cookie/hotkey behaviour, inline mount between the
  region comments, save/publish round-trips with Modern re-entry, byte-identical
  cancel restore, per-block selection-bubble filtering, maximize from inline,
  and a 10-cycle enter/exit leak audit. It also loads `plugin-fixture.js` for
  T29's two Modern-mode context assertions (`ctx.mode === "inline"`,
  `ctx.frame === null`) — the half of the plugin API that a boxed editor cannot
  exercise. Results on `window.__results` / `window.__done`.

- **`/test-plugin-api.html`** (T29) — the plugin API for dependent extensions
  (`preside-ext-tiptap-*`), driven by **`plugin-fixture.js`**: a dummy add-on
  loaded *after* the facade, exactly as Sticker orders a real one, registering
  one of everything against `PresideTiptap.plugins`. Covers: the whole
  `PresideTiptap.api` surface and `apiVersion`, duplicate/nameless/late
  `register()` handling, a contributed Tiptap extension reaching the built
  editor, a contributed toolbar button (its own icon, its `i18nDefaults` title,
  a working active state, and **no leading/trailing/doubled separator** around
  it — nor left behind when it is switched off), `slashItems` filtering and the
  dropping of an item whose command does not exist, the `ctx` object (mode,
  frame, container, and `api.containerOf()` resolving from inside the frame —
  the `closest()` trap), the lifecycle order
  `beforeExtensions → toolbarReady → instanceReady → beforeDestroy` with
  `beforeDestroy` firing **before** `_cleanups` and with the editor still alive,
  `chrome()`'s teardown running on `destroy()`, the per-field
  `defaultConfigs.<name> = false` opt-out gating all of it, and — the point of
  the whole exercise — **`getData()` byte-identical with the plugin registered
  and idle**. Results on `window.__results` / `window.__done`.

## Driving with Playwright

Point Playwright (or the Playwright MCP browser) at the two URLs, then
screenshot / snapshot / click / evaluate. Example contract check on the Tiptap page:

```js
await page.goto("http://localhost:8700/tiptap.html");
await page.evaluate(() => window.CKEDITOR.instances.content.getData());  // token HTML
```

**The editable is inside an iframe**, so `container.querySelector(".ProseMirror")`
finds nothing — it cannot cross a document boundary. Use `page.frameLocator(
"iframe.tiptap-editor-frame" )`, or in page script the helpers at the top of
`test-realworld.html`: `frameElOf()` / `frameDocOf()` / `$in()` (search the
frame), `surfaceEl()` (the editable's visible box in the host document — the
frame element), `scrollerOf()` (what actually scrolls: the frame's *document*)
and `hoverAt()` (dispatch a hover the drag handle will see, which means inside
the frame). Modern inline mode has no frame and every helper falls back to the
container, so the same test text works for both.

## Status vs. what you'll see

- **CKEditor page**: full fidelity — toolbar incl. Preside buttons, image preview
  rendered via the mock endpoint, widget placeholder rendered.
- **Tiptap page**: full toolbar (own MIT SVG icon set), live token previews for
  image/attachment/widget embeds (widgets are block-level, matching CKEditor),
  Format + Styles dropdowns, Source view, mocked link/image/widget pickers.
  Registry hooks (`CKEDITOR.instances`, `ckeditorinstance`) work. Its sample
  content is deliberately heading-rich and taller than the editable so the
  **document outline** rail (right edge — hover it, then click an entry) and its
  click-to-scroll can be exercised. `/test-realworld.html` T8/T9 assert the
  opt-out plus the adaptive depth, rail/panel agreement, centring and
  no-overflow invariants (90 headings in a 120px-tall field).

`PRESIDE_ASSETS` defaults to this checkout's `system/assets`. Set it when the CKEditor comparison pane should use a different Preside tree.
