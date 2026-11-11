# Module CINEMA — livraison complète

Date : 11/11/2026. Documentation technique : `instruction/CINEMA.md`. Plan et décisions : `TO-DO-CINEMA-1.md`.

Le module ajoute à l'ERP un menu **Cinéma** (tout en haut, avant Ferme) : salles et plans de places, films (avec photo),
achats de films et de matériel (sortie de caisse), séances (avec calendrier), réservations sur le plan de salle,
paiement en une fois avec plusieurs modes (facture automatique + entrées de caisse), clients, tableau de bord,
réinitialisation des données. **Aucun fichier existant de l'application n'est modifié** : tous les fichiers sont nouveaux.

## Contenu de la livraison (à copier à la même place dans `projet-standard/`)

| Dossier | Contenu |
|---|---|
| `arbiochem-ejb/src/java/cinema/` | classes métier : `salle`, `film`, `achat`, `diffusion`, `reservation`, `paiement`, `utils` |
| `arbiochem-war/src/java/cinema/servlet/` | `CinFilmPhotoServlet` (photos des films, `/cinema/film-photo`) |
| `arbiochem-war/web/pages/cinema/` | toutes les pages JSP du module (+ fragments `inc/`) |
| `arbiochem-war/web/WEB-INF/cinema/donnees-demo.sql` | copie de la démo, lue par le bouton « recharger la démonstration » |
| `data/cinema/` | scripts SQL (`etape-0` à `etape-9`), `donnees-demo.sql`, `cinema-reset.sql` |
| `instruction/CINEMA.md` | documentation technique du module |

## Installation

1. Copier les dossiers ci-dessus dans `projet-standard/`.
2. Exécuter **dans l'ordre** sur la base Oracle (SQL Developer ou SQL*Plus, en gardant le `SET DEFINE OFF;` du début de chaque script) :

   | Ordre | Script | Contenu |
   |---|---|---|
   | 1 | `etape-0-menu.sql` | menu Cinéma + droit d'accès (`USERMENU`) |
   | 2 | `etape-1-referentiels.sql` | cinéma, classes de place, catégories, acteurs, paramètres (délai d'expiration 30 min) |
   | 3 | `etape-2-salles.sql` | salles et places |
   | 4 | `etape-3-films.sql` | films et photos |
   | 5 | `etape-4-achats.sql` | achats + caisse « Caisse Cinema » (`CAICINEMA`) |
   | 6 | `etape-5-diffusions.sql` | séances |
   | 7 | `etape-6-reservations.sql` | réservations (tickets) |
   | 8 | `etape-7-paiements.sql` | paiements, factures, caisses par mode, mode « Mobile money » |
   | 9 | `etape-8-clients-tableau.sql` | clients du cinéma, tableau de bord |
   | 10 | `etape-9-reinitialisation.sql` | menu « Réinitialiser les données » |
   | 11 | `donnees-demo.sql` (facultatif) | données de démonstration (dates calculées à partir du jour d'exécution) |

3. `ant -f build.xml deploy`.
4. Se **déconnecter puis se reconnecter** (le menu est gardé en session).

Les caisses proposées par mode de paiement (`etape-7`) utilisent les caisses de la base de référence (Mvola `CAI000232`,
chèques `CAISB001`, banque `CAI000229`) ; si elles n'existent pas, la Caisse Cinema est utilisée. Elles se changent dans
Cinéma → Configurations → Caisses par mode.

## Parcours de test (après `donnees-demo.sql`)

| # | Écran | À vérifier |
|---|---|---|
| 1 | Cinéma → Accueil cinéma | 10 cartes actives (Configurations, Salles, Films, Achats, Diffusions, Réservations, Paiements, Factures, Clients, Tableau de bord) |
| 2 | Configurations → Classes de place | Standard 10 000, Moyen 15 000, Premium 20 000 Ar, avec leur couleur |
| 3 | Salles → Salle 1 → fiche | plan 6 × 10 : rangées A-C jaunes, D-E vertes, F rouges, F10 hachurée (hors service) ; « Modifier le plan » (pinceaux) |
| 4 | Films → Liste → « Le Lemurien d'or » | fiche : « Ajouter une photo » (JPG / PNG / WEBP, 2 Mo max) |
| 5 | Achats → achat « Equip Cine SARL » → **Viser** | sortie de 1 650 000 Ar de la Caisse Cinema, lien vers le mouvement de caisse |
| 6 | Diffusions → Calendrier | séances de la semaine par jour, une couleur par salle, séance annulée barrée |
| 7 | Diffusions → nouvelle séance qui chevauche une autre dans la même salle | refusée « La salle … est déjà occupée … » |
| 8 | Fiche de la séance « Le Lemurien d'or » de demain 18:00 → **Réserver des places** | places réservées barrées ✕ ; client « raz » → Razafy Nirina (recherche standard, « + » pour créer) ; cliquer A1 et D3 → total 25 000 Ar → Valider → fiche du ticket |
| 9 | Fiche du ticket → **Payer** | espèce 15 000 + Mobile money 10 000 (caisse Mvola pré-remplie) → « Compte juste » → facture `FCaaaa-00001` |
| 10 | Facture → **Imprimer / exporter en PDF** | facture + un billet par place ; « Exporter en PDF » → enregistrer au format PDF |
| 11 | Réservations → Liste | statuts Réservé, Payé, Annulé, **Expiré** (ticket de la séance « Rire en famille » qui commence 20 min après le chargement de la démo) |
| 12 | Clients → Razafy Nirina | ses réservations et ses paiements |
| 13 | Tableau de bord | recettes, places vendues, réservations en attente, achats, résultat, solde de la Caisse Cinema ; recettes par film ; remplissage des séances |
| 14 | Configurations → Paramètres | délai d'expiration 30 → 60 : les réservations expirent plus tôt ; remettre 30 |
| 15 | Réinitialiser les données | aperçu des quantités ; taper REINITIALISER ; option « recharger la démonstration » pour revenir à l'état de démo |

Le détail des tests de chaque écran est à la fin de chaque section « Étape n » de `instruction/CINEMA.md`.

## Règles du module (rappel)

- `apresTarif.jsp` et `apresMultiple.jsp` ne sont jamais modifiés ; toute la logique est dans les classes Java du package `cinema`.
- Tables et vues préfixées `CIN_`, identifiants préfixés `CIN...`, menus `MENDYNCINEMA...`.
- Données créées par les scripts **sans accent** ; sources Java en **ASCII pur** (le build compile en ISO-8859-1).
- Listes en tableau APJ standard ; champs de saisie APJ standard (ex. recherche client).

## Désinstallation

`data/cinema/cinema-reset.sql` supprime tout le module de la base : objets `CIN_*`, menus, caisse `CAICINEMA` avec ses
mouvements et reports, mode `MPCINMOB`, clients `CLICIN...`. Les autres données de l'application ne sont pas touchées.
Puis retirer les dossiers `cinema` copiés et redéployer.
