###############################################################################
# GKE Fleet
###############################################################################

# module "gke_fleet" {
#   source = "./modules/gke-fleet/"
#   # version = "~> 1.0.0"

#   gke_fleet_project = var.google_project
#   gke_fleet_clusters = {
#     "gke-0" = { project = "lab5-gcp-uat1", name = "gke-0", location = "us-central1" },
#     "gke-1" = { project = "lab5-gcp-uat1", name = "gke-1", location = "us-east1" },
#   }

#   depends_on = [
#     google_container_cluster.gke,
#   ]
# }
