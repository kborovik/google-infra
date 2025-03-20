###############################################################################
# GKE Hub Fleet
###############################################################################

resource "google_gke_hub_fleet" "fleet" {
  display_name = "fleet-${var.google_project}"
  project      = var.google_project

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

resource "google_gke_hub_feature" "servicemesh" {
  name     = "servicemesh"
  project  = var.google_project
  location = "global"

  depends_on = [
    google_gke_hub_membership.gke,
    google_project_service.main
  ]
}

resource "google_gke_hub_feature_membership" "servicemesh" {
  count               = var.enable_gke ? length(var.gke_config) : 0
  feature             = google_gke_hub_feature.servicemesh.name
  membership          = google_gke_hub_membership.gke[count.index].membership_id
  membership_location = google_gke_hub_membership.gke[count.index].location
  location            = "global"

  mesh {
    management = "MANAGEMENT_AUTOMATIC"
  }
}

resource "google_gke_hub_feature" "policycontroller" {
  name     = "policycontroller"
  project  = var.google_project
  location = "global"

  depends_on = [
    google_gke_hub_membership.gke,
    google_project_service.main
  ]
}

# resource "google_gke_hub_feature_membership" "policycontroller" {
#   count               = var.enable_gke ? length(var.gke_config) : 0
#   feature             = google_gke_hub_feature.policycontroller.name
#   membership          = google_gke_hub_membership.gke[count.index].membership_id
#   membership_location = google_gke_hub_membership.gke[count.index].location
#   location            = "global"
# }

# resource "google_gke_hub_feature" "configmanagement" {
#   name     = "configmanagement"
#   location = "global"

#   depends_on = [
#     google_gke_hub_membership.gke,
#     google_project_service.main
#   ]
# }

# resource "google_gke_hub_feature_membership" "configmanagement" {
#   count               = var.enable_gke ? length(var.gke_config) : 0
#   feature             = google_gke_hub_feature.configmanagement.name
#   membership          = google_gke_hub_membership.gke[count.index].membership_id
#   membership_location = google_gke_hub_membership.gke[count.index].location
#   location            = "global"

#   configmanagement {
#     management = "MANAGEMENT_AUTOMATIC"
#     config_sync {
#       enabled       = true
#       prevent_drift = true
#       source_format = "hierarchy"
#       stop_syncing  = false
#       git {
#         sync_repo   = "https://github.com/kborovik/gke-hub-config-mgmt.git"
#         sync_branch = "main"
#         secret_type = "none"
#       }
#     }
#   }
# }
