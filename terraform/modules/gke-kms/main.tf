###############################################################################
# GKE KMS Module
###############################################################################

data "google_project" "main" {
  project_id = var.gke_project
}

locals {
  gke_service_agent = "serviceAccount:service-${data.google_project.main.number}@container-engine-robot.iam.gserviceaccount.com"
  kms_roles = [
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
    "roles/cloudkms.cryptoKeyEncrypterDecrypterViaDelegation",
  ]
}

resource "google_project_service" "main" {
  project                    = var.gke_project
  service                    = "cloudkms.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_kms_key_ring" "main" {
  name     = "keyring-${var.gke_region}"
  project  = var.gke_project
  location = var.gke_region

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    google_project_service.main
  ]
}

resource "google_kms_crypto_key" "main" {
  name     = "gke-etcd-${google_kms_key_ring.main.name}"
  key_ring = google_kms_key_ring.main.id

  purpose = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_binding" "main" {
  count         = length(local.kms_roles)
  crypto_key_id = google_kms_crypto_key.main.id
  role          = local.kms_roles[count.index]
  members       = [local.gke_service_agent]
}
