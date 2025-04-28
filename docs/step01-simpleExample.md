# Etape 1: Premières commandes Terraform
Dans la première étape de ce lab, on va prendre le temps d'explorer le contenu du repository, et de le compléter pour ajouter nos premières ressources dans Azure.

## Le fichier `versions.tf` et la notion de _providers_
Tout le code HCL/Terraform va se trouver dans le dossier `infra`, qui pour le moment contient un fichier `versions.tf` avec le contenu suivant:
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  required_version = "~> 1.11.0"
}

provider "azurerm" {
  features {}
}
```
Il y a plusieurs choses intéressantes dans ce fichier. Tout d'abord la section `terraform/required_providers` contient la liste des _providers_ utilisés par notre configuration. Les providers sont des plugins utilisés par Terraform pour interagir avec un provider de cloud ou tout autre API. Dans ce lab on va utiliser 2 providers développés par HashiCorp:
- Le provider `hashicorp/azurerm` permet logiquement d'interagir avec les APIs d'Azure
- Le provider `hashicorp/random` ajoute des fonctionnalités de _random_ pour s'assurer que le nom de nos ressources dans Azure soient uniques

Le provider `hashicorp/azurerm` a sa propre section de configuration dans qui est vide mais qui au besoin permet de gérer différentes fonctionnalités comme documenté [ici](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block).  

Enfin on précise dans l'élément `terraform/required_version` la version de Terraform à utiliser pour appliquer notre configuration.

> [!NOTE]
> Pour en savoir plus sur les providers, consultez [cette page](https://developer.hashicorp.com/terraform/language/providers) de la documentation.  
Pour comprendre la syntaxe du `required_version`, [c'est par là](https://developer.hashicorp.com/terraform/language/expressions/version-constraints).

## Initialisation de Terraform

Placez-vous dans le dossier infra depuis le terminal de votre codespace et lancez la commande `terraform init`.  

Cette commande initialise l'environnement Terraform avec les actions suivantes:
- Téléchargement des providers dans le sous-dossier `.terraform`
- Création du fichier `.terraform.lock.hcl`

Les providers sont des fichiers binaires qui ne doivent pas être inclus dans le repository git.  
Par contre le fichier `.terraform.lock.hcl` doit être inclus, il contient les informations sur les versions utilisées, et permet donc que tous les utilisateurs du repository utilisent exactement les mêmes versions de providers. Ce fichier n'est jamais modifié à la main (heureusement vu son contenu 😉), mais via la commande `init` de Terraform.  

## Création d'une première ressource dans Azure

### Création des premières ressources
Toujours dans le dossier `infra` ajoutez le contenu suivant au fichier `main.tf`:
```hcl
resource "azurerm_storage_account" "account" {
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  name                = local.storage_account_name

  account_replication_type      = "LRS"
  account_tier                  = "Standard"
  public_network_access_enabled = true
  https_traffic_only_enabled    = true
  min_tls_version               = "TLS1_2"
}

resource "azurerm_storage_account_static_website" "static_website" {
  storage_account_id = azurerm_storage_account.account.id
  index_document     = "index.html"
}

resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.account.name
  storage_container_name = "$web"

  type           = "Block"
  content_type   = "text/html"
  source_content = file("../src/index.html")

  depends_on = [azurerm_storage_account_static_website.static_website]
}
```
Ce fichier est le début de notre configuration avec les 4 ressources suivantes:
1. Le `random_pet` du provider `random`, déjà présent, permet de générer un nom d'animal (comme le nom des conteneur docker) qu'on va utiliser dans le nom des ressources Azure pour les rendre unique (c'est juste un peu plus sympa qu'un _guid_)
2. `azure_storage_account` représente le futur compte de stockage dans Azure.
3. `azurerm_storage_account_static_website` active la fonctionnalité de site web statique
4. `azurerm_storage_blob` permet de prendre le fichier `index.html` de notre repository pour le charger dans le compte de stockage. On voit que le compte est référencé par son nom via l'attribut `storage_account_name`

### Premier _plan_
De retour dans le terminal du codespace, lancez la commande `terraform plan`.  
Cette commande fondamentale permet de comparer notre _configuration_ (ce qu'il y a dans nos fichiers `.tf`) avec notre _infrastructure_ (ce qu'il y a dans Azure). Comme pour le moment notre infrastructure est vide, vous devez avoir la ligne suivante dans l'output de la commande:
```
Plan: 4 to add, 0 to change, 0 to destroy.
```
Ainsi que le détail des 4 ressources que Terraform prévoit d'ajouter.

### Premier _apply_
Deuxième commande fondamentale à lancer dès maintenant: `terraform apply` (tapez `yes` quand on vous le demande pour valider les changements).  
Cette commande applique les modifications du _plan_ et créé donc les ressources dans Azure comme on le voit dans cette ligne de l'output:
```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
``` 
Le compte de stockage est maintenant visible depuis le [portail Azure](https://portal.azure.com/#browse/Microsoft.Storage%2FStorageAccounts). 
Vous pouvez également voir le fichier `index.html` et son contenu depuis le compte de stockage, dans la partie _Data storage_, _Containers_, sélectionnez le container puis le fichier, et enfin sélectionnez l'onglet _Edit_.

### Le _state_ et les _backends_
De retour dans votre codespace, dans l'explorateur de fichier vous remarquerez le fichier `terraform.tfstate` qui vient d'être créé par la commande `apply`.  
Ce fichier représente le _state_, un concept très important de Terraform. Le state est une représentation de l'ensemble des ressources, et permet à Terraform de faire le lien entre la _configuration_ et l'_infrastructure_.  
Quand Terraform effectue un `plan` ou un `apply`, il s'appuie sur le state pour déterminer les changements à effectuer, dont les suppressions de ressources, et détecter d'éventuels changement fait en dehors de Terraform (depuis le portail Azure par exemple).  

> [!NOTE]
> Le state est un sujet assez complexe, pour mieux le comprendre vous pouvez consulter [cette page](https://developer.hashicorp.com/terraform/language/state) de la documentation ainsi que [celle-ci](https://developer.hashicorp.com/terraform/language/state/purpose) qui explique en quoi il est nécessaire.

Prenez le temps de regarder le contenu du fichier `terraform.tfstate`: il s'agit d'une représentation en `json` des ressources qui existent dans Azure (le compte de stockage et la page index.html) et en dehors d'Azure (le `random_pet` qui n'existe que dans le state).  

Pour le moment, stocker le state dans un fichier fonctionne pour ce lab mais dans une situation réelle posera les problèmes suivants:
- Le state contient des informations sensibles donc il faut absolument le sécuriser
- Comme il n'est bien entendu pas inclus dans le repository, cela ne permet pas de collaborer à plusieurs sur notre base de code IaC

Pour adresser cela, Terraform utilise la notion de _backends_. Un _backend_ représente l'endroit ou Terraform stocke son state. Par défaut, c'est le backend _local_ qui est utilisé (c'est notre cas).  
Il existe d'autres _backends_ qui permettent de stocker le state dans différents services de stockage comme Terraform Cloud, Azure Blob Storage (qu'on utilisera plus loin dans ce lab), ou AWS S3.  

> [!NOTE]
> Encore une fois pour aller plus loin le mieux est de se référer à la documentation officielle, qui explique [ici](https://developer.hashicorp.com/terraform/language/settings/backends/configuration) la notion de _backend_ et liste les options disponibles.

## Etape suivante
C'est la fin de cette première étape importante qui présente les commandes de base. Vous pouvez passer à [l'étape suivante](/docs/step02-addModule.md) !