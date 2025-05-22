# Lab Terraform avec Azure

Bienvenue dans ce lab d'introduction à Terraform dans un environnement Azure. L'objectif de ce lab est de vous faire découvrir l'outil Terraform avec une utilisation de base.  

Avant de commencer, voici quelques points et définitions avec des liens à visiter si nécessaire:
- Tout d'abord, Terraform est un outil d'Infrastructure-as-Code (IaC) créé par HashiCorp et développé en open-source
- Terraform permet de définir de l'infrastructure pour des fournisseurs de cloud publique (AWS, GCP, Azure), des solutions on-prem, et de nombreux eco-systèmes comme Kubernetes par exemple
- Terraform utilise une approche IaC _déclarative_, à l'opposé de l'approche _impérative_:
    - Dans une approche _impérative_ on définit une suite d'étapes pour arriver à un résultat, c'est le cas avec un script Bash ou PowerShell par exemple
    - L'approche _déclarative_ de Terraform décrit le résultat attendu, sans s'occuper des étapes pour l'atteindre: on dit à Terraform _"voilà ce que je veux"_, et il est sensé se débrouiller pour y arriver
- Dans ce lab (comme dans la plupart des cas avec Terraform) on va décrire notre infrastructure en utilisant le langage HCL (pour HashiCorp Configuration Language)

D'autres définitions et liens vers la documentation seront proposés en temps voulu tout au long de ce lab.

Pour faire tourner ce lab vous n'avez rien à installer, vous allez utiliser le service GitHub Codespace qui permet d'interagir avec une machine de développement (éditeur de code et terminal) depuis votre navigateur web. Tous les outils dont vous avez besoin (Terraform et git en tête) y sont déjà installés.  

## Fonctionnement, objectif et lancement du lab
L'objectif de ce lab est de créer une application web simple hébergée dans un _storage account_, le service de stockage managé par Azure.  

> [!NOTE]
> Théoriquement ce lab peut être fait en autonomie, mais il a été conçu pour être supervisé par un formateur, dans un groupe de plusieurs personnes. Le formateur (ou la formatrice) est supposé vous fournir un compte pour vous connecter à un environnement Azure, ainsi qu'un groupe de ressources dans une souscription pour le déroulement du lab.

Tout le contenu du lab est dans ce repository GitHub, suivez ces étapes pour commencer:
1. Créez un fork du repository sur votre compte en cliquant [ici](https://github.com/xaviermignot/terraform-azure-lab/fork)
2. Depuis votre fork, créez un _codespace_ en utilisant le bouton _Code_ en haut de la page principal comme expliqué [ici](https://docs.github.com/en/codespaces/developing-in-a-codespace/creating-a-codespace-for-a-repository#creating-a-codespace-for-a-repository)
3. Une fois le codespace prêt, placez-vous dans le terminal et lancez la commande `az login` pour vous connecter à Azure
4. Lancez ensuite les commandes suivantes:
```shell
zsh
omz plugin enable terraform
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export TF_VAR_current_user=$(az ad signed-in-user show --query displayName -o tsv)
```
Ces commandes lancent le shell _zsh_ à place de _bash_, et activent le plugin de Terraform de _Oh My Zsh_, avec de l'auto-complétion et des alias bien pratiques 🤓  
Elles définissent également des variables d'environnements utiles pour le lab, assurez-vous qu'elles soient toujours définies.

> [!TIP]
> Par défaut, votre codespace va se mettre automatiquement en veille au bout de 30 minutes. Si vous devez le redémarrer après cela, ou si vous faites le lab en plusieurs fois, la connexion avec Azure sera toujours active au redémarrage du codespace. Par contre vous devrez relancer les commandes de l'étape 4 ci-dessus pour vous replacer dans `zsh` avec les plugins chargés et surtout pour redéfinir les variables d'environnement.

Pour plus d'information sur l'interface de GitHub Codespaces, la documentation utilisateur est disponible [ici](https://docs.github.com/en/codespaces/developing-in-a-codespace/developing-in-a-codespace). La plupart des raccourci claviers habituels fonctionnent dans le terminal (`tab` pour l'autocomplétion, `Ctrl+r` pour rechercher dans l'historique, `Ctrl+l` pour effacer, etc.). Le raccourci `Ctrl+j` est également bien pratique pour masquer le terminal et donc de basculer entre le terminal et l'éditeur de code, et inversement 😉

## Organisation du repo et solution 😉
Le répertoire `infra` du repo (et donc de votre fork) contient le début de la configuration Terraform du lab, c'est un point de départ que vous allez modifier depuis votre codespace.  
Si besoin la solution de chaque étape du lab est disponible dans des sous-dossiers du répertoire `_solution`. Vous pouvez les utilisez si jamais vous êtes bloqué ou que vous voulez aller plus vite.  

Les étapes principales du lab se passent en local, donc vous pouvez rester dans le filesystem de votre codespace sans faire de commit. Il y a une étape "bonus" qui consiste à faire tourner Terraform depuis un pipeline Azure DevOps. Pour cela il va falloir pousser vos changements, et établir une connexion entre votre fork et une organisation Azure DevOps. C'est pour cela qu'il vaut mieux créer un fork du repo, sinon il ne serait pas possible de pousser vos changement sur un repository distant.

## A propos de la documentation de Terraform
Les concepts principaux de Terraform seront abordés tout au long de ce lab, avec des liens vers la documentation officielle.  
En travaillant avec Terraform vous serez amené à utiliser régulièrement les deux sites suivants:
1. [developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform) pour tout ce qui concerne le coeur de l'outil:
    - La partie [CLI](https://developer.hashicorp.com/terraform/cli) avec toutes les commandes
    - La partie [HCL](https://developer.hashicorp.com/terraform/language) avec tout ce qui concerne le langage (la [syntaxe](https://developer.hashicorp.com/terraform/language/syntax), les [expressions](https://developer.hashicorp.com/terraform/language/expressions), les [functions](https://developer.hashicorp.com/terraform/language/functions), etc.)
2. [registry.terraform.io](https://registry.terraform.io/) pour la documentation de chaque _provider_ (un concept expliqué dès le début du lab). Typiquement on va consulter ce site pour tout ce qui est spécifique à [Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest) (liste des resources, connexion entre Terraform et Azure, etc.)

Ces sites seront souvent cités au cours du lab, mais vous pouvez déjà les ajouter à vos favoris.

## Démarrage du lab
Une fois le codespace correctement lancé et configuré, vous pouvez commencer le lab avec la première [étape](/docs/step01-simpleExample.md) 🚀
