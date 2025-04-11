###############################################################################
# Module Outputs
###############################################################################

output "kms_crypto_key_id" {
  description = "KMS Crypto Key ID"
  value       = google_kms_crypto_key.main.id
}
