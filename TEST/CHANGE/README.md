# Mise à jour : AVOIR-FC (réduction automatique par avoir + réinitialisation)

Ce dossier contient **uniquement les fichiers ajoutés ou modifiés**. Ils sont rangés dans la **même arborescence que le projet** :
chaque fichier se copie au même chemin, à partir de la racine du projet `projet-standard/`.

Documentation complète de la fonctionnalité : `instruction/AVOIR-FC.md`.

---

## 1. Où copier chaque fichier

Racine = dossier `projet-standard/` (celui qui contient `arbiochem-ejb`, `arbiochem-war`, `build.xml`).

### Java : `arbiochem-ejb/src/java/`

| Fichier | Destination | Action |
|---|---|---|
| `ImputationAvoirFC.java` | `arbiochem-ejb/src/java/avoir/` | **nouveau** |
| `ReinitialisationVente.java` | `arbiochem-ejb/src/java/vente/` | **nouveau** |
| `Vente.java` | `arbiochem-ejb/src/java/vente/` | remplace l'existant |
| `VenteArbiochem.java` | `arbiochem-ejb/src/java/vente/` | remplace l'existant |

### JSP : `arbiochem-war/web/pages/vente/`

| Fichier | Destination | Action |
|---|---|---|
| `avoir-auto-info.jspf` | `arbiochem-war/web/pages/vente/inc/` | **nouveau** |
| `apres-viser-avoir.jsp` | `arbiochem-war/web/pages/vente/` | **nouveau** |
| `reinitialisation-donnees.jsp` | `arbiochem-war/web/pages/vente/` | **nouveau** |
| `apres-reinitialisation.jsp` | `arbiochem-war/web/pages/vente/` | **nouveau** |
| `vente-fiche.jsp` | `arbiochem-war/web/pages/vente/` | remplace l'existant |
| `vente-arbiochem-fiche.jsp` | `arbiochem-war/web/pages/vente/` | remplace l'existant |
| `vente-saisie.jsp` | `arbiochem-war/web/pages/vente/` | remplace l'existant |
| `vente-arbiochem-saisie.jsp` | `arbiochem-war/web/pages/vente/` | remplace l'existant |
| `vente-arbiochem-liste.jsp` | `arbiochem-war/web/pages/vente/` | remplace l'existant |

### Base de données et documentation

| Fichier | Destination | Action |
|---|---|---|
| `avoir-fc.sql` | `data/` | **nouveau** (à exécuter, voir étape 3) |
| `AVOIR-FC.md` | `instruction/` | **nouveau** (documentation) |

> Attention : les fichiers marqués « remplace l'existant » écrasent ta version. Si tu as fait des modifications perso
> dans `Vente.java`, `VenteArbiochem.java` ou ces JSP, compare d'abord (WinMerge, `diff`…) au lieu d'écraser.
> Les changements y sont petits et commentés (voir section 4).

---

## 2. Copie rapide

Le plus simple : copier **le contenu** de `CHANGE/` (sauf ce README) à la racine du projet en acceptant de remplacer.

Git Bash, depuis le dossier qui contient `CHANGE/` :

```bash
cp -r CHANGE/arbiochem-ejb CHANGE/arbiochem-war CHANGE/data CHANGE/instruction /chemin/vers/projet-standard/
```

PowerShell :

```powershell
Copy-Item -Recurse -Force CHANGE\arbiochem-ejb, CHANGE\arbiochem-war, CHANGE\data, CHANGE\instruction C:\chemin\vers\projet-standard\
```

---

## 3. Après la copie

1. **Base Oracle** : exécuter `data/avoir-fc.sql` avec l'utilisateur de l'application (celui de `arbiochem-ejb/src/java/apj.properties`). Le script :
   - ajoute l'entrée de menu **Vente → Réinitialiser les données** ;
   - crée la table `VENTE_AVOIR_NON_APPLIQUE` (case « Ne pas appliquer l'avoir »).
   Aucune autre table ni vue n'est modifiée.
2. **Compiler et déployer** :
   ```bash
   ant -f build.xml deploy
   ```
3. **Tester** :
   - créer un avoir pour un client et le **viser** ;
   - saisir une nouvelle facture pour ce client : le bandeau « Avoir disponible / Net à payer » apparaît sous le Total ;
   - sur la fiche, **Viser** : le reste à payer est réduit (onglet « Liaison paiement(s) ») ;
   - refaire avec la case **« Ne pas appliquer l'avoir »** cochée avant de viser : rien n'est déduit, l'avoir est gardé.

En cas de page blanche : regarder la console WildFly et `standalone/tmp` (voir `instruction/APJ.md`).

---

## 4. Résumé des changements

| Fichier | Changement |
|---|---|
| `avoir/ImputationAvoirFC.java` | Calcul de l'avoir disponible d'un client et imputation automatique au visa (LiaisonPaiement + lettrage). Gère aussi le choix « ne pas appliquer l'avoir ». |
| `vente/Vente.java` | Fin de `validerObject` : appel de `ImputationAvoirFC.imputerSurFacture`. Nouvelle méthode `imputerAvoirAuVisa()`. Correction d'un NullPointerException quand la connexion était `null`. |
| `vente/VenteArbiochem.java` | Le bloc « paiement avoir » du visa utilise `ImputationAvoirFC` (n'utilise plus les avoirs non visés). `imputerAvoirAuVisa()` renvoie `false` pour éviter une double imputation. |
| `vente/ReinitialisationVente.java` | Suppression des clients, factures et avoirs (et de leurs dépendances) en une transaction. Produits, stock et caisse conservés. |
| `vente-saisie.jsp`, `vente-arbiochem-saisie.jsp` | Bandeau « Avoir disponible / Déduit au visa / Net à payer / Avoir restant ». |
| `vente-fiche.jsp`, `vente-arbiochem-fiche.jsp` | Inclusion de `inc/avoir-auto-info.jspf`. Le bouton Viser passe par `apres-viser-avoir.jsp`. |
| `inc/avoir-auto-info.jspf` | Bandeau avoir de la fiche et case « Ne pas appliquer l'avoir ». |
| `apres-viser-avoir.jsp` | Enregistre le choix de la case, puis lance le visa standard (`apresTarif.jsp` n'est pas modifié). |
| `vente-arbiochem-liste.jsp` | Bouton rouge « Réinitialiser les données ». |
| `reinitialisation-donnees.jsp`, `apres-reinitialisation.jsp` | Page de confirmation (taper `REINITIALISER`) et résultat. |

**Rappel : la réinitialisation supprime définitivement tous les clients, factures et avoirs.** Faire un export de la base avant de l'essayer.
