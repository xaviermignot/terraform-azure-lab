# Etape 5: Ajout d'une page d'erreur et d'une feuille de style

Jusqu'à présent notre site manque de style, et dans le répertoire `src` il y a un fichier `error.html` et `main.css` qui ne sont pas encore utilisés.  
Dans cette étape on va remédier à cela en utilisant des fonctionnalités un peu plus avancées du language HCL.

## Ajout de la page d'erreur
Avec notre configuration actuelle si on accède à une URL invalide de notre site (par exemple en rajoutant `/oups` à l'URL de base), on tombe sur une page indiquant que le fichier `error.html` est introuvable:
![error.html not found](/docs/assets/step05-notFound.png)

Le fichier `error.html` existe déjà dans le répertoire `src`, pour l'envoyer dans notre compte de stockage il faut ajouter une nouvelle ressource de type `azurerm_storage_blob` dans le fichier `infra/main.tf`:
<details>
<summary>Ajout dans le fichier <code>infra/main.tf</code></summary>

```hcl
resource "azurerm_storage_blob" "error" {
  name                   = "error.html"
  storage_account_name   = module.storage_account.name
  storage_container_name = "$web"

  type           = "Block"
  content_type   = "text/html"
  source_content = file("../src/error.html")

  depends_on = [module.storage_account]
}
```
</details>

Il faut également modifier la ressource `azurerm_storage_account_static_website.static_website` pour qu'elle utilise le fichier `error.html` en cas d'erreur:
<details>
<summary>Modification dans le fichier <code>infra/main.tf</code></summary>

```hcl
resource "azurerm_storage_account_static_website" "static_website" {
  storage_account_id = module.storage_account.id
  index_document     = "index.html"
  error_404_document = "error.html"
}
```
</details>

Lancez un `terraform apply`, et tentez à nouveau d'accéder à une URL invalide de votre site, vous devriez obtenir la page d'erreur:
![Page d'erreur](/docs/assets/step05-errorPage.png)

## Optimisation du code avec un `for_each`
Après l'ajout de la page d'erreur, nous avons les lignes suivantes dans le fichier `infra/main.tf` pour déclarer les objets du blob container:
```hcl
resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = module.storage_account.name
  storage_container_name = "$web"

  type           = "Block"
  content_type   = "text/html"
  source_content = file("../src/index.html")

  depends_on = [module.storage_account]
}

resource "azurerm_storage_blob" "error" {
  name                   = "error.html"
  storage_account_name   = module.storage_account.name
  storage_container_name = "$web"

  type           = "Block"
  content_type   = "text/html"
  source_content = file("../src/error.html")

  depends_on = [module.storage_account]
}
```
Ces 2 blocs de code se ressemblent, avec un langage de programmation classique on chercherait à factoriser cette partie, on peut aussi le faire avec Terraform.  
Pour cela on va combiner les éléments suivants:
- L'argument [`for_each`](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each) dans un bloc `resource` permet de faire créer plusieurs ressources avec un seul bloc
- La function [`toset`](https://developer.hashicorp.com/terraform/language/functions/toset) qui permet de transformer une [`list`](https://developer.hashicorp.com/terraform/language/expressions/types#lists-tuples) de strings en `set`
- L'objet `each` et sa propriété `key` qui ne sont disponibles que dans le cas d'un `for_each`, et qui permettent d'accéder à la valeur de l'instance en cours

L'idée est de remplacer les 2 ressources `azurerm_storage_blob` en un seul bloc `resource` avec un `for_each` auquel on passe nos 2 noms de fichiers.  
Essayer de faire la modification vous-même avant de regarder la solution ci-dessous:
<details>
<summary>Remplacer les 2 ressources par le bloc suivant:</summary>

```hcl
resource "azurerm_storage_blob" "files" {
  for_each = toset(["index.html", "error.html"])

  name                   = each.key
  storage_account_name   = module.storage_account.name
  storage_container_name = "$web"

  type           = "Block"
  content_type   = "text/html"
  source_content = file("../src/${each.key}")

  depends_on = [module.storage_account]
}
```
</details>

Lancez un `terraform plan`, vous constatez que Terraform veut supprimer les objets pour les recréer, c'est normal car on a changé leur noms logiques, comme lorsque l'on a ajouté un premier module à l'étape 2 de ce lab.  
Vous pouvez soit appliquer ce plan tel quel, soit chercher à éviter la suppression/recréation en utilisant deux blocs `moved`, puis en faisant un `apply` pour juste mettre à jour le state.

## Ajout de la feuille de style
On va maintenant ajouter du style à nos pages web, vous avez peut-être remarqué qu'une feuille de style est déjà présente dans le dossier `src`, et qu'elle est même utilisée dans les deux fichiers html mais comme on ne l'a pas encore envoyée sur le compte de stockage, ça ne fonctionne pas.  

Pour corriger ça, on pourrait ajouter le fichier `main.css` dans le `for_each` créé à l'instant:
<details>
<summary>Possible modification dans le fichier <code>infra/main.tf</code>:</summary>

```hcl
resource "azurerm_storage_blob" "files" {
  for_each = toset(["index.html", "error.html", "main.css"])

  name                   = each.key
  storage_account_name   = module.storage_account.name
  storage_container_name = "$web"

  type           = "Block"
  content_type   = "text/html"
  source_content = file("../src/${each.key}")

  depends_on = [module.storage_account]
}
```
</details>

Mais on va avoir un problème avec l'argument `content_type`, qui doit être `text/html` pour les fichiers `html`, et `text/css` pour le fichier `css`.  
On devrait s'en sortir en utilisant l'extension de chaque fichier au lieu de mettre `text/html` en dur. Il y a une fonction Terraform qui va nous aider pour cela. Essayer de trouver quelle est cette fonction en fouillant dans [cette section](https://developer.hashicorp.com/terraform/language/functions) de la documentation.  
Si vous n'avez pas trouvé, ce n'est pas grave, il s'agit de cette [function](https://developer.hashicorp.com/terraform/language/functions/split). Essayer de modifier le code pour utiliser cette fonction et résoudre notre "problème".  
<details>
<summary>Si vous n'avez pas trouvé, ce n'est pas grave non plus, dépliez la solution ci-dessous:</summary>

```hcl
resource "azurerm_storage_blob" "files" {
  for_each = toset(["index.html", "error.html", "main.css"])

  name                   = each.key
  storage_account_name   = module.storage_account.name
  storage_container_name = "$web"

  type           = "Block"
  content_type = "text/${split(".", each.key)[1]}"
  source_content = file("../src/${each.key}")

  depends_on = [module.storage_account]
}
```
</details>

Vous pouvez relancer un `terraform apply` qui devrait ajouter le fichier  `main.css`.  
De retour dans le navigateur, vous pouvez rafraîchir la page d'accueil du site et la voir sous un nouveau jour 🤩:
![Site avec style](/docs/assets/step05-withStyle.png)

## Conclusion
Félicitations vous avez atteint l'ultime étape de ce lab 🚀🥳  
Mais ce lab n'est qu'un point de départ et il y a encore plein de choses à apprendre dans le monde de Terraform. N'hésitez pas à continuer d'explorer par vous-même, il existe également d'autres [tutoriels](https://developer.hashicorp.com/terraform/tutorials) sur le site officiel.  
N'hésitez pas à vous référer au paragraphe [suivant](/README.md#a-propos-de-la-documentation-de-terraform) au début de ce lab pour voir les liens vers les sections principales de la documentation officielle.  

Dernier point avant de partir, quand vous aurez terminé n'oubliez pas de supprimer vos ressources dans Azure avec la commande suivante:
```shell
terraform destroy -auto-approve
```
(A utiliser sur vos ressources de test mais pas en production bien entendu).
