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

resource "google_gke_hub_membership" "gke" {
  count         = var.enable_gke ? length(var.gke_config) : 0
  membership_id = google_container_cluster.gke[count.index].name
  location      = var.gke_config[count.index].gke_region

  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${google_container_cluster.gke[count.index].id}"
    }
  }

  depends_on = [
    google_container_cluster.gke,
  ]
}
