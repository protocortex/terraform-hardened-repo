<!-- SPDX-License-Identifier: Apache-2.0 -->
# terraform-hardened-repo

Reusable Terraform module that codifies a standard hardening posture for a
protocortex GitHub repository: settings, branch/tag rulesets, a canonical label
set, community/governance files, and shared CI workflows, every piece opt-in
via a boolean.

Consumed by [`protocortex/infra`](https://github.com/protocortex/infra)'s GitHub
governance root. Pin it by tag.

## Usage

```hcl
module "my_repo" {
  source = "git::https://github.com/protocortex/terraform-hardened-repo.git?ref=v0.1.0"

  name        = "my-repo"
  description = "…"
  visibility  = "private"

  # All protocortex repos are private on GitHub free tier: one switch forces
  # off the eight Pro-only features GitHub 403s (rulesets, vuln alerts, secret
  # scanning + push protection, Dependabot security updates, dependency review,
  # private vuln reporting).
  private_free_tier = true

  # WARNING: manage_labels = true DELETES any label not in the canonical set.
  manage_labels = false
}
```

The provider is configured by the **calling** root, not here. Pass a `github`
provider (App auth or PAT) whose `owner` matches the repos being managed.

## Safety

- `github_repository.this` has `prevent_destroy = true` and
  `archive_on_destroy = true`: Terraform refuses to destroy the repo and, in a
  forced override, archives rather than deletes.
- `private_free_tier` drives a `check` block that fails the plan if a Pro-only
  feature is enabled on a private repo without it.

## Inputs

`variables.tf` is the full public API (~90 variables). The common groups:

- **Identity**, `name`, `owner` (default `protocortex`), `description`, `visibility`, `topics`.
- **Free-tier / security**, `private_free_tier`, `enable_*` toggles.
- **Governance files**, `manage_security_md`, `manage_code_of_conduct`, `manage_codeowners`, `manage_icla`, `manage_ccla`, `manage_license`, …
- **Workflows**, one `manage_workflow_*` per shared workflow.
- **Plan-time reads**, `github_token` (optional; only needed when `manage_security_md` or `enforce_pr_creation_policy` is true, for private-repo REST reads).

## License

Apache-2.0. See [LICENSE](LICENSE).
