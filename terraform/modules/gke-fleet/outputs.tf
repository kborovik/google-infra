###############################################################################
# Module Outputs
###############################################################################

output "gke_fleet_id" {
  description = "GKE Fleet ID"
  value       = google_gke_hub_fleet.fleet.id
}
