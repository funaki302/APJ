# CINEMA : module de gestion d'un cinéma

Dernière mise à jour : 11/11/2026 (étape 3)

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
| Servlets | `arbiochem-war/src/java/cinema/servlet/` (`@WebServlet`, rien à déclarer dans `web.xml`) |
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
| `etape-2-salles.sql` | tables `CIN_SALLE`, `CIN_PLACE`, vues `CIN_SALLE_LIB`, `CIN_PLACE_LIB`, menus Salles |
| `etape-3-films.sql` | tables `CIN_FILM`, `CIN_FILM_PHOTO`, vue `CIN_FILM_LIB`, menus Films |
| `cinema-reset.sql` | supprime tous les objets `CIN_*` / `SEQ_CIN_*` / `GETSEQCIN*` et les menus `MENDYNCINEMA%`. Testé le 11/11/2026. |

## 4. Avancement

| Étape | Contenu | État |
|---|---|---|
| 0 | Socle : packages, dossiers, menu, accueil, reset, doc | fait (11/11/2026) |
| 1 | Référentiels | fait (11/11/2026) |
| 2 | Salles et places | fait (11/11/2026) |
| 3 | Films | fait (11/11/2026) |
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

## 6 bis. Étape 2 : salles et places

| Table | Classe Java | Préfixe id | Pages |
|---|---|---|---|
| `CIN_SALLE` (vue `CIN_SALLE_LIB`) | `cinema.salle.CinSalle` / `CinSalleLib` | `CINSAL` | `cinema/salle/salle-{saisie,liste,fiche,modif,plan}.jsp`, `apres-salle-plan.jsp` |
| `CIN_PLACE` (vue `CIN_PLACE_LIB`) | `cinema.salle.CinPlace` / `CinPlaceLib` | `CINPLA` + 8 chiffres | pas de page propre : plan de la salle |

- **Création d'une salle** : `CinSalle.createObject` insère la salle puis `genererPlaces` crée `NB_RANGEES × NB_COLONNES` places (A1…Z40) par un insert en lot, dans la classe renvoyée par `getIdClasseParDefaut` (classe active la moins chère). Tout est dans la transaction d'`apresTarif.jsp` : si la génération échoue, la salle n'est pas créée.
- **Prix d'une place** = prix de sa classe (pas de colonne `PRIX` dans `CIN_PLACE`) : changer le prix d'une classe change le prix de toutes ses places.
- **Structure figée** : rangées et colonnes ne changent plus après la création (contrôle dans `updateToTableWithHisto`).
- **Plan** : `CinSalle.getPlaces(idSalle, c)` (places triées, avec couleur et prix) + `CinClassePlace.getClassesActives(c)` alimentent le fragment `cinema/inc/plan-salle.jspf`. Variables à déclarer avant l'include : `planPlaces`, `planColonnes`, `planClasses`, `planEditable`. Chaque place est un `div.cin-place` avec `data-id`, `data-classe`, `data-etat`, `data-rangee`, `data-colonne`.
- **Modification du plan** : `salle-plan.jsp` envoie `modifs = "idplace:idclasse;idplace:HS;..."` à `apres-salle-plan.jsp` → `CinSalle.modifierPlaces(idSalle, modifs)` (sa propre transaction). Une classe remet la place en service ; `HS` la met hors service sans changer sa classe.
- **Suppression d'une salle** : supprime ses places (`ON DELETE CASCADE`).

## 6 ter. Étape 3 : films

| Table | Classe Java | Préfixe id | Pages |
|---|---|---|---|
| `CIN_FILM` (vue `CIN_FILM_LIB`) | `cinema.film.CinFilm` / `CinFilmLib` | `CINFIL` | `cinema/film/film-{saisie,liste,fiche,modif}.jsp` |
| `CIN_FILM_PHOTO` | `cinema.film.CinFilmPhoto` (pas une `ClassMAPTable`) | clé = id du film | servlet `/cinema/film-photo` |

- **Photo** : stockée en base (BLOB), une par film, supprimée avec le film. JPG / PNG / WEBP reconnus sur les premiers octets du fichier (un `.jpg` qui n'est pas une image est refusé), 2 Mo maximum.
- **Servlet** `cinema.servlet.CinFilmPhotoServlet` (`/cinema/film-photo`, dans `arbiochem-war`) : `GET ?id=` renvoie l'image ou un dessin « Pas de photo » ; `POST` multipart (`idfilm` + `photo`, ou `idfilm` + `action=supprimer`) enregistre puis revient à la fiche. Réservée aux utilisateurs connectés.
- **Liste en cartes** : `film-liste.jsp` garde le formulaire de recherche et la pagination de `PageRecherche` mais affiche `pr.getListe()` en cartes au lieu du tableau.
- **Durée** saisie en minutes, affichée « 2 h 05 » (`DUREELIB`).

Tests à faire dans WildFly :

| Écran | À vérifier |
|---|---|
| Films → Saisie | titre, catégorie, acteur, 125 min, PA → la fiche s'ouvre avec « Pas de photo » |
| Fiche → Ajouter une photo | choisir un JPG ou PNG → l'affiche apparaît ; « Changer la photo » la remplace ; « Supprimer la photo » remet « Pas de photo » |
| Fiche → photo refusée | un PDF ou un fichier renommé en .jpg → message « Format non accepté » ; une image de plus de 2 Mo → « L'image dépasse 2 Mo » |
| Films → Liste | cartes avec vignette, « Titre (acteur) », catégorie, « 2 h 05 », Détail ; filtres et pagination |
| Fiche → Modifier | durée 700 → refusée ; catégorie inactive non proposée |

## 7. Pièges APJ (à retenir pour les étapes suivantes)

- **Modification** : `apresTarif.jsp` → `UserEJB.updateObject` → `UpdateObject` → `updateToTableWithHisto`. `controlerUpdate` n'est **pas** appelé (seulement par `updateObjectValidation`). Contrôles de modification : surcharger `updateToTableWithHisto(String, Connection)`.
- **Insertion** : `createObject` appelle `controler(c)` **avant** `construirePK` puis insère toutes les colonnes : un attribut vide écrase le `DEFAULT` de la table → donner les valeurs par défaut dans `controler`.
- **Suppression** : `deleteToTableWithHisto` appelle `controlerDelete(c)`.
- **Menu** : un menu de niveau 1 doit avoir une ligne `USERMENU` autorisée (voir §5).
- **Scripts SQL** : `SET DEFINE OFF;` à cause des entités HTML.
- **Pilote Oracle ancien** (`ojdbc6-11.jar`, classes `oracle.jdbc.dbaccess`) : pour un BLOB, ne pas utiliser `setBinaryStream` / `setBytes` / `getBytes`. Écrire avec `EMPTY_BLOB()` + `SELECT ... FOR UPDATE` + `getBinaryOutputStream()`, lire avec `getBlob()` (voir `CinFilmPhoto`).
