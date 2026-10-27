terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }

  # Le runner GitHub repart de zéro à chaque exécution : le state doit être distant
  backend "azurerm" {
    resource_group_name  = "rg-formation-partage"
    storage_account_name = "stformationtfstates"
    container_name       = "oidc"
    key                  = "titouan.tfstate"       # À COMPLÉTER : votre prénom
  }
}

provider "azurerm" {
  features {}
}

# Une ressource gratuite, créée par le pipeline dans le seul resource group où il a des droits
resource "azurerm_user_assigned_identity" "depuis_github" {
  name                = "id-titouan-depuis-github"   # À COMPLÉTER : votre prénom
  resource_group_name = "rg-titouan-oidc"            # À COMPLÉTER : votre prénom
  location            = "swedencentral"
}
