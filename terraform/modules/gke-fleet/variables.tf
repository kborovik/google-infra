###############################################################################
# Module Variables
###############################################################################

variable "google_project" {
  description = "GCP Project Id"
  type        = string
  default     = "lab5-gcp-uat1"
}

variable "google_region" {
  description = "Default GCP region"
  type        = string
  default     = "us-central1"
}

variable "gke_clusters" {
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
