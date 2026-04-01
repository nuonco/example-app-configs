provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "kubernetes" {
  # Configured via KUBE_CONFIG_PATH or in-cluster config by the runner
}
