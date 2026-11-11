# POURCENTAGE-AVOIR : part maximale d'une facture payable par avoir

Dernière mise à jour : 22/10/2026

Prérequis : la fonctionnalité **AVOIR-FC** (voir `instruction/AVOIR-FC.md`, livraison `TEST/CHANGE/`).

---

## 1. Règle

Chaque client a un **pourcentage d'avoir** (`CLIENT.POURCENTAGE`) : c'est la part maximale d'une facture qu'il peut payer avec son avoir.
Le reste se paie en cash ou par un autre moyen de paiement.

```text
payable par avoir = min( avoir disponible du client ,
                         montant TTC de la facture x POURCENTAGE / 100 - avoir déjà imputé sur cette facture ,
                         reste à payer de la facture )
```

| Facture | Pourcentage | Avoir disponible | Payé par avoir | Reste à payer (cash / autre) | Avoir restant |
|---|---|---|---|---|---|
| 100 000 Ar | 40 % | 100 000 Ar | **40 000 Ar** | **60 000 Ar** | 60 000 Ar |
| facture suivante 100 000 Ar | 40 % | 60 000 Ar | 40 000 Ar | 60 000 Ar | 20 000 Ar |
| facture suivante 100 000 Ar | 40 % | 20 000 Ar | 20 000 Ar | 80 000 Ar | 0 Ar |
| 100 000 Ar | 100 % | 30 000 Ar | 30 000 Ar | 70 000 Ar | 0 Ar |
| 100 000 Ar | 0 % | 50 000 Ar | 0 Ar | 100 000 Ar | 50 000 Ar |

Valeurs du pourcentage :

- **100** (valeur par défaut, et valeur donnée à tous les clients existants) : pas de limite, comme avant ;
- **0** : l'avoir n'est jamais utilisé pour payer une facture ;
- vide : traité comme 100 ;
- hors de 0–100 : refusé (contrôle Java dans le formulaire + contrainte `CK_CLIENT_POURCENTAGE` en base).

Le plafond est calculé sur le **TTC de la facture**, pas sur le reste. Si une avance a déjà payé une partie, l'avoir couvre au plus `min(40 % du TTC, reste)`.

---

## 2. Base de données (`data/pourcentage-avoir.sql`)

1. `ALTER TABLE CLIENT ADD (POURCENTAGE NUMBER(5,2) DEFAULT 100)` + contrainte `CHECK (POURCENTAGE BETWEEN 0 AND 100)` ;
2. vue `CLIENTLIB` (fiche client) recréée **à l'identique** + la colonne `POURCENTAGE`.

On suit le même modèle que la colonne `SEUIL` : colonne sur `CLIENT`, attribut dans `client.ClientArbiochem` seulement.
Les autres vues client (`CLIENT_ACTIF`…) n'ont pas besoin de la colonne : APJ ignore en lecture un attribut absent de la vue (vérifié).

---

## 3. Écritures en base

Rien ne change dans la nature des écritures faites au visa (voir AVOIR-FC §3.3). Seul le **montant** est limité par le pourcentage :

1. `LIAISONPAIEMENT` (etat 11) : `id1` = avoir, `id2` = facture, `montant` = part payée par avoir (ex. 40 000 Ar) ;
   les vues font baisser `VENTE_CPL.MONTANTRESTE` (il reste 60 000 Ar à payer) et `AVOIRFCLIB_CPL.RESTEAPAYERAR` (l'avoir passe à 60 000 Ar) ;
2. `HISTORIQUE` : insertion + validation de la liaison ;
3. lettrage comptable (`COMPTA_LETTRAGE`, `COMPTA_SOUS_ECRITURE.LETTRAGE`) entre la ligne client de la facture et celle de l'avoir.
   Le lettrage est **partiel** (lettre en minuscule) puisque la facture n'est réglée qu'en partie.

Les 60 000 Ar restants se règlent ensuite par les écrans habituels (« Payer », « Payer par portefeuille », avance…).
Chacun génère son propre mouvement de caisse et sa propre écriture.

---

## 4. Ce qui a été modifié

| Fichier | Changement |
|---|---|
| `client/ClientArbiochem.java` | attribut `pourcentage` (getter/setter). Le setter refuse une valeur hors de 0–100 à la saisie (`mode modif`). |
| `avoir/ImputationAvoirFC.java` | `getPourcentageAvoirClient` (lecture JDBC, vide ou colonne absente = 100), `getPlafondAvoir`, `getPlafondRestant`. `simulerImputation(idClient, ttc, reste, c)` tient compte du pourcentage. `imputerSurFacture` limite le montant à `min(reste, plafond restant)`. Correction : un objet sans écriture comptable ne fait plus planter le lettrage. |
| `paiement/LiaisonPaiement.java` | `creerPaiementFacture` (bouton manuel **Payer par Ristourne/Avoir**) applique la **même limite**. Message « Plafond atteint : ce client ne peut payer que X% de la facture par avoir » si la part est déjà consommée. Correction au passage : plus de liaison à 0 Ar quand un avoir est vide ou que la facture est déjà couverte. |
| `client/client-arbiochem-saisie.jsp` | champ « Part max d'une facture payable par avoir (%) », 100 par défaut à la création. |
| `client/client-arbiochem-fiche.jsp` | libellé du champ. |
| `vente/inc/avoir-auto-info.jspf` | bandeau de la fiche facture : « Part payable par avoir : 40 % de la facture, soit au plus X Ar ». Le montant déduit au visa tient compte du plafond. |
| `vente/vente-saisie.jsp`, `vente/vente-arbiochem-saisie.jsp` | bandeau de saisie : affiche le pourcentage. « Déduit au visa » = `min(avoir, total x %)`. |

Le visa (`Vente.validerObject` / `VenteArbiochem.validerObject`), la case « Ne pas appliquer l'avoir » et la réinitialisation ne changent pas : ils passent tous par `ImputationAvoirFC`.

Non concernée : la **ristourne automatique** de `VenteArbiochem` (avoir de ristourne créé et imputé sur sa propre facture). C'est une remise commerciale, pas l'utilisation du solde d'avoir du client.

---

## 5. Tests réalisés (base locale `arbiochem@XE`, tout annulé par ROLLBACK)

| Test | Résultat |
|---|---|
| Colonne ajoutée, vue `CLIENTLIB` recréée | client existant à 100 |
| Scénario de l'énoncé : facture 100 000 Ar, 40 %, avoir 120 000 Ar | 40 000 Ar payables par avoir |
| Facture réelle `VNT001740081527` (24 000 Ar), client à 40 %, avoir 120 000 Ar | 9 600 Ar imputés, reste à payer 14 400 Ar, avoir restant 110 400 Ar |
| 2e imputation sur la même facture | 0 Ar (plafond restant 0) |
| Pourcentage 0 / vide / 150 | 0 Ar / traité comme 100 / refusé par la contrainte |
| Compilation des classes modifiées (javac 1.8) | OK |

Les JSP n'ont pas été testées dans WildFly : à vérifier après `ant -f build.xml deploy`.
