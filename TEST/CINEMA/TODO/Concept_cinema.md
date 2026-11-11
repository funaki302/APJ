# CINEMA

On veut  creer une application qui gere un cinema, qui a plusieurs salle. Dans une salle il y a plusieurs chaises qui ont chacun leur prix selon leur classe(standard, moyen, prenium). Les pages principaux qu'on doit avoir sont : `achat de films` qui a une consequence sur la `caisse`, `gestion films`, `gestion salle`, `gestion difusion`, `reservation de place`, `paiement` qui genere une `facture client` et qui a une consequence sur la `caisse`

## Pages

**Gestion des salles**:
- salle_liste: liste des salles(nom, capacite,statut), filtre, pagination
- salle_saisie: formulaire de saisie/modification de salle
- salle_fiche: details d'une salle (nom, capacite, statut), disposition des places(numero, classe)
*NB:* on a trois classes : standard(jaune), moyen(vert), prenium(rouge)

**Gestion des films**:
- film_liste: liste des films(nom, photo, acteur, duree, categorie, statut), filtre, pagination
- film_saisie: formulaire de saisie/modification de film
- film_fiche: details d'un film (nom, photo, duree, PA, acteur, statut, categorie)

**Gestion des diffusions**:
- diffusion_liste: liste des diffusions(films, salle, date-heure, statut), filtre, pagination
- diffusion_saisie: formulaire de saisie/modification de diffusion
- diffusion_fiche: details d'une diffusion(films, salle, date-heure, statut)

**Gestion des clients**:
- client_liste: liste des clients(nom, contact), filtre, pagination
- client_saisie: formulaire de saisie/modification de client
- client_fiche: details d'un client

**Gestion des reservations**:
- reservation_liste: liste des reservations(client, date reservation, diffusion, salle, date diffusion, montant, statut)
- reservation_saisi: page saisie/modification d'une reservation
- reservation_fiche: details d'une reservation(client, date reservation, diffusion, salle, date diffusion, montant, statut), la liste des places reserves(ticket_details)

**Gestion de paiement**:
- liste des tickets (paye/reserve)
- fiche d'un ticket: details (client, date reservation, diffusion, salle, date diffusion, montant, statut, date paiement, details de paiement), la liste des places reserves(ticket_details)
- saisi de paiement

## Tables a creer

- cinema (**id**, nom, localisation, date_creation, statut)
- salle (**id**, #cinema_id, nom, capacite, date_creation, statut)
- classe (**id**, libelle, prix, date_creation, statut)
- place (**id**, #salle_id, #classe_id, prix, numero)
- categorie_film (**id**, libelle. date_creation, statut)
- acteur (**id**, nom, date_naissance, nom_acteur)
- film (**id**, #categorie_film_id, #acteur_id, titre, duree, PA, date_creation, statut)
- diffusion (**id**, date_diffusion, heure_diffusion, #film_id, #salle_id, date_creation, statut)
- ticket (**id**, #client_id, date_reservation, $diffusion_id, #salle_id, statut)
- ticket_detail (**id**, #ticket_id, #place_id, #classe_id, prix)
- paiement (**id**, #client_id, $ticket_id, date_paiement, montant_a_payer)
- paiement_detail (**id**, #paiement_id, mode_paiement, montant)

## Autres tables existants utiles

- caisse
- as_bondecommande
- as_bondecommandefille
- factureclient
- factureclientdetails

1. le client est la table CLIENT deja existant
2. Pour achat film, je ne sais pas encore, j'ai besoin de suggestion
3. Oui, une reservation est expirer si elle n'est pas payee apres un temps qui sera parametrable du debut de la diffusion reserve
4. Un paiement peut etre multi-mode, mais doit etre payer en un seul paiement
5. la facture est creer lorsque le paiement est effectue a la total
6. On peut utiliser la calendrier pour afficher les diffusions, et aussi la generation automatique des places d'une salle(par defaut de classe stadard mais modifiable dans sallle_saisie pour modification d'une salle)
7. Dans un film, on a un acteur principale
