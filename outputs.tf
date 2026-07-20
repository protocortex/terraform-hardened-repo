# SPDX-License-Identifier: Apache-2.0

output "repository_id" {
  value       = github_repository.this.node_id
  description = "GraphQL node ID of the managed repository."
}

output "repository_full_name" {
  value       = github_repository.this.full_name
  description = "owner/name slug of the managed repository."
}

output "default_branch_ruleset_id" {
  value       = try(github_repository_ruleset.default_branch[0].ruleset_id, null)
  description = "Ruleset ID for the default-branch protection rule, or null if disabled."
}

output "release_tags_ruleset_id" {
  value       = try(github_repository_ruleset.release_tags[0].ruleset_id, null)
  description = "Ruleset ID for the tag-protection rule, or null if disabled."
}
