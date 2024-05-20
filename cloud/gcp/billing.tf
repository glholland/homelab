data "google_billing_account" "account" {
  display_name = "My Billing Account"
  open         = true

}

resource "google_billing_budget" "budget" {
  billing_account = data.google_billing_account.account.id
  display_name = "Billing Budget"
  amount {
    specified_amount {
      currency_code = "USD"
      units = "10"
    }
  }
  threshold_rules {
      threshold_percent =  0.5
  }

	depends_on = [ google_project_service.gcp_services ]
}

resource "google_billing_account_iam_binding" "admin" {
  billing_account_id = data.google_billing_account.account.id
  role               = "roles/billing.admin"
  members = [
    "user:${var.gcp_account}"
  ]

}
