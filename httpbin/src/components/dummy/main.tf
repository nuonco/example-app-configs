variable "install_id" {
  type = string
}

resource "random_pet" "this" {
  length = 2

  keepers = {
    install_id = var.install_id
  }
}
