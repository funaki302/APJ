# TO-DO CINEMA — version 1

Dernière mise à jour : 11/11/2026

Sources : `TEST/CINEMA/cinemaSESSION.md`, `TEST/CINEMA/TODO/Concept_cinema.md`, photos `TEST/CINEMA/IMAGE/` (concept, maquettes des pages, MCD), base actuelle `data/REAL DATA/script_schema.sql` + `data_inserts.sql`, règles `instruction/documentation.md` et `instruction/APJ.md`.

> Toutes les questions ont reçu une réponse : voir §10 (décisions) et §11 (perspectives d'avenir).

---

## 1. Objectif

Ajouter à l'ERP un module **CINEMA** complètement séparé du reste, sans toucher aux fonctionnalités existantes (ferme, production, vente, achat…).

Flux métier :

```text
Achat de film / matériel ──► sortie d'argent (MOUVEMENTCAISSE, débit)
        │
        ▼
Film ──► Diffusion (film + salle + date/heure)
                │
                ▼
        Réservation (client + places choisies sur le plan de salle) = ticket
                │   non payée avant [délai paramétrable] avant la séance ──► expirée, places libérées
                ▼
        Paiement en UNE fois, plusieurs modes (espèce + mobile money + …)
                │
                ├──► Facture client générée automatiquement
                └──► entrée d'argent (MOUVEMENTCAISSE, crédit), une ligne par mode
```

---

## 2. Règles d'organisation (pour ne pas se perdre)

| Où | Règle |
|---|---|
| Java (back) | **Un seul package racine `cinema`** dans `arbiochem-ejb/src/java/cinema/`, avec des sous-packages par domaine : `cinema.salle`, `cinema.film`, `cinema.achat`, `cinema.diffusion`, `cinema.reservation`, `cinema.paiement` (paiement + facture), `cinema.utils`. Aucune classe cinéma ailleurs. |
| JSP (front) | **Un seul dossier `arbiochem-war/web/pages/cinema/`**, même découpage : `cinema/salle/`, `cinema/film/`, `cinema/achat/`, `cinema/diffusion/`, `cinema/reservation/`, `cinema/paiement/`, `cinema/facture/`, `cinema/client/`, `cinema/inc/` (fragments partagés). |
| Base de données | **Toutes les tables et vues préfixées `CIN_`** (ex. `CIN_SALLE`, `CIN_FILM_LIB`). Cela évite les conflits avec l'existant (`CATEGORIE`, `CLIENT`, `PAIEMENT…` existent déjà) et permet de tout retrouver avec `LIKE 'CIN\_%'`. Séquences `SEQ_CIN_xxx` + fonctions `GETSEQCINxxx` (modèle de `data/Exercice/Exercice.sql`). |
| Scripts SQL | Dossier `data/cinema/` : un script par étape (`etape-0-menu.sql`, `etape-1-referentiels.sql`, …) + `cinema-reset.sql` (supprime tout le module). |
| Menu | Un menu de niveau 1 **CINEMA** (icône `movie`) dans `MENUDYNAMIQUE`, à côté de Ferme / Production / Produit. Tous les sous-menus ont `ID_PERE` = ce menu. |
| Fichiers intouchables | `apresTarif.jsp` et `apresMultiple.jsp` ne sont **jamais** modifiés. Si besoin d'un traitement spécial : page relais `cinema/.../apres-xxx.jsp` puis renvoi vers `apresTarif.jsp`. |
| Logique | Dans les classes Java (`controler`, `createObject`, `validerObject`, surcharges + appel de `super`), jamais seulement dans la JSP. Pas de `commit()` au milieu d'un visa. |
| Livraison | **Une seule fois, à la fin de toutes les étapes** (décision du 11/11/2026) : copie de tous les fichiers du module dans `TEST/CINEMA/` (en gardant l'arborescence `arbiochem-ejb/…`, `arbiochem-war/…`, `data/…`) + un `README.md` global. Pendant les étapes : seulement cocher ce TO-DO et tenir `instruction/CINEMA.md` à jour. |

Conventions APJ reprises de l'existant : `ID VARCHAR2`, `ETAT NUMBER` (1 = créé, 11 = visé/validé, 0 = annulé) à la place d'un champ texte `statut`, `DATY` pour les dates, classes `*Lib` / `*Cpl` pour lire les vues d'affichage.

---

## 3. Ce qu'on réutilise dans la base actuelle

| Existant | Usage dans le cinéma | Remarque (analyse de la base) |
|---|---|---|
| `CLIENT` (classe `client.Client`) | client qui réserve | Réponse n°1 du concept : on garde la table `CLIENT`. Colonnes utiles : `NOM`, `TELEPHONE`, `MAIL`. Pas de table `CIN_CLIENT`. |
| `MODEPAIEMENT` | modes de chaque ligne de paiement | Contient déjà `0001 chèque`, `0002 espèce`, `0003 virement`, `0004 traite`, `0005 Multiple`… Mobile money à ajouter si besoin. |
| `CAISSE` | caisse qui reçoit / paie | Existantes : `Caisse Analakely`, `Caisse Ankorondrano`, `Mvola…`, banques… On créera une **caisse « Caisse Cinéma »**. **Décidé** : chaque ligne de paiement / chaque achat choisit sa caisse, pré-remplie selon le mode (espèce → Caisse Cinéma, Mvola → caisse Mvola…). |
| `MOUVEMENTCAISSE` (classe `caisse.MvtCaisse`, préfixe `MTC`) | écriture de caisse | `DEBIT` = sortie (dépense, `isDepense()`), `CREDIT` = entrée. Colonnes utiles : `IDCAISSE`, `IDORIGINE` (id de l'achat ou du paiement cinéma), `IDTIERS`, `IDMODEPAIEMENT`, `DATY`, `DESIGNATION`. |
| `MENUDYNAMIQUE` | menu CINEMA | Niveau 1 existants : Ferme (rang 1), Production (2), Produit (3), Vente (4)… |
| `USERMENU` | droits sur le menu | Liste d'**autorisations** (`INTERDIT = 0` ou vide) **et** d'interdits (`INTERDIT = 1`). Un menu de niveau 1 sans ligne autorisée n'est **pas affiché** : ligne `UMCINEMA01` (`REFUSER = '*'`) ajoutée pour Cinéma. |
| `CONFIGURATION` | — | Non utilisée : le délai d'expiration est stocké dans une petite table `CIN_PARAMETRE`, pour garder le cinéma à part. |
| `VENTE` / `FACTURECLIENT` | — | **Décidé : non utilisées.** La facture cinéma a sa propre table `CIN_FACTURE`, pour éviter les effets de bord de `VENTE` (stock, avoirs, prévision). |
| `AS_BONDECOMMANDE` | — | **Décidé : non utilisé.** Les achats cinéma ont leur propre table `CIN_ACHAT`. |

---

## 4. Modèle de données proposé (à partir du MCD de la photo)

| Table | Colonnes | Type APJ | Notes |
|---|---|---|---|
| `CIN_CINEMA` | ID, NOM, LOCALISATION, DATE_CREATION, ETAT | `ClassEtat` | Un seul cinéma au départ, mais le modèle en accepte plusieurs. |
| `CIN_CLASSE_PLACE` | ID, VAL (standard / moyen / premium), DESCE, PRIX, COULEUR, DATE_CREATION, ETAT | `ClassMAPTable` | Couleurs du concept : standard jaune, moyen vert, premium rouge. |
| `CIN_SALLE` | ID, IDCINEMA, NOM, CAPACITE, NB_RANGEES, NB_COLONNES, DATE_CREATION, ETAT | `ClassMAPTable` (fait, étape 2) | `NB_RANGEES` × `NB_COLONNES` ajoutées pour dessiner le plan (maquette `salle_saisie`). Les places sont créées par `createObject`. |
| `CIN_PLACE` | ID, IDSALLE, IDCLASSE, NUMERO (A1, A2…), RANGEE, COLONNE, ETAT (1 en service / 0 hors service) | `ClassMAPTable` (fait, étape 2) | Générées automatiquement à la création de la salle, dans la classe active la moins chère. **Pas de colonne PRIX** : le prix est celui de la classe (vue `CIN_PLACE_LIB`), conformément à la décision « prix selon la classe seule ». |
| `CIN_CATEGORIE_FILM` | ID, VAL, DESCE, DATE_CREATION, ETAT | `TypeObjet` | Action, comédie… |
| `CIN_ACTEUR` | ID, NOM, NOM_ACTEUR (nom de scène), DATE_NAISSANCE | `ClassMAPTable` | Un acteur principal par film. |
| `CIN_FILM` + `CIN_FILM_PHOTO` | ID, TITRE, IDCATEGORIE, IDACTEUR, DUREE (minutes), PA, DESCRIPTION, DATE_CREATION, ETAT — photo : IDFILM, CONTENU (BLOB), TYPE_MIME, NOM_FICHIER, TAILLE, DATE_MAJ | `ClassMAPTable` (fait, étape 3) | `PA` = prix d'achat. **Photo stockée en base** (décision du 11/11/2026), affichée par la servlet `/cinema/film-photo`. |
| `CIN_ACHAT` + `CIN_ACHAT_FILLE` | mère : ID, DATY, FOURNISSEUR, IDCAISSE, MONTANT, ETAT — fille : ID, IDACHAT, TYPE (film / matériel), IDFILM, DESIGNATION, QTE, PU | `ClassMere` / `ClassFille` | **Décidé.** Le visa génère le débit de caisse. |
| `CIN_DIFFUSION` | ID, IDFILM, IDSALLE, DATY, HEURE (HH:MI), DATE_CREATION, ETAT | `ClassEtat` | `HEURE` en texte comme l'existant (`MOUVEMENTCAISSE.HEURE`, `VENTE.HEURESAISIE`). |
| `CIN_TICKET` (réservation) | ID, IDCLIENT, IDDIFFUSION, DATY_RESERVATION, MONTANT, ETAT | `ClassMere` (fille = ticket_detail) | La salle se lit par la diffusion (vue), inutile de la stocker deux fois. |
| `CIN_TICKET_DETAIL` | ID, IDTICKET, IDDIFFUSION, IDPLACE, IDCLASSE, PRIX | `ClassFille` | `IDDIFFUSION` recopié pour contrôler qu'une place n'est vendue qu'une fois par séance. `PRIX` figé au moment de la réservation. |
| `CIN_PAIEMENT` | ID, IDTICKET, IDCLIENT, DATY, MONTANT, IDFACTURE, ETAT | `ClassMere` | Un seul paiement par ticket. |
| `CIN_PAIEMENT_DETAIL` | ID, IDPAIEMENT, IDMODEPAIEMENT, IDCAISSE, MONTANT, IDMVTCAISSE | `ClassFille` | Une ligne par mode ; la somme doit être égale au montant du ticket. |
| `CIN_FACTURE` + `CIN_FACTURE_DETAIL` | mère : ID, NUMERO (0001/2026…), IDCLIENT, IDTICKET, IDPAIEMENT, DATY, MONTANT, ETAT — fille : ID, IDFACTURE, IDPLACE, DESIGNATION (film, séance, place), PRIX | `ClassMere` / `ClassFille` | Générée automatiquement au paiement complet, une ligne par place. |

Vues principales :

- `CIN_SALLE_LIB`, `CIN_PLACE_LIB` (avec libellé et couleur de la classe) ;
- `CIN_FILM_LIB` (catégorie, acteur) ;
- `CIN_DIFFUSION_LIB` (titre, durée, salle, heure de fin calculée) ;
- `CIN_PLACE_DIFFUSION` : **pour chaque diffusion × chaque place de la salle → LIBRE / RÉSERVÉE / PAYÉE**, en ignorant les tickets annulés et expirés. C'est la vue qui alimente le plan de réservation ;
- `CIN_TICKET_LIB` (client, film, salle, date séance, montant, état calculé : réservé / payé / expiré / annulé) ;
- `CIN_PAIEMENT_LIB`.

---

## 5. Étapes

Chaque étape se termine par : compilation (`ant -f build.xml deploy`), script SQL joué, test dans WildFly. La livraison dans `TEST/CINEMA/` se fait une seule fois, à l'étape 9.

### Étape 0 : Socle du module — ✅ FAIT (11/11/2026, livraison `TEST/CINEMA/ETAPE-0/`)

- [x] Créer le package `arbiochem-ejb/src/java/cinema/` + sous-packages `salle`, `film`, `achat`, `diffusion`, `reservation`, `paiement`, `utils` (un `package-info.java` dans chacun décrit son contenu).
- [x] Créer le dossier `arbiochem-war/web/pages/cinema/` + sous-dossiers `salle/`, `film/`, `achat/`, `diffusion/`, `reservation/`, `paiement/`, `facture/`, `client/`, `inc/`.
- [x] `data/cinema/etape-0-menu.sql` : menu niveau 1 **Cinéma** (`ID = 'MENDYNCINEMA'`, `ICONE = 'movie'`, `NIVEAU = 1`, `RANG = 0` : **tout en haut, avant Ferme** qui a le rang 1) + sous-menu **Accueil cinéma**. Joué sur la base locale.
  - Changement par rapport au plan : pas de sous-menus vides. Chaque sous-menu (Salles, Films…) est ajouté par le script de son étape, quand la page existe, pour ne pas avoir de liens vers des pages blanches.
  - Ajout de la ligne `USERMENU` `UMCINEMA01` (`REFUSER = '*'`, `INTERDIT = 0`) : sans elle le menu n'apparaissait pas (corrigé le 11/11/2026 après ton test).
  - Le script commence par `SET DEFINE OFF;` : sans cela, SQL*Plus prend `&eacute;` pour une variable et enregistre « Cin;ma ».
- [x] Page d'accueil `cinema/cinema-accueil.jsp` : une carte par partie du module, grisée « À venir (étape n) » tant que la page n'existe pas.
- [x] `data/cinema/cinema-reset.sql` : supprime tous les objets `CIN_*`, `SEQ_CIN_*`, `GETSEQCIN*` + les menus `MENDYNCINEMA%`. Testé (suppression puis réinsertion du menu).
- [x] Créer `instruction/CINEMA.md`.
- [ ] **À tester par toi dans WildFly** : `ant -f build.xml deploy`, se déconnecter / reconnecter, vérifier que **Cinéma** est en haut du menu et que **Accueil cinéma** affiche les cartes.

### Étape 1 : Référentiels — ✅ FAIT (11/11/2026, livraison `TEST/CINEMA/ETAPE-1/`)

- [x] `data/cinema/etape-1-referentiels.sql` : tables `CIN_CINEMA`, `CIN_CLASSE_PLACE`, `CIN_CATEGORIE_FILM`, `CIN_ACTEUR`, `CIN_PARAMETRE` (ID, CODE, VALEUR, DESCE) + séquences `SEQ_CIN_*` + fonctions `GETSEQCIN*` + vues `CIN_CINEMA_LIB`, `CIN_CLASSE_PLACE_LIB`, `CIN_CATEGORIE_FILM_LIB` (libellé de l'état). Joué sur la base locale.
- [x] Données initiales : 1 cinéma (« Cinéma principal », Antananarivo), 3 classes (Standard 10 000 Ar jaune, Moyen 15 000 Ar vert, Premium 20 000 Ar rouge — **prix à ajuster dans l'appli**), 7 catégories, paramètre `DELAI_EXPIRATION_MIN` = **30**.
- [x] Classes Java : `cinema.salle.CinCinema` (+ `Lib`), `cinema.salle.CinClassePlace` (+ `Lib`), `cinema.film.CinCategorieFilm` (+ `Lib`), `cinema.film.CinActeur`, `cinema.utils.CinParametre` (+ `getDelaiExpirationMinutes()` pour l'étape 6), `cinema.utils.CinUtils`.
- [x] Pages saisie / liste / fiche / modif pour cinémas, classes de place (sélecteur de couleur + pastille de couleur dans liste et fiche), catégories, acteurs ; liste / fiche / modif pour les paramètres (pas de saisie ni de suppression).
- [x] Contrôles (Java) : libellé / nom obligatoire, **pas de doublon** (sans tenir compte des majuscules), prix de classe > 0, couleur au format `#RRGGBB`, état Actif / Inactif, naissance pas dans le futur, délai d'expiration entier ≥ 0, paramètre non supprimable.
- [x] Menus : **Cinéma → Configurations →** Cinémas / Classes de place / Catégories de film / Acteurs (Saisie, Liste) + Paramètres. Carte « Configurations » sur l'accueil cinéma.
- [x] Tests faits par moi : compilation Java, compilation des 20 JSP (conversion en Java), 12 tests Java contre la base avec ROLLBACK, scripts rejoués depuis zéro (reset → étape 0 → étape 1).
- [ ] **À tester par toi dans WildFly** : `ant -f build.xml deploy`, reconnexion, puis saisie / liste / fiche / modification / suppression de chaque référentiel (voir `TEST/CINEMA/ETAPE-1/README.md`).

Remarques techniques découvertes pendant l'étape :

- La modification standard (`apresTarif.jsp` → `UserEJB.updateObject`) **n'appelle pas `controlerUpdate`** : les contrôles de modification sont dans une surcharge de `updateToTableWithHisto`.
- APJ insère **toutes** les colonnes : une colonne vide est enregistrée à NULL même si la table a un `DEFAULT`. `DATE_CREATION` est donc remplie dans `controler`.

### Étape 2 : Salles et places — ✅ FAIT (11/11/2026, livraison `TEST/CINEMA/ETAPE-2/`)

- [x] `data/cinema/etape-2-salles.sql` : tables `CIN_SALLE`, `CIN_PLACE` (suppression en cascade des places avec la salle) + vues `CIN_SALLE_LIB` (nom du cinéma, places en service), `CIN_PLACE_LIB` (classe, couleur, prix) + menus **Cinéma → Salles → Saisie / Liste**. Joué sur la base locale.
- [x] `CinSalle` (`ClassMAPTable`, pas `ClassMere` : les places ne se saisissent pas ligne par ligne) : à la création, **génération automatique des places** (`NB_RANGEES` × `NB_COLONNES`, numéros A1, A2…, classe active la moins chère = Standard), dans la même transaction. Capacité = rangées × colonnes, calculée par le Java.
- [x] Contrôles : nom obligatoire et unique dans le cinéma, cinéma actif, 1 à 26 rangées (A à Z), 1 à 40 places par rangée, au moins une classe de place active.
- [x] `salle-liste.jsp` : salle, cinéma, rangées, places / rangée, capacité, places en service, état ; filtres nom, cinéma, capacité min / max, état ; clic droit « plan des places ».
- [x] `salle-saisie.jsp` : cinéma (actifs seulement), nom, rangées, colonnes, capacité affichée en direct.
- [x] `salle-fiche.jsp` : infos + **plan de salle coloré** (fragment `cinema/inc/plan-salle.jspf`, réutilisable pour la réservation) + légende avec prix et nombre de places par classe.
- [x] `salle-plan.jsp` (remplace l'idée de `salle-modif` pour les places) : pinceaux (une classe ou « Hors service »), clic sur une place, une lettre (toute la rangée) ou un numéro (toute la colonne) → `apres-salle-plan.jsp` → `CinSalle.modifierPlaces` (vérifie que chaque place est de la salle et chaque classe active).
- [x] `salle-modif.jsp` : nom, cinéma, état. **Structure (rangées / colonnes) non modifiable** après la création (champ en lecture seule + contrôle Java) : supprimer et recréer la salle.
- [x] Places **hors service** (siège cassé) : grisées sur le plan, à exclure de la réservation à l'étape 6.
- [x] Tests faits par moi : compilation Java + 26 JSP, 17 tests Java avec ROLLBACK, rendu HTML du plan vérifié, scripts rejoués depuis zéro (reset → étapes 0, 1, 2).
- [ ] **À tester par toi dans WildFly** (voir `TEST/CINEMA/ETAPE-2/README.md`).
- [x] Fait à l'étape 5 : une salle qui a des diffusions ne peut pas être supprimée (message clair, la passer en Inactive).
- [ ] À faire à l'étape 6 : interdire la mise hors service d'une place déjà réservée pour une séance à venir.

### Étape 3 : Films — ✅ FAIT (11/11/2026)

- [x] `data/cinema/etape-3-films.sql` : tables `CIN_FILM`, `CIN_FILM_PHOTO` (photo supprimée avec le film) + vue `CIN_FILM_LIB` (catégorie, acteur, durée « 2 h 05 », présence d'une photo) + menus **Cinéma → Films → Saisie / Liste**. Joué sur la base locale.
- [x] Décisions : **photo stockée dans la base** (BLOB, JPG / PNG / WEBP, 2 Mo max, format reconnu sur le contenu du fichier) et **ajoutée depuis la fiche du film** (pas dans le formulaire de saisie).
- [x] `film-saisie.jsp` : titre, catégorie (actives), acteur principal, durée en minutes, PA, description, état.
- [x] `film-liste.jsp` (maquette) : cartes avec vignette, titre (acteur), catégorie, description, durée, bouton Détail ; filtres titre / catégorie / acteur / durée min-max / état ; pagination APJ.
- [x] `film-fiche.jsp` (maquette) : photo en grand avec l'état, infos, ajouter / changer / supprimer la photo, Modifier, Supprimer.
- [x] `film-modif.jsp`.
- [x] Servlet `arbiochem-war/src/java/cinema/servlet/CinFilmPhotoServlet` (`/cinema/film-photo`) : GET = image (ou « Pas de photo »), POST = enregistrer / supprimer ; réservée aux utilisateurs connectés.
- [x] Contrôles (Java) : titre obligatoire, catégorie active, acteur existant, durée 1 à 600 min, PA ≥ 0, description ≤ 1000 caractères.
- [x] Tests faits par moi : compilation Java + servlet + 30 JSP, 16 tests Java avec ROLLBACK, test des photos de 300 octets à 2 Mo (relues identiques), scripts rejoués depuis zéro (étapes 0 à 3), tests des étapes 1 et 2 relancés.
- [ ] **À tester par toi dans WildFly** : saisie d'un film, ajout / changement / suppression de la photo, liste en cartes (voir le tableau en bas de `instruction/CINEMA.md` §6 ter).

Problème découvert : le pilote Oracle du projet (`ojdbc6-11.jar`) est très ancien. `setBinaryStream` / `setBytes` échouent au-delà de quelques Ko (ORA-01460) et `getBytes` sur un BLOB renvoie le pointeur au lieu du contenu. `CinFilmPhoto` écrit donc avec `EMPTY_BLOB()` + `SELECT ... FOR UPDATE` + `getBinaryOutputStream()`, et lit avec `getBlob()`.

### Étape 4 : Achats (films et matériel) → sortie de caisse — ✅ FAIT (11/11/2026)

- [x] `data/cinema/etape-4-achats.sql` : tables `CIN_ACHAT` (mère) et `CIN_ACHAT_FILLE` (lignes FILM / MATERIEL) + vues `CIN_ACHAT_LIB`, `CIN_ACHAT_FILLE_LIB` + **caisse `CAICINEMA` « Caisse Cinéma »** ajoutée dans la table `CAISSE` + menus **Cinéma → Achats → Saisie / Liste**. Joué sur la base locale.
- [x] Saisie mère / lignes (`PageInsertMultiple` → `apresMultiple.jsp`) : date, fournisseur, caisse (Caisse Cinéma par défaut, toutes les caisses actives proposées), mode de paiement (espèce par défaut), remarque ; 8 lignes (type, film, désignation, quantité, prix unitaire), total en direct. Les lignes vides sont ignorées. Un film doit exister avant d'être acheté.
- [x] **Au visa** (`CinAchat.validerObject`, même transaction) : achat à l'état 11, **mouvement de caisse visé** dans `MOUVEMENTCAISSE` (DEBIT = montant, caisse, mode, `IDORIGINE` = id de l'achat), id du mouvement gardé dans `CIN_ACHAT.IDMVTCAISSE`, et **le PA des films achetés prend le prix de la ligne**.
- [x] **Pas de contrôle de solde** : l'achat est toujours accepté (décision).
- [x] Annulation (état 0) possible seulement avant le visa ; un achat visé ne peut être ni annulé ni supprimé, ni générer deux sorties de caisse.
- [x] Liste des achats (filtres date, fournisseur, caisse, montant, état ; total des montants) et fiche (lignes, boutons Viser / Annuler, lien vers le mouvement de caisse).
- [x] Tests faits par moi : compilation (21 classes, 33 JSP), 18 tests Java avec ROLLBACK (dont le visa réel avec `MvtCaisse`), scripts rejoués depuis zéro (étapes 0 à 4, la suppression nettoie aussi la Caisse Cinéma), tests des étapes 1 à 3 relancés.
- [ ] **À tester par toi dans WildFly** (tableau en bas de la section « Étape 4 » de `instruction/CINEMA.md`).

Choix et constats de l'étape :

- La sortie de caisse est un mouvement **visé dans `MOUVEMENTCAISSE` sans écriture comptable générale** : `MvtCaisse.validerObject` n'est pas appelé, car il exige un tiers comptable (fournisseur avec compte 401…) et lance journal + lettrage. La comptabilité complète pourra être ajoutée plus tard si besoin.
- La première sortie d'une caisse sans report crée automatiquement un report de caisse (comportement standard de `MvtCaisse.createObject`).
- Dans la base locale, la vue `V_ETATCAISSE` (solde des caisses) ne compte que les mouvements qui ont un `IDREPORT`, ce qu'aucun mouvement n'a : le solde de l'écran Caisse existant n'est pas fiable. Le tableau de bord cinéma (étape 8) calculera son propre solde à partir de `MOUVEMENTCAISSE`.
- Pas de page de modification d'un achat en v1 : avant le visa, l'annuler et le ressaisir.

### Étape 5 : Diffusions (séances) — ✅ FAIT (11/11/2026)

- [x] `data/cinema/etape-5-diffusions.sql` : table `CIN_DIFFUSION` (film, salle, date, heure `HH:MM`, état 1 programmée / 0 annulée) + vue `CIN_DIFFUSION_LIB` (film, durée, salle, cinéma, début / fin calculés, places en service, statut Programmée / En cours / Terminée / Annulée) + menus **Cinéma → Diffusions → Saisie / Liste / Calendrier**. Joué sur la base locale.
- [x] Saisie (`diffusion-saisie.jsp`) : film actif, salle active, date, heure (champ horaire) ; pré-remplissage possible par `idfilm` / `idsalle` dans l'URL.
- [x] Contrôles (`CinDiffusion`) : film et salle actifs, salle avec au moins une place en service, heure valide (normalisée en HH:MM), **séance dans le futur**, **pas de chevauchement** dans la même salle (début < fin de l'autre et fin > début de l'autre, sans marge ; deux séances qui se touchent sont acceptées ; une séance annulée libère le créneau). Message : « La salle X est déjà occupée le … de 18:00 à 20:00 par « Film » ».
- [x] Une séance **commencée ou terminée** ne se modifie plus et ne se supprime plus. Annulation = passer l'état à « Annulée » dans la modification.
- [x] Liste en cartes (maquette « diffusion ») : vignette du film, titre, salle, date, heure début – fin (durée), statut ; filtres date min / max, film, salle, état ; pagination APJ.
- [x] Fiche : affiche du film, infos, **plan de la salle** (fragment `plan-salle.jspf`), Modifier / annuler, Supprimer ; bouton « Réserver » prévu pour l'étape 6.
- [x] **Calendrier** de la semaine (`diffusion-calendrier.jsp`) : lundi → dimanche, semaine précédente / suivante, une couleur par salle, séances annulées barrées, jour courant encadré, clic → fiche.
- [x] Bonus : une salle ou un film qui a des diffusions (ou un film présent dans un achat) ne peut pas être supprimé (message clair au lieu de l'erreur Oracle ORA-02292).
- [x] Tests faits par moi : compilation (23 classes, 38 JSP), 21 tests Java + 2 tests de suppression, tous les tests des étapes 1 à 5 lancés deux fois de suite sans laisser de données, scripts rejoués depuis zéro (étapes 0 à 5).
- [ ] **À tester par toi dans WildFly** (tableau en bas de la section « Étape 5 » de `instruction/CINEMA.md`).

Problème découvert : `ClassMAPTable.deleteToTable` (appelé par `deleteToTableWithHisto`) fait un **`commit`** de toute la transaction. Mes tests qui finissaient par une suppression APJ avaient donc laissé des données de test en base (une salle, deux acteurs « Rabe Hery », la catégorie Drame inactive) : nettoyées, tests corrigés. Dans l'appli ce n'est pas gênant (une suppression via `apresTarif.jsp` est seule dans sa transaction), mais il ne faut **jamais** appeler une suppression APJ au milieu d'un traitement qui doit pouvoir être annulé (à retenir pour l'étape 6).

### Étape 6 : Réservation (ticket)

- [ ] Tables `CIN_TICKET`, `CIN_TICKET_DETAIL` + vues `CIN_PLACE_DIFFUSION`, `CIN_TICKET_LIB`.
- [ ] Page `reservation-saisie.jsp` (maquette du bas) : en-tête diffusion (film, titre, salle, heure, durée), client (choix/autocomplete + bouton « + » pour créer un client), **plan de salle** où les places réservées/payées sont barrées (✗) et non cliquables, légende avec les prix, bouton Valider. Total recalculé en direct.
- [ ] Page relais `apres-reservation.jsp` → `CinTicket.createObject` : crée la mère + une fille par place, fige les prix.
- [ ] Contrôles (Java, dans la transaction) : au moins une place, places de la bonne salle, **place encore libre pour cette diffusion** (re-vérifiée au moment de l'insertion, pour deux caissiers en même temps), diffusion pas encore commencée ni annulée.
- [ ] **Expiration** : ticket non payé et `SYSDATE > début de séance − 30 min` (valeur lue dans `CIN_PARAMETRE`) → état « expiré », calculé dans la vue (pas besoin de tâche planifiée), places libérées automatiquement dans `CIN_PLACE_DIFFUSION`.
- [ ] Liste des réservations (client, date réservation, diffusion, salle, date séance, montant, état) + filtres.
- [ ] Fiche réservation : infos + liste des places (numéro, classe, prix) + boutons Payer / Annuler.

### Étape 7 : Paiement multi-mode → facture + entrée de caisse

- [ ] Tables `CIN_PAIEMENT`, `CIN_PAIEMENT_DETAIL`, `CIN_FACTURE`, `CIN_FACTURE_DETAIL` + vues `CIN_PAIEMENT_LIB`, `CIN_FACTURE_LIB`.
- [ ] Page `paiement-saisie.jsp` depuis la fiche ticket : montant à payer affiché, tableau de lignes (mode de paiement, caisse pré-remplie selon le mode mais modifiable, montant), reste à répartir recalculé en direct.
- [ ] `CinPaiement.createObject` / `validerObject` (une seule transaction) :
  - [ ] ticket ni payé, ni annulé, ni expiré ;
  - [ ] **somme des lignes = montant du ticket** (paiement en une seule fois, sinon refus) ;
  - [ ] un `MvtCaisse` **CREDIT** par ligne (`IDMODEPAIEMENT`, `IDCAISSE`, `IDTIERS` = client, `IDORIGINE` = id du paiement), id du mouvement stocké dans `IDMVTCAISSE` ;
  - [ ] **génération automatique de la facture** `CIN_FACTURE` (numéro séquentiel, une ligne par place) ;
  - [ ] ticket passé à l'état « payé ».
- [ ] Liste des tickets (payé / réservé), fiche ticket (+ date de paiement, détail des modes, lien vers la facture).
- [ ] Liste et fiche des factures cinéma (`cinema/facture/`).
- [ ] Page d'impression du ticket et de la facture (mise en page imprimable) avec un bouton **« Exporter en PDF »**.

### Étape 8 : Consultation client et suivi

- [ ] Fiche client cinéma (`cinema/client/client-fiche.jsp`) : ses réservations et ses paiements (le client est la table `CLIENT` existante, les pages client existantes ne sont pas modifiées).
- [ ] Tableau de bord cinéma : recettes par jour / film / salle, taux de remplissage par diffusion, achats vs recettes (solde de la caisse cinéma).

### Étape 9 : Recette finale

- [ ] Scénario complet : achat d'un film → diffusion → réservation de 3 places (classes différentes) → paiement espèce + mobile money → facture générée → 1 débit + 2 crédits dans `MOUVEMENTCAISSE`.
- [ ] Cas limites : place déjà prise, chevauchement de séances, paiement incomplet refusé, ticket expiré non payable, annulation.
- [ ] Vérifier que le reste de l'appli n'est pas impacté (Vente, Caisse, Ferme…).
- [ ] `instruction/CINEMA.md` à jour, `cinema-reset.sql` testé.
- [ ] **Livraison unique** dans `TEST/CINEMA/` : tous les fichiers du module (Java, JSP, scripts `data/cinema/` dans l'ordre, `instruction/CINEMA.md`) + README global (installation + tests de chaque étape).

---

## 6. Correspondance pages ↔ maquettes

| Maquette (photo) | Page | Étape |
|---|---|---|
| film_liste | `cinema/film/film-liste.jsp` | 3 |
| film_saisie | `cinema/film/film-saisie.jsp` | 3 |
| film_fiche | `cinema/film/film-fiche.jsp` | 3 |
| salle_liste | `cinema/salle/salle-liste.jsp` | 2 |
| salle_saisie (plan + classes) | `cinema/salle/salle-saisie.jsp` + `salle-modif.jsp` | 2 |
| salle_fiche (plan coloré) | `cinema/salle/salle-fiche.jsp` | 2 |
| diffusion | `cinema/diffusion/diffusion-liste.jsp` | 5 |
| réservation (client + plan + ✗ réservé) | `cinema/reservation/reservation-saisie.jsp` | 6 |

---

## 7. Points techniques à surveiller

- Le plan de salle et le choix multiple de places ne sont pas fournis par APJ : HTML/JS fait main dans un fragment `.jspf`, envoyé vers une page relais (comme `apres-viser-avoir.jsp` pour AVOIR-FC).
- Les noms des colonnes SQL, des attributs Java et des champs JSP doivent être identiques.
- Encodage UTF-8 pour toutes les nouvelles JSP.
- Pas de valeur saisie par l'utilisateur concaténée dans un `aWhere` sans contrôle.
- Montants en Ariary uniquement (comme le reste de la caisse).

---

## 8. Ordre de dépendance

```text
Étape 0 ─► 1 ─► 2 (salles) ─┐
              └► 3 (films) ─┼─► 5 (diffusions) ─► 6 (réservation) ─► 7 (paiement) ─► 8 ─► 9
                   └► 4 (achats)
```

---

## 9. Hors périmètre de la version 1

- Espace client en ligne (le client réserve lui-même sur un site) : ici c'est l'**administrateur / le caissier** qui saisit pour le client.
- Remboursement d'un ticket payé, promotions, abonnements, tarifs selon l'heure.

---

## 10. Décisions prises (11/11/2026)

| Sujet | Décision |
|---|---|
| Achat de film / matériel | Table dédiée `CIN_ACHAT` + `CIN_ACHAT_FILLE` ; le visa crée un **débit** dans `MOUVEMENTCAISSE`. |
| Facture client | Table dédiée `CIN_FACTURE` + `CIN_FACTURE_DETAIL`, générée au paiement complet. `VENTE` / `FACTURECLIENT` ne sont pas utilisées. |
| Caisse | Choisie **par ligne** (paiement ou achat), pré-remplie selon le mode de paiement. |
| Prix d'une place | Selon la **classe seule** (prix de la place, repris de sa classe). Pas de majoration par séance en v1. |
| Client | Table `CLIENT` existante. |
| Paiement | Une seule fois, plusieurs modes, somme = montant du ticket. |
| Expiration | Réservation non payée expirée **30 min** avant le début de la séance ; valeur modifiable dans `CIN_PARAMETRE`. |
| Achat et solde de caisse | Achat d'un film **toujours accepté**, sans contrôle de solde. |
| Menu | CINEMA **tout en haut**, avant Ferme (`RANG = 0`). |
| Chevauchement des séances | Refusé dans la même salle, **sans marge de nettoyage** en v1. |
| Impression | Page imprimable du ticket / de la facture + bouton « Exporter en PDF ». |

## 11. Perspectives d'avenir (après la v1)

- Marge de nettoyage paramétrable entre deux séances dans la même salle (ex. 15 min).
- Tarifs selon la séance (soirée, 3D…) en plus du prix de la classe.
- Espace client en ligne, remboursement, promotions, abonnements (voir §9).
