# Etape 2: Ajout d'un module

Dans cette étape nous allons introduire la notion de _module_ qui permet de mieux organiser notre code Terraform.  

> [!TIP]
> Si vous avez rencontré des soucis sur la première étape, vous pouvez consulter le code lié au tag `step01-simpleExample` [ici](https://github.com/xaviermignot/terraform-azure-lab/tree/step01-simpleExample/infra) sur la branche `solution` pour voir la solution et l'intégrer dans votre copie du repo.
> Vous pouvez aussi vous référer au dossier `_solution` qui contient un _worktree_ git avec le code lié à ce tag.

## Les modules de Terraform
Comme dans de nombreux langages les modules de Terraform permettent d'organiser le code pour combiner des ressources, et créer des briques facilement réutilisables.  
Jusqu'à présent on a déjà utilisé un module sans le savoir, le module _root_ constitué des fichiers `tf` dans le répertoire de départ (`infra`). Par défaut Terraform utilise tous les fichiers `.tf`dans le répertoire à partir duquel il est lancé, par convention on utilise au moins les 3 fichiers suivants dans chaque module:
- Le fichier `variables.tf` contient les _variables_, les paramètres d'entrée du module
- Le fichier `outputs.tf` contient les _outputs_, les valeurs de sortie du module
- Le fichier `main.tf` qui contient les ressources à créer, ou au moins les principales. On peut créer d'autres fichiers `.tf` pour découper celui-ci et faciliter la lecture du code (ça ne change rien pour Terraform qui met tous les fichiers `.tf` au même niveau quel que soit leur nom)

> [!NOTE]
> La documentation explique avec plus de détails la notion de modules [ici](https://developer.hashicorp.com/terraform/language/modules), ainsi que les conventions sur [cette page](https://developer.hashicorp.com/terraform/language/modules/develop/structure).

## Création d'un premier module
Pour illustrer cela on va déplacer le compte de stockage dans un module.
1. Créez un dossier `storage_account` dans le dossier `infra`
2. Dans ce nouveau dossier, créez 3 fichiers `main.tf`, `variables.tf` et `outputs.tf`
3. Notre module va prendre en entrée une variable `name` avec le nom du compte de stockage, ajoutez ceci dans le fichier `variables.tf`:
```hcl
variable "name" {
  type        = string
  description = "The name of the storage account to create"
}
```
4. Petite particularité d'Azure, il va falloir dans chaque module des variables pour la région Azure et le groupe de ressources, à ajouter également dans le fichier `variables.tf`:
```hcl
variable "resource_group_name" {
  type        = string
  description = "The name of the resource group to create the storage account in"
}

variable "location" {
  type        = string
  description = "The location to use for all resources."
}
```
5. Dans le fichier `storage_account/main.tf` on déplace la déclaration du compte de stockage et du site web statique en utilisant les variables:
```hcl
resource "azurerm_storage_account" "account" {
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = var.name

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
```
6. Dans le module root, l'URL du site web est retournée en tant qu'_output_. Comme le compte de stockage n'est plus dans le module root, il faut exposer cette URL en tant qu'output du module `storage_account`, dans le fichier `storage_account/outputs.tf`. Le module root a aussi besoin du nom du compte de stockage, donc on l'ajoute également en tant qu'output:
```hcl
output "name" {
  value = azurerm_storage_account.account.name
}

output "static_website_url" {
  value = azurerm_storage_account.account.primary_web_endpoint
}
```
7. Notre module `storage_account` est prêt mais il faut mettre à jour le module root qui doit l'appeler. Dans le fichier `infra/main.tf`, on remplace les ressources `azurerm_storage_account` et `azurerm_storage_account_static_website` par l'appel au module:
```hcl
module "storage_account" {
  source              = "./storage_account"
  name                = local.storage_account_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
}
```
8. Il faut ensuite mettre à jour la ressource `azurerm_storage_blob.index` pour lui faire utiliser l'_output_ du module à la place des _attributs_ de la ressource de type `azurerm_storage_account` qui a été déplacée dans le module. Il faut également modifier le meta-argument `depends_on` sur cette ressource pour indiquer qu'elle dépend du module:
```hcl
resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = module.storage_account.name
  # ...
}
```
> [!NOTE]
> L'utilisation de `depends_on` est nécessaire ici pour faire comprendre à Terraform que le blob doit être créé après la création de la ressource `azurerm_storage_account_static_website`. Avant cette étape le `depends_on` était utilisé en référençant directement la ressource, désormais on utilise le module pour indiquer à Terraform de terminer la création de _toutes_ les ressources du module avant de passer au blob.  
> Vous trouverez plus d'information le _meta-argument_ `depends_on` sur [cette page](https://developer.hashicorp.com/terraform/language/meta-arguments/depends_on) de la documentation.
9. Dernier point, le module `storage_account` renvoie l'URL du site web en tant qu'_output_. Le module root peut également renvoyer des _output_, notamment pour les afficher dans la console. Pour cela on ajoute l'output suivant dans le fichier `infra/outputs.tf` qui était vide jusqu'à présent:
```hcl
output "website_url" {
  value       = module.storage_account.static_website_url
  description = "The URL of the static website."
}
```
Les modifications sont terminées, on va pouvoir valider les changements.

## Lancement d'un plan et d'un apply
Depuis le terminal du codespace, dans le dossier `infra`, lancez un `terraform plan`.  
Vous obtenez une erreur `Error: Module not installed`, car le module n'est pas installé: après chaque ajout de module, il faut relancer un `terraform init`.  
Une fois que c'est fait, relancez le `terraform plan`. Le plan devrait se dérouler correctement avec le résultat suivant:
```
Plan: 3 to add, 0 to change, 3 to destroy.
```
Terraform prévoit donc d'ajouter 3 ressources et d'en détruire 3, alors qu'on a juste "refactorisé" notre code sans changer aux ressources 🧐  
C'est un effet du state de Terraform: déplacer le compte de stockage dans un module change son nom logique dans la configuration, alors que l'ancien nom est toujours dans le state. Pour Terraform il faut donc supprimer le compte de stockage du module _root_ et créer celui du module `storage_account`.  
Et comme l'objet index.html ne peut pas être déplacé d'un compte de stockage à un autre, Terraform pense qu'il faut aussi le supprimer et le recréer.  

Il faut garder cette mécanique à l'esprit quand on travaille avec Terraform: une des conséquence du state est que le renommage de ressources et le refactoring du code en général peuvent avoir des conséquences. Imaginez avoir fait la même chose sur une base de données de production 🤯  

> [!NOTE]
> Récemment Terraform a ajouté des solutions pour permettre de faciliter le [refactoring](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring) du code, notamment avec les blocs `moved`

On va donc utiliser un block `moved` dans le fichier `main.tf` du module _root_ comme ceci:
```hcl
moved {
  from = azurerm_storage_account.account
  to   = module.storage_account.azurerm_storage_account.account
}

moved {
  from = azurerm_storage_account_static_website.static_website
  to   = module.storage_account.azurerm_storage_account_static_website.static_website
}
```
Avant de relancer un _plan_: cette fois aucun changement n'est détecté, on lance également un _apply_ pour que mettre à jour le state, sans conséquence sur notre infrastructure.

## Etape suivante
C'est la fin de cette étape, vous pouvez passer à la [suivante](/docs/step03-addStorageBackend.md) on l'on va changer de _backend_.
