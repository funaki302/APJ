# ALEA du 12/11/2026 : programme de novembre du cinéma

Données fournies dans `PHOTO/` : plan des salles A, B, C, liste des films, programme du 16 au 30/11/2026.

## Ce qui a été fait

- **Colonnes ajoutées** à `CIN_FILM` : `REALISATEUR` et `CLASSIFICATION` (Tous publics, -12, -16, -18). L'acteur principal devient facultatif (les photos donnent le réalisateur, pas l'acteur).
- **Classes de place** : Standard 15 000 Ar (rangées A-B), Confort 20 000 Ar (rangée C), VIP 30 000 Ar (rangée D). Moyen / Premium sont renommées.
- **Salles** A, B, C : 4 rangées × 5 places (20 places). « ENTRÉE » est maintenant affichée au fond du plan de salle.
- **Films** : Les Gardiens du Baobab (Aventure, 115 min, Tous publics), Nuit sur Analamanga (Thriller, 105 min, -12), Le Petit Lemurien (Animation, 90 min, Tous publics). Prix d'achat **0 Ar**.
- **Séances** : le programme de la semaine est répété chaque jour du lundi 16 au lundi 30/11/2026, soit 41 séances.
- **Réinitialiser les données** propose maintenant 3 choix : vide, programme de novembre (par défaut), démonstration de test.
- Les données sont **déjà chargées dans la base locale** (12/11/2026).

## Fichiers (à copier à la même place dans `projet-standard/`)

| Fichier | Changement |
|---|---|
| `data/cinema/etape-10-films-realisateur.sql` | **nouveau** : colonnes réalisateur / classification, acteur facultatif, vue `CIN_FILM_LIB` |
| `data/cinema/donnees-alea-12-11-26.sql` | **nouveau** : classes, salles, films, séances du programme (rejouable) |
| `arbiochem-war/web/WEB-INF/cinema/donnees-alea-12-11-26.sql` | copie identique, lue par la réinitialisation |
| `data/cinema/etape-1-referentiels.sql` | classes Standard / Confort / VIP aux nouveaux prix (installation neuve) |
| `data/cinema/donnees-demo.sql` + copie `WEB-INF` | noms de classes Confort / VIP, montants calculés depuis le ticket |
| `arbiochem-ejb/src/java/cinema/film/CinFilm.java` | champs `realisateur`, `classification`, contrôles, acteur facultatif |
| `arbiochem-ejb/src/java/cinema/film/CinActeur.java` | `getActeurs` (liste déroulante avec choix vide) |
| `arbiochem-ejb/src/java/cinema/utils/CinReinitialisation.java` | libellé du résultat |
| `arbiochem-war/web/pages/cinema/film/film-{saisie,modif,fiche,liste}.jsp` | réalisateur, classification, acteur facultatif |
| `arbiochem-war/web/pages/cinema/inc/plan-salle.jspf` | « ENTRÉE » au fond de la salle |
| `arbiochem-war/web/pages/cinema/parametre/{reinitialisation,apres-reinitialisation}.jsp` | option « programme de novembre » |
| `instruction/CINEMA.md` | §3, §4 et §6 undecies (étape 10) |

## Installation sur une autre base

1. `data/cinema/etape-10-films-realisateur.sql` (après les étapes 0 à 9).
2. `ant -f build.xml deploy`, puis se reconnecter.
3. Cinéma → Réinitialiser les données → « programme du 16 au 30/11/2026 » → taper REINITIALISER.
   (Ou exécuter `data/cinema/donnees-alea-12-11-26.sql` dans SQL Developer.)

## À tester dans WildFly

| Écran | Attendu |
|---|---|
| Configurations → Classes de place | Standard 15 000, Confort 20 000, VIP 30 000 |
| Salles → fiche Salle A | 20 places : A-B gris (Standard), C vert (Confort), D orange (VIP), ÉCRAN devant, ENTRÉE au fond |
| Films → Liste | 3 films, colonnes Réalisateur et Classification, prix 0 ; filtre Classification -12 → Nuit sur Analamanga |
| Films → Saisie | acteur laissé sur « - » → accepté |
| Diffusions → Calendrier, semaine du 16/11 | 18 séances (lundi : 14h A et B, 17h B, 20h A et B ...) |
| Réservation d'une place D1 | 30 000 Ar |
