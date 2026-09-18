# Conditional field visibility — browser tests

Tests for the `toggleWhen` form field attribute (PRESIDECMS-3321) and its
`conditionalFieldVisibility` plugin.

Unlike the Cypress suite in `tests/e2e/tests/`, these tests need **no running Preside
application and no datasource**. The page loads Preside's own jQuery build and the
plugin itself straight from `system/assets/`, builds markup matching what
`formcontrols/layouts/field.cfm` emits, and asserts the resulting visibility.

A real browser is required rather than a DOM emulator, because the plugin relies on
jQuery's `:visible`, which needs layout.

## Running

Open `index.html` directly in a browser, or serve the repository root and visit
`/tests/e2e/browser/conditionalFieldVisibility/index.html`.

```bash
python3 -m http.server 8900   # from the repository root
```

The summary line reports `ALL PASS — <n> assertions` or the failure count. Results are
also exposed on `window.__results` (`{ pass, fail, tests }`) with `window.__done` set
once the run finishes, for scripted/CI use.

## Coverage

| Acceptance criterion | Covered |
|---|---|
| Reveals/hides on `change` and initial render (select) | yes |
| Radio, checkbox and composite/picker-shaped controls | yes |
| `toggleWhen="a,b"` match-any; `toggleWhen="!a"` invert | yes |
| Targets by field name, `#id`, `.class`, and `fieldset` | yes |
| Wrappers without `toggleWhen` left untouched | yes |
| `toggledon` / `toggledoff` events | yes |
| Nested toggles (a revealed field that is itself a source) | yes |
| No value selected on load starts hidden | yes |

Not covered here — these need a running application: the CFML side (the
`conditionalFieldVisibility` feature flag and the emission of `data-toggle-fields` /
`data-toggle-when` onto the `.form-group` wrapper).
