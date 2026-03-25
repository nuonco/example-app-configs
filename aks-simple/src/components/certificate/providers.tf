provider "azurerm" {
  features {}
}

provider "kubernetes" {
  config_path = "${path.root}/.kubeconfig"
}

provider "kubectl" {
  config_path = "${path.root}/.kubeconfig"
}

provider "helm" {
  kubernetes {
    config_path = "${path.root}/.kubeconfig"
  }
}
