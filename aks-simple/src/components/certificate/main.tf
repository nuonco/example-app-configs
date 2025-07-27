resource "azurerm_key_vault_certificate" "example" {
  # name         = "${var.install_id}-cert"
  name         = "https-cert"
  key_vault_id = var.key_vault_id

  certificate_policy {
    issuer_parameters {
      name = "Self" # or "Unknown" for imported, or the name of a CA
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = [var.domain_name]
      }

      subject            = "CN=${var.domain_name}"
      validity_in_months = 12
    }
  }
}
