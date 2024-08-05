###############################################################################
# GitHub OpenID Connect Provider
###############################################################################

locals {
  github_owner_id      = "'59314971'"
  github_repository    = "kborovik/google-infra"
  github_repository_id = "''"
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub OIDC"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_provider_id = "google-infra"
  display_name                       = "GitHub Repo google-infra"
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  attribute_mapping = {
    "attribute.repository" = "assertion.repository"
    "google.subject"       = "assertion.sub"
  }
  attribute_condition = "assertion.repository_owner_id == ${local.github_owner_id}"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# GitHub - principalSet IAM
###############################################################################

locals {
  github_aim_roles = [
    "roles/editor",
    "roles/iam.serviceAccountAdmin",
    "roles/resourcemanager.projectIamAdmin,"
  ]
}

resource "google_project_iam_member" "github_principal_set" {
  count   = length(local.github_aim_roles)
  project = var.google_project
  role    = local.github_aim_roles[count.index]
  member  = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${local.github_repository}"
}
