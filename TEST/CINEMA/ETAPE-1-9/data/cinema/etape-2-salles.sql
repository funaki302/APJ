-- =====================================================================
-- CINEMA - Etape 2 : salles et places
-- Tables : CIN_SALLE, CIN_PLACE ; vues : CIN_SALLE_LIB, CIN_PLACE_LIB ; menus Cinema > Salles.
-- Prerequis : etape-1-referentiels.sql. Se reconnecter apres execution (menu en session).
-- Les places sont generees par le Java a la creation d'une salle (rangees x colonnes).
-- Le prix d'une place n'est pas stocke : c'est celui de sa classe (vue CIN_PLACE_LIB).
-- ETAT salle : 1 = active, 0 = inactive. ETAT place : 1 = en service, 0 = hors service.
-- =====================================================================

SET DEFINE OFF;

CREATE TABLE CIN_SALLE (
    ID            VARCHAR2(50)  NOT NULL,
    IDCINEMA      VARCHAR2(50)  NOT NULL,
    NOM           VARCHAR2(255) NOT NULL,
    NB_RANGEES    NUMBER(3)     NOT NULL,
    NB_COLONNES   NUMBER(3)     NOT NULL,
    CAPACITE      NUMBER(6)     NOT NULL,
    DATE_CREATION DATE DEFAULT SYSDATE,
    ETAT          NUMBER(2) DEFAULT 1,
    CONSTRAINT PK_CIN_SALLE PRIMARY KEY (ID),
    CONSTRAINT FK_CIN_SALLE_CINEMA FOREIGN KEY (IDCINEMA) REFERENCES CIN_CINEMA (ID),
    CONSTRAINT UK_CIN_SALLE_NOM UNIQUE (IDCINEMA, NOM),
    CONSTRAINT CK_CIN_SALLE_RANGEES CHECK (NB_RANGEES BETWEEN 1 AND 26),
    CONSTRAINT CK_CIN_SALLE_COLONNES CHECK (NB_COLONNES BETWEEN 1 AND 40),
    CONSTRAINT CK_CIN_SALLE_ETAT CHECK (ETAT IN (0, 1))
);

-- Une place par (rangee, colonne). NUMERO = lettre de la rangee + colonne (A1, A2... B1...).
-- ON DELETE CASCADE : supprimer une salle supprime ses places.
CREATE TABLE CIN_PLACE (
    ID       VARCHAR2(50) NOT NULL,
    IDSALLE  VARCHAR2(50) NOT NULL,
    IDCLASSE VARCHAR2(50) NOT NULL,
    NUMERO   VARCHAR2(10) NOT NULL,
    RANGEE   NUMBER(3)    NOT NULL,
    COLONNE  NUMBER(3)    NOT NULL,
    ETAT     NUMBER(2) DEFAULT 1,
    CONSTRAINT PK_CIN_PLACE PRIMARY KEY (ID),
    CONSTRAINT FK_CIN_PLACE_SALLE FOREIGN KEY (IDSALLE) REFERENCES CIN_SALLE (ID) ON DELETE CASCADE,
    CONSTRAINT FK_CIN_PLACE_CLASSE FOREIGN KEY (IDCLASSE) REFERENCES CIN_CLASSE_PLACE (ID),
    CONSTRAINT UK_CIN_PLACE_POSITION UNIQUE (IDSALLE, RANGEE, COLONNE),
    CONSTRAINT UK_CIN_PLACE_NUMERO UNIQUE (IDSALLE, NUMERO),
    CONSTRAINT CK_CIN_PLACE_ETAT CHECK (ETAT IN (0, 1))
);

CREATE INDEX IX_CIN_PLACE_CLASSE ON CIN_PLACE (IDCLASSE);

CREATE SEQUENCE SEQ_CIN_SALLE START WITH 1 INCREMENT BY 1 NOCACHE;
-- Beaucoup de places : sequence avec cache
CREATE SEQUENCE SEQ_CIN_PLACE START WITH 1 INCREMENT BY 1 CACHE 100;

CREATE OR REPLACE FUNCTION GETSEQCINSALLE RETURN NUMBER IS
    retour NUMBER;
BEGIN
    SELECT SEQ_CIN_SALLE.NEXTVAL INTO retour FROM DUAL;
    RETURN retour;
END;
/

CREATE OR REPLACE FUNCTION GETSEQCINPLACE RETURN NUMBER IS
    retour NUMBER;
BEGIN
    SELECT SEQ_CIN_PLACE.NEXTVAL INTO retour FROM DUAL;
    RETURN retour;
END;
/

-- Salle avec le nom du cinema, le libelle de l'etat et le nombre de places en service
CREATE OR REPLACE VIEW CIN_SALLE_LIB AS
SELECT s.ID, s.IDCINEMA, c.NOM AS IDCINEMALIB, s.NOM, s.NB_RANGEES, s.NB_COLONNES, s.CAPACITE,
       s.DATE_CREATION, s.ETAT, DECODE(s.ETAT, 1, 'Active', 'Inactive') AS ETATLIB,
       (SELECT COUNT(*) FROM CIN_PLACE p WHERE p.IDSALLE = s.ID AND p.ETAT = 1) AS NB_PLACES_SERVICE
FROM CIN_SALLE s
JOIN CIN_CINEMA c ON c.ID = s.IDCINEMA;

-- Place avec sa classe : libelle, couleur et prix (le prix d'une place = prix de sa classe)
CREATE OR REPLACE VIEW CIN_PLACE_LIB AS
SELECT p.ID, p.IDSALLE, s.NOM AS IDSALLELIB, p.IDCLASSE, cl.VAL AS IDCLASSELIB, cl.COULEUR, cl.PRIX,
       p.NUMERO, p.RANGEE, p.COLONNE, p.ETAT, DECODE(p.ETAT, 1, 'En service', 'Hors service') AS ETATLIB
FROM CIN_PLACE p
JOIN CIN_SALLE s ON s.ID = p.IDSALLE
JOIN CIN_CLASSE_PLACE cl ON cl.ID = p.IDCLASSE;

-- ---------------------------------------------------------------------
-- Menus : Cinema > Salles > (Saisie, Liste)
-- ---------------------------------------------------------------------
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA02', 'Salles', 'chair', NULL, 2, 2, 'MENDYNCINEMA');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA0201', 'Saisie', 'add', 'module.jsp?but=cinema/salle/salle-saisie.jsp', 1, 3, 'MENDYNCINEMA02');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA0202', 'Liste', 'list', 'module.jsp?but=cinema/salle/salle-liste.jsp', 2, 3, 'MENDYNCINEMA02');

COMMIT;

-- Controle
-- SELECT * FROM CIN_SALLE_LIB;
-- SELECT IDCLASSELIB, COUNT(*) FROM CIN_PLACE_LIB WHERE IDSALLE = '...' GROUP BY IDCLASSELIB;
