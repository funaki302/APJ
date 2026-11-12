# Facturation du cinéma par la facturation existante (VENTE), 12/11/2026

## Principe

- Sur la fiche d'une réservation, **Payer** crée la facture du ticket dans la facturation de l'application, puis la **vise** :
  numéro de facture, écriture comptable, prévision d'encaissement, imputation automatique des avoirs et avances du client.
- La fiche de la vente (`vente/vente-arbiochem-fiche.jsp`) s'ouvre ensuite : on y encaisse (Payer), on génère un avoir,
  on imprime, comme pour toute facture.
- Les chaises commandées sont les produits : **un produit par classe** (« Place Standard », « Place Confort », « Place VIP »),
  quantité = nombre de chaises, la désignation de la ligne liste la séance et les chaises
  (ex. « Place VIP - Nuit sur Analamanga 16/11/2026 20:00 - Salle B - D1, D2 »). TVA 0, compte 706, catégorie service (pas de stock).
- Le ticket est **acquis dès le visa** (plus d'expiration). Si la vente est annulée dans la facturation, la réservation
  affiche « Facture annulée » et ses chaises redeviennent libres.
- L'ancienne facturation du cinéma (Paiements, Factures, Caisses par mode) n'a plus de menu ; ses tables restent en base.
- Aucun fichier de la facturation existante n'est modifié : tout est dans le module cinéma.

## Points d'attention

- Le client doit avoir un **compte comptable 411...** : c'est le cas de tout client créé par la fiche client
  (bouton « + » du champ Client de la réservation). Sinon « Payer » affiche un message clair.
- Les factures sont inscrites sur le magasin du paramètre **MAGASIN_VENTE** (défaut `MAGA0008` « Central »),
  modifiable dans Cinéma > Configurations > Paramètres.
- « Réinitialiser les données » n'efface **jamais** les factures, leurs encaissements ni les clients qui ont une facture
  (pièces comptables : à annuler dans la facturation si besoin).
- Le seuil d'impayés du client (contrôle existant de la facturation) s'applique aussi aux tickets.

## Fichiers (à copier à la même place dans `projet-standard/`)

| Fichier | Changement |
|---|---|
| `data/cinema/etape-11-facturation-vente.sql` | **nouveau** : produits « Place ... », `CIN_CLASSE_PLACE.IDPRODUIT`, `CIN_TICKET.IDVENTE`, paramètre `MAGASIN_VENTE`, vues `CIN_TICKET_LIB`, `CIN_PLACE_DIFFUSION`, `CIN_FACTURE_VENTE`, `CIN_RECETTE`, `CIN_CLIENT_LIB`, retrait des anciens menus |
| `arbiochem-ejb/src/java/cinema/paiement/CinFacturation.java` | **nouveau** : création + visa de la vente d'un ticket |
| `arbiochem-ejb/src/java/cinema/paiement/CinFactureVente.java` | **nouveau** : factures des tickets (fiche client) |
| `arbiochem-ejb/src/java/cinema/salle/CinClassePlace.java` | produit de la classe créé / mis à jour automatiquement |
| `arbiochem-ejb/src/java/cinema/reservation/CinTicket.java`, `CinTicketLib.java` | lien vers la vente, message d'annulation |
| `arbiochem-ejb/src/java/cinema/reservation/CinClient.java` | factures au lieu des paiements |
| `arbiochem-ejb/src/java/cinema/utils/CinTableauBord.java` | recettes = tickets facturés, encaissements des factures |
| `arbiochem-ejb/src/java/cinema/utils/CinReinitialisation.java` | factures, encaissements et clients facturés jamais effacés |
| `arbiochem-war/web/pages/cinema/reservation/apres-facturation.jsp` | **nouveau** : bouton Payer → facture → fiche de la vente |
| `arbiochem-war/web/pages/cinema/reservation/reservation-{fiche,saisie,liste}.jsp` | bouton Payer, lien « Voir la facture », statuts |
| `arbiochem-war/web/pages/cinema/client/client-{fiche,liste}.jsp` | section Factures, libellés |
| `arbiochem-war/web/pages/cinema/tableau/tableau-bord.jsp`, `cinema-accueil.jsp`, `inc/plan-salle.jspf` | libellés (facturé, vendue), carte Factures |
| `arbiochem-war/web/pages/cinema/salle/classe-place-{saisie,modif,fiche}.jsp` | champ produit (automatique) |
| `arbiochem-war/web/pages/cinema/parametre/reinitialisation.jsp` | explication : factures jamais effacées |
| `data/cinema/donnees-demo.sql` + copie `arbiochem-war/web/WEB-INF/cinema/` | clients de démo avec compte comptable, plus de ticket payé d'avance |
| `data/cinema/cinema-reset.sql` | garde factures, encaissements, clients et produits facturés |
| `instruction/CINEMA.md` | §1, §3, §4, §6 duodecies (étape 11) |

## Installation

1. `data/cinema/etape-11-facturation-vente.sql` (après les étapes 0 à 10). **Déjà exécuté sur la base locale.**
2. `ant -f build.xml deploy`, puis se déconnecter / reconnecter (menus).

## À tester dans WildFly

| Écran | Attendu |
|---|---|
| Réservations → Nouvelle réservation | client créé par la fiche client, 2 chaises VIP + 1 Standard sur une séance du programme |
| Fiche réservation → Payer | confirmation, puis fiche de la vente : 2 lignes (Place VIP × 2 = 60 000, Place Standard × 1 = 15 000), visée, numéro de facture |
| Fiche vente → Payer | encaissement normal ; la réservation affiche « Facturé et payé » |
| Fiche vente → Générer avoir | avoir sur la facture du ticket |
| Plan de la séance | chaises vendues barrées ; elles ne sont plus réservables |
| Annuler la vente | la réservation affiche « Facture annulée », les chaises sont libres |
| Cinéma → Clients → fiche | section Factures (montant, payé, reste) |
| Cinéma → Tableau de bord | recettes = tickets facturés |
| Menu Cinéma | plus de Paiements / Factures / Caisses par mode |
