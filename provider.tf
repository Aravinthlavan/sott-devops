terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.26.0"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id = "57d7d5ca-8ebb-41e9-9a6c-9b709f5ec483"
  resource_provider_registrations = "none"
}
