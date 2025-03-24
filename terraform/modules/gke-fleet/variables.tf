###############################################################################
# Module Variables
###############################################################################

variable "gke_fleet_project" {
  description = "GKE Fleet Project"
  type        = string
  default     = "lab5-gcp-uat1"
}

variable "gke_fleet_clusters" {
  description = "Set of GKE clusters to be added to GKE Fleet"
  type = map(object({
    name     = string
    location = string
  }))
  default = {
    "gke-0" = { name = "gke-0", location = "us-central1" },
    "gke-1" = { name = "gke-1", location = "us-east1" },
  }
}
