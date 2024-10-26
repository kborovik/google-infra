###############################################################################
# General project settings
###############################################################################

variable "app_id" {
  description = "Application ID to identify GCP resources"
  type        = string
  default     = "gcp"
}

variable "google_project" {
  description = "GCP Project Id"
  type        = string
  default     = null
}

variable "google_region" {
  description = "Default GCP region"
  type        = string
  default     = "us-central1"
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

variable "enable_gke" {
  description = "Enable GKE"
  type        = bool
  default     = false
}

variable "enable_nat" {
  description = "Enable NAT"
  type        = bool
  default     = false
}
