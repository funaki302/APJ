-- =====================================================================
-- CINEMA - Etape 0 : menu CINEMA
-- Menu de niveau 1 tout en haut (RANG 0, avant Ferme qui a le rang 1).
-- Les sous-menus des autres pages sont ajoutes par le script de chaque etape,
-- quand la page existe (pas de lien vers une page vide).
-- Le menu est mis en cache dans la session : se deconnecter / reconnecter pour le voir.
-- =====================================================================

-- Les libelles contiennent des & (entites HTML) : ne pas les prendre pour des variables
SET DEFINE OFF;

-- Menu racine CINEMA
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA', 'Cin&eacute;ma', 'movie', NULL, 0, 1, NULL);

-- Accueil du module
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA00', 'Accueil cin&eacute;ma', 'home',
        'module.jsp?but=cinema/cinema-accueil.jsp', 0, 2, 'MENDYNCINEMA');

-- Droit d'acces : un menu de niveau 1 n'est affiche que s'il a une ligne USERMENU autorisee
-- (INTERDIT = 0). REFUSER = '*' : tous les utilisateurs (meme modele que le menu Ferme).
-- Les sous-menus suivent leur parent : pas besoin de ligne pour eux.
INSERT INTO USERMENU (ID, REFUSER, IDMENU, IDROLE, CODESERVICE, CODEDIR, INTERDIT)
VALUES ('UMCINEMA01', '*', 'MENDYNCINEMA', NULL, NULL, NULL, 0);

COMMIT;

-- Controle
 SELECT ID, LIBELLE, HREF, RANG, NIVEAU, ID_PERE FROM MENUDYNAMIQUE
WHERE ID LIKE 'MENDYNCINEMA%' ORDER BY NIVEAU, RANG;
