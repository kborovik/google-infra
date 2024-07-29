###############################################################################
# GitHub OpenID Connect Provider
###############################################################################

locals {
  assertion_aud = "https://github.com/kborovik"
  assertion_sub = "repo:kborovik/google-infra:environment:${var.google_project}"
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
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
    "google.subject"       = "assertion.sub"
  }
  oidc {
    allowed_audiences = [local.assertion_aud]
    issuer_uri        = "https://token.actions.githubusercontent.com"
  }
}

###############################################################################
# GitHub - Service Account Mapping
###############################################################################

resource "google_service_account" "github" {
  account_id   = "github"
  display_name = "GitHub OIDC"
}

resource "google_service_account_iam_binding" "github" {
  service_account_id = google_service_account.github.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.sub/${local.assertion_sub}",
  ]
}

locals {
  github_aim_roles = [
    "roles/compute.admin",
    "roles/iam.workloadIdentityUser",
    "roles/networkmanagement.admin",
  ]
}

resource "google_project_iam_member" "github" {
  count   = length(local.github_aim_roles)
  project = var.google_project
  role    = local.github_aim_roles[count.index]
  member  = "serviceAccount:${google_service_account.github.email}"
}

