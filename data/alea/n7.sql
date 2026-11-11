SET DEFINE OFF;
-- =====================================================================
-- ESTIMATION v2 : duree de vie, poussins existants, lots recus non tries,
--                 poussins a venir des poussins estimes (2 generations)
-- Ordre d'execution : 1) ALTER  2) V_POUSSINS_EXISTANTS  3) V_ESTIMATION_POUSSIN
--                     4) V_ESTIM_POUSSIN_CALENDRIER
-- =====================================================================

-- 1) Duree de vie d'un lot (en jours, comptee depuis son arrivee).
--    NULL = pas de limite. Au-dela, le lot ne produit plus d'oeufs.
ALTER TABLE SOUCHE ADD (DUREE_VIE_JOURS NUMBER);
-- Exemple (a adapter, ce n'est pas execute) :
UPDATE SOUCHE SET DUREE_VIE_JOURS = 100;  COMMIT;

-- 2) Poussins existants par lot (stock a ce jour)
--    QTE_EXISTANTS = QTERECUS - MORTS (reception)
--                    - (MORTS + PERDUS) constates au triage
--                    - pertes (MORTALITE + CULLS + TRI) des suivis VALIDES (ETAT = 11)
--    Note : PERDUS de la reception (= quantite du BL - quantite recue) n'est PAS retire,
--    car ces poussins ne sont deja pas dans QTERECUS.
CREATE OR REPLACE VIEW V_POUSSINS_EXISTANTS AS
WITH rec AS (
    SELECT r.IDLOT,
           SUM(NVL(r.QTERECUS, 0)) AS QTE_RECUE,
           SUM(NVL(r.MORTS, 0))    AS MORTS_RECEPTION,
           SUM(NVL(r.PERDUS, 0))   AS PERDUS_RECEPTION
    FROM RECEPTIONPOUSSINAEROPORT r
    GROUP BY r.IDLOT
),
tri AS (
    SELECT t.IDLOT, SUM(NVL(t.MORTS, 0) + NVL(t.PERDUS, 0)) AS PERTES_TRIAGE
    FROM TRIAGEBATIMENTPARQUET t
    GROUP BY t.IDLOT
),
suivi AS (
    SELECT s.IDLOT,
           SUM(NVL(sd.MORTALITE, 0) + NVL(sd.CULLS, 0) + NVL(sd.TRI, 0)) AS PERTES_SUIVI
    FROM SUIVIJOURNALIER s
             JOIN SUIVIJOURNALIERDETAIL sd ON sd.IDMERE = s.ID
    WHERE s.ETAT = 11
    GROUP BY s.IDLOT
)
SELECT l.ID AS IDLOT,
       l.NOMLOT,
       so.VAL AS SOUCHE,
       rec.QTE_RECUE,
       rec.MORTS_RECEPTION,
       rec.PERDUS_RECEPTION,
       NVL(tri.PERTES_TRIAGE, 0)  AS PERTES_TRIAGE,
       NVL(suivi.PERTES_SUIVI, 0) AS PERTES_SUIVI,
       GREATEST(0, rec.QTE_RECUE - rec.MORTS_RECEPTION - NVL(tri.PERTES_TRIAGE, 0) - NVL(suivi.PERTES_SUIVI, 0)) AS QTE_EXISTANTS
FROM LOT l
         JOIN rec            ON rec.IDLOT = l.ID
         LEFT JOIN tri       ON tri.IDLOT = l.ID
         LEFT JOIN suivi     ON suivi.IDLOT = l.ID
         LEFT JOIN SOUCHE so ON so.ID = l.IDSOUCHE;

-- 3) Estimation detaillee
--  GENERATION 1 : poussins a venir des poules RECUES.
--      - lot trie     : une ligne par ligne de triage FEMELLE (comme avant, pertes des suivis valides deduites)
--      - lot non trie : une ligne par lot, femelles = lignes FEMELLES de la reception aeroport
--  GENERATION 2 : poussins a venir des POUSSINS ESTIMES de la generation 1.
--      Les poussins estimes d'un lot, groupes par date d'eclosion, forment des cohortes "nees" ce jour-la.
--      On suppose 50 % de femelles (constante PRC_FEMELLES ci-dessous, a ajuster).
--      Aucune perte n'est prevue sur ces cohortes.
--  Duree de vie : une poule ne pond plus des que  jour de ponte >= date d'arrivee (ou de naissance) + DUREE_VIE_JOURS.
CREATE OR REPLACE VIEW V_ESTIMATION_POUSSIN AS
WITH param AS (
    SELECT 0.5 AS PRC_FEMELLES FROM DUAL
),
perte AS (
    SELECT s.IDLOT, sd.IDBATIMENT, sd.IDPARQUET, TRUNC(s.DATY) AS DATY,
           SUM(NVL(sd.MORTALITE, 0) + NVL(sd.CULLS, 0) + NVL(sd.TRI, 0)) AS PERTE
    FROM SUIVIJOURNALIER s
             JOIN SUIVIJOURNALIERDETAIL sd ON sd.IDMERE = s.ID
    WHERE s.ETAT = 11
    GROUP BY s.IDLOT, sd.IDBATIMENT, sd.IDPARQUET, TRUNC(s.DATY)
),
rec_f AS (   -- femelles vivantes a la reception, par lot
    SELECT r.IDLOT, MIN(r.ID) AS IDRECEPTION, MIN(r.DATY) AS DATY_RECEPTION, SUM(NVL(d.QTE, 0)) AS QTE_FEM
    FROM RECEPTIONPOUSSINAEROPORT r
             JOIN RECEPTIONPOUSSINAEROPORTDETAIL d ON d.IDMERE = r.ID
             JOIN SEXE sx                          ON sx.ID = d.IDSEXE
    WHERE UPPER(sx.VAL) LIKE 'F%'
    GROUP BY r.IDLOT
),
src AS (
    -- lots tries : lignes de triage FEMELLES vivantes
    SELECT d.ID                                   AS IDDETAIL,
           d.IDMERE                               AS IDTRIAGE,
           t.IDLOT                                AS IDLOT,
           d.IDBATIMENT                           AS IDBATIMENT,
           d.IDPARQUET                            AS IDPARQUET,
           NVL(p.VAL, d.IDPARQUET)                AS PARQUET,
           d.QTE                                  AS QTE_SRC,
           SUM(d.QTE) OVER (PARTITION BY t.IDLOT, d.IDBATIMENT, d.IDPARQUET) AS QTE_PARQUET,
           NVL(l.DATEARRIVEE, t.DATY)             AS DATE_ARRIVEE
    FROM TRIAGEBATIMENTPARQUETDETAIL d
             JOIN TRIAGEBATIMENTPARQUET t ON t.ID  = d.IDMERE
             JOIN LOT l                   ON l.ID  = t.IDLOT
             JOIN SEXE sx                 ON sx.ID = d.IDSEXE
             LEFT JOIN PARQUET p          ON p.ID  = d.IDPARQUET
    WHERE UPPER(sx.VAL) LIKE 'F%'
      AND NVL(d.SANTE, 10) > 0
      AND NVL(d.QTE, 0) > 0
    UNION ALL
    -- lots recus mais pas encore tries
    SELECT rf.IDRECEPTION,
           CAST(NULL AS VARCHAR2(100)),
           rf.IDLOT,
           CAST(NULL AS VARCHAR2(100)),
           CAST(NULL AS VARCHAR2(100)),
           'Non trie',
           rf.QTE_FEM,
           rf.QTE_FEM,
           NVL(l.DATEARRIVEE, rf.DATY_RECEPTION)
    FROM rec_f rf
             JOIN LOT l ON l.ID = rf.IDLOT
    WHERE rf.QTE_FEM > 0
      AND NOT EXISTS (SELECT 1 FROM TRIAGEBATIMENTPARQUET t WHERE t.IDLOT = rf.IDLOT)
),
base AS (
    SELECT s.IDDETAIL, s.IDTRIAGE, s.IDLOT, l.NOMLOT, s.IDBATIMENT, s.IDPARQUET, s.PARQUET,
           so.ID  AS IDSOUCHE,
           so.VAL AS SOUCHE,
           s.QTE_SRC AS QTE_TRIAGE,
           s.QTE_PARQUET,
           TRUNC(s.DATE_ARRIVEE)                                           AS DATE_ARRIVEE,
           TRUNC(s.DATE_ARRIVEE) + so.AGE_ENTREE_PONTE_JOUR                AS DATE_DEBUT_PONTE,
           so.DUREE_INCUBATION_JOUR,
           NVL(so.PRC_LAMOKANY, 0)                                         AS PRC_LAMOKANY,
           so.POTENTIEL_PONTE,
           so.DUREE_VIE_JOURS,
           so.FREQUENCE_VAL / so.FREQUENCE_JOUR                            AS TAUX_PONTE_JOUR,
           CEIL(so.POTENTIEL_PONTE / (so.FREQUENCE_VAL / so.FREQUENCE_JOUR)) AS NB_JOURS_PONTE
    FROM src s
             JOIN LOT l    ON l.ID  = s.IDLOT
             JOIN SOUCHE so ON so.ID = l.IDSOUCHE
    WHERE NVL(so.FREQUENCE_VAL, 0)  > 0
      AND NVL(so.FREQUENCE_JOUR, 0) > 0
      AND NVL(so.POTENTIEL_PONTE, 0) > 0
      AND so.AGE_ENTREE_PONTE_JOUR IS NOT NULL
      AND so.DUREE_INCUBATION_JOUR IS NOT NULL
      AND s.DATE_ARRIVEE IS NOT NULL
),
jours AS (
    SELECT LEVEL - 1 AS K FROM DUAL CONNECT BY LEVEL <= 2000
),
-- ---------- generation 1 ----------
g1 AS (
    SELECT b.*, j.K,
           b.DATE_DEBUT_PONTE + j.K AS DATE_PONTE,
           GREATEST(0, b.QTE_TRIAGE - NVL((SELECT SUM(pt.PERTE)
                                            FROM perte pt
                                            WHERE pt.IDLOT = b.IDLOT
                                              AND pt.IDBATIMENT = b.IDBATIMENT
                                              AND pt.IDPARQUET = b.IDPARQUET
                                              AND pt.DATY <= b.DATE_DEBUT_PONTE + j.K), 0)
                                          * b.QTE_TRIAGE / b.QTE_PARQUET) AS NB_FEMELLES
    FROM base b
             JOIN jours j ON j.K < b.NB_JOURS_PONTE
    WHERE b.DUREE_VIE_JOURS IS NULL
       OR b.DATE_DEBUT_PONTE + j.K < b.DATE_ARRIVEE + b.DUREE_VIE_JOURS
),
g1e AS (
    SELECT g.*,
           g.DATE_PONTE + g.DUREE_INCUBATION_JOUR AS DATE_ECLOSION,
           g.NB_FEMELLES * LEAST(g.TAUX_PONTE_JOUR, g.POTENTIEL_PONTE - g.K * g.TAUX_PONTE_JOUR) AS OEUFS
    FROM g1 g
),
-- ---------- generation 2 : cohortes = poussins estimes de la generation 1 ----------
cohorte AS (
    SELECT e.IDLOT, e.NOMLOT, e.IDSOUCHE, e.SOUCHE, e.DATE_ECLOSION AS DATE_NAISSANCE,
           SUM(e.OEUFS * (1 - e.PRC_LAMOKANY / 100)) AS NB_POUSSINS
    FROM g1e e
    GROUP BY e.IDLOT, e.NOMLOT, e.IDSOUCHE, e.SOUCHE, e.DATE_ECLOSION
),
g2b AS (
    SELECT c.IDLOT, c.NOMLOT, c.IDSOUCHE, c.SOUCHE, c.DATE_NAISSANCE,
           c.NB_POUSSINS * pa.PRC_FEMELLES                    AS NB_FEMELLES,
           c.DATE_NAISSANCE + so.AGE_ENTREE_PONTE_JOUR        AS DATE_DEBUT_PONTE,
           so.DUREE_INCUBATION_JOUR,
           NVL(so.PRC_LAMOKANY, 0)                            AS PRC_LAMOKANY,
           so.POTENTIEL_PONTE,
           so.DUREE_VIE_JOURS,
           so.FREQUENCE_VAL / so.FREQUENCE_JOUR               AS TAUX_PONTE_JOUR,
           CEIL(so.POTENTIEL_PONTE / (so.FREQUENCE_VAL / so.FREQUENCE_JOUR)) AS NB_JOURS_PONTE
    FROM cohorte c
             JOIN SOUCHE so ON so.ID = c.IDSOUCHE
             CROSS JOIN param pa
    WHERE c.NB_POUSSINS > 0
),
g2 AS (
    SELECT b.IDLOT, b.NOMLOT, b.IDSOUCHE, b.SOUCHE,
           b.DATE_DEBUT_PONTE + j.K                                  AS DATE_PONTE,
           b.DATE_DEBUT_PONTE + j.K + b.DUREE_INCUBATION_JOUR        AS DATE_ECLOSION,
           b.NB_FEMELLES                                             AS NB_FEMELLES,
           b.NB_FEMELLES * LEAST(b.TAUX_PONTE_JOUR, b.POTENTIEL_PONTE - j.K * b.TAUX_PONTE_JOUR) AS OEUFS,
           b.NB_FEMELLES * LEAST(b.TAUX_PONTE_JOUR, b.POTENTIEL_PONTE - j.K * b.TAUX_PONTE_JOUR)
               * (1 - b.PRC_LAMOKANY / 100)                          AS POUSSINS
    FROM g2b b
             JOIN jours j ON j.K < b.NB_JOURS_PONTE
    WHERE b.DUREE_VIE_JOURS IS NULL
       OR b.DATE_DEBUT_PONTE + j.K < b.DATE_NAISSANCE + b.DUREE_VIE_JOURS
),
g2a AS (   -- regroupe par lot et jour de ponte (plusieurs cohortes pondent le meme jour)
    SELECT IDLOT, NOMLOT, IDSOUCHE, SOUCHE, DATE_PONTE, DATE_ECLOSION,
           SUM(NB_FEMELLES) AS NB_FEMELLES, SUM(OEUFS) AS OEUFS, SUM(POUSSINS) AS POUSSINS
    FROM g2
    GROUP BY IDLOT, NOMLOT, IDSOUCHE, SOUCHE, DATE_PONTE, DATE_ECLOSION
)
SELECT e.IDDETAIL, e.IDTRIAGE, e.IDLOT, e.NOMLOT, e.IDBATIMENT, e.IDPARQUET, e.PARQUET,
       e.IDSOUCHE, e.SOUCHE,
       ROUND(e.NB_FEMELLES, 2)                                  AS NB_FEMELLES,
       e.DATE_PONTE,
       e.DATE_ECLOSION,
       e.OEUFS                                                  AS NB_OEUFS_ESTIMES,
       e.OEUFS * (1 - e.PRC_LAMOKANY / 100)                     AS NB_POUSSINS_ESTIMES,
       1                                                        AS GENERATION,
       NVL(x.QTE_EXISTANTS, 0)                                  AS QTE_EXISTANTS
FROM g1e e
         LEFT JOIN V_POUSSINS_EXISTANTS x ON x.IDLOT = e.IDLOT
UNION ALL
SELECT 'EST-' || a.IDLOT                                        AS IDDETAIL,
       CAST(NULL AS VARCHAR2(100))                              AS IDTRIAGE,
       a.IDLOT, a.NOMLOT,
       CAST(NULL AS VARCHAR2(100))                              AS IDBATIMENT,
       CAST(NULL AS VARCHAR2(100))                              AS IDPARQUET,
       'Poussins estimes'                                       AS PARQUET,
       a.IDSOUCHE, a.SOUCHE,
       ROUND(a.NB_FEMELLES, 2)                                  AS NB_FEMELLES,
       a.DATE_PONTE,
       a.DATE_ECLOSION,
       a.OEUFS                                                  AS NB_OEUFS_ESTIMES,
       a.POUSSINS                                               AS NB_POUSSINS_ESTIMES,
       2                                                        AS GENERATION,
       NVL(x.QTE_EXISTANTS, 0)                                  AS QTE_EXISTANTS
FROM g2a a
         LEFT JOIN V_POUSSINS_EXISTANTS x ON x.IDLOT = a.IDLOT;

-- 4) Calendrier (meme logique, + GENERATION et QTE_EXISTANTS ; NB_FEMELLES additionne les
--    femelles qui pondent ce jour-la ; arrondi a 2 decimales pour ne pas perdre de poussins
--    dans les totaux)
CREATE OR REPLACE VIEW V_ESTIM_POUSSIN_CALENDRIER AS
SELECT
    DATE_ECLOSION,
    IDDETAIL,
    IDTRIAGE,
    IDLOT,
    NOMLOT,
    IDBATIMENT,
    IDPARQUET,
    PARQUET,
    SOUCHE,
    GENERATION,
    MAX(QTE_EXISTANTS)                  AS QTE_EXISTANTS,
    ROUND(SUM(NB_FEMELLES), 2)          AS NB_FEMELLES,
    ROUND(SUM(NB_OEUFS_ESTIMES), 2)     AS NB_OEUFS_ESTIMES,
    ROUND(SUM(NB_POUSSINS_ESTIMES), 2)  AS NB_POUSSINS_ESTIMES
FROM V_ESTIMATION_POUSSIN
GROUP BY DATE_ECLOSION, IDDETAIL, IDTRIAGE, IDLOT, NOMLOT, IDBATIMENT, IDPARQUET, PARQUET, SOUCHE, GENERATION;

-- Verification
SELECT OBJECT_NAME, STATUS FROM USER_OBJECTS
WHERE OBJECT_NAME IN ('V_POUSSINS_EXISTANTS', 'V_ESTIMATION_POUSSIN', 'V_ESTIM_POUSSIN_CALENDRIER');
