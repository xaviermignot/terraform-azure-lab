# Etape 6: Exécution depuis Azure Pipelines

Dans cette étape nous allons exécuter Terraform depuis Azure Pipelines qui fait partie d'Azure DevOps.  

## Connexion entre Azure DevOps et Azure
Pour commencer il faut créer une _service connection_ au niveau du projet Azure DevOps.  

> [!NOTE]
> Pour les besoins de ce lab, il faut nommer la service connection `sc-azureRm`

Le plus simple pour cela est de suivre la documentation officielle en choisissant le scénario _"App Registration avec Workload Identity Federation (WIF)"_ sur [cette page](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops#create-an-app-registration-with-workload-identity-federation-automatic).

## Installation de l'extension Terraform
Si ce n'est déjà fait, il faut également installer l'extension Terraform depuis la [marketplace](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks) sur votre organisation Azure DevOps.

## Création d'un groupe de variables
Un groupe de variable est également nécessaire pour partager des informations aux pipelines sans les inclure dans le repository.  
Ce groupe (qui existe peut-être déjà) doit avoir les caractéristiques suivantes:
- Nom: `global-variables`
- Variables: une variable `subscriptionId` avec comme valeur l'identifiant de la souscription Azure à utiliser

Si ce groupe n'existe pas, il faut le créer depuis la partie _Library_ d'Azure Pipelines.

## Création d'un premier _pipeline_
Dans cette partie nous allons ajouter un pipeline pour déployer notre infrastructure avec Terraform.  
Dans le dossier `/.azuredevops`, ajoutez un fichier `deploy.yml`.  

Ce fichier va contenir le yaml du pipeline de déploiement qui doit avoir les caractéristiques suivantes:
- Un paramètre `currentUser` de type `string`
- Aucun trigger
- Utiliser les runners `ubuntu-latest` de Microsoft
- Utiliser le groupe de variables `global-variables` 

Si vous êtes familier avec la syntaxe d'Azure Pipelines, ajouter la structure de base du pipeline dans le fichier `deploy.yml`.  
Si vous avez besoin d'aide, voici ce que vous devez ajouter dans le fichier:
<details>
<summary>Début du fichier <code>.azuredevops/deploy.yml</code></summary>

```yaml
name: Deploy Azure resources

parameters:
  - name: currentUser
    type: string
    displayName: 'Current User'

trigger: none

pool:
  vmImage: ubuntu-latest

variables:
  - group: global-variables
```
</details>

### Installation et initialisation de Terraform
Les premières étapes du pipelines consistent en l'installation de Terraform et le lancement de la commande `terraform init`.  
Ces étapes ont été préparées dans le template `.azuredevops/templates/tasks/terraform-init.yml`. Prenez-le temps d'observer le [contenu](/.azuredevops/templates/tasks/terraform-init.yml) de ce fichier.  

Il faut ajouter dans notre pipeline une étape pour appeler ce template, et lui passer la valeur du paramètre `currentUser`. Essayez de modifier le pipeline dans ce sens, si vous avez besoin d'aide voici ce qu'il faut ajouter:
<details>
<summary>Ajout dans le fichier <code>.azuredevops/deploy.yml</code></summary>

```yaml
steps:
  - template: /.azuredevops/templates/tasks/terraform-init.yml
    parameters:
      currentUser: ${{ parameters.currentUser }}
```
</details>

### Application des changements
L'étape suivante consiste à ajouter une tâche de type `AzureCLI` pour appliquer les changements. Le yaml de cette tâche va ressembler au contenu du fichier `.azuredevops/templates/tasks/terraform-init.yml`, à l'exception de la commande dans la partie `inlineScript` qui sera `terraform apply -auto-approve` au lieu de `terraform init`.  
Aussi les variables d'environnement dans la partie `env` ne sont pas les mêmes: les informations du compte de stockage ne sont plus nécessaires car Terraform est déjà initialisé. Par contre il faut ajouter une variable `TF_VAR_current_user` avec l'utilisateur courant et une variable `ARM_SUBSCRIPTION_ID` avec l'identifiant de la souscription Azure.  

<details>
<summary>Dans le fichier <code>.azuredevops/deploy.yml</code>, remplacer l'élément <code>/<code> avec le contenu suivant:</summary>

```yaml
steps:
  - template: /.azuredevops/templates/tasks/terraform-init.yml
    parameters:
      currentUser: ${{ parameters.currentUser }}
  - task: AzureCLI@2
    displayName: 'Terraform Apply'
    inputs:
      azureSubscription: sc-azureRm
      scriptType: bash
      scriptLocation: inlineScript
      inlineScript: |
        terraform apply -auto-approve
      workingDirectory: infra
    env:
      TF_VAR_current_user: ${{ parameters.currentUser }}
      ARM_SUBSCRIPTION_ID: $(subscriptionId)
```
</details>

## Création du pipeline dans Azure DevOps et premier lancement
Une fois les modifications terminées, vous pouvez:
- Créer une branche sur ce repository
- Faire un commit avec tous vos changements
- Depuis l'interface d'Azure DevOps, vous pouvez ajouter votre pipeline en allant chercher le fichier sur votre branche et le lancer pour la première fois
