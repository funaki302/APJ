# CINEMA — Étape 1 : référentiels

Date : 11/11/2026. Prérequis : **étape 0** (`TEST/CINEMA/ETAPE-0/`). Plan : `TEST/CINEMA/TO-DO-CINEMA-1.md`. Documentation : `instruction/CINEMA.md`.

Aucun fichier existant de l'application n'est modifié : seuls des fichiers du module cinéma sont ajoutés ou remplacés.

## Fichiers (à copier à la même place dans `projet-standard/`)

| Fichier | Nouveau / remplace |
|---|---|
| `arbiochem-ejb/src/java/cinema/salle/CinCinema.java`, `CinCinemaLib.java` | nouveau |
| `arbiochem-ejb/src/java/cinema/salle/CinClassePlace.java`, `CinClassePlaceLib.java` | nouveau |
| `arbiochem-ejb/src/java/cinema/film/CinCategorieFilm.java`, `CinCategorieFilmLib.java`, `CinActeur.java` | nouveau |
| `arbiochem-ejb/src/java/cinema/utils/CinParametre.java`, `CinUtils.java` | nouveau |
| `arbiochem-war/web/pages/cinema/salle/cinema-{saisie,liste,fiche,modif}.jsp` | nouveau |
| `arbiochem-war/web/pages/cinema/salle/classe-place-{saisie,liste,fiche,modif}.jsp` | nouveau |
| `arbiochem-war/web/pages/cinema/film/categorie-film-{saisie,liste,fiche,modif}.jsp` | nouveau |
| `arbiochem-war/web/pages/cinema/film/acteur-{saisie,liste,fiche,modif}.jsp` | nouveau |
| `arbiochem-war/web/pages/cinema/parametre/parametre-{liste,fiche,modif}.jsp` | nouveau (dossier `parametre/` à créer) |
| `arbiochem-war/web/pages/cinema/inc/couleur-apercu.jspf` | nouveau |
| `arbiochem-war/web/pages/cinema/cinema-accueil.jsp` | **remplace** celui de l'étape 0 (carte « Configurations » ajoutée) |
| `data/cinema/etape-1-referentiels.sql` | nouveau |
| `instruction/CINEMA.md` | **remplace** celui de l'étape 0 |

## Installation

1. Exécuter `data/cinema/etape-1-referentiels.sql` (garder le `SET DEFINE OFF;` du début).
2. `ant -f build.xml deploy`.
3. Se **déconnecter puis se reconnecter** (nouveaux menus).

## Test

Menu **Cinéma → Configurations** :

| Écran | À vérifier |
|---|---|
| Cinémas → Liste | « Cinéma principal » apparaît ; clic sur l'id → fiche ; Modifier / Supprimer |
| Cinémas → Saisie | créer un cinéma → arrive sur sa fiche, état Actif ; recréer le même nom → message « Un cinéma porte déjà le nom… » |
| Classes de place → Liste | Standard / Moyen / Premium avec une pastille de couleur ; filtre prix min / max |
| Classes de place → Saisie | sélecteur de couleur ; prix 0 → refusé ; libellé « standard » → refusé (doublon) |
| Classes de place → fiche → Modifier | changer le prix → enregistré ; renommer en « Premium » → refusé |
| Catégories de film | 7 catégories ; créer « Thriller » ; doublon refusé |
| Acteurs | créer un acteur (nom obligatoire) ; date de naissance future → refusée |
| Paramètres | `DELAI_EXPIRATION_MIN` = 30 ; Modifier → mettre « abc » → refusé ; mettre 45 → enregistré ; pas de bouton Supprimer |

Les prix des classes (10 000 / 15 000 / 20 000 Ar) sont des valeurs d'exemple : les ajuster dans l'écran Classes de place.
