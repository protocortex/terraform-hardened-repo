# Action release flavor

Standardized release pipeline for GitHub Actions (git-ref + Marketplace),
distinct from the npm/JSR library flavor. Enable it in a repo's module call:

    language                = "javascript"   # or omit for a non-JS composite action
    manage_workflow_release = true
    release_profile         = "action"
    manage_workflow_publish = false           # actions do not publish to a registry
    protect_tag_pattern     = "v*"            # tag ruleset; bot bypasses non-fast-forward
    manage_bot_app_secrets  = true            # or rely on org-level BOT_APP_* secrets
    bot_app_id              = var.bot_app_id
    bot_app_client_id       = var.bot_app_client_id
    bot_app_private_key     = var.bot_app_private_key

What it renders into the repo:

- `.github/workflows/release.yml` — `workflow_dispatch` with a `version` input.
- `cliff.toml` — Keep-a-Changelog git-cliff config.

Cutting a release: run the `release` workflow (Actions tab) with `version`
(e.g. `1.0.0`). The bot-privileged job renders `CHANGELOG.md`, commits it,
tags `v1.0.0`, publishes a GitHub Release with a build-provenance attestation
over the source tarball, and moves the `v1` major tag (stable releases only;
prereleases like `1.0.0-rc.1` do not move the major tag).

Prerequisites (one-time, per repo):

1. **Disable GitHub Immutable Releases.** Moving the major tag needs mutable
   tags. See `disable-immutable-releases.md`. The `warn_on_immutable_releases`
   check fires a plan warning if a published release is immutable.
2. **Marketplace branding.** Add `branding: { icon, color }` to `action.yml`.
   The first-ever Marketplace publish is a manual acceptance in the Release UI;
   subsequent releases list automatically.
3. **Bot secrets present.** `BOT_APP_CLIENT_ID` / `BOT_APP_PRIVATE_KEY`
   (repo-level via `manage_bot_app_secrets`, or org-level).

Not included: registry publishing, SLSA reusable-generator provenance (the
library flavor's `publish.<language>.yml` / SLSA L3 pipeline). The attestation
here is a single `actions/attest-build-provenance` step over the tarball.
