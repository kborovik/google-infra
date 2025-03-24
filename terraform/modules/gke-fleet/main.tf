###############################################################################
# GKE Hub Fleet
###############################################################################

data "google_container_cluster" "cluster" {
  for_each = var.gke_fleet_clusters
  name     = each.value.name
  location = each.value.location
}

resource "google_gke_hub_fleet" "fleet" {
  display_name = "fleet-${var.gke_fleet_project}"
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
  project  = var.gke_fleet_project
  location = "global"

  depends_on = [
    google_gke_hub_fleet.fleet
  ]
}

resource "google_gke_hub_feature_membership" "configmanagement" {
  for_each            = var.gke_fleet_clusters
  feature             = google_gke_hub_feature.configmanagement.name
  membership          = google_gke_hub_membership.gke[each.key].id
  membership_location = google_gke_hub_membership.gke[each.key].location
  location            = "global"

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

# resource "google_gke_hub_feature" "servicemesh" {
#   name     = "servicemesh"
#   project  = var.gke_fleet_project
#   location = "global"

#   depends_on = [
#     google_gke_hub_membership.gke,
#     google_project_service.main
#   ]
# }

# resource "google_gke_hub_feature_membership" "servicemesh" {
#   count               = var.enable_gke ? length(var.gke_config) : 0
#   feature             = google_gke_hub_feature.servicemesh.name
#   membership          = google_gke_hub_membership.gke[count.index].membership_id
#   membership_location = google_gke_hub_membership.gke[count.index].location
#   location            = "global"

#   mesh {
#     management = "MANAGEMENT_AUTOMATIC"
#   }

#   depends_on = [
#     google_gke_hub_membership.gke,
#   ]
# }

# resource "google_gke_hub_feature" "policycontroller" {
#   name     = "policycontroller"
#   project  = var.gke_fleet_project
#   location = "global"

#   depends_on = [
#     google_gke_hub_membership.gke,
#     google_project_service.main
#   ]
# }

# resource "google_gke_hub_feature_membership" "policycontroller" {
#   count               = var.enable_gke ? length(var.gke_config) : 0
#   feature             = google_gke_hub_feature.policycontroller.name
#   membership          = google_gke_hub_membership.gke[count.index].membership_id
#   membership_location = google_gke_hub_membership.gke[count.index].location
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

