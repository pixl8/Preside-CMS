# TipTap editor (Preside core)

Tiptap v3 rich editor used in place of CKEditor 4 when the `tiptapEditor` Labs experiment is on for the current admin user. CKEditor stays the editor when the lab is off.

Stored content is unchanged: `{{image}}`, `{{attachment}}` and `{{widget}}` tokens, and `{{link}}` / `{{asset}}` / `{{custom}}` hrefs, round-trip through the editor. `settings.ckeditor.*` (toolbars, defaults, link picker) is the config for both engines.

## Load order

When the lab is on, `admin.layout.richEditorJs` includes sticker ids `tiptap`, `tiptap-facade` and `tiptap-css`. Those scripts load before `/js/admin/presidecore/`.

- `tiptap` exposes `window.PresideTiptap` (editor engine and plugin registry).
- `tiptap-facade` exposes `window.PresideTiptapRichEditor`.
- `preside.richeditor.js` defines `PresideRichEditor`, which constructs `PresideTiptapRichEditor` when `cfrequest.richeditorEngine` is `"tiptap"`, and `PresideCkEditor` otherwise.

`formFields.js` mounts `textarea.richeditor` on `DOMContentLoaded`, so an add-on script ordered `.after( "tiptap-facade" )` can call `PresideTiptap.plugins.register()` before the first editor exists. Chrome strings are `settings.tiptap.i18nKeys`, translated into `cfrequest.tiptapI18n`. Append keys; do not override `views/admin/layout/tiptapEditorJs.cfm`.

## Build

```bash
cd system/assets
npx grunt all          # includes the TipTap build; `npx grunt` does not

cd system/assets/tiptap
npm install
npm run build          # dist/ (gitignored)
npm run watch
```

`src/` is esbuild input. `dist/` is what Preside serves and is produced by `grunt all` (`exec:tiptap` runs `npm install && npm run build` in this directory). Filenames are content-hashed; `system/assets/StickerBundle.cfc` resolves them with wildcard paths.

## Harness

```bash
cd system/assets/tiptap/harness
node server.mjs                # http://localhost:8700
node test-link-serialization.mjs
```

The harness boots CKEditor and TipTap without a Preside server. `PRESIDE_ASSETS` defaults to this checkout's `system/assets`.

## Invariants

- Stored `{{…}}` tokens round-trip byte-identically.
- `CKEDITOR.instances[name]`, `$textarea.data( "ckeditorinstance" )` and `getData` / `setData` / `initialdata` keep their CKEditor-era shapes.
- Picker pages are used unmodified via the `onDialogEvent` dialog protocol.
