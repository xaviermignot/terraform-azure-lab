# Etape 3: Déplacer le backend dans Azure Blob Storage

Dans cette étape on déplacer notre state dans un nouveau compte de stockage et donc remplacer le backend _local_ par le backend [azurerm](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm).  

## Création d'un compte de stockage pour stocker notre state

Depuis le [portal Azure](https://portal.azure.com/#create/Microsoft.StorageAccount), créez un nouveau compte de stockage en choisissant un nom globalement unique. Sélectionnez _LRS_ en redondance et laissez les autres valeurs par défaut, puis finalisez la création.  

> [!NOTE]
> A noter qu'on créé ici le compte de stockage à la main, notre code Terraform ne peut pas créer le compte  de son propre state. C'est un problème dit d'oeuf et de poule qui se solutionne en deux temps dans un scénario à l'échelle, soit en utilisant un script, soit avec une autre configuration Terraform chargée de créer les comptes de stockage des autres configurations Terraform de l'entreprise (et de positionner les bons droits).

## Migration du state vers le nouveau backend

La déclaration du nouveau backend s'effectue en ajoutant une section `backend "azurerm"` comme ceci dans le fichier `versions.tf`:
```hcl
terraform {
  required_providers {
    # ...
  }

  backend "azurerm" {
    container_name = "tfstate"
    key            = "terraform.tfstate"
  }
}
```
Il existe différentes façon de [configurer](https://developer.hashicorp.com/terraform/language/backend#partial-configuration) le backend dans la configuration Terraform. Chaque backend a ses spécificités, dans le cas du backend [azurerm](https://developer.hashicorp.com/terraform/language/backend/azurerm#configuration-variables), les noms du compte de stockage, du container et du blob sont requis, ainsi que celui du groupe de ressource suivant la méthode d'authentification.  
Ces informations peuvent se trouver dans la section `backend "azurerm"` (et donc dans le repo), ou dans un fichier non inclus dans le repo. Ici on choisit de mettre le nom du container et du blob dans le code, et le reste dans un fichier à part.  

1. Ajoutez la section `backend "azurerm"` dans le fichier `versions.tf` comme ci-dessus.
2. Ajoutez un fichier `config.azurerm.tfbackend` dans le dossier `infra` avec le contenu suivant (rajoutez le nom du group de ressource et du compte de stockage entre les guillemets):
```shell
resource_group_name = ""
storage_account_name = ""
```
Le fait de changer le _backend_ nécessite de relancer la command `init`, il faut le faire avec la syntaxe suivante:
```shell
terraform init -backend-config=config.azurerm.tfbackend
```
A la question demandant si le state existant doit être migré, répondez `yes`.  
Terraform a détecté la présence du state local et propose de migrer automatiquement le state existant. Après cette migration le fichier `infra/terraform.tfstate` est vide, et un nouveau fichier `infra/.terraform/terraform.tfstate` a été créé. Ce dernier contient la configuration du nouveau backend: type de backend, nom du compte de stockage, du groupe de ressources, etc.  
Vous pouvez lancer un `terraform plan` ou `terraform apply` pour vérifier la bonne communication avec le nouveau backend: il ne devrait pas y avoir de changement à appliquer.  

## Etape suivante
C'est la fin de cette étape, dans la prochaine nous allons découvrir la fonctionnalité de _workspaces_, c'est par [ici](/docs/step04-addWorkspaces.md).