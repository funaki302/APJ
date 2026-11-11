-- =====================================================================
-- CINEMA - Etape 5 : diffusions (seances)
-- Table : CIN_DIFFUSION ; vue : CIN_DIFFUSION_LIB ; menus Cinema > Diffusions.
-- Prerequis : etape-2-salles.sql et etape-3-films.sql. Se reconnecter apres execution (menu en session).
-- Une diffusion = un film dans une salle, a une date (DATY) et une heure (HEURE 'HH24:MI').
-- Fin de la seance = debut + duree du film. Deux seances actives d'une meme salle ne se chevauchent pas
-- (controle Java, sans marge de nettoyage en v1).
-- ETAT : 1 = programmee, 0 = annulee. La vue calcule aussi "En cours" et "Terminee".
-- =====================================================================

SET DEFINE OFF;

CREATE TABLE CIN_DIFFUSION (
    ID            VARCHAR2(50) NOT NULL,
    IDFILM        VARCHAR2(50) NOT NULL,
    IDSALLE       VARCHAR2(50) NOT NULL,
    DATY          DATE         NOT NULL,
    HEURE         VARCHAR2(5)  NOT NULL,
    DATE_CREATION DATE DEFAULT SYSDATE,
    ETAT          NUMBER(2) DEFAULT 1,
    CONSTRAINT PK_CIN_DIFFUSION PRIMARY KEY (ID),
    CONSTRAINT FK_CIN_DIFFUSION_FILM FOREIGN KEY (IDFILM) REFERENCES CIN_FILM (ID),
    CONSTRAINT FK_CIN_DIFFUSION_SALLE FOREIGN KEY (IDSALLE) REFERENCES CIN_SALLE (ID),
    CONSTRAINT CK_CIN_DIFFUSION_HEURE CHECK (REGEXP_LIKE(HEURE, '^([01][0-9]|2[0-3]):[0-5][0-9]$')),
    CONSTRAINT CK_CIN_DIFFUSION_ETAT CHECK (ETAT IN (0, 1))
);

CREATE INDEX IX_CIN_DIFFUSION_SALLE ON CIN_DIFFUSION (IDSALLE, DATY);
CREATE INDEX IX_CIN_DIFFUSION_FILM ON CIN_DIFFUSION (IDFILM);

CREATE SEQUENCE SEQ_CIN_DIFFUSION START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE OR REPLACE FUNCTION GETSEQCINDIFFUSION RETURN NUMBER IS
    retour NUMBER;
BEGIN
    SELECT SEQ_CIN_DIFFUSION.NEXTVAL INTO retour FROM DUAL;
    RETURN retour;
END;
/

-- Diffusion avec film, salle, cinema, debut / fin de seance, statut calcule et places en service de la salle
CREATE OR REPLACE VIEW CIN_DIFFUSION_LIB AS
SELECT x.*,
       TO_CHAR(x.DATE_FIN, 'HH24:MI') AS HEURE_FIN,
       CASE WHEN x.ETAT = 0 THEN 'Annul&eacute;e'
            WHEN x.DATE_FIN <= SYSDATE THEN 'Termin&eacute;e'
            WHEN x.DATE_DEBUT <= SYSDATE THEN 'En cours'
            ELSE 'Programm&eacute;e' END AS ETATLIB
FROM (
    SELECT d.ID, d.IDFILM, f.TITRE AS IDFILMLIB, f.DUREE,
           TRUNC(f.DUREE / 60) || ' h ' || LPAD(MOD(f.DUREE, 60), 2, '0') AS DUREELIB,
           d.IDSALLE, s.NOM AS IDSALLELIB, s.IDCINEMA, c.NOM AS IDCINEMALIB,
           d.DATY, d.HEURE,
           TO_DATE(TO_CHAR(d.DATY, 'YYYY-MM-DD') || ' ' || d.HEURE, 'YYYY-MM-DD HH24:MI') AS DATE_DEBUT,
           TO_DATE(TO_CHAR(d.DATY, 'YYYY-MM-DD') || ' ' || d.HEURE, 'YYYY-MM-DD HH24:MI') + f.DUREE / 1440 AS DATE_FIN,
           (SELECT COUNT(*) FROM CIN_PLACE p WHERE p.IDSALLE = d.IDSALLE AND p.ETAT = 1) AS NB_PLACES,
           d.DATE_CREATION, d.ETAT
    FROM CIN_DIFFUSION d
    JOIN CIN_FILM f ON f.ID = d.IDFILM
    JOIN CIN_SALLE s ON s.ID = d.IDSALLE
    JOIN CIN_CINEMA c ON c.ID = s.IDCINEMA
) x;

-- ---------------------------------------------------------------------
-- Menus : Cinema > Diffusions > (Saisie, Liste, Calendrier)
-- ---------------------------------------------------------------------
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA05', 'Diffusions', 'event', NULL, 5, 2, 'MENDYNCINEMA');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA0501', 'Saisie', 'add', 'module.jsp?but=cinema/diffusion/diffusion-saisie.jsp', 1, 3, 'MENDYNCINEMA05');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA0502', 'Liste', 'list', 'module.jsp?but=cinema/diffusion/diffusion-liste.jsp', 2, 3, 'MENDYNCINEMA05');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA0503', 'Calendrier', 'calendar_month', 'module.jsp?but=cinema/diffusion/diffusion-calendrier.jsp', 3, 3, 'MENDYNCINEMA05');

COMMIT;

-- Controle
-- SELECT ID, IDFILMLIB, IDSALLELIB, DATY, HEURE, HEURE_FIN, ETATLIB FROM CIN_DIFFUSION_LIB ORDER BY DATE_DEBUT;
