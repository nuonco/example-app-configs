# The runner writes a kubeconfig for the install's cluster and points
# KUBE_CONFIG_PATH at it, so the provider needs no explicit host or credentials.
provider "kubectl" {
  load_config_file = true
}
