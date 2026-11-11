# AVOIR-FC : réduction automatique du prix à payer par avoir

Dernière mise à jour : 21/10/2026

Ce document décrit :

1. le fonctionnement **manuel** des avoirs clients (`AvoirFC`) tel qu'il existait ;
2. l'**automatisation** : au visa d'une facture, les avoirs disponibles du client réduisent le reste à payer ;
3. le bouton **Réinitialiser les données** (clients, factures, avoirs).

---

## 1. Scénarios couverts

| Situation | Résultat après visa de la facture |
|---|---|
| Achat 20 000 Ar, avoir disponible 5 000 Ar | Reste à payer **15 000 Ar**, avoir restant **0 Ar** |
| Achat 2 000 Ar, avoir disponible 10 000 Ar | Reste à payer **0 Ar**, avoir restant **8 000 Ar** |
| Achat suivant 3 000 Ar (avoir restant 8 000 Ar) | Reste à payer **0 Ar**, avoir restant **5 000 Ar** |
| … et ainsi de suite | jusqu'à épuisement de l'avoir |

Plusieurs avoirs : ils sont consommés du **plus ancien au plus récent** (date, puis id).

---

## 2. Fonctionnement manuel existant (analyse)

### 2.1 Classes

| Classe | Rôle |
|---|---|
| `avoir.AvoirFC` (`ClassMere`, table `AVOIRFC`) | Avoir client. Fille `avoir.AvoirFCFille`, liaison `idAvoirFC`. Préfixe `AVRFC`, séquence `GETSEQAVOIRFC`. |
| `avoir.AvoirFCFille` (`ClassFille`, table `AVOIRFCFILLE`) | Lignes : produit, qté, pu, tva, taux de change. Préfixe `AVRFCF`. |
| `avoir.AvoirFCLib` | Lecture via les vues `AVOIRFCLIB`, `AVOIRFCLIB_CPL` (montants, reste). |
| `paiement.LiaisonPaiement` (`ClassEtat`, table `LIAISONPAIEMENT`) | **Lien de paiement** : `id1` = pièce qui paie (avoir ou mouvement de caisse), `id2` = facture payée, `montant`. Visé = `etat 11`. |
| `vente.Vente` / `vente.VenteArbiochem` | Facture client (table `VENTE`). |

### 2.2 Cycle de vie d'un avoir (`AvoirFC`)

- **Création** (`createObject`) : numéro `numavoir` tiré de `V_NUMEROAVOIR_EN_COURS` (`0001/2026`…).
- **Visa** (`validerObject`) :
  - met à jour le plan de paiement (`Prevision`) des lignes ;
  - selon le type d'avoir : `genererBR` (retour en stock) ou `desengagerStock` (stock engagé) ;
  - `genererEcriture` : écriture comptable, journal vente : **débit** comptes produits (HT), **débit** TVA collectée, **crédit** compte client 411 + compte auxiliaire = client (TTC) ;
  - `genererLettrage(idOrigine)` : lettrage entre la ligne client de la facture d'origine et celle de l'avoir.

Seul un avoir **visé** (`etat >= 11`) a une écriture comptable : c'est pour cela que l'automatisation n'utilise que les avoirs visés.

### 2.3 Paiement manuel d'une facture par avoir

Bouton **« Payer par Ristourne/Avoir »** sur la fiche facture → `vente/paiement-facture-par-avoir.jsp` → `vente/apres-paiement.jsp` (`acte=paiement_facture`) → `LiaisonPaiement.creerPaiementFacture` :
pour chaque avoir choisi, une `LiaisonPaiement(id1 = avoir, id2 = facture, montant)` est créée puis visée, au maximum le reste de la facture.

### 2.4 Comment les vues calculent les restes

- `LIAISONPAIEMENTTOTAL` : somme des liaisons visées par facture (`id2`).
- `VENTE_CPL.MONTANTRESTE` = TTC − `LIAISONPAIEMENTTOTAL` − (avoirs rattachés à cette facture non utilisés ailleurs).
- `MOUVEMENTCAISSEGRPAVOIR_LP` : somme des liaisons visées par pièce payante (`id1`).
- `AVOIRFCLIB_CPL.RESTEAPAYERAR` = part de l'avoir **disponible** − ce qui a déjà été utilisé (`MOUVEMENTCAISSEGRPAVOIR_LP`).
  La part disponible vaut tout l'avoir si sa facture d'origine est soldée, sinon seulement l'excédent par rapport au reste de cette facture : un avoir sert d'abord à régler sa propre facture.

Conséquence : **créer une `LiaisonPaiement` visée suffit** à faire baisser à la fois le reste de la facture et le reste de l'avoir. Le solde d'avoir est donc reporté naturellement sur les factures suivantes.

### 2.5 Existant dans `VenteArbiochem`

`VenteArbiochem.validerObject` faisait déjà une imputation automatique (`genererPaiementFactureParAvoirAutom` + `creerPaiementFacture`), avec des défauts :

- prenait aussi les avoirs **non visés** (`etat 1`) et annulés, qui n'ont pas d'écriture comptable ;
- pouvait créer une liaison à **0 Ar** quand un avoir couvrait exactement la facture ;
- `creerPaiementFacture` fait un `commit()` au milieu de la transaction du visa ;
- aucun lettrage comptable ;
- `vente.Vente` (page « Nouvelle vente » → `vente-fiche.jsp`) n'avait rien.

---

## 3. Ce qui a été créé / modifié

### 3.1 `avoir/ImputationAvoirFC.java` (nouveau)

| Méthode | Rôle |
|---|---|
| `getAvoirsDisponibles(idClient, c)` | Avoirs du client dans `AVOIRFCLIB_CPL` avec `etat >= 11` et `resteapayerar > 0`, ordre FIFO (`daty`, `id`). |
| `getSoldeAvoirClient(idClient, c)` | Somme des restes : avoir disponible du client. |
| `simulerImputation(idClient, montant, c)` | `min(solde avoir, montant)` : affichage seulement, n'écrit rien. |
| `getMontantAvoirImpute(idVente, c)` | Total des liaisons visées « avoir → facture » sur une facture. |
| `imputerSurFacture(idVente, u, c)` | **Imputation réelle** (appelée au visa, voir 3.2). |
| `lettrer(idAvoir, idVente, u, c)` | Lettrage comptable entre la ligne client (411 + auxiliaire) de la facture et celle de l'avoir (`ComptaLettrage.createLettrageCSEMF`, comme `AvoirFC.genererLettrage`). |

Algorithme de `imputerSurFacture` :

```text
facture = VENTE_CPL(idVente)
si devise != AR -> rien (les restes d'avoir sont en Ariary)
reste = facture.montantreste
pour chaque avoir disponible du client (FIFO) tant que reste > 0 :
    montant = min(avoir.resteapayerar, reste)
    LiaisonPaiement(id1 = avoir, id2 = facture, montant) -> createObject + validerObject (etat 11)
    lettrer(avoir, facture)
    reste -= montant
retourne le total imputé
```

Pas de `commit` dans cette classe : tout se fait dans la transaction du visa. Si une étape échoue, le visa entier est annulé.

### 3.2 Branchement au visa

- `vente/Vente.java`
  - `validerObject` : à la fin (après écriture comptable de la facture, stock engagé, ristourne, prévision) → `ImputationAvoirFC.imputerSurFacture(...)` si `imputerAvoirAuVisa()` renvoie vrai ;
  - nouvelle méthode `protected boolean imputerAvoirAuVisa()` qui renvoie `true` ;
  - correction : quand `c == null`, la connexion est maintenant ouverte **avant** `setAutoCommit(false)` (avant, ça donnait un NullPointerException), et un `commit` est fait si la méthode a ouvert sa propre connexion.
- `vente/VenteArbiochem.java`
  - surcharge `imputerAvoirAuVisa()` → `false` pour ne pas imputer deux fois ;
  - dans `validerObject`, le bloc « paiement avoir » appelle maintenant `ImputationAvoirFC.imputerSurFacture`, **au même endroit** : après ristourne et avance du bon de commande, avant les avances client. L'ordre de priorité existant est conservé.

Pages concernées : bouton **Viser** de `vente-fiche.jsp` (classe `vente.Vente`) et de `vente-arbiochem-fiche.jsp` (classe `vente.VenteArbiochem`), ainsi que `Vente.enregistrerViserLivrer`, qui appelle aussi `validerObject`.

### 3.3 Écritures en base faites au visa

Pour chaque avoir consommé :

1. `LIAISONPAIEMENT` : une ligne `etat = 11` (id1 = `AVRFC…`, id2 = `VNT…`, montant) ;
2. `HISTORIQUE` : insertion + validation (automatique via APJ) ;
3. `COMPTA_LETTRAGE` + `COMPTA_SOUS_ECRITURE.LETTRAGE` : lettrage de la ligne client de la facture avec celle de l'avoir. Lettre en minuscule si partiel, en majuscule si soldé (règle de `createLettrageCSEMF`).
   Si la ligne de l'avoir est **déjà lettrée** (en général avec sa facture d'origine), on ne l'écrase pas : l'imputation est faite, mais le lettrage est à compléter à la main dans la compta.

Aucune nouvelle écriture débit/crédit n'est nécessaire : l'avoir a déjà crédité le compte client, la facture l'a débité. L'imputation est un rapprochement (liaison + lettrage) sur le même compte 411.

### 3.4 Affichage

- **Saisie** (`vente-saisie.jsp` et `vente-arbiochem-saisie.jsp`) : une fois le client choisi, sous le **Total**, un bandeau « Avoir disponible / Déduit au visa / Net à payer estimé / Avoir restant ». Il se recalcule en direct quand les lignes changent. C'est un affichage seulement : rien n'est écrit à la saisie.
- **Fiche** (`vente-fiche.jsp`, `vente-arbiochem-fiche.jsp`), fragment partagé `vente/inc/avoir-auto-info.jspf` :
  - avant visa : avoir disponible, montant qui sera déduit, reste estimé, avoir restant ;
  - après visa : montant d'avoir déduit de cette facture et avoir restant du client. Le détail est dans l'onglet « Liaison paiement(s) ».

### 3.5 Case « Ne pas appliquer l'avoir sur cette facture »

Scénario : le client veut **garder son avoir** pour une prochaine facture. Il ne veut pas qu'il soit déduit de celle-ci.

- Sur la fiche d'une facture **non visée**, quand le client a un avoir disponible, le bandeau bleu propose la case **« Ne pas appliquer l'avoir sur cette facture (le client le garde pour plus tard) »**.
  Le texte du bandeau change selon la case : « X Ar seront déduits » ou « rien ne sera déduit ».
- Le bouton **Viser** ne va plus directement à `apresTarif.jsp`. Il passe par `vente/apres-viser-avoir.jsp`, qui :
  1. enregistre le choix (`ImputationAvoirFC.setAvoirNonApplique`) : case cochée = une ligne dans `VENTE_AVOIR_NON_APPLIQUE`, case décochée = ligne supprimée ;
  2. enchaîne sur le visa standard `apresTarif.jsp?acte=valider…`. `apresTarif.jsp` n'est pas modifié.
- Au visa, `ImputationAvoirFC.imputerSurFacture` s'arrête tout de suite si la facture est dans `VENTE_AVOIR_NON_APPLIQUE` : aucune liaison, aucun lettrage. L'avoir reste entier pour les factures suivantes.
- Après visa, la fiche affiche « Avoir non appliqué au visa (choix du client) » et l'avoir restant.
- Si plus tard le client veut finalement utiliser l'avoir sur cette facture déjà visée : bouton manuel **« Payer par Ristourne/Avoir »**.

Table (script `data/avoir-fc.sql`) :

```sql
CREATE TABLE VENTE_AVOIR_NON_APPLIQUE (
    IDVENTE VARCHAR2(100) NOT NULL PRIMARY KEY,   -- FK VENTE(ID) ON DELETE CASCADE
    DATY    DATE DEFAULT SYSDATE,                 -- date du choix
    IDUSER  VARCHAR2(100)                         -- utilisateur qui a visé
);
```

Si la table n'existe pas encore (script non joué), l'avoir est appliqué comme avant, sans erreur. Un message dans la console WildFly rappelle d'exécuter le script.

Les autres chemins de visa (`Vente.enregistrerViserLivrer`) n'ont pas de case : l'avoir y est toujours appliqué.

---

## 4. Bouton « Réinitialiser les données »

### 4.1 Accès

- Bouton rouge **Réinitialiser les données** en haut de la liste des factures (`vente/vente-arbiochem-liste.jsp`) ;
- entrée de menu sous **Vente** : exécuter `data/avoir-fc.sql` ;
- page `vente/reinitialisation-donnees.jsp` : affiche le nombre de lignes concernées et demande de taper **REINITIALISER** ;
- traitement `vente/apres-reinitialisation.jsp` → `vente.ReinitialisationVente.reinitialiser(u)` → tableau des lignes traitées par étape.

### 4.2 Ce qui est supprimé

Clients, factures (`VENTE`, `VENTE_DETAILS`), avoirs (`AVOIRFC`, `AVOIRFCFILLE`), et ce qui en dépend obligatoirement (contraintes FK) :

- liaisons de paiement des factures et avoirs (`LIAISONPAIEMENT`) ;
- écritures comptables des factures et avoirs (`COMPTA_ECRITURE`, `COMPTA_SOUS_ECRITURE`), leurs lettrages (`COMPTA_LETTRAGE`). Les lignes conservées qui partageaient ces lettrages sont délettrées ;
- plans de paiement des factures (`PREVISION`, avec `SCINDERPREVISION`, `MULTIPLICATION_PREVISION`, `MVTCAISSEPREVISION`) ;
- ristournes, stock engagé des ventes, références de facture, commissions, fichiers attachés, choix « ne pas appliquer l'avoir » (`VENTE_AVOIR_NON_APPLIQUE`) ;
- bons de commande client, bons de livraison client, cartons, proformas, commandes client ;
- encaissements, chèques et précisions d'encaissement des clients ; réservations / check-in / actes des clients.

### 4.3 Ce qui est conservé

Produits (`AS_INGREDIENTS`, recettes…), tarifs, remises, magasins, caisses, fournisseurs et achats, utilisateurs, menus, module ferme.

Les **mouvements de stock** (`MVTSTOCK`, `MVTSTOCKFILLE`) et de **caisse** (`MOUVEMENTCAISSE`) sont gardés, donc les soldes ne changent pas. Ils sont seulement **détachés** : `IDVENTE`, `IDVENTEDETAIL`, `IDPREVISION`, `IDORIGINE` (facture/avoir) et `IDTIERS` (client) passent à `NULL`. Même principe pour `FABRICATION`, `OFAB`, `TRAVAUX` et leurs filles, liés à un bon de commande client.

### 4.4 Sécurité

- Une seule transaction : si une étape échoue, **rien** n'est supprimé (rollback) et le message indique l'étape fautive.
- Une table absente de la base (ORA-00942 / ORA-00904) est ignorée et marquée « ignorée ».
- Les numéros de facture et d'avoir repartent à zéro tout seuls (les vues de numérotation lisent `VENTE` / `AVOIRFC`).
- Irréversible après exécution : faire un export (`.dmp`) avant si besoin.

---

## 5. Tests réalisés (base locale `arbiochem@XE`, tout annulé par ROLLBACK)

| Test | Résultat |
|---|---|
| Compilation des classes modifiées (javac 1.8, libs `build-file/lib`) | OK |
| `imputerSurFacture` sur `VNT001601153701` (reste 68 280 Ar), client `CLIA1660` avec avoir `AVRFC000314` de 78 000 Ar | 68 280 Ar imputés, facture reste **0**, avoir reste **9 720 Ar** |
| Second appel sur la même facture | 0 Ar imputé (pas de double imputation) |
| `lettrer` sur un avoir et une facture non lettrés | lettrage `abj` (partiel) posé sur les deux lignes client |
| Case « Ne pas appliquer l'avoir » cochée sur `VNT001727205103` (avoir disponible 16 000 Ar) | 0 Ar imputé, avoir restant 16 000 Ar |
| Même facture, case décochée | 16 000 Ar imputés, avoir restant 0 Ar |
| Script complet de réinitialisation | aucune erreur de contrainte, 0 client / 0 facture / 0 avoir, 882 produits et 62 mouvements de stock conservés |

---

## 6. Limites connues

- Les factures en devise autre que l'Ariary ne sont pas réduites automatiquement : les restes d'avoir sont en Ar.
- La caisse rapide (`Vente.enregistrerViserLivrerEncaisser`, « Facture code barre ») vise sans passer par `validerObject` et encaisse tout de suite le montant total : elle n'applique pas l'avoir, sinon le client paierait en double.
- Un avoir non visé n'est jamais utilisé : il faut d'abord le viser.
- Données existantes : quelques avoirs ont un reste négatif dans `AVOIRFCLIB_CPL` (ex. `AVRFC000274`) ; ils sont ignorés (`resteapayerar > 0`).

---

## 7. Fichiers

| Fichier | Type |
|---|---|
| `arbiochem-ejb/src/java/avoir/ImputationAvoirFC.java` | nouveau |
| `arbiochem-ejb/src/java/vente/ReinitialisationVente.java` | nouveau |
| `arbiochem-ejb/src/java/vente/Vente.java` | modifié (visa) |
| `arbiochem-ejb/src/java/vente/VenteArbiochem.java` | modifié (visa) |
| `arbiochem-war/web/pages/vente/inc/avoir-auto-info.jspf` | nouveau (fragment fiche) |
| `arbiochem-war/web/pages/vente/vente-fiche.jsp` | modifié (include du fragment) |
| `arbiochem-war/web/pages/vente/vente-arbiochem-fiche.jsp` | modifié (include du fragment) |
| `arbiochem-war/web/pages/vente/vente-saisie.jsp` | modifié (bandeau avoir) |
| `arbiochem-war/web/pages/vente/vente-arbiochem-saisie.jsp` | modifié (bandeau avoir) |
| `arbiochem-war/web/pages/vente/vente-arbiochem-liste.jsp` | modifié (bouton réinitialiser) |
| `arbiochem-war/web/pages/vente/apres-viser-avoir.jsp` | nouveau (choix avoir puis visa) |
| `arbiochem-war/web/pages/vente/reinitialisation-donnees.jsp` | nouveau |
| `arbiochem-war/web/pages/vente/apres-reinitialisation.jsp` | nouveau |
| `data/avoir-fc.sql` | nouveau (entrée de menu, table `VENTE_AVOIR_NON_APPLIQUE`, requêtes de contrôle) |

Après modification : `ant -f build.xml deploy`, puis exécuter `data/avoir-fc.sql` (menu + table ; sur la base locale `arbiochem@XE` la table est déjà créée).
