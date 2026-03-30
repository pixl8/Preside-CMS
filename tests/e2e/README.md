# Preside end-to-end test suite

The Preside end-to-end test suite uses [Cypress](https://www.cypress.io/) to test a running Preside application.

## Test data strategy

Runs assume the **database is empty** (or equivalent to a first Preside boot: no system admin yet, schema created by the app on startup). The suite does **not** rely on fixtures loaded ahead of time. Instead, specs create what they need as they run—for example, the first-time admin flow in `01.babysteps/setupadmin.cy.js` creates the superuser before other tests can sign in.

For a clean local run, reset the e2e database (name from your datasource, usually `endtoenddb`) before starting Cypress. In CI the database is created fresh for the job, so this holds automatically.

## Running Cypress and executing tests

The process of running the suite locally is:

1. Build Preside static assets and start the `fullcmsapp` CommandBox application with a working datasource and empty database.
2. Run Cypress from the command line or open its GUI to run or author tests.

### 1. Get the fullcmsapp running

Configure the server as you do for local Preside development: `.cfconfig.json` (see `.cfconfig.gh.json` as a starting point), `server.json`, MySQL reachable at the datasource settings, and `grunt all` in `system/assets` so admin Sticker assets exist.

### 2. Run Cypress

From `tests/e2e/tests`:

```bash
npm install
npx cypress open
```

Or headless:

```bash
npx cypress run
```

`cypress.config.js` sets `baseUrl` (default `http://127.0.0.1:9998`) and admin credentials in `env` for use after first-time setup.
