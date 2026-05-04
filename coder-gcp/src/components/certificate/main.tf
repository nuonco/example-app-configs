# Apex + wildcard cert (DNS-authorized) bound to a Certificate Map.
# A single DNS authorization on the apex domain authorizes issuance for
# both the apex and *.apex — GCP rejects DnsAuthorization resources
# created against a wildcard hostname.

locals {
  apex = trimsuffix(var.domain_name, ".")
}

resource "google_certificate_manager_dns_authorization" "apex" {
  project  = var.project_id
  name     = "${var.install_id}-apex-auth"
  location = "global"
  domain   = local.apex
}

resource "google_certificate_manager_certificate" "apex_wildcard" {
  project  = var.project_id
  name     = "${var.install_id}-apex-wildcard"
  location = "global"

  managed {
    domains = [local.apex, "*.${local.apex}"]
    dns_authorizations = [
      google_certificate_manager_dns_authorization.apex.id,
    ]
  }

  labels = {
    "install-nuon-co-id" = var.install_id
  }
}

resource "google_certificate_manager_certificate_map" "default" {
  project = var.project_id
  name    = "${var.install_id}-certmap"

  labels = {
    "install-nuon-co-id" = var.install_id
  }
}

resource "google_certificate_manager_certificate_map_entry" "apex" {
  project      = var.project_id
  name         = "${var.install_id}-apex"
  map          = google_certificate_manager_certificate_map.default.name
  certificates = [google_certificate_manager_certificate.apex_wildcard.id]
  hostname     = local.apex
}

resource "google_certificate_manager_certificate_map_entry" "wildcard" {
  project      = var.project_id
  name         = "${var.install_id}-wildcard"
  map          = google_certificate_manager_certificate_map.default.name
  certificates = [google_certificate_manager_certificate.apex_wildcard.id]
  hostname     = "*.${local.apex}"
}

resource "google_dns_record_set" "apex_validation" {
  project      = var.project_id
  managed_zone = var.dns_zone_name
  name         = google_certificate_manager_dns_authorization.apex.dns_resource_record[0].name
  type         = google_certificate_manager_dns_authorization.apex.dns_resource_record[0].type
  ttl          = 300
  rrdatas      = [google_certificate_manager_dns_authorization.apex.dns_resource_record[0].data]
}
