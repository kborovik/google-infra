###############################################################################
# Service Roles
###############################################################################

locals {
  terraform_roles = [
    "roles/artifactregistry.admin",
    "roles/compute.admin",
    "roles/container.admin",
    "roles/gkehub.admin",
    "roles/gkehub.gatewayAdmin",
    "roles/gkemulticloud.admin",
    "roles/logging.admin",
    "roles/monitoring.admin",
    "roles/networkmanagement.admin",
    "roles/storage.admin",
  ]
}
