###############################################################################
# Google Kubernetes Engine (GKE) Service Account
###############################################################################

locals {
  gke_project_roles = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/viewer",
  ])
}

resource "google_service_account" "gke" {
  count        = var.enable_gke ? length(var.gke_config) : 0
  account_id   = "gke-cluster-${count.index}"
  display_name = "GKE Service Account"
}

resource "google_project_iam_member" "gke" {
  for_each = {
    for pair in setproduct(toset(google_service_account.gke.*.member), local.gke_project_roles) :
    "${pair[0]}-${pair[1]}" => {
      member = pair[0]
      role   = pair[1]
    }
  }
  project = var.google_project
  member  = each.value.member
  role    = each.value.role

  depends_on = [google_service_account.gke]
}

module "gke_kms" {
  source = "./modules/gke-kms/"

  count       = var.enable_gke ? length(var.gke_config) : 0
  gke_project = var.google_project
  gke_region  = var.gke_config[count.index].gke_region
}

###############################################################################
# GKE Cluster
###############################################################################

resource "google_container_cluster" "gke" {
  count               = var.enable_gke ? length(var.gke_config) : 0
  name                = var.gke_config[count.index].gke_name
  location            = var.gke_config[count.index].gke_region
  deletion_protection = false
  initial_node_count  = 1

  network    = google_compute_network.main.id
  subnetwork = google_compute_subnetwork.gke_net[count.index].id

  ip_allocation_policy {
    services_secondary_range_name = google_compute_subnetwork.gke_net[count.index].secondary_ip_range[1].range_name
    cluster_secondary_range_name  = google_compute_subnetwork.gke_net[count.index].secondary_ip_range[0].range_name
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

  database_encryption {
    state    = "ENCRYPTED"
    key_name = module.gke_kms[count.index].kms_crypto_key_id
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
      "APISERVER",
      "SCHEDULER",
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
    ]
  }

  monitoring_config {
    enable_components = [
      "DEPLOYMENT",
      "HPA",
      "STATEFULSET",
      "STORAGE",
      "SYSTEM_COMPONENTS",
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
      display_name = "Toronto Canada"
      cidr_block   = "142.205.13.0/24"
    }
  }

  node_config {
    machine_type = "e2-highmem-2"
    disk_type    = "pd-balanced"
    preemptible  = true
  }

  depends_on = [
    google_compute_network.main,
    google_compute_subnetwork.gke_net,
    google_project_service.main,
    module.gke_kms,
  ]
}
