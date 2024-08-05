###############################################################################
# Google Kubernetes cluster (GKE)
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
# A minimal configuration GKE (regional) configuration
# The cluster dedicated to a single application. 
# Single application design drives the configuration choices.
###############################################################################

resource "google_container_cluster" "gke1" {
  name                     = "${var.app_id}-01"
  project                  = var.google_project
  location                 = var.google_region
  deletion_protection      = false
  initial_node_count       = 1
  remove_default_node_pool = true

  # Network configuration
  # https://cloud.google.com/kubernetes-engine/docs/concepts/alias-ips
  network    = google_compute_network.main.id
  subnetwork = google_compute_subnetwork.gke_net.id

  ip_allocation_policy {
    services_secondary_range_name = google_compute_subnetwork.gke_net.secondary_ip_range[1].range_name
    cluster_secondary_range_name  = google_compute_subnetwork.gke_net.secondary_ip_range[0].range_name
  }

  addons_config {
    # enable DNS cache
    # https://cloud.google.com/kubernetes-engine/docs/how-to/nodelocal-dns-cache
    dns_cache_config {
      enabled = true
    }
    # https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/gce-pd-csi-driver
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  # https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept
  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.31.255.240/28"

    master_global_access_config {
      enabled = true
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

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
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

resource "google_container_node_pool" "p1" {
  name               = "p1"
  cluster            = google_container_cluster.gke1.name
  location           = var.google_region
  initial_node_count = 1
  max_pods_per_node  = 110

  # https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-autoscaler
  autoscaling {
    max_node_count = 3
    min_node_count = 1
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    service_account = google_service_account.gke1.email
    spot            = var.gke_machine_spot
    machine_type    = var.gke_machine_type
    oauth_scopes    = ["cloud-platform"]

    gvnic {
      enabled = true
    }

    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }
  }
}
