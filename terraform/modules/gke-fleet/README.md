# GKE Fleet Terraform Module

This Terraform module manages a GKE Fleet configuration across multiple Google Kubernetes Engine (GKE) clusters. It enables centralized management and configuration of multiple GKE clusters across different regions through GKE Fleet features.

## Usage

```h

module "gke_fleet" {
  source = "./modules/gke-fleet/"
  version = "~> 1.0.0"

  gke_fleet_project = "gke-fleet-project-id"
  gke_fleet_clusters = {
    "gke-0" = { name = "gke-0", location = "us-central1" },
    "gke-1" = { name = "gke-1", location = "us-east1" },
  }
}

```