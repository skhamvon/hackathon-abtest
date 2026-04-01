## hackathon-abtest

Ce dépôt est le **point d’entrée** de ton environnement d’A/B testing.  
Il ne contient pas de logique métier : il orchestre uniquement les différents dépôts via des **submodules Git**.

### Contenu

- `small-webserver/` → dépôt du petit serveur web de test
- `abtest-solution/` → dépôt de la solution d’A/B testing (API, remote, UI, moteur)
- `.gitmodules` → configuration des submodules

La configuration des campagnes et segments est située dans le submodule imbriqué :

- `abtest-solution/abtest-campaigns-segments/`

### Clonage et initialisation

Pour récupérer ce dépôt **avec tous les submodules** (y compris les campagnes/segments) :

```bash
git clone git@github.com:skhamvon/hackathon-abtest.git
cd hackathon-abtest
git submodule update --init --recursive
```

Si tu ajoutes ou mets à jour des submodules, pense à committer les nouveaux pointeurs dans ce dépôt.

### Mise à jour ultérieure des submodules

Depuis la racine de `hackathon-abtest` :

```bash
git submodule update --init --recursive
```

Pour tirer les dernières révisions distantes (à utiliser en connaissance de cause) :

```bash
git submodule update --remote --recursive
```

N’oublie pas ensuite de committer les pointeurs de submodules mis à jour.

### Intégrer le module fédéré sur un serveur web générique

Le dépôt `abtest-solution` expose un **remote/module fédéré** que n’importe quel site hôte peut consommer (le dépôt `small-webserver` n’est qu’un exemple d’intégration de test).

L’intégration se fait en deux grandes étapes :

1. **Déployer le remote d’A/B testing**

   - Builder et déployer la partie « remote » de `abtest-solution` (par exemple sur une URL publique du type `https://cdn.example.com/abtest-remote/`).
   - Cette URL de base est ensuite utilisée par ton site hôte pour charger dynamiquement le bundle du remote.

2. **Configurer ton serveur / appli hôte**
   - Côté front, ton application (React, Vue, site static, etc.) est configurée pour charger le remote via **Module Federation** (Webpack ou Vite) en lui donnant l’URL du remote déployé.
   - Une fois chargé, tu peux :
     - appeler l’API JS exposée par le remote pour **évaluer une campagne** et récupérer la variante à afficher,
     - ou monter directement un **composant React** fourni par le remote dans ta page.

En résumé, pour un serveur web générique :

- tu déploies le remote `abtest-solution` sur une URL stable,
- tu configures ton build front (ou ton HTML) pour charger ce remote via Module Federation,
- tu utilises l’API/composants du remote pour afficher les variantes A/B.

Le dépôt `small-webserver` montre un exemple complet de cette intégration dans un contexte de test, mais n’est pas requis en production.
