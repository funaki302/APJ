# Comprehension de APJ

## Logique d'heritage

        ClassMapTable
            |
            |
          Etat
            |
            |
          /   \
        Mere  Fille
         \     /
 Lien entre Mere et Fille (col)

## Fichiers intouchable

Ce sont les fichiers qui controlent les actions a faire

- apresMultiple.jsp
- apresTarif.jsp 

## Si on doit ajouter une condition ou logique 

- on trouve la fonction appeler
- on override la fonction appeler dans la class qui en a besoin
- et on ajoute les logiques suplementaires au dessus de l'appel de l'ancienne fonction

## Face a une page blanche

- voir les erreurs affciher par le terminal de wildfly
- voir dans `D:\Apps\wildfly-10.0.0.Final\wildfly-10.0.0.Final\standalone\tmp` les erreurs qui correspond
au projet
- on met le chemin exacte du fichier sur l'url afin que l'erreur s'affiche sur le navigateur

## Pour creer une page a partir a APJ

- tout est rattacher a la base de donnnes, donc on construit une page a partir de sa base
- **Si on veut creer une page simple** PageInsert
- **Si on veut creer une page avec Mere et Fille** --Multiple : qui require une mere et les filles

## Remarques

### Mere & Fille

- Lors des mofications d'une class Mere, on fait aussi setFille
- Une mere peut recuperer ses filles
- Il ne faut pas oublier de montionner la colonne qui relie une mere a ses filles

### Creation d'une page

- si on veut afficher un champ sur une page qui conserne une class, il faut que le nom de colonne
et attribut soit le meme & dans la declaration dans la page il faut que le nom reste le meme
