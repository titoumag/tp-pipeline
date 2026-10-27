# TP4 : premier pipeline

[Sommaire du jour 2](../enonce.md) · [Se connecter à Azure](../enonce.md#avant-de-commencer)

**Objectif** : faire vérifier votre code Terraform automatiquement, à chaque pull request. **Durée** : 30 minutes.
**Dossier de travail** : votre propre dépôt GitHub, cloné **en dehors** du dépôt de la formation

## Où on en est, où on va

Jusqu'ici, c'est vous qui lancez `fmt` et `validate`, quand vous y pensez.
À la fin de ce TP, GitHub Actions les lancera tout seul à chaque pull request, et bloquera un code mal formaté. C'est la première brique d'un pipeline CI/CD.

## Étape 1 : un dépôt GitHub avec un peu de Terraform

**À faire** sur [github.com](https://github.com) : créez un dépôt **vide** à vous (bouton **New**), par exemple `tp-pipeline`.

**À lancer**, depuis le dossier **parent** du dépôt de la formation (pas dedans) :

```bash
# Clone votre nouveau dépôt, à côté de celui de la formation
git clone https://github.com/<votre-compte>/tp-pipeline.git
cd tp-pipeline
# Y copie du code Terraform : la solution du TP2 d'hier
cp ../formation-azure-terraform/jour1/solutions/tp2/*.tf .
```

**Vérifier** : `ls` affiche `main.tf`, `outputs.tf`, `variables.tf` et `versions.tf`.

## Étape 2 : le workflow

Un **workflow** GitHub Actions est un fichier YAML dans `.github/workflows/` : il dit quand se déclencher et quelles commandes lancer.

**À lancer** :

```bash
# Crée le dossier attendu par GitHub
mkdir -p .github/workflows
```

**À compléter** dans un nouveau fichier `.github/workflows/terraform-validate.yml` :

```yaml
name: terraform-validate

on:
  pull_request:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      prenom:
        description: Votre prénom, en minuscules et sans accent (préfixe du resource group)
        required: true
        type: string
      location:
        description: La région des ressources
        required: true
        type: choice
        options:
          - swedencentral
        default: swedencentral

# Les variables Terraform : saisies dans le formulaire si lancé à la main, sinon les variables du dépôt GitHub
env:
  TF_VAR_prenom: ${{ inputs.prenom || vars.PRENOM }}
  TF_VAR_location: ${{ inputs.location || vars.LOCATION }}

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: hashicorp/setup-terraform@v4
        with:
          terraform_version: "~1.16"
      - run: terraform fmt -check -recursive
      - run: terraform init -backend=false
      - run: terraform ...                  # À COMPLÉTER : la commande qui vérifie la syntaxe
```

> **Explication.**
> - `on` : quand le workflow se déclenche. Ici, à chaque pull request, à chaque push sur `main`, et à la demande (`workflow_dispatch`).
> - `workflow_dispatch` ajoute un bouton **Run workflow** dans l'onglet **Actions**, avec un formulaire : `prenom` et `location`.
> - `env` : Terraform lit toute variable d'environnement `TF_VAR_<nom>` comme la variable `<nom>`. La valeur vient du formulaire si le workflow est lancé à la main, sinon des **variables du dépôt** `PRENOM` et `LOCATION` (étape 3). Jamais de prénom en dur : chacun a ainsi ses propres noms de ressources.
> - `runs-on: ubuntu-latest` : une machine Linux fournie par GitHub, effacée à la fin.
> - `actions/checkout` récupère votre code ; `hashicorp/setup-terraform` installe Terraform.
> - `fmt -check` **échoue** si le code n'est pas formaté, sans rien modifier. `init -backend=false` télécharge les providers sans toucher à aucun state.

## Étape 3 : déclarer vos variables dans GitHub

Le formateur le montre en direct au début du TP.

**À faire** sur GitHub, dans votre dépôt : **Settings > Secrets and variables > Actions**, onglet **Variables**, bouton **New repository variable**. Créez-en deux :

| Nom | Valeur |
|---|---|
| `PRENOM` | Votre prénom, en minuscules et sans accent |
| `LOCATION` | `swedencentral` |

**Vérifier** : l'onglet **Variables** liste `PRENOM` et `LOCATION`.

> **Explication.** Une **variable** de dépôt n'est pas secrète : elle s'affiche en clair dans les journaux, et se lit avec `vars.<NOM>`. Un **secret** (onglet voisin, `secrets.<NOM>`) est masqué : il servira au « Pour aller plus loin ».

## Étape 4 : envoyer le code et ouvrir une pull request

**À lancer** :

```bash
# Crée une branche de travail
git checkout -b ajout-pipeline
# Prépare tous les fichiers pour le commit
git add .
git commit -m "Code Terraform et pipeline de vérification"
# Envoie la branche sur GitHub
git push -u origin ajout-pipeline
```

**À faire** sur GitHub : la page du dépôt propose **Compare & pull request** : ouvrez la pull request.

**Vérifier** : onglet **Actions**, le workflow `terraform-validate` tourne, puis passe au vert.

## Étape 5 : casser le format, voir le pipeline échouer

**À faire** : dans `main.tf`, décalez une ligne avec des espaces en trop.

**À lancer** :

```bash
git commit -am "Format cassé exprès"
git push
```

**Vérifier** : le pipeline passe au **rouge** sur l'étape `terraform fmt -check`. Corrigez :

```bash
# Remet le code en forme, puis renvoie la correction
terraform fmt
git commit -am "Format corrigé"
git push
```

## Étape 6 : lancer le pipeline à la demande

**À faire** sur GitHub, une fois la pull request fusionnée dans `main` (bouton **Merge pull request**) : onglet **Actions**, workflow `terraform-validate`, bouton **Run workflow**. Le formulaire propose `prenom` et `location` : saisissez votre prénom, gardez `swedencentral`, puis **Run workflow**.

**Vérifier** : une nouvelle exécution apparaît, déclenchée par `workflow_dispatch`, et passe au vert.

> **Explication.** GitHub n'affiche le bouton **Run workflow** que pour un workflow présent sur la branche par défaut : d'où la fusion d'abord.

## Documentation

- [Automatiser Terraform avec GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
- [La syntaxe des workflows](https://docs.github.com/actions/writing-workflows/workflow-syntax-for-github-actions)

## Questions

- Pourquoi `-backend=false` ?
- Le pipeline parle-t-il à Azure ? De quoi aurait-il besoin pour un `plan` ?

## Pour aller plus loin

Ajoutez un job `plan`, qui se connecte à Azure avec un service principal.

1. **À copier** : le contenu de `jour2/tp4/plan-job.yml` (dépôt de la formation), à la fin de votre `terraform-validate.yml`, sous `jobs:`.
2. **À faire** : dans votre dépôt GitHub, **Settings > Secrets and variables > Actions**, créez les quatre secrets `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID` et `ARM_SUBSCRIPTION_ID`. Le formateur vous les donne.
3. **Vérifier** : sur la pull request, le plan annonce `rg-<prénom>-dev`, avec **votre** prénom, lu dans `PRENOM`. Lancé à la main avec un autre prénom, il annonce ce prénom-là.

---

Précédent : [TP3 : une identité managée avec un rôle](../tp3/README.md) · Suivant : [TP5 : mon cluster AKS](../tp5/README.md) · [Sommaire du jour 2](../enonce.md)
