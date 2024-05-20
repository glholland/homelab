resource "google_secret_manager_secret" "secrets_tfvars" {
  secret_id = "secrets_tfvars"

  labels = {
    label = "terraform"
  }

  replication {
    user_managed {
      replicas {
        location = "us-central1"
			}
    }
  }
}
