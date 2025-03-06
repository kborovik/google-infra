###############################################################################
# Network configuration
###############################################################################

resource "google_compute_network" "main" {
  name                    = "main"
  description             = "Default Network"
  routing_mode            = "REGIONAL"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke_net" {
  count                    = var.enable_gke ? length(var.gke_config) : 0
  name                     = "gke-${count.index}"
  region                   = var.gke_config[count.index].gke_region
  network                  = google_compute_network.main.id
  purpose                  = "PRIVATE"
  private_ip_google_access = true
  ip_cidr_range            = var.gke_config[count.index].gke_net

  secondary_ip_range {
    range_name    = "gke-pod-${count.index}"
    ip_cidr_range = var.gke_config[count.index].gke_pod
  }
  secondary_ip_range {
    range_name    = "gke-svc-${count.index}"
    ip_cidr_range = var.gke_config[count.index].gke_svc
  }
}

###############################################################################
# Google Managed Services IP ranges
###############################################################################

resource "google_compute_global_address" "google_service_network" {
  name          = "google-managed-services"
  network       = google_compute_network.main.id
  address       = cidrhost(var.google_network.gcp_svc, 0)
  prefix_length = split("/", var.google_network.gcp_svc)[1]
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
}

resource "google_service_networking_connection" "google_service_network" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.google_service_network.name]
}

###############################################################################
# Network NAT
###############################################################################

resource "google_compute_address" "cloud_nat" {
  count        = var.enable_nat ? 1 : 0
  name         = "cloud-nat-${var.app_id}"
  region       = var.google_region
  address_type = "EXTERNAL"
}

resource "google_compute_router" "main" {
  count   = var.enable_nat ? 1 : 0
  name    = "main"
  region  = var.google_region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "main" {
  count                              = var.enable_nat ? 1 : 0
  name                               = "main"
  region                             = var.google_region
  router                             = google_compute_router.main[0].name
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.cloud_nat[0].id]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

###############################################################################
# Firewall Rules
###############################################################################

resource "google_compute_firewall" "allow_google_iap" {
  name        = "allow-google-iap"
  description = "Allow Google IAP Services"
  network     = google_compute_network.main.id
  priority    = 100

  source_ranges = [
    "35.235.240.0/20",
  ]

  destination_ranges = [
    var.google_network.project
  ]

  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }
}

resource "google_compute_firewall" "allow_google_lb" {
  name        = "allow-google-lb"
  description = "Allow Google Load Balancers"
  network     = google_compute_network.main.id
  priority    = 101

  source_ranges = [
    "35.235.240.0/20",
    "35.191.0.0/16",
    "130.211.0.0/22",
  ]

  destination_ranges = [
    var.google_network.project
  ]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}
