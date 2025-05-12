resource "google_firebase_project" "firebase-poc" {
  provider = google-beta
  project  = var.ty_gcp_project_id
}

# Create a Firebase web app only after manual Firebase project setup in console
resource "google_firebase_web_app" "poc-app" {
  provider        = google-beta
  project         = "392286243478"
  display_name    = "A POC Firebase App"
  api_key_id      = google_apikeys_key.web.uid
  deletion_policy = "ABANDON"
  depends_on      = [google_firebase_project.firebase-poc]
}

# Commenting out the data source that's causing errors
# data "google_firebase_web_app_config" "poc-app" {
#   provider   = google-beta
#   web_app_id = google_firebase_web_app.poc-app.app_id
# }

resource "google_storage_bucket" "default" {
  provider = google-beta
  project  = var.ty_gcp_project_id
  name     = "fb-webapp-poc-app"
  location = "US"
}

resource "google_apikeys_key" "web" {
  provider     = google-beta
  project      = var.ty_gcp_project_id
  name         = "fb-api-key"
  display_name = "Display Name TS"

  restrictions {
    browser_key_restrictions {
      allowed_referrers = ["tylerstefancin.com"]
    }
  }
}

resource "google_storage_bucket_object" "default" {
  provider = google-beta
  bucket   = google_storage_bucket.default.name
  name     = "firebase-config.json"

  # Use a placeholder configuration that you can manually update later
  content = jsonencode({
    appId = google_firebase_web_app.poc-app.app_id
    # You'll need to manually get these values from the Firebase console
    apiKey        = google_apikeys_key.web.key_string
    authDomain    = "${var.ty_gcp_project_id}.firebaseapp.com"
    storageBucket = "${var.ty_gcp_project_id}.appspot.com"
    # Optional fields that can be added manually later if needed
    databaseURL       = ""
    messagingSenderId = ""
    measurementId     = ""
  })
}
