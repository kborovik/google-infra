###############################################################################
# GitHub OpenID Connect Provider
###############################################################################

locals {
  assertion_repository = "kborovik/google-infra"
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub OIDC"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_provider_id = "google-infra"
  display_name                       = "GitHub Repo google-infra"
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  attribute_mapping = {
    "attribute.actor"            = "assertion.actor"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.repository"       = "assertion.repository"
    "google.subject"             = "assertion.sub"
  }
  attribute_condition = "assertion.repository_owner == 'kborovik'"
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

###############################################################################
# GitHub - principalSet IAM
###############################################################################

locals {
  github_aim_roles = [
    "roles/editor",
  ]
}

resource "google_project_iam_member" "github_principal_set" {
  count   = length(local.github_aim_roles)
  project = var.google_project
  role    = local.github_aim_roles[count.index]
  member  = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${local.assertion_repository}"
}
