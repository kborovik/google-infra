###############################################################################
# GKE Fleet
###############################################################################

module "gke_fleet" {
  source = "./modules/gke-fleet/"
  # version = "~> 1.0.0"

  gke_fleet_project = "lab5-gcp-uat1"
  gke_fleet_clusters = {
    "gke-0" = { name = "gke-0", location = "us-central1" },
    "gke-1" = { name = "gke-1", location = "us-east1" },
  }
}
