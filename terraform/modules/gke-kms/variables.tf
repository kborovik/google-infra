###############################################################################
# Module Variables
###############################################################################

variable "gke_project" {
  description = "GKE cluster GCP Project ID"
  type        = string
  default     = "lab5-gcp-uat1"
}

variable "gke_region" {
  description = "GKE cluster GCP Region"
  type        = string
  default     = "us-central1"
}
