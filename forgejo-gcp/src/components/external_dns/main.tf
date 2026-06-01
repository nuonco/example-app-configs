resource "google_service_account" "external_dns" {
  project      = var.project_id
  account_id   = "ext-dns-${substr(var.install_id, 0, 18)}"
  display_name = "external-dns for ${var.install_id}"
}

resource "google_project_iam_member" "external_dns" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.external_dns.email}"
}

resource "google_service_account_iam_member" "external_dns_wi" {
  service_account_id = google_service_account.external_dns.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[external-dns/external-dns]"
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  namespace        = "external-dns"
  create_namespace = true
  repository       = "https://kubernetes-sigs.github.io/external-dns"
  chart            = "external-dns"
  version          = var.chart_version
  wait             = true
  timeout          = 300

  values = [yamlencode({
    provider = {
      name = "google"
    }

    extraArgs = [
      "--google-project=${var.project_id}",
      "--google-zone-visibility=public",
    ]

    serviceAccount = {
      create = true
      name   = "external-dns"
      annotations = {
        "iam.gke.io/gcp-service-account" = google_service_account.external_dns.email
      }
    }

    domainFilters = split(",", var.domain_filters)

    policy = "upsert-only"

    sources = ["ingress", "service", "gateway-httproute"]

    txtOwnerId = var.install_id
  })]

  depends_on = [
    google_service_account_iam_member.external_dns_wi,
  ]
}

resource "helm_release" "external_dns_internal" {
  name             = "external-dns-internal"
  namespace        = "external-dns"
  create_namespace = true
  repository       = "https://kubernetes-sigs.github.io/external-dns"
  chart            = "external-dns"
  version          = var.chart_version
  wait             = true
  timeout          = 300

  values = [yamlencode({
    provider = {
      name = "google"
    }

    extraArgs = [
      "--google-project=${var.project_id}",
      "--google-zone-visibility=private",
    ]

    serviceAccount = {
      create = false
      name   = "external-dns"
    }

    domainFilters = split(",", var.internal_domain_filters)

    policy = "upsert-only"

    sources = ["ingress", "service", "gateway-httproute"]

    txtOwnerId = "${var.install_id}-internal"
  })]

  depends_on = [
    helm_release.external_dns,
  ]
}
