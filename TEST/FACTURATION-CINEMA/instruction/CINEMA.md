# CINEMA : module de gestion d'un cinéma

Dernière mise à jour : 12/11/2026 (étape 11 : la facturation du cinéma passe par la facturation existante, VENTE)

Plan de travail et décisions : `TEST/CINEMA/TO-DO-CINEMA-1.md`. Livraison complète : `TEST/CINEMA/ETAPE-1-9/`.

---

## 1. Principe

Le cinéma est un module **séparé** du reste de l'ERP : rien de l'existant n'est modifié. Il réutilise seulement :

| Existant | Usage |
|---|---|
| `VENTE` / `VENTE_DETAILS` (`vente.VenteArbiochem`) | **facture d'un ticket** (étape 11) : créée et visée au clic sur « Payer », payée sur la fiche de la vente |
| `AS_INGREDIENTS` | un produit « Place <classe> » par classe de place (catégorie service, compte 706, TVA 0) |
| `CLIENT` | client qui réserve (doit avoir son compte comptable 411..., donné par la fiche client) |
| `MODEPAIEMENT` | mode de chaque ligne de paiement |
| `CAISSE` | caisse choisie par ligne (paiement ou achat) |
| `MOUVEMENTCAISSE` (`caisse.MvtCaisse`) | `DEBIT` = sortie (achat), `CREDIT` = entrée (ticket payé) |
| `MENUDYNAMIQUE` | menu CINEMA |

## 2. Où se trouve quoi

| Partie | Emplacement |
|---|---|
| Servlets | `arbiochem-war/src/java/cinema/servlet/` (`@WebServlet`, rien à déclarer dans `web.xml`) : `/cinema/film-photo` |
| Java | `arbiochem-ejb/src/java/cinema/` : `salle`, `film`, `achat`, `diffusion`, `reservation`, `paiement` (paiement + facture), `utils` |
| JSP | `arbiochem-war/web/pages/cinema/` : `salle/`, `film/`, `achat/`, `diffusion/`, `reservation/`, `paiement/`, `facture/`, `client/`, `inc/` (fragments) |
| SQL | `data/cinema/` : `etape-n-*.sql` (à jouer dans l'ordre) et `cinema-reset.sql` |
| Base | tables et vues `CIN_*`, séquences `SEQ_CIN_*`, fonctions `GETSEQCIN*` |
| Clés primaires | préfixes commençant par `CIN` (ex. `CINSAL…`), pour retrouver les mouvements de caisse du cinéma avec `IDORIGINE LIKE 'CIN%'` |
| Menu | racine `MENDYNCINEMA` (niveau 1, rang 0 = tout en haut), sous-menus `MENDYNCINEMAnn` |

Règles : `apresTarif.jsp` et `apresMultiple.jsp` ne sont jamais modifiés ; la logique est dans les classes Java ; JSP en UTF-8.

**Données sans accents** (décision du 11/11/2026) : toutes les données créées par les scripts (données de départ, données de démonstration, données de test) et les libellés générés par le Java et enregistrés en base (désignations des mouvements de caisse, lignes de facture…) s'écrivent **sans accent et sans entité HTML** : « Cinema principal », « Comedie », « Nuit a Tana », « Achat cinema … ». Les accents restent permis dans le texte d'interface (pages, menus, messages d'erreur, libellés d'état calculés par les vues).

**Listes et champs standard** : les listes utilisent le tableau APJ (`pr.getTableau()`), jamais un affichage fait main après `getTableauRecap()`. Les champs de saisie : utiliser les champs APJ comme les autres pages de l'appli (ex. client : `setPageAppelComplete("client.Client", "id", "Client")` + `setPageAppelInsert("client/client-saisie.jsp", ...)`), plutôt que des recherches faites à la main.

## 3. Scripts SQL

Les scripts commencent par `SET DEFINE OFF;` car les libellés contiennent des entités HTML (`&eacute;`) : sans cela, SQL*Plus / SQL Developer demandent une valeur de variable et enregistrent un libellé abîmé (`Cin;ma`).

| Script | Contenu |
|---|---|
| `etape-0-menu.sql` | menu racine **Cinéma** (icône `movie`) + sous-menu **Accueil cinéma** + droit d'accès `USERMENU` (`UMCINEMA01`) |
| `etape-1-referentiels.sql` | référentiels : tables `CIN_CINEMA`, `CIN_CLASSE_PLACE`, `CIN_CATEGORIE_FILM`, `CIN_ACTEUR`, `CIN_PARAMETRE`, vues `*_LIB`, données initiales, menus Configurations |
| `etape-2-salles.sql` | tables `CIN_SALLE`, `CIN_PLACE`, vues `CIN_SALLE_LIB`, `CIN_PLACE_LIB`, menus Salles |
| `etape-3-films.sql` | tables `CIN_FILM`, `CIN_FILM_PHOTO`, vue `CIN_FILM_LIB`, menus Films |
| `etape-4-achats.sql` | tables `CIN_ACHAT`, `CIN_ACHAT_FILLE`, vues `CIN_ACHAT_LIB`, `CIN_ACHAT_FILLE_LIB`, caisse `CAICINEMA`, menus Achats |
| `etape-5-diffusions.sql` | table `CIN_DIFFUSION`, vue `CIN_DIFFUSION_LIB`, menus Diffusions (saisie, liste, calendrier) |
| `etape-6-reservations.sql` | tables `CIN_TICKET`, `CIN_TICKET_DETAIL`, vues `CIN_TICKET_LIB`, `CIN_TICKET_DETAIL_LIB`, `CIN_PLACE_DIFFUSION`, menus Réservations |
| `etape-7-paiements.sql` | tables `CIN_MODE_CAISSE`, `CIN_PAIEMENT`, `CIN_PAIEMENT_DETAIL`, `CIN_FACTURE`, `CIN_FACTURE_DETAIL`, vues `*_LIB`, mode Mobile money `MPCINMOB`, menus Paiements / Factures / Caisses par mode |
| `etape-8-clients-tableau.sql` | vue `CIN_CLIENT_LIB`, menus Clients et Tableau de bord |
| `etape-9-reinitialisation.sql` | menu « Réinitialiser les données » (le traitement est dans `CinReinitialisation`) |
| `etape-10-films-realisateur.sql` | colonnes `CIN_FILM.REALISATEUR` et `CIN_FILM.CLASSIFICATION` (Tous publics, -12, -16, -18), acteur principal facultatif, vue `CIN_FILM_LIB` recréée |
| `etape-11-facturation-vente.sql` | facturation par `VENTE` : `CIN_CLASSE_PLACE.IDPRODUIT` + produits « Place ... », `CIN_TICKET.IDVENTE`, paramètre `MAGASIN_VENTE`, vues `CIN_TICKET_LIB`, `CIN_PLACE_DIFFUSION`, `CIN_FACTURE_VENTE`, `CIN_RECETTE`, `CIN_CLIENT_LIB`, retrait des menus Paiements / Factures / Caisses par mode |
| `donnees-alea-12-11-26.sql` | **programme du 16 au 30/11/2026** (photos `TEST/ALEA-12-11-26/PHOTO`, après les étapes 0 à 10, rejouable) : classes Standard 15 000 / Confort 20 000 / VIP 30 000, salles A, B, C (4 rangées × 5), 3 films à 0 Ar, 41 séances |
| `donnees-demo.sql` | **données de démonstration** (après les étapes 0 à 7, rejouable) : acteurs, films, salles, achats, séances, clients `CLICINDEMO...`, tickets, un ticket payé avec sa facture |
| `cinema-reset.sql` | supprime tous les objets `CIN_*` / `SEQ_CIN_*` / `GETSEQCIN*`, les menus `MENDYNCINEMA%`, la caisse `CAICINEMA` avec ses reports et mouvements, les mouvements de caisse `IDORIGINE LIKE 'CIN%'`, les clients `CLICIN%` et le mode `MPCINMOB`. Testé le 11/11/2026. |

## 4. Avancement

| Étape | Contenu | État |
|---|---|---|
| 0 | Socle : packages, dossiers, menu, accueil, reset, doc | fait (11/11/2026) |
| 1 | Référentiels | fait (11/11/2026) |
| 2 | Salles et places | fait (11/11/2026) |
| 3 | Films | fait (11/11/2026) |
| 4 | Achats → sortie de caisse | fait (11/11/2026) |
| 5 | Diffusions | fait (11/11/2026) |
| 6 | Réservations | fait (11/11/2026) |
| 7 | Paiement → facture + entrée de caisse | fait (11/11/2026) |
| 8 | Consultation client, tableau de bord | fait (11/11/2026) |
| 9 | Recette finale, réinitialisation, livraison | fait (11/11/2026) |
| 10 | Données du programme de novembre (ALEA du 12/11/2026) | fait (12/11/2026) |
| 11 | Facturation par la facturation existante (VENTE) | fait (12/11/2026) |

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
- **Liste** : `film-liste.jsp` utilise le tableau APJ standard (`pr.getTableau()`), comme toutes les listes de l'appli ; la photo se voit sur la fiche. (Une première version en cartes faites main a été abandonnée le 11/11/2026 : placée après le récapitulatif de `PageRecherche`, elle s'affichait écrasée sur le côté.)
- **Durée** saisie en minutes, affichée « 2 h 05 » (`DUREELIB`).

Tests à faire dans WildFly :

| Écran | À vérifier |
|---|---|
| Films → Saisie | titre, catégorie, réalisateur, acteur (facultatif), classification, 125 min, PA → la fiche s'ouvre avec « Pas de photo » |
| Fiche → Ajouter une photo | choisir un JPG ou PNG → l'affiche apparaît ; « Changer la photo » la remplace ; « Supprimer la photo » remet « Pas de photo » |
| Fiche → photo refusée | un PDF ou un fichier renommé en .jpg → message « Format non accepté » ; une image de plus de 2 Mo → « L'image dépasse 2 Mo » |
| Films → Liste | tableau standard : titre, acteur, catégorie, « 2 h 05 », prix d'achat, état ; clic sur l'ID → fiche ; filtres et pagination |
| Fiche → Modifier | durée 700 → refusée ; catégorie inactive non proposée |

## 6 quater. Étape 4 : achats → sortie de caisse

| Table | Classe Java | Préfixe id | Pages |
|---|---|---|---|
| `CIN_ACHAT` (vue `CIN_ACHAT_LIB`) | `cinema.achat.CinAchat` (`ClassMere`) / `CinAchatLib` | `CINACH` | `cinema/achat/achat-{saisie,liste,fiche}.jsp` |
| `CIN_ACHAT_FILLE` (vue `CIN_ACHAT_FILLE_LIB`) | `cinema.achat.CinAchatFille` (`ClassFille`, liaison `idachat`) / `CinAchatFilleLib` | `CINACF` | lignes de la saisie / fiche |
| `CAISSE` (existante) | — | `CAICINEMA` | caisse « Caisse Cinéma » ajoutée par le script |

- **Cycle** : saisie → état 1 ; **Viser** (`apresTarif.jsp`, `acte=valider`) → état 11 + sortie de caisse ; **Annuler** (`acte=annuler`) → état 0, seulement avant le visa (`controleAnnule`). Un achat visé ne se supprime pas (`controlerDelete`).
- **Saisie** : `CinAchat.createObject` retire les lignes vides, contrôle chaque ligne (`CinAchatFille.verifier` : film existant pour FILM, désignation pour MATERIEL, quantité > 0, prix ≥ 0) et calcule `MONTANT` = Σ quantité × prix.
- **Visa** : `CinAchat.validerObject` → `super.validerObject` (état 11, lignes comprises) → `genererSortieCaisse` : `MvtCaisse` avec `DEBIT` = montant, `IDCAISSE`, `IDMODEPAIEMENT`, `IDORIGINE` = id de l'achat, `IDDEVISE` = AR, puis état 11 ; id gardé dans `CIN_ACHAT.IDMVTCAISSE`. Ensuite `CIN_FILM.PA` = prix de la ligne pour les films achetés. Tout est dans la transaction du visa.
- **Pas d'écriture comptable générale** (choix v1) : `MvtCaisse.validerObject` n'est pas appelé (il exige un tiers avec compte comptable et fait journal + lettrage).
- **Retrouver les sorties de caisse du cinéma** : `SELECT * FROM MOUVEMENTCAISSE WHERE IDORIGINE LIKE 'CINACH%'`.

Tests à faire dans WildFly :

| Écran | À vérifier |
|---|---|
| Achats → Saisie | fournisseur, Caisse Cinéma et espèce proposées par défaut ; ligne 1 : choisir un film (le type passe à Film), prix 2 000 000 ; ligne 2 : Matériel « Fauteuils », 10 × 150 000 ; le total affiche 3 500 000 → Enregistrer → fiche, état Créé |
| Saisie sans aucune ligne remplie | refusée « Ajoutez au moins une ligne » |
| Fiche → Viser | confirmation « 3 500 000 Ar vont sortir de la caisse… » → état Visé, lien « Voir le mouvement de caisse » (débit 3 500 000 sur Caisse Cinéma) |
| Fiche du film acheté | le prix d'achat vaut 2 000 000 |
| Achat visé | plus de bouton Viser / Annuler |
| Autre achat → Annuler | état Annulé, aucun mouvement de caisse |
| Liste des achats | filtres, total des montants en bas |

## 6 quinquies. Étape 5 : diffusions

| Table | Classe Java | Préfixe id | Pages |
|---|---|---|---|
| `CIN_DIFFUSION` (vue `CIN_DIFFUSION_LIB`) | `cinema.diffusion.CinDiffusion` / `CinDiffusionLib` | `CINDIF` | `cinema/diffusion/diffusion-{saisie,liste,fiche,modif,calendrier}.jsp` |

- **Horaire** : `DATY` (jour) + `HEURE` (texte `HH:MM`, contrainte SQL). La vue calcule `DATE_DEBUT`, `DATE_FIN` = début + durée du film, `HEURE_FIN` et le statut (`ETATLIB`) : Annulée (état 0), Terminée (fin passée), En cours, Programmée.
- **Chevauchement** (`CinDiffusion.verifierChevauchement`) : refus si une autre séance programmée de la même salle vérifie `date_debut < fin` et `date_fin > debut`. Pas de marge de nettoyage en v1 (perspective d'avenir).
- **Création** : séance dans le futur, film actif, salle active avec au moins une place en service. **Modification / suppression** : refusées si la séance a déjà commencé (`dejaCommencee`). Annuler = état 0 via la modification (le contrôle de chevauchement ne s'applique pas à une annulation).
- **Calendrier** : `CinDiffusion.getDiffusionsEntre(debut, fin, idCinema, c)` ; paramètre `semaine=AAAA-MM-JJ`.
- **Protection des suppressions** : `CinSalle.controlerDelete` (salle avec diffusions) et `CinFilm.controlerDelete` (film avec diffusions ou dans un achat).

Tests à faire dans WildFly :

| Écran | À vérifier |
|---|---|
| Diffusions → Saisie | film de 2 h, salle A, demain 18:00 → fiche : début 18:00, fin 20:00, plan de la salle |
| Nouvelle saisie | même salle demain 19:00 → refusée « La salle … est déjà occupée … de 18:00 à 20:00 » ; même salle 20:00 → acceptée ; autre salle 18:30 → acceptée |
| Saisie dans le passé | refusée « La séance doit être dans le futur » |
| Fiche → Modifier / annuler | état « Annulée » → la carte apparaît barrée ; le créneau 18:00 redevient libre |
| Diffusions → Liste | tableau standard : film, salle, date, début, fin, durée, places, statut ; clic sur l'ID → fiche ; filtres |
| Diffusions → Calendrier | séances de la semaine par jour, couleur par salle, semaine suivante / précédente |
| Salles → fiche d'une salle avec séances → Supprimer | refusé « Cette salle a des diffusions » |

## 6 sexies. Étape 6 : réservations

| Table / vue | Classe Java | Préfixe id | Pages |
|---|---|---|---|
| `CIN_TICKET` (vue `CIN_TICKET_LIB`) | `cinema.reservation.CinTicket` (`ClassMere`) / `CinTicketLib` | `CINTKT` | `cinema/reservation/reservation-{saisie,liste,fiche}.jsp`, `apres-reservation.jsp` |
| `CIN_TICKET_DETAIL` (vue `CIN_TICKET_DETAIL_LIB`) | `CinTicketDetail` (`ClassFille`, liaison `idticket`) / `CinTicketDetailLib` | `CINTKD` | places du ticket |
| vue `CIN_PLACE_DIFFUSION` | `CinPlaceDiffusion` (étend `CinPlaceLib`) | — | plan d'une séance |

- **États d'un ticket** : 1 réservé, 11 payé (étape 7), 0 annulé. **Expiré** = réservé et `SYSDATE > début de séance − DELAI_EXPIRATION_MIN` ; calculé dans `CIN_TICKET_LIB` (`ETATLIB`, `ACTIF`, `DATE_LIMITELIB`). Un ticket **actif** (payé, ou réservé non expiré) occupe ses places dans `CIN_PLACE_DIFFUSION` ; un ticket expiré ou annulé les libère.
- **Réserver** : `CinTicket.reserver(idDiffusion, idClient, idPlaces[], remarque, refUser)` : verrou `SELECT ... FOR UPDATE` sur la séance (deux caisses passent l'une après l'autre), contrôles (client, séance programmée, `reservationOuverte`, places de la salle, en service, libres), prix figés depuis la classe, insertion mère + places (`ClassMere.createObject`), commit.
- **Réservation ouverte** (`CinTicket.reservationOuverte`) : séance programmée et `SYSDATE <= début − délai`. Elle ferme au moment où un ticket non payé expirerait.
- **Annuler** : `apresTarif.jsp` `acte=annuler` → `controleAnnule` (refus si payé ou déjà annulé). Pas de suppression de ticket. `validerObject` refuse : le passage à « payé » se fera par le paiement (étape 7).
- **Plan d'une séance** : `CinTicket.getPlacesDiffusion(idDiffusion, c)` donne des `CinPlaceDiffusion` au fragment `plan-salle.jspf`, qui barre (✕) les places réservées / payées et ajoute `data-statut`, `data-prix`, `data-numero`. `request.setAttribute("cinTicketCourant", id)` encadre les places d'un ticket.
- **Client** : champ APJ standard, comme les autres saisies de l'appli (`PageInsert` sur `CinTicket`, champ `idclient` avec `setPageAppelComplete("client.Client", "id", "Client")` et bouton « + » `setPageAppelInsert("client/client-saisie.jsp", "idclient;idclientlibelle", "id;nom")`). La page est en deux colonnes : séance + places choisies + client à gauche, plan à droite. (L'ancienne servlet `/cinema/clients` a été supprimée.)
- **Protections ajoutées** : `CinDiffusion` (pas de modification / annulation avec réservations actives, pas de suppression avec tickets), `CinSalle.modifierPlaces` (pas de mise hors service d'une place réservée pour une séance à venir).

Tests à faire dans WildFly (après `donnees-demo.sql`) :

| Écran | À vérifier |
|---|---|
| Diffusions → fiche « Le Lémurien d'or » (demain 18:00) | plan : C5, C6, F4-F6 barrées ✕, F10 hachurée ; légende « Réservée (5) » ; bouton « Réserver des places » |
| Réserver des places | champ Client : taper « raz » → Razafy Nirina (même recherche que sur les autres pages ; « + » pour créer un client) ; cliquer A1 et D3 → « A1, D3 · Total 25 000 Ar » ; Valider → fiche du ticket, places encadrées sur le plan, « à payer avant le ... 17:30 » |
| Réserver une place barrée | impossible (le clic ne fait rien) |
| Deux onglets sur la même séance | réserver la même place dans les deux : le 2e reçoit « La place ... vient d'être prise » |
| Réservations → Liste | 5 tickets de démo : Réservé ×3 (+ le vôtre), Annulé, **Expiré** (séance « Rire en famille » dans 20 min) ; filtres |
| Fiche d'un ticket réservé → Annuler | statut Annulé, places de nouveau libres sur le plan |
| Nouvelle réservation (menu) | liste des séances ouvertes : la séance dans 20 min et celle d'hier n'y sont pas |
| Fiche de la séance de demain → Modifier / annuler | refusé tant qu'il y a des réservations actives |
| Salles → Salle 1 → Modifier le plan → mettre C5 hors service | refusé (place réservée) |
| Configurations → Paramètres → délai 30 → 60 | le ticket expire plus tôt (la vue recalcule tout de suite) ; remettre 30 |

## 6 septies. Étape 7 : paiement, facture, caisse

| Table | Classe Java | Préfixe id | Pages |
|---|---|---|---|
| `CIN_MODE_CAISSE` (vue `_LIB`) | `cinema.paiement.CinModeCaisse` / `CinModeCaisseLib` | `CINMCA` | `cinema/paiement/mode-caisse-{liste,saisie,modif}.jsp` |
| `CIN_PAIEMENT` (vue `_LIB`) | `CinPaiement` (`ClassMere`) / `CinPaiementLib` | `CINPAI` | `cinema/paiement/paiement-{saisie,liste,fiche}.jsp`, `apres-paiement.jsp` |
| `CIN_PAIEMENT_DETAIL` (vue `_LIB`) | `CinPaiementDetail` (`ClassFille`, liaison `idpaiement`) / `CinPaiementDetailLib` | `CINPAD` | lignes du paiement |
| `CIN_FACTURE` (vue `_LIB`) | `CinFacture` / `CinFactureLib` | `CINFAC`, numéro `FCaaaa-nnnnn` (séquence `SEQ_CIN_FACTURE_NUMERO`) | `cinema/facture/facture-{liste,fiche,impression}.jsp` |
| `CIN_FACTURE_DETAIL` | `CinFactureDetail` | `CINFAD` | lignes de la facture |

- **Payer** : `CinPaiement.payer(idTicket, modes[], caisses[], montants[], refUser)` (sa transaction) : `SELECT ... FOR UPDATE` sur le ticket ; refus si payé, annulé ou expiré ; lignes vides ignorées ; mode parmi les modes actifs de `CIN_MODE_CAISSE` ; caisse active ; **somme = montant du ticket** (tolérance 0,005) ; puis paiement + lignes (`ClassMere.createObject`), un `MvtCaisse` visé **CREDIT** par ligne (`CinCaisse.creerMouvementVise`, `IDORIGINE` = paiement, `IDTIERS` = client), facture + une ligne par place, ticket et places à l'état 11.
- **Mouvements de caisse du cinéma** : `cinema.utils.CinCaisse.creerMouvementVise` (achat : DEBIT ; paiement : CREDIT). Retrouver : `IDORIGINE LIKE 'CINACH%'` (sorties) et `IDORIGINE LIKE 'CINPAI%'` (entrées).
- **Impression** : `facture-impression.jsp` est une page autonome (nouvel onglet, sans menu, réservée aux utilisateurs connectés) : facture, modes de paiement, un billet par place ; « Exporter en PDF » = `window.print()` → « Enregistrer au format PDF ».
- **Montants saisis** : espaces (y compris insécables) acceptés, virgule = point.
- Un paiement ne s'annule pas, une facture ne se modifie pas et ne se supprime pas (v1).

Tests à faire dans WildFly (après `donnees-demo.sql`) :

| Écran | À vérifier |
|---|---|
| Réservations → ticket de Razafy Nirina (3 Premium, 60 000 Ar) → **Payer** | ligne 1 espèce + Caisse Cinéma + 60 000 ; changer en 40 000 → « Reste à répartir : 20 000 Ar », Valider grisé |
| Même écran, ligne 2 | Mobile money (caisse Mvola pré-remplie) 20 000 → « Compte juste » → Valider → facture `FCaaaa-00001` avec 3 lignes, message « Paiement enregistré » |
| Facture → Imprimer / exporter en PDF | nouvel onglet : facture + 3 billets ; « Exporter en PDF » → enregistrer en PDF |
| Paiements → Liste | « espèce 40 000 + Mobile money 20 000 », facture ; fiche → liens vers les 2 mouvements de caisse (crédit) |
| Ticket payé | statut Payé, liens Paiement / Facture, plus de bouton Annuler ; places « Payée » sur le plan de la séance |
| Ticket expiré (séance « Rire en famille ») | pas de bouton Payer |
| Configurations → Caisses par mode | changer la caisse du chèque, ou désactiver le virement → il n'est plus proposé au paiement |
| Facture de démo `FCaaaa-D0001` | espèce 10 000 + Mobile money 20 000, places E1 et E2 |

## 6 octies. Étape 8 : clients et tableau de bord

| Élément | Classe Java | Pages |
|---|---|---|
| vue `CIN_CLIENT_LIB` (lecture seule) | `cinema.reservation.CinClient` (`getTickets`, `getPaiements`) | `cinema/client/client-{liste,fiche}.jsp` |
| calculs du tableau de bord | `cinema.utils.CinTableauBord.calculer(debut, fin, c)` | `cinema/tableau/tableau-bord.jsp` |

- **Clients** : uniquement les clients qui ont au moins un ticket. La création / modification d'un client reste dans les pages client existantes (lien « Fiche client complète »).
- **Période** du tableau de bord (paramètres `debut`, `fin` au format AAAA-MM-JJ ; mois en cours par défaut) : recettes et places vendues = paiements de la période ; achats = achats visés de la période ; remplissage = séances programmées de la période. Réservations en attente et solde de la Caisse Cinéma = situation actuelle.
- **Solde de la Caisse Cinéma** = somme (crédit − débit) des mouvements visés de la caisse `CAICINEMA`, depuis le début.
- **Graphiques** : barres horizontales en HTML / CSS (pas de librairie) ; recettes par film = une seule mesure (une couleur, pas de légende) ; remplissage = payées (bleu) + réservées (orange) avec légende ; chaque graphique a un tableau de valeurs (« Voir le tableau ») et une infobulle au survol.

Tests à faire dans WildFly (après `donnees-demo.sql`) :

| Écran | À vérifier |
|---|---|
| Cinéma → Clients | 3 clients de démo ; Razafy Nirina : 2 tickets, 1 payé, 30 000 Ar ; clic sur l'ID → fiche |
| Fiche client | ses réservations et ses paiements, liens vers ticket / paiement / facture |
| Cinéma → Tableau de bord | recettes 30 000 Ar, places vendues 2, 3 réservations en attente (110 000 Ar), achats 4 300 000 Ar, solde Caisse Cinéma −4 290 000 Ar |
| Tableau de bord, graphiques | « Nuit a Tana » 30 000 Ar ; remplissage de la séance de demain 18:00 (réservées en orange) ; « Voir le tableau » |
| Payer un ticket, revenir au tableau de bord | recettes, places vendues et solde augmentent, réservations en attente diminuent |
| Changer la période (ex. 2020) | chiffres à 0, messages « Aucun paiement / Aucune séance » |

## 6 nonies. Étape 9 : réinitialisation, recette finale

- **Réinitialiser les données** (menu Cinéma, page `cinema/parametre/reinitialisation.jsp` → `apres-reinitialisation.jsp` → `cinema.utils.CinReinitialisation.executer`) : efface tout sauf la configuration, dans l'ordre des clés étrangères, en SQL direct et dans **une seule transaction** (17 étapes, aperçu des quantités avant). Garde : `CIN_CINEMA`, `CIN_CLASSE_PLACE`, `CIN_CATEGORIE_FILM`, `CIN_PARAMETRE`, `CIN_MODE_CAISSE`, la caisse `CAICINEMA`, les menus. Puis remet à 1 la séquence des numéros de facture.
- **Recharger la démonstration** : même page, option « Réinitialiser puis recharger la démonstration ». Le script lu est `arbiochem-war/web/WEB-INF/cinema/donnees-demo.sql`, exécuté par `cinema.utils.CinScriptSql` (lignes `--`, `SET`, `COMMIT` ignorées ; `;` en fin de ligne ; blocs PL/SQL terminés par `/`). **Ce fichier doit rester identique à `data/cinema/donnees-demo.sql`** (le war ne contient pas le dossier `data/`).
- **Ce que le module ajoute dans des tables existantes** (rien n'est modifié ni supprimé dans l'existant) : `MENUDYNAMIQUE` (menus `MENDYNCINEMA...`), `USERMENU` (`UMCINEMA01`), `CAISSE` (`CAICINEMA`), `MODEPAIEMENT` (`MPCINMOB`), `CLIENT` (clients de démo `CLICIN...`), `MOUVEMENTCAISSE` et `REPORTCAISSE` (mouvements du cinéma, `IDORIGINE LIKE 'CIN%'` ou caisse `CAICINEMA`). `cinema-reset.sql` retire tout cela.
- **Recette finale** : scénario complet achat → séance → réservation → paiement multi-mode → facture → caisse → tableau de bord, et cas limites, testés en Java (voir `TEST/CINEMA/ETAPE-1-9/README.md` pour le parcours dans l'application).

## 6 undecies. Étape 10 : programme de novembre (12/11/2026)

Données fournies en photos (`TEST/ALEA-12-11-26/PHOTO`) : plan des salles A, B, C, liste des films, programme du 16 au 30/11/2026.

- **Colonnes ajoutées** (`etape-10-films-realisateur.sql`) : `CIN_FILM.REALISATEUR` (texte libre) et `CIN_FILM.CLASSIFICATION` (liste fermée `CinFilm.CLASSIFICATIONS` + contrainte `CK_CIN_FILM_CLASSIFICATION`). `CIN_FILM.IDACTEUR` devient **facultatif** (les données ne donnent que le réalisateur) ; s'il est rempli, l'acteur doit exister. Pages films : réalisateur et classification en saisie, modification, fiche, liste (colonnes et filtres) ; liste des acteurs avec un choix vide (`CinActeur.getActeurs`).
- **Classes de place** : Standard 15 000 Ar (rangées A-B), Confort 20 000 Ar (rangée C), VIP 30 000 Ar (rangée D). Les anciennes classes Moyen / Premium sont renommées par le script (mêmes id, donc les places existantes suivent). `etape-1-referentiels.sql` crée directement ces trois classes pour une installation neuve ; la démo utilise les nouveaux noms et calcule les montants du ticket payé à partir des prix.
- **Plan de salle** : « ENTRÉE » affichée sous la grille (l'écran est devant, l'entrée au fond, comme sur le schéma).
- **Films** : prix d'achat **0 Ar** (non fourni), catégories Aventure / Thriller (créée si absente) / Animation.
- **Séances** : le programme hebdomadaire est appliqué à chaque jour du 16 au 30/11/2026 → 41 séances (Les Gardiens du Baobab 14 en salle A, Nuit sur Analamanga 15 en salle B, Le Petit Lemurien 12 en salle C).
- **Chargement** : Cinéma → Réinitialiser les données → option « programme du 16 au 30/11/2026 » (choix par défaut), qui exécute `WEB-INF/cinema/donnees-alea-12-11-26.sql` (**identique à `data/cinema/donnees-alea-12-11-26.sql`**). L'option « démonstration de test » reste disponible.

Tests à faire dans WildFly :

| Écran | À vérifier |
|---|---|
| Configurations → Classes de place | Standard 15 000, Confort 20 000, VIP 30 000 |
| Salles → Liste / fiche | Salle A, B, C : 20 places, A-B Standard, C Confort, D VIP, « ÉCRAN » devant et « ENTRÉE » au fond |
| Films → Liste | 3 films, colonnes Réalisateur et Classification, prix 0 ; filtre Classification = -12 → Nuit sur Analamanga |
| Films → Saisie | acteur laissé sur « - » → accepté ; classification au choix |
| Diffusions → Calendrier | semaine du 16/11 : 18 séances, ex. lundi 14:00 salle A et salle B |
| Réservations | une place VIP d'une séance → 30 000 Ar |

## 6 duodecies. Étape 11 : facturation par la facturation existante (12/11/2026)

Décisions de l'utilisateur : la facture d'un ticket est une **vente** de l'application (liée aux avoirs, aux écritures, à l'encaissement) ; les chaises commandées sont les produits ; **un produit par classe** ; « Payer » **crée et vise** la vente automatiquement ; le ticket est **acquis dès le visa** ; l'ancienne facturation du cinéma est **gardée en base sans menus**.

- **Bouton « Payer »** (fiche de la réservation) → `cinema/reservation/apres-facturation.jsp` → `cinema.paiement.CinFacturation.facturer(idTicket, user)` dans une transaction :
  1. verrou sur le ticket (`FOR UPDATE`), ticket réservé et non expiré, client avec un compte comptable ;
  2. vente `vente.VenteArbiochem` (table `VENTE`) : date du jour, échéance = aujourd'hui, désignation « Cinema - <film> <date> <heure> - <salle> », remarque « Ticket cinema <id> », magasin = paramètre `MAGASIN_VENTE` (défaut `MAGA0008`, doit exister dans `MAGASINVENTE`), mode de livraison 2 (récupération) ;
  3. **une ligne par classe** : produit `CIN_CLASSE_PLACE.IDPRODUIT`, quantité = nombre de chaises, prix = prix des chaises à la réservation, TVA 0, compte 706, désignation « Place VIP - Nuit sur Analamanga 16/11/2026 20:00 - Salle B - D1, D2 » (une vente refuse deux lignes du même produit, d'où le regroupement) ;
  4. `createObject` puis **`validerObject`** de la vente : numéro de facture, écriture comptable, prévision d'encaissement, imputation automatique des avoirs et des avances du client, contrôle du seuil d'impayés du client (code existant, non modifié) ;
  5. `CIN_TICKET.ETAT = 11`, `CIN_TICKET.IDVENTE` = la vente ; puis ouverture de `vente/vente-arbiochem-fiche.jsp` : Payer / Encaisser, avoirs, impression, comme toute facture.
- **Produits** : `CinClassePlace.synchroniserProduit` crée le produit « Place <classe> » (`AS_INGREDIENTS`, id `IG` + id de la classe, catégorie `CATINGSERVICE` donc aucun engagement de stock, unité `UNT00005`) à la création d'une classe et met à jour libellé, prix et actif à chaque modification.
- **Statut du ticket** (`CIN_TICKET_LIB.ETATLIB`) : Réservé / Expiré / Annulé / **Facturé** / **Facturé et payé** (reste à payer nul dans `VENTE_CPL`) / **Facture annulée** (la vente annulée dans la facturation rend le ticket inactif : ses chaises redeviennent libres) / Payé (ancienne facturation du cinéma). Sur le plan de salle, une chaise facturée est « vendue ».
- **Annulation** : un ticket facturé ne s'annule pas côté cinéma ; on annule sa facture dans la facturation.
- **Fiche client** : section « Factures » (vue `CIN_FACTURE_VENTE` : montant, payé, reste, état de la vente). **Tableau de bord** : recettes = tickets facturés (vue `CIN_RECETTE`, qui garde aussi les anciens paiements), mouvements de caisse = ceux du cinéma + les encaissements des factures des tickets.
- **Réinitialisation** et `cinema-reset.sql` : les ventes, leurs encaissements (mouvements dont `IDORIGINE` est une vente, même sur la Caisse Cinéma), les clients qui ont une facture et les produits utilisés par une facture ne sont **jamais effacés**.
- **Démo** : clients de démo créés avec un compte comptable (`COMPTA_COMPTE` `COMCINDEMO..`, comptes `411999000..`) ; plus de ticket payé d'avance : 4 tickets à payer.
- Menus retirés : Paiements, Factures, Configurations > Caisses par mode (pages et tables conservées). Carte « Factures » de l'accueil → `vente/vente-arbiochem-liste.jsp`.

Tests faits (Java, ROLLBACK) : facturation d'un ticket 2 VIP + 1 Confort + 1 Standard (95 000 Ar, 3 lignes, écriture, pas de stock), statut, plan, fiche client, tableau de bord, double facturation, annulation refusée, chaise vendue non réservable, facture annulée → chaises libres, ticket expiré, magasin inconnu, client sans compte, produit créé / synchronisé avec la classe, réinitialisation avec une facture encaissée sur la Caisse Cinéma, rechargement de la démo.

Tests à faire dans WildFly :

| Écran | À vérifier |
|---|---|
| Réservations → Nouvelle réservation | client créé par la fiche client (il a un compte 411...), 2 chaises VIP + 1 Standard |
| Fiche réservation → Payer | confirmation, puis la fiche de la vente s'ouvre : 2 lignes (Place VIP × 2, Place Standard × 1), état visé, numéro de facture |
| Fiche vente → Payer | encaissement comme une vente normale ; la fiche réservation affiche « Facturé et payé » |
| Fiche vente → Générer avoir | avoir de la facture du ticket |
| Plan de la séance | chaises vendues barrées |
| Vente annulée | la réservation affiche « Facture annulée » et les chaises sont libres |
| Clients cinéma → fiche | section Factures |

## 6 decies. Limites connues et perspectives

- Pas d'écriture comptable générale (journal, lettrage) pour les achats et les paiements : seulement des mouvements visés dans `MOUVEMENTCAISSE`.
- Pas de modification d'un achat (annuler puis ressaisir avant le visa), pas d'annulation d'un paiement ni d'avoir sur un ticket payé.
- Pas de marge de nettoyage entre deux séances, pas de tarif selon la séance (3D, soirée), pas d'espace client en ligne.
- La vue `V_ETATCAISSE` de la base locale (solde des caisses de l'appli) ne compte que les mouvements rattachés à un report : le tableau de bord du cinéma calcule son propre solde.

## 7. Pièges APJ (à retenir pour les étapes suivantes)

- **Modification** : `apresTarif.jsp` → `UserEJB.updateObject` → `UpdateObject` → `updateToTableWithHisto`. `controlerUpdate` n'est **pas** appelé (seulement par `updateObjectValidation`). Contrôles de modification : surcharger `updateToTableWithHisto(String, Connection)`.
- **Insertion** : `createObject` appelle `controler(c)` **avant** `construirePK` puis insère toutes les colonnes : un attribut vide écrase le `DEFAULT` de la table → donner les valeurs par défaut dans `controler`.
- **Suppression** : `deleteToTableWithHisto` appelle `controlerDelete(c)`.
- **Menu** : un menu de niveau 1 doit avoir une ligne `USERMENU` autorisée (voir §5).
- **Scripts SQL** : `SET DEFINE OFF;` à cause des entités HTML.
- **Pilote Oracle ancien** (`ojdbc6-11.jar`, classes `oracle.jdbc.dbaccess`) : pour un BLOB, ne pas utiliser `setBinaryStream` / `setBytes` / `getBytes`. Écrire avec `EMPTY_BLOB()` + `SELECT ... FOR UPDATE` + `getBinaryOutputStream()`, lire avec `getBlob()` (voir `CinFilmPhoto`).
- **Visa d'une `ClassEtat` / `ClassMere`** : `apresTarif.jsp` (`acte=valider`) → `ValiderObject` recharge l'objet (avec ses filles pour une mère) puis appelle `validerObject(String, Connection)` : c'est la méthode à surcharger. États APJ : créé = 1, visé = 11, annulé = 0.
- **Annulation** : `annulerObject` appelle `controleAnnule(c)` (et non `controleAnnuler`).
- **Tables mère / fille** : APJ ne remplit que les colonnes présentes dans la table (pas besoin de `IDUSER`). Donner une colonne `ETAT` à la table fille, car le visa d'une mère vise aussi ses filles.
- **Suppression APJ = commit** : `ClassMAPTable.deleteToTable` (via `deleteToTableWithHisto`) fait `commit` de toute la transaction, et `deleteToTableWithHisto` fait `rollback` en cas d'erreur. Ne jamais l'appeler au milieu d'un traitement qui doit rester annulable : supprimer en SQL (requête préparée) dans la transaction.
- **Sources Java en ASCII pur** : `build.xml` compile en ISO-8859-1. Aucun caractère accentué ou spécial en clair dans un `.java` : utiliser les entités HTML dans les messages (`&eacute;`) ou `(char) 0x00A0` / `\u00e9`.
- **Accents en base** : les libellés sont souvent stockés en entités HTML (`Cin&eacute;ma`). Pour afficher un texte de la base dans une page, ne pas réécrire `&` en `&amp;` quand il commence une entité valide (voir la fonction `html()` des pages du cinéma).
