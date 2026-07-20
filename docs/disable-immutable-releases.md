# Disable Immutable Releases (one-time, per repo)

GitHub's Immutable Releases beta has no public API surface — neither the
REST nor GraphQL schema exposes a repo-level toggle (verified via schema
introspection 2026-05-29). The Terraform `integrations/github` provider
likewise has no attribute for it. The setting can only be flipped via
the GitHub web UI.

## Why we disable it

The module's SLSA L3 release workflow attaches an in-toto attestation
signed by Sigstore (Fulcio + Rekor) to every release artifact via
`slsa-framework/slsa-github-generator`. That provenance is verifiable
by anyone with `slsa-verifier` or `cosign`, independent of GitHub's
internal release-object state.

The tag-protection ruleset
(`github_repository_ruleset.release_tags`) already enforces non-deletion
and non-fast-forward on `v*` tags. Combined, these cover the integrity
and non-deletion properties Immutable Releases would otherwise provide.

Running both pipelines side by side has been observed to wedge on
certain tag states: the release-creation API returns HTTP 200 with
`"id": null` and the response is cached server-side keyed on
`(repo_id, tag_name)`, so every retry replays the same broken stub
without ever materialising a real release record. The `publish.yml`
webhook trigger (`release: published`) never fires because no real
release was published. The only manual recovery is to delete and
re-push the tag, which requires admin bypass of the tag-protection
ruleset.

## Steps

1. `https://github.com/<owner>/<repo>/settings#code-and-automation-releases`
2. Uncheck *Immutable Releases*
3. Save

## Verify the disable took effect

```bash
gh api graphql -f query='
  {
    repository(owner: "<owner>", name: "<repo>") {
      releases(last: 1) {
        nodes { tagName, immutable }
      }
    }
  }' --jq '.data.repository.releases.nodes'
```

If the most recent release still shows `immutable: true` after the
toggle, the setting may apply only to releases created after the
toggle. Cut a fresh release; subsequent ones will report
`immutable: false`.

## If a tag is stuck in the `id: null` limbo

```bash
# Delete the broken tag (admin bypass required by the tag ruleset).
git push --delete origin v<x.y.z>

# Re-create signed locally.
git tag -s v<x.y.z> <commit-sha> -m "v<x.y.z>"

# Re-push.
git push origin v<x.y.z>
```

The signed tag push retriggers `release.yml`, which mints a new release
object on a fresh `(repo_id, tag_name)` idempotency key.

## Drift detection

`modules/hardened-repo/main.tf` includes a Terraform `check` block that
queries the most recent release's `immutable` field on every plan. If
the setting is re-enabled by mistake, the next plan emits a warning
naming the repo. The check is suppressible per-repo via
`warn_on_immutable_releases = false`.
