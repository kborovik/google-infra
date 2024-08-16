###############################################################################
# General project settings
###############################################################################

variable "app_id" {
  description = "Application ID to identify GCP resources"
  type        = string
  default     = "esrag"
}

variable "google_project" {
  description = "GCP Project Id"
  type        = string
  default     = null
}

variable "google_region" {
  description = "Default GCP region"
  type        = string
  default     = "us-east5"
}

variable "google_network" {
  description = "Google network address"
  type = object({
    project = string
    gke_net = string
    gke_pod = string
    gke_svc = string
    gcp_svc = string
  })
  default = null
}
