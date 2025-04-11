# GKE KMS Terraform Module

This Terraform module encrypts the GKE clusters `etcd` database with a KMS key.

## Google Documentation

- https://cloud.google.com/kubernetes-engine/docs/how-to/encrypt-etcd-control-plane-disks
- https://cloud.google.com/kms/docs/cmek-best-practices

## Requirements

- GKE cluster must run version 1.31.1-gke.1846000 or later.
- GKE cluster must be in a [KMS-enabled region](https://cloud.google.com/kms/docs/locations).


## Usage

```hcl

module "gke_kms" {
  source = "./modules/gke-kms/"

  gke_project  = "google_project_id"
  gke_region = "google_region"
}


```