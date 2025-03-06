google_project = "lab5-gcp-prd1"
google_region  = "us-central1"

google_network = {
  project = "10.130.0.0/16",
  gcp_svc = "10.130.240.0/20"
}

gke_config = [
  {
    gke_name   = "gke-0",
    gke_region = "us-central1",
    gke_net    = "10.130.16.0/20",
    gke_pod    = "10.130.32.0/20",
    gke_svc    = "10.130.48.0/20",
  },
  {
    gke_name   = "gke-1",
    gke_region = "us-east1",
    gke_net    = "10.130.64.0/20",
    gke_pod    = "10.130.80.0/20",
    gke_svc    = "10.130.96.0/20",
  }
]

enable_gke = false
enable_nat = false
