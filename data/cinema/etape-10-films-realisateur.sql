-- =====================================================================
-- CINEMA - Etape 10 (12/11/2026) : colonnes demandees par les donnees du programme de novembre
-- Film : REALISATEUR et CLASSIFICATION (Tous publics, -12, -16, -18) ; acteur principal devenu facultatif
-- (les donnees fournies donnent le realisateur, pas l'acteur). Vue CIN_FILM_LIB recreee avec ces colonnes.
-- Prerequis : etape-3-films.sql (et les suivantes). Aucun menu ajoute.
-- =====================================================================

SET DEFINE OFF;

ALTER TABLE CIN_FILM ADD (
    REALISATEUR    VARCHAR2(255),
    CLASSIFICATION VARCHAR2(20)
);

ALTER TABLE CIN_FILM ADD CONSTRAINT CK_CIN_FILM_CLASSIFICATION
    CHECK (CLASSIFICATION IS NULL OR CLASSIFICATION IN ('Tous publics', '-12', '-16', '-18'));

ALTER TABLE CIN_FILM MODIFY (IDACTEUR NULL);

-- Film avec categorie, realisateur, acteur (facultatif), classification, duree lisible, etat, presence d'une photo
CREATE OR REPLACE VIEW CIN_FILM_LIB AS
SELECT f.ID, f.TITRE, f.IDCATEGORIE, c.VAL AS IDCATEGORIELIB, f.REALISATEUR, f.IDACTEUR,
       NVL(a.NOM_ACTEUR, a.NOM) AS IDACTEURLIB, f.CLASSIFICATION, f.DUREE,
       TRUNC(f.DUREE / 60) || ' h ' || LPAD(MOD(f.DUREE, 60), 2, '0') AS DUREELIB,
       f.PA, f.DESCRIPTION, f.DATE_CREATION, f.ETAT, DECODE(f.ETAT, 1, 'Actif', 'Inactif') AS ETATLIB,
       CASE WHEN p.IDFILM IS NULL THEN 0 ELSE 1 END AS A_PHOTO
FROM CIN_FILM f
JOIN CIN_CATEGORIE_FILM c ON c.ID = f.IDCATEGORIE
LEFT JOIN CIN_ACTEUR a ON a.ID = f.IDACTEUR
LEFT JOIN CIN_FILM_PHOTO p ON p.IDFILM = f.ID;

COMMIT;
