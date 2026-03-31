## hackathon-abtest

Ce dépôt joue le rôle d’orchestrateur pour une solution d’A/B testing composée de plusieurs dépôts Git imbriqués (submodules).

### Architecture des dépôts

- **Dépôt principal**: `hackathon-abtest` (ce dépôt)

  - Remote prévu: `git@github.com:skhamvon/hackathon-abtest.git`
  - Contenu principal:
    - `README.md` (ce fichier)
    - `.gitignore`
    - `.gitmodules` (créé automatiquement par Git lorsque les submodules sont ajoutés)
    - Submodules:
      - `small-webserver/` → `git@github.com:skhamvon/small-webserver.git`
      - `abtest-solution/` → `git@github.com:skhamvon/abtest-solution.git`

- **Submodule `abtest-solution`** (dans `abtest-solution/`)

  - Dépôt: `git@github.com:skhamvon/abtest-solution.git`
  - Contient lui-même un submodule:
    - `abtest-campaigns-segments/` → `git@github.com:skhamvon/abtest-campaigns-segments.git`

- **Submodule final `abtest-campaigns-segments`**
  - Dépôt: `git@github.com:skhamvon/abtest-campaigns-segments.git`
  - Contient les définitions de campagnes d’A/B test, segments, configuration de ciblage, etc.

### Initialisation locale recommandée

Dans un shell, à lancer dans le dossier `hackathon-abtest`:

```bash
git init -b main
git remote add origin git@github.com:skhamvon/hackathon-abtest.git
git add README.md .gitignore
git commit -m "chore: init repository"
git push -u origin main
```

### Ajout des submodules

Depuis la racine du dépôt `hackathon-abtest`:

```bash
# 1. Submodule du petit serveur web
git submodule add git@github.com:skhamvon/small-webserver.git small-webserver

# 2. Submodule de la solution d'A/B testing
git submodule add git@github.com:skhamvon/abtest-solution.git abtest-solution

git add .gitmodules small-webserver abtest-solution
git commit -m "chore: add webserver and abtest-solution submodules"
git push
```

Dans le submodule `abtest-solution` (imbriqué) :

```bash
cd abtest-solution

# Initialiser le submodule interne pour les campagnes/segments
git submodule add git@github.com:skhamvon/abtest-campaigns-segments.git abtest-campaigns-segments

git add .gitmodules abtest-campaigns-segments
git commit -m "chore: add campaigns/segments submodule"
git push

# Revenir à la racine du dépôt principal et committer le nouveau pointeur
cd ..
git add abtest-solution
git commit -m "chore: update abtest-solution submodule pointer"
git push
```

### Clonage avec tous les submodules

Pour cloner le dépôt principal avec tous les submodules (y compris imbriqués) :

```bash
git clone git@github.com:skhamvon/hackathon-abtest.git
cd hackathon-abtest
git submodule update --init --recursive
```

### Mise à jour des submodules

Pour mettre à jour tous les submodules vers les commits référencés dans le dépôt principal :

```bash
git submodule update --init --recursive
```

Pour suivre les branches distantes des submodules (optionnel, à utiliser avec précaution) :

```bash
git submodule update --remote --recursive
```

Ensuite, il faut committer dans le dépôt principal les nouveaux pointeurs de submodules.
