# CINEMA : module de gestion d'un cinéma

Dernière mise à jour : 11/11/2026 (étape 1)

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
| `etape-1-referentiels.sql` | référentiels : tables `CIN_CINEMA`, `CIN_CLASSE_PLACE`, `CIN_CATEGORIE_FILM`, `CIN_ACTEUR`, `CIN_PARAMETRE`, vues `*_LIB`, données initiales, menus Configurations |
| `cinema-reset.sql` | supprime tous les objets `CIN_*` / `SEQ_CIN_*` / `GETSEQCIN*` et les menus `MENDYNCINEMA%`. Testé le 11/11/2026. |

## 4. Avancement

| Étape | Contenu | État |
|---|---|---|
| 0 | Socle : packages, dossiers, menu, accueil, reset, doc | fait (11/11/2026) |
| 1 | Référentiels | fait (11/11/2026) |
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

## 6. Étape 1 : référentiels

| Table | Classe Java | Préfixe id | Pages | Notes |
|---|---|---|---|---|
| `CIN_CINEMA` (vue `CIN_CINEMA_LIB`) | `cinema.salle.CinCinema` / `CinCinemaLib` | `CINCIN` | `cinema/salle/cinema-*.jsp` | nom unique |
| `CIN_CLASSE_PLACE` (vue `CIN_CLASSE_PLACE_LIB`) | `cinema.salle.CinClassePlace` / `CinClassePlaceLib` | `CINCLA` | `cinema/salle/classe-place-*.jsp` | libellé unique, prix > 0, couleur `#RRGGBB` (champ `type=color`) |
| `CIN_CATEGORIE_FILM` (vue `CIN_CATEGORIE_FILM_LIB`) | `cinema.film.CinCategorieFilm` / `CinCategorieFilmLib` | `CINCAT` | `cinema/film/categorie-film-*.jsp` | libellé unique |
| `CIN_ACTEUR` | `cinema.film.CinActeur` | `CINACT` | `cinema/film/acteur-*.jsp` | `NOM` = nom civil, `NOM_ACTEUR` = nom de scène |
| `CIN_PARAMETRE` | `cinema.utils.CinParametre` | `CINPAR` | `cinema/parametre/parametre-{liste,fiche,modif}.jsp` | code fixe, valeur modifiable, pas de suppression |

- `ETAT` des référentiels : 1 = Actif, 0 = Inactif (liste déroulante). Les étapes suivantes ne proposeront que les éléments actifs.
- `CinParametre.getDelaiExpirationMinutes(c)` : délai d'expiration des réservations (30 par défaut si absent ou invalide).
- `CinUtils.valeurExiste(...)` : contrôle de doublon par requête préparée (la valeur saisie n'est jamais concaténée dans le SQL).
- Fragment `cinema/inc/couleur-apercu.jspf` : affiche une pastille de couleur devant tout texte `#RRGGBB` d'un tableau ou d'une fiche.

## 7. Pièges APJ (à retenir pour les étapes suivantes)

- **Modification** : `apresTarif.jsp` → `UserEJB.updateObject` → `UpdateObject` → `updateToTableWithHisto`. `controlerUpdate` n'est **pas** appelé (seulement par `updateObjectValidation`). Contrôles de modification : surcharger `updateToTableWithHisto(String, Connection)`.
- **Insertion** : `createObject` appelle `controler(c)` **avant** `construirePK` puis insère toutes les colonnes : un attribut vide écrase le `DEFAULT` de la table → donner les valeurs par défaut dans `controler`.
- **Suppression** : `deleteToTableWithHisto` appelle `controlerDelete(c)`.
- **Menu** : un menu de niveau 1 doit avoir une ligne `USERMENU` autorisée (voir §5).
- **Scripts SQL** : `SET DEFINE OFF;` à cause des entités HTML.

