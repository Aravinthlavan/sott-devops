 terraform {
   backend "azurerm" {
     resource_group_name = "Dev-RG"
     storage_account_name = "ttfstatesa"
     container_name = "tfstate"
     key = "terraform.tfstate"
   }
 }
#terraform {
# backend "local" {
# path = "C:/Users/Rahul/OneDrive/documents/devops/terraform/dev.terraform.tfstate"
# }
#}
