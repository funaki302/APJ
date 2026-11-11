-- =====================================================================
-- CINEMA - Etape 1 : referentiels
-- Tables : CIN_CINEMA, CIN_CLASSE_PLACE, CIN_CATEGORIE_FILM, CIN_ACTEUR, CIN_PARAMETRE
-- Vues d'affichage : CIN_CINEMA_LIB, CIN_CLASSE_PLACE_LIB, CIN_CATEGORIE_FILM_LIB
-- Donnees initiales + menus Cinema > Configurations.
-- Prerequis : etape-0-menu.sql. Se reconnecter apres execution (menu en session).
-- ETAT des referentiels : 1 = actif, 0 = inactif.
-- Donnees sans accents (regle du projet pour les donnees creees par les scripts).
-- =====================================================================

SET DEFINE OFF;

-- ---------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------
CREATE TABLE CIN_CINEMA (
    ID            VARCHAR2(50)  NOT NULL,
    NOM           VARCHAR2(255) NOT NULL,
    LOCALISATION  VARCHAR2(255),
    DATE_CREATION DATE DEFAULT SYSDATE,
    ETAT          NUMBER(2) DEFAULT 1,
    CONSTRAINT PK_CIN_CINEMA PRIMARY KEY (ID),
    CONSTRAINT CK_CIN_CINEMA_ETAT CHECK (ETAT IN (0, 1))
);

CREATE TABLE CIN_CLASSE_PLACE (
    ID            VARCHAR2(50)  NOT NULL,
    VAL           VARCHAR2(100) NOT NULL,
    DESCE         VARCHAR2(255),
    PRIX          NUMBER(15, 2) NOT NULL,
    COULEUR       VARCHAR2(7)   NOT NULL,
    DATE_CREATION DATE DEFAULT SYSDATE,
    ETAT          NUMBER(2) DEFAULT 1,
    CONSTRAINT PK_CIN_CLASSE_PLACE PRIMARY KEY (ID),
    CONSTRAINT UK_CIN_CLASSE_PLACE_VAL UNIQUE (VAL),
    CONSTRAINT CK_CIN_CLASSE_PLACE_PRIX CHECK (PRIX > 0),
    CONSTRAINT CK_CIN_CLASSE_PLACE_ETAT CHECK (ETAT IN (0, 1))
);

CREATE TABLE CIN_CATEGORIE_FILM (
    ID            VARCHAR2(50)  NOT NULL,
    VAL           VARCHAR2(100) NOT NULL,
    DESCE         VARCHAR2(255),
    DATE_CREATION DATE DEFAULT SYSDATE,
    ETAT          NUMBER(2) DEFAULT 1,
    CONSTRAINT PK_CIN_CATEGORIE_FILM PRIMARY KEY (ID),
    CONSTRAINT UK_CIN_CATEGORIE_FILM_VAL UNIQUE (VAL),
    CONSTRAINT CK_CIN_CATEGORIE_FILM_ETAT CHECK (ETAT IN (0, 1))
);

-- NOM = nom civil, NOM_ACTEUR = nom de scene
CREATE TABLE CIN_ACTEUR (
    ID             VARCHAR2(50)  NOT NULL,
    NOM            VARCHAR2(255) NOT NULL,
    NOM_ACTEUR     VARCHAR2(255),
    DATE_NAISSANCE DATE,
    CONSTRAINT PK_CIN_ACTEUR PRIMARY KEY (ID)
);

-- Parametres du module : CODE fixe (lu par le Java), VALEUR modifiable dans l'ecran Parametres
CREATE TABLE CIN_PARAMETRE (
    ID     VARCHAR2(50)  NOT NULL,
    CODE   VARCHAR2(100) NOT NULL,
    VALEUR VARCHAR2(255) NOT NULL,
    DESCE  VARCHAR2(255),
    CONSTRAINT PK_CIN_PARAMETRE PRIMARY KEY (ID),
    CONSTRAINT UK_CIN_PARAMETRE_CODE UNIQUE (CODE)
);

-- ---------------------------------------------------------------------
-- Sequences + fonctions (utilisees par preparePk / makePK)
-- ---------------------------------------------------------------------
CREATE SEQUENCE SEQ_CIN_CINEMA START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_CIN_CLASSE_PLACE START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_CIN_CATEGORIE_FILM START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_CIN_ACTEUR START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_CIN_PARAMETRE START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE OR REPLACE FUNCTION GETSEQCINCINEMA RETURN NUMBER IS
    retour NUMBER;
BEGIN
    SELECT SEQ_CIN_CINEMA.NEXTVAL INTO retour FROM DUAL;
    RETURN retour;
END;
/

CREATE OR REPLACE FUNCTION GETSEQCINCLASSEPLACE RETURN NUMBER IS
    retour NUMBER;
BEGIN
    SELECT SEQ_CIN_CLASSE_PLACE.NEXTVAL INTO retour FROM DUAL;
    RETURN retour;
END;
/

CREATE OR REPLACE FUNCTION GETSEQCINCATEGORIEFILM RETURN NUMBER IS
    retour NUMBER;
BEGIN
    SELECT SEQ_CIN_CATEGORIE_FILM.NEXTVAL INTO retour FROM DUAL;
    RETURN retour;
END;
/

CREATE OR REPLACE FUNCTION GETSEQCINACTEUR RETURN NUMBER IS
    retour NUMBER;
BEGIN
    SELECT SEQ_CIN_ACTEUR.NEXTVAL INTO retour FROM DUAL;
    RETURN retour;
END;
/

CREATE OR REPLACE FUNCTION GETSEQCINPARAMETRE RETURN NUMBER IS
    retour NUMBER;
BEGIN
    SELECT SEQ_CIN_PARAMETRE.NEXTVAL INTO retour FROM DUAL;
    RETURN retour;
END;
/

-- ---------------------------------------------------------------------
-- Vues d'affichage (listes et fiches) : libelle de l'etat
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW CIN_CINEMA_LIB AS
SELECT c.ID, c.NOM, c.LOCALISATION, c.DATE_CREATION, c.ETAT,
       DECODE(c.ETAT, 1, 'Actif', 'Inactif') AS ETATLIB
FROM CIN_CINEMA c;

CREATE OR REPLACE VIEW CIN_CLASSE_PLACE_LIB AS
SELECT c.ID, c.VAL, c.DESCE, c.PRIX, c.COULEUR, c.DATE_CREATION, c.ETAT,
       DECODE(c.ETAT, 1, 'Actif', 'Inactif') AS ETATLIB
FROM CIN_CLASSE_PLACE c;

CREATE OR REPLACE VIEW CIN_CATEGORIE_FILM_LIB AS
SELECT c.ID, c.VAL, c.DESCE, c.DATE_CREATION, c.ETAT,
       DECODE(c.ETAT, 1, 'Actif', 'Inactif') AS ETATLIB
FROM CIN_CATEGORIE_FILM c;

-- ---------------------------------------------------------------------
-- Donnees initiales (modifiables ensuite dans l'application)
-- ---------------------------------------------------------------------
INSERT INTO CIN_CINEMA (ID, NOM, LOCALISATION, ETAT)
VALUES ('CINCIN' || LPAD(GETSEQCINCINEMA, 6, '0'), 'Cinema principal', 'Antananarivo', 1);

-- Couleurs du concept : standard jaune, moyen vert, premium rouge
INSERT INTO CIN_CLASSE_PLACE (ID, VAL, DESCE, PRIX, COULEUR, ETAT)
VALUES ('CINCLA' || LPAD(GETSEQCINCLASSEPLACE, 6, '0'), 'Standard', 'Place standard', 10000, '#F4C430', 1);
INSERT INTO CIN_CLASSE_PLACE (ID, VAL, DESCE, PRIX, COULEUR, ETAT)
VALUES ('CINCLA' || LPAD(GETSEQCINCLASSEPLACE, 6, '0'), 'Moyen', 'Place confort', 15000, '#4CAF50', 1);
INSERT INTO CIN_CLASSE_PLACE (ID, VAL, DESCE, PRIX, COULEUR, ETAT)
VALUES ('CINCLA' || LPAD(GETSEQCINCLASSEPLACE, 6, '0'), 'Premium', 'Place premium', 20000, '#E53935', 1);

INSERT INTO CIN_CATEGORIE_FILM (ID, VAL, ETAT) VALUES ('CINCAT' || LPAD(GETSEQCINCATEGORIEFILM, 6, '0'), 'Action', 1);
INSERT INTO CIN_CATEGORIE_FILM (ID, VAL, ETAT) VALUES ('CINCAT' || LPAD(GETSEQCINCATEGORIEFILM, 6, '0'), 'Aventure', 1);
INSERT INTO CIN_CATEGORIE_FILM (ID, VAL, ETAT) VALUES ('CINCAT' || LPAD(GETSEQCINCATEGORIEFILM, 6, '0'), 'Animation', 1);
INSERT INTO CIN_CATEGORIE_FILM (ID, VAL, ETAT) VALUES ('CINCAT' || LPAD(GETSEQCINCATEGORIEFILM, 6, '0'), 'Comedie', 1);
INSERT INTO CIN_CATEGORIE_FILM (ID, VAL, ETAT) VALUES ('CINCAT' || LPAD(GETSEQCINCATEGORIEFILM, 6, '0'), 'Drame', 1);
INSERT INTO CIN_CATEGORIE_FILM (ID, VAL, ETAT) VALUES ('CINCAT' || LPAD(GETSEQCINCATEGORIEFILM, 6, '0'), 'Horreur', 1);
INSERT INTO CIN_CATEGORIE_FILM (ID, VAL, ETAT) VALUES ('CINCAT' || LPAD(GETSEQCINCATEGORIEFILM, 6, '0'), 'Science-fiction', 1);

INSERT INTO CIN_PARAMETRE (ID, CODE, VALEUR, DESCE)
VALUES ('CINPAR' || LPAD(GETSEQCINPARAMETRE, 6, '0'), 'DELAI_EXPIRATION_MIN', '30',
        'Minutes avant le debut de la seance apres lesquelles une reservation non payee expire');

-- ---------------------------------------------------------------------
-- Menus : Cinema > Configurations > (Cinemas, Classes de place, Categories de film, Acteurs, Parametres)
-- ---------------------------------------------------------------------
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA01', 'Configurations', 'settings', NULL, 1, 2, 'MENDYNCINEMA');

INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA0101', 'Cin&eacute;mas', 'theaters', NULL, 1, 3, 'MENDYNCINEMA01');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA010101', 'Saisie', NULL, 'module.jsp?but=cinema/salle/cinema-saisie.jsp', 1, 4, 'MENDYNCINEMA0101');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA010102', 'Liste', NULL, 'module.jsp?but=cinema/salle/cinema-liste.jsp', 2, 4, 'MENDYNCINEMA0101');

INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA0102', 'Classes de place', 'chair', NULL, 2, 3, 'MENDYNCINEMA01');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA010201', 'Saisie', NULL, 'module.jsp?but=cinema/salle/classe-place-saisie.jsp', 1, 4, 'MENDYNCINEMA0102');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA010202', 'Liste', NULL, 'module.jsp?but=cinema/salle/classe-place-liste.jsp', 2, 4, 'MENDYNCINEMA0102');

INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA0103', 'Cat&eacute;gories de film', 'category', NULL, 3, 3, 'MENDYNCINEMA01');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA010301', 'Saisie', NULL, 'module.jsp?but=cinema/film/categorie-film-saisie.jsp', 1, 4, 'MENDYNCINEMA0103');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA010302', 'Liste', NULL, 'module.jsp?but=cinema/film/categorie-film-liste.jsp', 2, 4, 'MENDYNCINEMA0103');

INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA0104', 'Acteurs', 'person', NULL, 4, 3, 'MENDYNCINEMA01');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA010401', 'Saisie', NULL, 'module.jsp?but=cinema/film/acteur-saisie.jsp', 1, 4, 'MENDYNCINEMA0104');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA010402', 'Liste', NULL, 'module.jsp?but=cinema/film/acteur-liste.jsp', 2, 4, 'MENDYNCINEMA0104');

-- Les parametres ont des codes fixes : pas de saisie, seulement liste / modification
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA0105', 'Param&egrave;tres', 'tune', 'module.jsp?but=cinema/parametre/parametre-liste.jsp', 5, 3, 'MENDYNCINEMA01');

COMMIT;

-- Controle
-- SELECT * FROM CIN_CLASSE_PLACE_LIB;
-- SELECT * FROM CIN_PARAMETRE;
