###############################################################################
# Enable GCP Project Services
###############################################################################

locals {
  google_project_services = [
    "anthos.googleapis.com",
    "anthosconfigmanagement.googleapis.com",
    "anthosidentityservice.googleapis.com",
    "anthospolicycontroller.googleapis.com",
    "apihub.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "connectgateway.googleapis.com",
    "container.googleapis.com",
    "containersecurity.googleapis.com",
    "gkehub.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "iap.googleapis.com",
    "logging.googleapis.com",
    "mesh.googleapis.com",
    "meshconfig.googleapis.com",
    "monitoring.googleapis.com",
    "multiclusteringress.googleapis.com",
    "multiclusterservicediscovery.googleapis.com",
    "networkmanagement.googleapis.com",
    "osconfig.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
  ]
}

resource "google_project_service" "main" {
  for_each                   = toset(local.google_project_services)
  service                    = each.value
  disable_dependent_services = true
  disable_on_destroy         = false
}
