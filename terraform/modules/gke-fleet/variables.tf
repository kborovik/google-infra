###############################################################################
# Module Variables
###############################################################################

variable "gke_fleet_project" {
  description = "The Google Project where GKE Fleet resides"
  type        = string
  default     = null
}

variable "gke_fleet_clusters" {
  description = "Set of GKE clusters to be added to GKE Fleet"
  type = map(object({
    project  = string
    name     = string
    location = string
  }))
  default = null
}
