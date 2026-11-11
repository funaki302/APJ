-- =====================================================================
-- CINEMA - Etape 3 : films
-- Tables : CIN_FILM, CIN_FILM_PHOTO (affiche en BLOB) ; vue : CIN_FILM_LIB ; menus Cinema > Films.
-- Prerequis : etape-1-referentiels.sql. Se reconnecter apres execution (menu en session).
-- DUREE en minutes. PA = prix d'achat. ETAT : 1 = actif, 0 = inactif.
-- La photo est stockee en base (CIN_FILM_PHOTO) et affichee par la servlet /cinema/film-photo.
-- =====================================================================

SET DEFINE OFF;

CREATE TABLE CIN_FILM (
    ID            VARCHAR2(50)   NOT NULL,
    TITRE         VARCHAR2(255)  NOT NULL,
    IDCATEGORIE   VARCHAR2(50)   NOT NULL,
    IDACTEUR      VARCHAR2(50)   NOT NULL,
    DUREE         NUMBER(4)      NOT NULL,
    PA            NUMBER(15, 2)  DEFAULT 0 NOT NULL,
    DESCRIPTION   VARCHAR2(1000),
    DATE_CREATION DATE DEFAULT SYSDATE,
    ETAT          NUMBER(2) DEFAULT 1,
    CONSTRAINT PK_CIN_FILM PRIMARY KEY (ID),
    CONSTRAINT FK_CIN_FILM_CATEGORIE FOREIGN KEY (IDCATEGORIE) REFERENCES CIN_CATEGORIE_FILM (ID),
    CONSTRAINT FK_CIN_FILM_ACTEUR FOREIGN KEY (IDACTEUR) REFERENCES CIN_ACTEUR (ID),
    CONSTRAINT CK_CIN_FILM_DUREE CHECK (DUREE BETWEEN 1 AND 600),
    CONSTRAINT CK_CIN_FILM_PA CHECK (PA >= 0),
    CONSTRAINT CK_CIN_FILM_ETAT CHECK (ETAT IN (0, 1))
);

CREATE INDEX IX_CIN_FILM_CATEGORIE ON CIN_FILM (IDCATEGORIE);
CREATE INDEX IX_CIN_FILM_ACTEUR ON CIN_FILM (IDACTEUR);

-- Une photo (affiche) par film ; supprimee avec le film
CREATE TABLE CIN_FILM_PHOTO (
    IDFILM      VARCHAR2(50)  NOT NULL,
    CONTENU     BLOB          NOT NULL,
    TYPE_MIME   VARCHAR2(50)  NOT NULL,
    NOM_FICHIER VARCHAR2(255),
    TAILLE      NUMBER(10),
    DATE_MAJ    DATE DEFAULT SYSDATE,
    CONSTRAINT PK_CIN_FILM_PHOTO PRIMARY KEY (IDFILM),
    CONSTRAINT FK_CIN_FILM_PHOTO_FILM FOREIGN KEY (IDFILM) REFERENCES CIN_FILM (ID) ON DELETE CASCADE
);

CREATE SEQUENCE SEQ_CIN_FILM START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE OR REPLACE FUNCTION GETSEQCINFILM RETURN NUMBER IS
    retour NUMBER;
BEGIN
    SELECT SEQ_CIN_FILM.NEXTVAL INTO retour FROM DUAL;
    RETURN retour;
END;
/

-- Film avec categorie, acteur (nom de scene, sinon nom), duree lisible, etat, presence d'une photo
CREATE OR REPLACE VIEW CIN_FILM_LIB AS
SELECT f.ID, f.TITRE, f.IDCATEGORIE, c.VAL AS IDCATEGORIELIB, f.IDACTEUR,
       NVL(a.NOM_ACTEUR, a.NOM) AS IDACTEURLIB, f.DUREE,
       TRUNC(f.DUREE / 60) || ' h ' || LPAD(MOD(f.DUREE, 60), 2, '0') AS DUREELIB,
       f.PA, f.DESCRIPTION, f.DATE_CREATION, f.ETAT, DECODE(f.ETAT, 1, 'Actif', 'Inactif') AS ETATLIB,
       CASE WHEN p.IDFILM IS NULL THEN 0 ELSE 1 END AS A_PHOTO
FROM CIN_FILM f
JOIN CIN_CATEGORIE_FILM c ON c.ID = f.IDCATEGORIE
JOIN CIN_ACTEUR a ON a.ID = f.IDACTEUR
LEFT JOIN CIN_FILM_PHOTO p ON p.IDFILM = f.ID;

-- ---------------------------------------------------------------------
-- Menus : Cinema > Films > (Saisie, Liste)
-- ---------------------------------------------------------------------
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA03', 'Films', 'movie', NULL, 3, 2, 'MENDYNCINEMA');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA0301', 'Saisie', 'add', 'module.jsp?but=cinema/film/film-saisie.jsp', 1, 3, 'MENDYNCINEMA03');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA0302', 'Liste', 'list', 'module.jsp?but=cinema/film/film-liste.jsp', 2, 3, 'MENDYNCINEMA03');

COMMIT;

-- Controle
-- SELECT ID, TITRE, IDCATEGORIELIB, IDACTEURLIB, DUREELIB, PA, A_PHOTO FROM CIN_FILM_LIB;
