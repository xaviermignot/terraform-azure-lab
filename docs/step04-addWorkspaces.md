# Etape 4: Ajout d'un environnement de "staging"

Dans cette étape on va ajouter un second environnement en se basant sur les _workspaces_ et les fichiers `*.tfvars`

## Les workspaces
La fonctionnalité de _workspaces_ de Terraform permet d'utiliser plusieurs infrastructures et plusieurs _states_ avec les mêmes fichiers de configuration. Cette [page](https://developer.hashicorp.com/terraform/language/state/workspaces) de la documentation explique comment utiliser les workspaces.

> [!WARNING]
> Attention à ne pas confondre les workspaces de Terraform CLI, dont on parle ici, avec les workspaces de Terraform Cloud/HCP Terraform qui présentent une meilleure isolation et plus de fonctionnalités, mais obligent à utiliser le service d'HashiCorp

### Workspaces et isolation des environnements
Les workspaces sont souvent utilisés pour gérer différents environnements (dev, qa, prod, ...), mais à la base ils n'ont pas été conçus pour cela.  
En effet tous les workspaces partagent la même configuration de backend, même s'il y a un fichier de state par workspace, ils sont tous au même endroit. Dans notre exemple avec le backend `azurerm`, les states sont tous dans le même compte de stockage.  

On ne peut donc pas séparer les accès, si on a accès au state d'un workspace, on a accès au state des autres workspaces. Ce n'est pas idéal en terme de sécurité, car cela ne respecte pas le principe de moindre privilège.  

Certes avoir accès au state ne veut pas dire qu'on a accès en lecture/écriture à l'infrastructure, et utiliser des identités différentes pour exécuter nos commandes `plan` et `apply` suivant les workspaces. Mais laisser la possibilité de manipuler le state de prod comme celui de dev est un problème de sécurité.

### Le workspace _default_
Depuis le début de ce lab on utilise un workspace sans s'en rendre compte. Il s'agit du workspace _default_, qui est créé comme son nom l'indique par défaut, et qu'il n'est pas possible de supprimer.  
Si on voulait gérer les environnements persistants (dev, qa, prod, ...) avec des workspaces, on supprimerait le workspace _default_ pour ne garder que des workspaces _dev_, _qa_, _prod_, etc. Mais ce n'est pas possible de supprimer le workspace _default_, encore une indication que les workspaces n'ont pas été conçu pour gérer des environnements persistants.  
Les workspaces ont été conçus pour gérer des environnements temporaires (ou _short-lived_), c'est ce qui est expliqué dans [ce message](https://discuss.hashicorp.com/t/prevent-default-workspace/25052/2) par un contributeur de Terraform sur le forum officiel. Pour résumer, l'infrastructure principale est liée au workspace _default_, et dans la majorité des cas c'est le seul workspace nécessaire.  

Une autre façon de voir les workspaces est de les considérer comme les _feature_ branches d'un repo git. Le workspace _default_ correspond à la branche _main_ ou _trunk_, et les autres vivent le temps de tester des changements. C'est ce qui est indiqué dans [cette section](https://developer.hashicorp.com/terraform/cli/workspaces#use-cases) de la documentation, en indiquant plus loin que pour gérer différents environnements persistants, il vaut mieux séparer les backends.

## Les fichiers de variables
Autre fonctionnalité importante de Terraform quand on veut gérer plusieurs environnements: le fichiers de variables ou [tfvars](https://developer.hashicorp.com/terraform/language/values/variables#variable-definitions-tfvars-files).  
Ces fichiers permettent de spécifier une plusieurs valeurs de variables, en utilisant une syntaxe de clé/valeurs pour les fichiers en `*.tfvars`, ou en json pour les fichiers en `*.tfvars.json`.

> [!NOTE]
> A noter que si un fichier est nommé `terraform.tfvars` ou `terraform.vars.json` ou que son nom termine par `.auto.tfvars` ou `.auto.tfvars.json`, Terraform le chargera automatiquement. Sinon il faut utiliser le paramètre `-var-file=chemin/vers/le-fichier.tfvars`.

## Utilisation dans le lab
On va maintenant combiner ces deux fonctionnalités pour ajouter un environnement de _staging_, environnement qui en général est utilisé pour faire des vérifications lors d'une mise en production.  
Tout d'abord on ajoute un _workspace_ via la commande suivante:
```shell
terraform workspace new staging
```
Terraform indique alors que le nouveau workspace est actif, on peut le constater en lançant la commande `terraform state list`: elle ne renvoie rien, confirmant que notre state est vide.  
On peut aussi lister les workspaces avec `terraform workspace list` qui renvoie:
```shell
$ terraform workspace list
  default
* staging
```

Si on lançait un `terraform apply` maintenant, cela ajouterait un nouveau compte de stockage, avec un autre nom mais non ne saurait pas identifier facilement celui de staging. Pour aider à cela on va ajouter la variable suivante dans le fichier `infra/variables.tf`:
```hcl
variable "workspace_suffix" {
  type        = string
  default     = ""
}
```
Et dans le fichier `infra/main.tf`, on utilise la nouvelle variable dans le nom du compte de stockage:
```hcl
locals {
  # ...
  storage_account_name = substr("st${replace("${local.project}${var.workspace_suffix}${random_pet.pet.id}", "-", "")}", 0, 24)
}
```
Enfin, dans le dossier `infra` on crée le fichier `staging.tfvars` avec le contenu suivant:
```hcl
workspace_suffix = "stg"
```

On peut maintenant lancer la commande suivante:
```shell
terraform apply -var-file=staging.tfvars
```

Cela va créer un nouveau compte de stockage dont le nom commence par `staztflabstg`, le `stg` permet de savoir qu'il s'agit du compte de _staging_.

> [!TIP]
> Pour la suite du lab, vous pouvez choisir de rester sur le workspace de staging, ou de détruire les ressources de staging (`terraform destroy`) avant de revenir sur le workspace par défaut (`terraform workspace select default`).

## Etape suivante
On peut maintenant passer à l'étape suivante du lab ou l'on va explorer des fonctionnalités plus avancées du langage HCL, c'est par [ici](docs/step05-addErrorPageAndCss.md).