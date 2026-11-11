# CINEMA — Étape 0 : socle du module

Date : 11/11/2026. Plan complet : `TEST/CINEMA/TO-DO-CINEMA-1.md`. Documentation : `instruction/CINEMA.md`.

Cette étape ne modifie **aucun fichier existant** : tous les fichiers sont nouveaux.

## Fichiers (à copier à la même place dans `projet-standard/`)

| Fichier | Rôle |
|---|---|
| `arbiochem-ejb/src/java/cinema/package-info.java` | package racine du cinéma |
| `arbiochem-ejb/src/java/cinema/{salle,film,achat,diffusion,reservation,paiement,utils}/package-info.java` | sous-packages (vides pour l'instant, la description dit ce qu'ils contiendront) |
| `arbiochem-war/web/pages/cinema/cinema-accueil.jsp` | page d'accueil du module (cartes) |
| `data/cinema/etape-0-menu.sql` | menu **Cinéma** tout en haut + sous-menu **Accueil cinéma** + droit d'accès dans `USERMENU` (sans lui le menu ne s'affiche pas) |
| `data/cinema/cinema-reset.sql` | supprime tout le module cinéma de la base (si besoin de repartir à zéro) |
| `instruction/CINEMA.md` | documentation du module |

Créer aussi les dossiers vides `arbiochem-war/web/pages/cinema/{salle,film,achat,diffusion,reservation,paiement,facture,client,inc}` (ils seront remplis aux étapes suivantes).

## Installation

1. Exécuter `data/cinema/etape-0-menu.sql` sur la base (SQL Developer ou SQL*Plus). Le script commence par `SET DEFINE OFF;` : le garder, sinon le libellé devient « Cin;ma ».
2. `ant -f build.xml deploy`.
3. Se **déconnecter puis se reconnecter** (le menu est gardé en session).

## Test

- Le menu **Cinéma** (icône film) apparaît tout en haut, avant **Ferme**.
- **Cinéma → Accueil cinéma** affiche 9 cartes grisées « À venir (étape n) ».
- Aucun autre menu ni page ne change.
