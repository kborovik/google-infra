###############################################################################
# Google Kubernetes Engine (GKE) Service Account
###############################################################################
locals {
  gke_project_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/secretmanager.secretAccessor",
    "roles/secretmanager.viewer",
    "roles/viewer",
  ]
}

resource "google_service_account" "gke1" {
  account_id   = "gke-${var.app_id}-01"
  display_name = "GKE Service Account"
}

resource "google_project_iam_member" "gke1" {
  count   = length(local.gke_project_roles)
  project = var.google_project
  role    = local.gke_project_roles[count.index]
  member  = "serviceAccount:${google_service_account.gke1.email}"
}

###############################################################################
# The cluster dedicated to a single application. 
# All GKE configuration choices based on the single-application workload.
###############################################################################

resource "google_container_cluster" "gke1" {
  name                = "${var.app_id}-01"
  project             = var.google_project
  location            = var.google_region
  deletion_protection = false
  enable_autopilot    = true

  # https://cloud.google.com/kubernetes-engine/docs/concepts/alias-ips
  network    = google_compute_network.main.id
  subnetwork = google_compute_subnetwork.gke_net.id

  ip_allocation_policy {
    services_secondary_range_name = google_compute_subnetwork.gke_net.secondary_ip_range[1].range_name
    cluster_secondary_range_name  = google_compute_subnetwork.gke_net.secondary_ip_range[0].range_name
  }

  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.gke1.email
      management {
        auto_repair  = true
        auto_upgrade = true
      }
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  # https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept
  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_global_access_config {
      enabled = true
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = true
    cidr_blocks {
      display_name = "Bell Canada"
      cidr_block   = "142.198.0.0/16"
    }
    cidr_blocks {
      display_name = "GCP Internal Network"
      cidr_block   = google_compute_subnetwork.gke_net.ip_cidr_range
    }
  }

  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
      "SCHEDULER",
    ]
  }

  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "STORAGE",
      "DEPLOYMENT",
      "STATEFULSET",
    ]
  }

  maintenance_policy {
    recurring_window {
      start_time = "2024-01-01T09:00:00Z"
      end_time   = "2024-01-01T17:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
  }
}
