# Trusted Publishers setup (one-time, per package)

The shared `publish.javascript.yml` workflow uses OIDC Trusted Publishing
for both npm and JSR. No `NPM_TOKEN` or `JSR_API_TOKEN` secret exists in
the repo; the workflow exchanges the GitHub Actions OIDC token at publish
time for a short-lived registry credential.

Each registry requires a one-time per-package web-UI step to register the
GitHub workflow as a Trusted Publisher. No public API or CLI exists for
this configuration on either npm or JSR.

## npm

1. Open `https://www.npmjs.com/package/<package>/access`
   - For scoped packages: `https://www.npmjs.com/package/@<scope>/<name>/access`
2. *Trusted Publisher* → *Add a Trusted Publisher* → *GitHub Actions*
3. Fill in:
   - Organization or user: `igorjs`
   - Repository: the bare repo name (e.g. `pure-fx`)
   - Workflow filename: `publish.yml`
   - Environment name: `npm-publish`
4. Save.

The `Environment name` field is the bit that gates publish on the
deployment environment created by Terraform
(`github_repository_environment.npm_publish`). Without it set on npm's
side, any workflow with `id-token: write` in the repo could publish.
With it set, only workflow runs scoped to the `npm-publish` environment
can.

### Verifying the trust relationship

Trigger a release-published event (e.g. publish a draft release in
`https://github.com/<owner>/<repo>/releases`). The `publish-npm` job
will run and the first registry-bound step (`npm publish --provenance`)
either succeeds or fails with:

> npm error 401 Unauthorized - PUT https://registry.npmjs.org/...

If 401, recheck step 3 fields against the OIDC token claims surfaced in
the publish job logs (search for `claim:`).

## JSR

1. Open `https://jsr.io/@<scope>/<name>/settings`
2. *GitHub Actions* section → *Link a GitHub repository*
3. Fill in:
   - Repository: `igorjs/<repo>`
4. Save. (JSR does not currently take a workflow-file or environment
   constraint; the link is at repo level.)

JSR's Trusted Publisher pipeline ties the package's identity to the
linked GitHub repo via Sigstore; the in-toto attestation is generated
by `npx jsr publish` automatically when running under GitHub Actions
with `id-token: write`.

## When a package moves

If a package is renamed on npm/JSR (e.g. `@igorjs/foo` → `@igorjs/bar`),
the Trusted Publisher entry on the OLD name does not carry over. Add a
new Trusted Publisher entry on the new package name, then deprecate the
old one. The Terraform `github_repository_environment` block does not
need changes; it is keyed on the workflow filename and environment name,
not on the package identity.
