terraform {
  required_version = ">= 0.15"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 1.9.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.53.0"
    }
  }
}

provider azurerm {
  features {}
}
