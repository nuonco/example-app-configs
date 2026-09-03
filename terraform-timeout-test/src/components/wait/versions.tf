terraform {
  required_version = ">= 1.11.0"

  required_providers {
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}
