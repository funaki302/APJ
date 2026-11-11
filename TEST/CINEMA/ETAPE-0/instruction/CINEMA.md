# CINEMA : module de gestion d'un cinéma

Dernière mise à jour : 11/11/2026 (étape 0)

Plan de travail et décisions : `TEST/CINEMA/TO-DO-CINEMA-1.md`. Livraisons : `TEST/CINEMA/ETAPE-n/`.

---

## 1. Principe

Le cinéma est un module **séparé** du reste de l'ERP : rien de l'existant n'est modifié. Il réutilise seulement :

| Existant | Usage |
|---|---|
| `CLIENT` | client qui réserve |
| `MODEPAIEMENT` | mode de chaque ligne de paiement |
| `CAISSE` | caisse choisie par ligne (paiement ou achat) |
| `MOUVEMENTCAISSE` (`caisse.MvtCaisse`) | `DEBIT` = sortie (achat), `CREDIT` = entrée (ticket payé) |
| `MENUDYNAMIQUE` | menu CINEMA |

## 2. Où se trouve quoi

| Partie | Emplacement |
|---|---|
| Java | `arbiochem-ejb/src/java/cinema/` : `salle`, `film`, `achat`, `diffusion`, `reservation`, `paiement` (paiement + facture), `utils` |
| JSP | `arbiochem-war/web/pages/cinema/` : `salle/`, `film/`, `achat/`, `diffusion/`, `reservation/`, `paiement/`, `facture/`, `client/`, `inc/` (fragments) |
| SQL | `data/cinema/` : `etape-n-*.sql` (à jouer dans l'ordre) et `cinema-reset.sql` |
| Base | tables et vues `CIN_*`, séquences `SEQ_CIN_*`, fonctions `GETSEQCIN*` |
| Clés primaires | préfixes commençant par `CIN` (ex. `CINSAL…`), pour retrouver les mouvements de caisse du cinéma avec `IDORIGINE LIKE 'CIN%'` |
| Menu | racine `MENDYNCINEMA` (niveau 1, rang 0 = tout en haut), sous-menus `MENDYNCINEMAnn` |

Règles : `apresTarif.jsp` et `apresMultiple.jsp` ne sont jamais modifiés ; la logique est dans les classes Java ; JSP en UTF-8.

## 3. Scripts SQL

Les scripts commencent par `SET DEFINE OFF;` car les libellés contiennent des entités HTML (`&eacute;`) : sans cela, SQL*Plus / SQL Developer demandent une valeur de variable et enregistrent un libellé abîmé (`Cin;ma`).

| Script | Contenu |
|---|---|
| `etape-0-menu.sql` | menu racine **Cinéma** (icône `movie`) + sous-menu **Accueil cinéma** + droit d'accès `USERMENU` (`UMCINEMA01`) |
| `cinema-reset.sql` | supprime tous les objets `CIN_*` / `SEQ_CIN_*` / `GETSEQCIN*` et les menus `MENDYNCINEMA%`. Testé le 11/11/2026. |

## 4. Avancement

| Étape | Contenu | État |
|---|---|---|
| 0 | Socle : packages, dossiers, menu, accueil, reset, doc | fait (11/11/2026) |
| 1 | Référentiels | à faire |
| 2 | Salles et places | à faire |
| 3 | Films | à faire |
| 4 | Achats → sortie de caisse | à faire |
| 5 | Diffusions | à faire |
| 6 | Réservations | à faire |
| 7 | Paiement → facture + entrée de caisse | à faire |
| 8 | Consultation client, tableau de bord | à faire |
| 9 | Recette finale | à faire |

## 5. Étape 0 : détail

- Page `cinema/cinema-accueil.jsp` : une carte par partie du module. Une carte devient cliquable quand sa page existe : remplir le lien (3e colonne du tableau `modules` en haut de la JSP).
- Les sous-menus des pages suivantes sont ajoutés par le script de leur étape, une fois la page créée (pas de lien vers une page vide).
- Le menu est mis en cache dans la session (`session.getAttribute("MENU")`) : après avoir joué un script de menu, **se déconnecter puis se reconnecter**.
- `USERMENU` sert **aussi de liste d'autorisations** : `MenuDynamique.getElementMenu` (apj-core2.jar) n'affiche un menu de niveau 1 que s'il a une ligne `USERMENU` avec `INTERDIT = 0` (ou vide) pour l'utilisateur (`REFUSER = '*'` ou son id), son rôle, son service ou sa direction. Les lignes `INTERDIT = 1` retirent ensuite des menus. Les sous-menus suivent leur parent. Le menu Cinéma a la ligne `UMCINEMA01` (`REFUSER = '*'`, `INTERDIT = 0`) : visible par tous, comme Ferme. Sans cette ligne, le menu est en base mais n'apparaît pas.
