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
Tout se passe dans ce repository git, en plusieurs étapes.  
Pour commencer, lancez un codespace en utilisant ce bouton:  
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/xaviermignot/terraform-azure-lab?quickstart=1)

Une fois le codespace prêt, placez-vous dans le terminal et lancez la commande `az login` pour vous connecter à Azure, puis lancez les commandes suivantes:
```shell
zsh
omz plugin enable terraform
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export TF_VAR_current_user=$(az ad signed-in-user show --query displayName -o tsv)
```
Ces commandes lancent le shell _zsh_ à place de _bash_, et activent le plugin de Terraform de _Oh My Zsh_, avec de l'auto-complétion et des alias bien pratiques 🤓  
Elles définissent également des variables d'environnements utiles pour le lab, assurez-vous qu'elles soient toujours définies.

Pour plus d'information sur l'interface de GitHub Codespaces, la documentation utilisateur est disponible [ici](https://docs.github.com/en/codespaces/developing-in-a-codespace/developing-in-a-codespace). La plupart des raccourci claviers habituels fonctionnent dans le terminal (`tab` pour l'autocomplétion, `Ctrl+r` pour rechercher dans l'historique, `Ctrl+l` pour effacer, etc.). Le raccourci `Alt+s` est également bien pratique pour passer du terminal à l'éditeur de code, et inversement 😉

## A propos de la documentation de Terraform
Les concepts principaux de Terraform seront abordés tout au long de ce lab, avec des liens vers la documentation officielle.  
En travaillant avec Terraform vous serez amené à utiliser régulièrement les deux sites suivants:
1. [developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform) pour tout ce qui concerne le coeur de l'outil:
    - La partie [CLI](https://developer.hashicorp.com/terraform/cli) avec toutes les commandes
    - La partie [HCL](https://developer.hashicorp.com/terraform/language) avec tout ce qui concerne le langage (la [syntaxe](https://developer.hashicorp.com/terraform/language/syntax), les [expressions](https://developer.hashicorp.com/terraform/language/expressions), les [functions](https://developer.hashicorp.com/terraform/language/functions), etc.)
2. [registry.terraform.io](https://registry.terraform.io/) pour la documentation de chaque _provider_ (un concept expliqué dès le début du lab). Typiquement on va consulter ce site pour tout ce qui est spécifique à [Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest) (liste des resources, connexion entre Terraform et Azure, etc.)

Ces sites seront souvent cités au cours du lab, mais vous pouvez déjà les ajouter à vos favoris.
