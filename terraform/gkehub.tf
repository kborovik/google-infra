###############################################################################
# GKE Hub Fleet
###############################################################################

resource "google_gke_hub_fleet" "fleet" {
  display_name = "fleet-${var.google_project}"

  default_cluster_config {

    binary_authorization_config {
      evaluation_mode = "DISABLED"
    }

    security_posture_config {
      mode               = "DISABLED"
      vulnerability_mode = "VULNERABILITY_DISABLED"
    }
  }
}

resource "google_gke_hub_membership" "gke1" {
  membership_id = google_container_cluster.gke1[0].name
  location      = var.google_region

  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${google_container_cluster.gke1[0].id}"
    }
  }

  depends_on = [
    google_container_cluster.gke1
  ]
}
