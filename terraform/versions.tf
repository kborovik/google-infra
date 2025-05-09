terraform {
  required_version = ">=1.0.0, <2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>6.29.0"
    }
  }

  backend "gcs" {}
}

provider "google" {
  project = var.google_project
  region  = var.google_region
}

