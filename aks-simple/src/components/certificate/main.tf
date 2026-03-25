# Install cert-manager via Helm
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.17.1"

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "podLabels.azure\\.workload\\.identity/use"
    value = "true"
  }

  set {
    name  = "serviceAccount.labels.azure\\.workload\\.identity/use"
    value = "true"
  }
}

# Managed Identity for cert-manager to manage DNS-01 challenges
resource "azurerm_user_assigned_identity" "cert_manager" {
  name                = "${var.install_id}-cert-manager"
  resource_group_name = var.resource_group
  location            = data.azurerm_resource_group.main.location
}

data "azurerm_resource_group" "main" {
  name = var.resource_group
}

# Grant DNS Zone Contributor so cert-manager can create DNS records
resource "azurerm_role_assignment" "cert_manager_dns" {
  scope                = var.dns_zone_id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.cert_manager.principal_id
}

# Federated credential linking the cert-manager SA to the Managed Identity
resource "azurerm_federated_identity_credential" "cert_manager" {
  name                = "${var.install_id}-cert-manager"
  resource_group_name = var.resource_group
  parent_id           = azurerm_user_assigned_identity.cert_manager.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.oidc_issuer_url
  subject             = "system:serviceaccount:cert-manager:cert-manager"
}

# Annotate the cert-manager SA with the Managed Identity client ID
resource "kubernetes_annotations" "cert_manager_sa" {
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = "cert-manager"
    namespace = "cert-manager"
  }
  annotations = {
    "azure.workload.identity/client-id" = azurerm_user_assigned_identity.cert_manager.client_id
  }

  depends_on = [helm_release.cert_manager]
}

# ClusterIssuer for Let's Encrypt using Azure DNS
resource "kubectl_manifest" "cluster_issuer" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v2.api.letsencrypt.org/directory"
        email  = "noreply@nuon.co"
        privateKeySecretRef = {
          name = "letsencrypt-prod-key"
        }
        solvers = [{
          dns01 = {
            azureDNS = {
              subscriptionID    = var.subscription_id
              resourceGroupName = var.resource_group
              hostedZoneName    = var.dns_zone_name
              managedIdentity = {
                clientID = azurerm_user_assigned_identity.cert_manager.client_id
              }
            }
          }
        }]
      }
    }
  })

  depends_on = [
    helm_release.cert_manager,
    kubernetes_annotations.cert_manager_sa,
    azurerm_federated_identity_credential.cert_manager,
    azurerm_role_assignment.cert_manager_dns,
  ]
}

# --- external-dns ---

# Managed Identity for external-dns
resource "azurerm_user_assigned_identity" "external_dns" {
  name                = "${var.install_id}-external-dns"
  resource_group_name = var.resource_group
  location            = data.azurerm_resource_group.main.location
}

# Grant DNS Zone Contributor so external-dns can create A records
resource "azurerm_role_assignment" "external_dns_dns" {
  scope                = var.dns_zone_id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.external_dns.principal_id
}

# Also grant Reader on the resource group so external-dns can list zones
resource "azurerm_role_assignment" "external_dns_rg_reader" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.external_dns.principal_id
}

# Federated credential for external-dns SA
resource "azurerm_federated_identity_credential" "external_dns" {
  name                = "${var.install_id}-external-dns"
  resource_group_name = var.resource_group
  parent_id           = azurerm_user_assigned_identity.external_dns.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.oidc_issuer_url
  subject             = "system:serviceaccount:external-dns:external-dns"
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns"
  chart            = "external-dns"
  namespace        = "external-dns"
  create_namespace = true
  version          = "1.15.2"

  set {
    name  = "provider.name"
    value = "azure"
  }

  set {
    name  = "extraArgs[0]"
    value = "--azure-resource-group=${var.resource_group}"
  }

  set {
    name  = "extraArgs[1]"
    value = "--azure-subscription-id=${var.subscription_id}"
  }

  set {
    name  = "domainFilters[0]"
    value = var.dns_zone_name
  }

  set {
    name  = "txtOwnerId"
    value = var.install_id
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "serviceAccount.labels.azure\\.workload\\.identity/use"
    value = "true"
  }

  set {
    name  = "serviceAccount.annotations.azure\\.workload\\.identity/client-id"
    value = azurerm_user_assigned_identity.external_dns.client_id
  }

  set {
    name  = "podLabels.azure\\.workload\\.identity/use"
    value = "true"
  }

  depends_on = [
    azurerm_federated_identity_credential.external_dns,
    azurerm_role_assignment.external_dns_dns,
    azurerm_role_assignment.external_dns_rg_reader,
  ]
}

# --- certificate ---

# Certificate for the app domain
resource "kubectl_manifest" "certificate" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "${var.install_id}-tls"
      namespace = "whoami"
    }
    spec = {
      secretName = "${var.install_id}-tls"
      issuerRef = {
        name = "letsencrypt-prod"
        kind = "ClusterIssuer"
      }
      dnsNames = [var.domain_name]
    }
  })

  depends_on = [kubectl_manifest.cluster_issuer]
}
