# Instructions pour les agents (Cursor / IA)

Ce fichier décrit le **projet hackathon-abtest**, les **dépôts associés**, leur **architecture** et les **règles de travail** à respecter.

---

## Vue d’ensemble du projet

**`hackathon-abtest`** est un dépôt parent qui sert de **point d’entrée** pour un environnement de démonstration et d’industrialisation d’une **solution d’A/B testing** : moteur de décision, API, interface d’administration, remote en **Module Federation**, données de campagnes/segments versionnées, documentation publique, et un **site hôte de lab** (serveur web, pages de démo, simulation de bande passante).

À la racine, `package.json` expose notamment :

- `npm run dev:abtest` — lance le développement dans `abtest-solution` ;
- `npm run dev:webserver` — lance le développement dans `small-webserver` ;
- `npm run dev` — lance les deux en parallèle (`concurrently`) ;
- `npm run ports:free` — envoie SIGTERM puis SIGKILL aux processus en écoute sur les ports par défaut du projet (voir `abtest-docs` : _Ports et variables_).

### Ports (développement local)

En parallèle (`npm run dev` à la racine, éventuellement la doc), plusieurs services écoutent chacun sur un port pour éviter les collisions. Les **valeurs par défaut** ci‑dessous sont celles documentées dans `abtest-docs` (_Ports et variables_) et ciblées par `scripts/free-project-ports.sh` ; elles peuvent être changées via les variables indiquées.

| Port     | Usage                                                                                                                                                                  |
| -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **5000** | Serveur Express unifié du lab (`small-webserver`) : throttle, préfixe `/api` du lab, fichiers statiques — variable `PORT`.                                             |
| **5001** | Dev server du **remote** réel (`abtest-solution` / `apps/remote`) : Module Federation et servage des assets des campagnes (`jsPath` / `cssPath`) — `VITE_REMOTE_PORT`. |
| **5002** | API Express (`abtest-solution` / `apps/api`) : CRUD campagnes/segments, `POST /api/evaluate`, etc. — `PORT`.                                                           |
| **5101** | Remote Module Federation **minimal** du lab (`small-webserver` / `apps/abtest-remote`, stub) — `VITE_ABTEST_REMOTE_PORT`.                                              |
| **5173** | Host React + HMR des démos lab (`small-webserver` / `apps/host`) — `VITE_HOST_PORT`.                                                                                   |
| **5174** | UI d’administration A/B (`abtest-solution` / `apps/ui`) — `VITE_UI_PORT`.                                                                                              |
| **5175** | Documentation VitePress (`abtest-docs`, `npm run docs:dev`) — port fixé dans le `package.json` du dépôt doc.                                                           |

En dev, les campagnes **frontend** pointent en général les assets vers le remote **solution** (`http://localhost:5001/...`), pas vers le port **5101** du stub labo. Détail des variables : `abtest-docs/docs/reference/ports-and-env.md`.

Prérequis documentés dans les sous-dépôts : **Node.js 20+**.

---

## Dépôts associés (submodules Git)

Le fichier `.gitmodules` à la racine référence les dépôts suivants comme **submodules** du dépôt parent :

| Chemin local      | Dépôt distant (tel que configuré)             |
| ----------------- | --------------------------------------------- |
| `abtest-solution` | `git@github.com:skhamvon/abtest-solution.git` |
| `abtest-docs`     | `git@github.com:skhamvon/abtest-docs.git`     |
| `small-webserver` | `git@github.com:skhamvon/small-webserver.git` |

**Remarque :** le dépôt **`abtest-campaigns-segments`** n’est pas un submodule de `hackathon-abtest` ; il est un **submodule de `abtest-solution`** (voir `.gitmodules` dans `abtest-solution/`). URL configurée : `https://github.com/skhamvon/abtest-campaigns-segments.git`, chemin local : `abtest-solution/abtest-campaigns-segments`.

Les URLs exactes des pages GitHub Pages, les branches par défaut et les comptes peuvent évoluer : se fier aux README et à la config du dépôt pour toute valeur opérationnelle.

---

## Architecture par dépôt

### `hackathon-abtest` (racine)

- Rôle : orchestrer le clonage (submodules) et faciliter le dev conjoint (scripts npm racine).
- Ne contient pas à lui seul le code métier A/B : il agrège les autres dépôts.

### `abtest-solution`

Monorepo **npm workspaces** (`apps/*`, `packages/*`) — solution A/B « interne » exposée comme module fédéré.

| Élément                     | Rôle                                                                                                                                                                                               |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `apps/api`                  | API HTTP (Node/Express) : CRUD campagnes/segments, `/api/evaluate`, etc., s’appuie sur les fichiers du dépôt campagnes/segments.                                                                   |
| `apps/remote`               | Remote **Module Federation** : `./AbTestSlot`, `./visitorId` (`getOrCreateVisitorId`, `setAbtestVisitorId`), sticky via `localStorage` (`abtest_assignments_v1`) avec migration depuis `ab_var_*`. |
| `apps/ui`                   | Interface d’administration (React).                                                                                                                                                                |
| `packages/core`             | Moteur (modèle, bucketing, ports storage / tracking).                                                                                                                                              |
| `packages/storage-fs`       | Adaptateur stockage fichier branché sur `abtest-campaigns-segments`.                                                                                                                               |
| `abtest-campaigns-segments` | Submodule : données fonctionnelles (JSON, JS, CSS des variantes).                                                                                                                                  |

**Identifiants métier** : campagnes, segments et variations utilisent des **ids numériques** (JSON `number`) avec plages et règles de validation décrites dans le dépôt **`abtest-docs`** (VitePress : _Solution_ → _Campagnes et segments_) et implémentées dans `packages/core/src/ids.ts` et le schéma `packages/storage-fs`.

**Squelettes depuis l’IDE** : `npm run scaffold:segment` et `npm run scaffold:campaign` à la racine de `abtest-solution` allouent le plus petit id libre et créent le `config.json` minimal (voir `abtest-docs` : _CLI : squelettes_).

Scripts utiles (voir `abtest-solution/package.json`) : `dev` (api + remote + ui en parallèle), `dev:api`, `dev:remote`, `dev:ui`, `build`, `scaffold:segment`, `scaffold:campaign`. Les ports par défaut et variables d’environnement sont documentés dans `abtest-docs` (page _Ports et variables_).

### `abtest-campaigns-segments`

Dépôt d’**assets et de configuration** versionné séparément du code : campagnes (`Campaigns/`), segments (`Segments/`), éventuellement `consent-config.json`. Structure et formats détaillés dans le README du dépôt et dans la doc VitePress.

### `abtest-docs`

Documentation publique **VitePress** : architecture, données de campagnes, consentement, référence segments, intégration hôte, développement. Commandes typiques : `npm install`, `npm run docs:dev`, `npm run docs:build` (voir README du dépôt).

### `small-webserver`

Monorepo de **lab** : application **host** (Vite + React), package **remote** MF minimal (`apps/abtest-remote`), UI partagée, **serveur Node** (Express) pour servir les builds et simuler des contraintes réseau (throttle). En dev, le host charge en principe le **`remoteEntry`** du remote **`abtest-solution`** via **`VITE_ABTEST_REMOTE_URL`** dans `small-webserver/apps/host/.env.development` (voir `small-webserver/.env.example`) ; le stub **5101** reste disponible si l’URL est repointée. Voir `abtest-docs` — intégration hôte / webserver.

---

## Règles de travail pour l’agent

### Véracité

- **N’inventer** aucune solution, comportement, API, chemin de fichier ou **commande** qui ne peut pas être **confirmé** dans le dépôt, la documentation (`abtest-docs`), les `package.json`, ou une source explicitement fournie par l’utilisateur.
- Si une information **manque** et qu’elle **ne peut pas** être retrouvable par exploration du projet, le **dire explicitement** et proposer une question ciblée ou une vérification humaine.

### Analyse du projet

- Lors d’un **nouveau** sujet / prompt : faire une **première analyse** suffisante du contexte (structure, fichiers pertinents, docs).
- Ensuite, **limiter** les analyses et lectures aux **parties pertinentes** pour la tâche en cours (éviter de tout rescanner systématiquement).

### Modifications importantes

- Pour toute modification **importante** (refactor large, nouveau flux, changement d’architecture, migration) : **proposer un plan** avant ou en début d’implémentation (étapes, risques, fichiers touchés).
- En **mode plan** (ou lorsque le besoin est ambigu) : **poser des questions** pour clarifier périmètre, contraintes et critères de succès avant d’écrire du code.

### Documentation

- Mettre à jour la documentation dans **`abtest-docs`** lorsque c’est **nécessaire** pour refléter un comportement réel, une procédure ou une API documentée (éviter la dérive entre code et doc publique).
- Mettre à jour **`AGENTS.md`** à la racine de **`hackathon-abtest`** lorsqu’un changement **structurel** ou **opérationnel** du dépôt parent l’exige (nouveaux scripts racine, évolution majeure des sous-dépôts, conventions d’ids, etc.), pour que les agents et la doc locale restent alignés.

---

## Périmètre de ce fichier

Ce qui n’est pas décrit ici (détail de chaque endpoint, tableau exhaustif des règles de segments, configuration de déploiement précise) se trouve dans **`abtest-docs`** et les README des sous-dépôts. En cas de doute, **vérifier le code source** ou indiquer clairement l’absence d’information vérifiable.
