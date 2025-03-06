###############################################################################
# Google Kubernetes Engine (GKE) Service Account
###############################################################################

locals {
  gke_project_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/viewer",
  ]
}

resource "google_service_account" "gke1" {
  account_id   = "gke-${var.app_id}-01"
  display_name = "GKE Service Account"
}

resource "google_project_iam_member" "gke1" {
  for_each = toset(local.gke_project_roles)
  project  = var.google_project
  role     = each.value
  member   = "serviceAccount:${google_service_account.gke1.email}"
}

###############################################################################
# The cluster dedicated to a single application. 
# All GKE configuration choices based on the single-application workload.
###############################################################################

resource "google_container_cluster" "gke" {
  count               = var.enable_gke ? length(var.gke_config) : 0
  name                = var.gke_config[count.index].gke_name
  location            = var.gke_config[count.index].gke_region
  deletion_protection = false
  enable_autopilot    = true

  network    = google_compute_network.main.id
  subnetwork = google_compute_subnetwork.gke_net[count.index].id

  ip_allocation_policy {
    services_secondary_range_name = google_compute_subnetwork.gke_net[count.index].secondary_ip_range[1].range_name
    cluster_secondary_range_name  = google_compute_subnetwork.gke_net[count.index].secondary_ip_range[0].range_name
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

  workload_identity_config {
    workload_pool = "${var.google_project}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }

  enterprise_config {
    desired_tier = "ENTERPRISE"
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_global_access_config {
      enabled = true
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

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = true
    cidr_blocks {
      display_name = "GCP Internal Network"
      cidr_block   = google_compute_subnetwork.gke_net[count.index].ip_cidr_range
    }
    cidr_blocks {
      display_name = "Bell Canada"
      cidr_block   = "142.198.0.0/16"
    }
    cidr_blocks {
      display_name = "Bell Canada"
      cidr_block   = "184.147.0.0/16"
    }
    cidr_blocks {
      display_name = "Bell Canada"
      cidr_block   = "184.144.0.0/16"
    }
    cidr_blocks {
      display_name = "TD Canada"
      cidr_block   = "142.205.13.0/24"
    }
  }
}
