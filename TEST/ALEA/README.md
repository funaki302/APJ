# Mise à jour : POURCENTAGE-AVOIR (part max d'une facture payable par avoir)

Chaque client a maintenant un **pourcentage d'avoir**.
Exemple : facture 100 000 Ar, pourcentage 40 %, avoir 100 000 Ar → **40 000 Ar** payés par l'avoir, **60 000 Ar** à payer en cash ou autre moyen, et il reste 60 000 Ar d'avoir pour les prochaines factures.

Documentation complète : `instruction/POURCENTAGE-AVOIR.md`.

---

## 0. Prérequis : appliquer d'abord `TEST/CHANGE/`

Cette mise à jour **complète** la fonctionnalité AVOIR-FC (réduction automatique par avoir).
Si tu ne l'as pas encore installée, applique **d'abord** le dossier `TEST/CHANGE/` (voir son README), y compris son script `data/avoir-fc.sql`.
Ensuite seulement, applique ce dossier `ALEA/`. Ses fichiers sont des versions plus récentes et remplacent ceux de `CHANGE/` quand ils ont le même nom.

---

## 1. Où copier chaque fichier

Les fichiers sont rangés dans **la même arborescence que le projet**. Chaque fichier se copie au même chemin, à partir de la racine `projet-standard/` (le dossier qui contient `arbiochem-ejb`, `arbiochem-war`, `build.xml`).

### Java : `arbiochem-ejb/src/java/`

| Fichier | Destination | Action |
|---|---|---|
| `ImputationAvoirFC.java` | `arbiochem-ejb/src/java/avoir/` | remplace la version de `CHANGE/` |
| `ClientArbiochem.java` | `arbiochem-ejb/src/java/client/` | remplace l'existant |
| `LiaisonPaiement.java` | `arbiochem-ejb/src/java/paiement/` | remplace l'existant |

### JSP : `arbiochem-war/web/pages/`

| Fichier | Destination | Action |
|---|---|---|
| `client-arbiochem-saisie.jsp` | `arbiochem-war/web/pages/client/` | remplace l'existant |
| `client-arbiochem-fiche.jsp` | `arbiochem-war/web/pages/client/` | remplace l'existant |
| `avoir-auto-info.jspf` | `arbiochem-war/web/pages/vente/inc/` | remplace la version de `CHANGE/` |
| `vente-saisie.jsp` | `arbiochem-war/web/pages/vente/` | remplace la version de `CHANGE/` |
| `vente-arbiochem-saisie.jsp` | `arbiochem-war/web/pages/vente/` | remplace la version de `CHANGE/` |

### Base de données et documentation

| Fichier | Destination | Action |
|---|---|---|
| `pourcentage-avoir.sql` | `data/` | **nouveau** (à exécuter, voir étape 3) |
| `POURCENTAGE-AVOIR.md` | `instruction/` | **nouveau** (documentation) |
| `AVOIR-FC.md` | `instruction/` | remplace (lien vers la nouvelle doc) |

> Les fichiers « remplace l'existant » écrasent ta version. Si tu as fait des modifications perso dans `ClientArbiochem.java`,
> `LiaisonPaiement.java` ou dans les pages client, compare d'abord (WinMerge, `diff`…) au lieu d'écraser.

---

## 2. Copie rapide

Git Bash, depuis le dossier qui contient `ALEA/` :

```bash
cp -r ALEA/arbiochem-ejb ALEA/arbiochem-war ALEA/data ALEA/instruction /chemin/vers/projet-standard/
```

PowerShell :

```powershell
Copy-Item -Recurse -Force ALEA\arbiochem-ejb, ALEA\arbiochem-war, ALEA\data, ALEA\instruction C:\chemin\vers\projet-standard\
```

---

## 3. Après la copie

1. **Base Oracle** : exécuter `data/pourcentage-avoir.sql` avec l'utilisateur de l'application (celui de `arbiochem-ejb/src/java/apj.properties`). Le script :
   - ajoute la colonne `CLIENT.POURCENTAGE`. Valeur par défaut 100 = pas de limite : les clients existants gardent le comportement d'avant ;
   - ajoute la contrainte 0 ≤ pourcentage ≤ 100 ;
   - recrée la vue `CLIENTLIB` (fiche client) avec la nouvelle colonne.

   > Le script recrée `CLIENTLIB` avec la définition standard du projet. Si tu as modifié cette vue chez toi, ajoute plutôt
   > seulement `c.POURCENTAGE` à ta version.
2. **Compiler et déployer** :
   ```bash
   ant -f build.xml deploy
   ```
3. **Tester** :
   - Client → Modifier un client → « Part max d'une facture payable par avoir (%) » = **40** ;
   - ce client doit avoir un avoir **visé** (ex. 100 000 Ar) ;
   - saisir une facture de 100 000 Ar : le bandeau affiche « Payable par avoir : 40 % », « Déduit au visa : 40 000 », « Net à payer : 60 000 » ;
   - **Viser** : reste à payer 60 000 Ar, onglet « Liaison paiement(s) » = 40 000 Ar d'avoir, avoir restant 60 000 Ar ;
   - le bouton manuel « Payer par Ristourne/Avoir » respecte aussi la limite de 40 %.

En cas de page blanche : regarder la console WildFly et `standalone/tmp` (voir `instruction/APJ.md`).

---

## 4. Résumé des changements

| Fichier | Changement |
|---|---|
| `ClientArbiochem.java` | Nouvel attribut `pourcentage`, refusé hors de 0–100. |
| `ImputationAvoirFC.java` | Lecture du pourcentage du client, calcul du plafond (TTC × %), imputation limitée au plafond. Un objet sans écriture comptable ne bloque plus le visa. |
| `LiaisonPaiement.java` | Le paiement manuel par avoir applique la même limite. Plus de liaisons à 0 Ar. |
| `client-arbiochem-saisie.jsp` / `-fiche.jsp` | Champ « Part max d'une facture payable par avoir (%) », 100 par défaut. |
| `avoir-auto-info.jspf` | Fiche facture : affiche le pourcentage et le plafond. |
| `vente-saisie.jsp` / `vente-arbiochem-saisie.jsp` | Bandeau de saisie : « Déduit au visa » limité au pourcentage. |

Écritures au visa (inchangées, seul le montant est limité) : `LIAISONPAIEMENT` visée (avoir → facture), `HISTORIQUE`, et lettrage comptable partiel entre la ligne client de la facture et celle de l'avoir.
