###############################################################################
# GitHub OpenID Connect Provider
###############################################################################

locals {
  # assertion_sub        = "repo:kborovik/google-infra:environment:${var.google_project}"
  assertion_repository = "kborovik/google-infra"
}

resource "google_iam_workload_identity_pool" "github" {
  display_name              = "github"
  workload_identity_pool_id = "github"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  display_name                       = "github"
  workload_identity_pool_provider_id = "github"
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  attribute_mapping = {
    "attribute.repository" = "assertion.repository"
    "google.subject"       = "assertion.sub"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

###############################################################################
# GitHub - Service Account Mapping
###############################################################################

resource "google_service_account" "github" {
  account_id   = "github"
  display_name = "GitHub OIDC"
}

resource "google_service_account_iam_member" "github" {
  service_account_id = google_service_account.github.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${local.assertion_repository}"
}

locals {
  github_aim_roles = [
    "roles/editor",
  ]
}

resource "google_project_iam_member" "github" {
  count   = length(local.github_aim_roles)
  project = var.google_project
  role    = local.github_aim_roles[count.index]
  member  = "serviceAccount:${google_service_account.github.email}"
}

