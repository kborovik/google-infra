google_project = "lab5-gcp-dev1"
google_region  = "us-central1"
google_network = {
  project = "10.128.0.0/16",
  gke_net = "10.128.16.0/20",
  gke_pod = "10.128.32.0/20",
  gke_svc = "10.128.48.0/20",
  gcp_svc = "10.128.240.0/20"
}

enable_gke = false
enable_nat = false
