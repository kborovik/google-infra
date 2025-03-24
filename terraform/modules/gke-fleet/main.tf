###############################################################################
# GKE Hub Fleet
###############################################################################

data "google_container_cluster" "cluster" {
  for_each = var.gke_fleet_clusters
  project  = each.value.project
  name     = each.value.name
  location = each.value.location
}

resource "google_gke_hub_fleet" "fleet" {
  display_name = "gke-fleet-0"
  project      = var.gke_fleet_project

  default_cluster_config {

    binary_authorization_config {
      evaluation_mode = "DISABLED"
    }

    security_posture_config {
      mode               = "DISABLED"
      vulnerability_mode = "VULNERABILITY_DISABLED"
    }
  }

  depends_on = [
    data.google_container_cluster.cluster
  ]
}

resource "google_gke_hub_membership" "gke" {
  for_each      = var.gke_fleet_clusters
  project       = data.google_container_cluster.cluster[each.key].project
  membership_id = data.google_container_cluster.cluster[each.key].name
  location      = data.google_container_cluster.cluster[each.key].location

  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${data.google_container_cluster.cluster[each.key].id}"
    }
  }

  depends_on = [
    data.google_container_cluster.cluster,
    google_gke_hub_fleet.fleet,
  ]
}

resource "google_gke_hub_feature" "configmanagement" {
  name     = "configmanagement"
  location = "global"
  project  = var.gke_fleet_project

  depends_on = [
    google_gke_hub_fleet.fleet
  ]
}

resource "google_gke_hub_feature_membership" "configmanagement" {
  for_each            = var.gke_fleet_clusters
  feature             = google_gke_hub_feature.configmanagement.id
  location            = "global"
  project             = google_gke_hub_membership.gke[each.key].project
  membership          = google_gke_hub_membership.gke[each.key].id
  membership_location = google_gke_hub_membership.gke[each.key].location

  configmanagement {
    management = "MANAGEMENT_AUTOMATIC"
    config_sync {
      enabled       = true
      prevent_drift = true
      source_format = "hierarchy"
      stop_syncing  = false
      git {
        sync_repo   = "https://github.com/kborovik/gke-hub-config-mgmt.git"
        sync_branch = "main"
        secret_type = "none"
      }
    }
  }
}

resource "google_gke_hub_feature" "servicemesh" {
  name     = "servicemesh"
  location = "global"
  project  = var.gke_fleet_project

  depends_on = [
    google_gke_hub_fleet.fleet
  ]
}

resource "google_gke_hub_feature_membership" "servicemesh" {
  for_each            = var.gke_fleet_clusters
  feature             = google_gke_hub_feature.servicemesh.id
  project             = google_gke_hub_membership.gke[each.key].project
  membership          = google_gke_hub_membership.gke[each.key].id
  membership_location = google_gke_hub_membership.gke[each.key].location
  location            = "global"

  mesh {
    management = "MANAGEMENT_AUTOMATIC"
  }
}

resource "google_gke_hub_feature" "policycontroller" {
  name     = "policycontroller"
  location = "global"
  project  = var.gke_fleet_project

  depends_on = [
    google_gke_hub_fleet.fleet
  ]
}

# resource "google_gke_hub_feature_membership" "policycontroller" {
#   for_each            = var.gke_fleet_clusters
#   feature             = google_gke_hub_feature.policycontroller.name
#   project             = google_gke_hub_membership.gke[each.key].project
#   membership          = google_gke_hub_membership.gke[each.key].id
#   membership_location = google_gke_hub_membership.gke[each.key].location
#   location            = "global"

#   policycontroller {
#     policy_controller_hub_config {
#       policy_content {
#         bundles {
#           bundle_name         = ""
#           exempted_namespaces = []
#         }
#       }
#     }
#   }
# }

