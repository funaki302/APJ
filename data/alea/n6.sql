-- =====================================================================
-- V_ESTIMATION_POUSSIN reactive aux suivis journaliers VALIDES (ETAT = 11)
--   NB_FEMELLES (au jour de ponte) = QTE du triage - pertes cumulees des suivis valides
--   dont la date <= jour de ponte, au prorata si un parquet a plusieurs lignes de triage.
--   pertes = MORTALITE + CULLS + TRI. Apres le dernier suivi valide, l'effectif reste
--   constant (aucune prevision de mortalite future).
--   V_ESTIM_POUSSIN_CALENDRIER et la classe Java ne changent pas.
-- =====================================================================
CREATE OR REPLACE VIEW V_ESTIMATION_POUSSIN AS
WITH perte AS (
    SELECT s.IDLOT, sd.IDBATIMENT, sd.IDPARQUET, TRUNC(s.DATY) AS DATY,
           SUM(NVL(sd.MORTALITE, 0) + NVL(sd.CULLS, 0) + NVL(sd.TRI, 0)) AS PERTE
    FROM SUIVIJOURNALIER s
             JOIN SUIVIJOURNALIERDETAIL sd ON sd.IDMERE = s.ID
    WHERE s.ETAT = 11
    GROUP BY s.IDLOT, sd.IDBATIMENT, sd.IDPARQUET, TRUNC(s.DATY)
),
base AS (
    SELECT
        d.ID                                                   AS IDDETAIL,
        d.IDMERE                                               AS IDTRIAGE,
        t.IDLOT,
        l.NOMLOT,
        d.IDBATIMENT,
        d.IDPARQUET,
        NVL(p.VAL, d.IDPARQUET)                                AS PARQUET,
        s.ID                                                   AS IDSOUCHE,
        s.VAL                                                  AS SOUCHE,
        d.QTE                                                  AS QTE_TRIAGE,
        SUM(d.QTE) OVER (PARTITION BY t.IDLOT, d.IDBATIMENT, d.IDPARQUET) AS QTE_PARQUET,
        TRUNC(NVL(l.DATEARRIVEE, t.DATY)) + s.AGE_ENTREE_PONTE_JOUR       AS DATE_DEBUT_PONTE,
        s.DUREE_INCUBATION_JOUR,
        NVL(s.PRC_LAMOKANY, 0)                                 AS PRC_LAMOKANY,
        s.POTENTIEL_PONTE,
        s.FREQUENCE_VAL / s.FREQUENCE_JOUR                     AS TAUX_PONTE_JOUR,
        CEIL(s.POTENTIEL_PONTE / (s.FREQUENCE_VAL / s.FREQUENCE_JOUR)) AS NB_JOURS_PONTE
    FROM TRIAGEBATIMENTPARQUETDETAIL d
    JOIN TRIAGEBATIMENTPARQUET t ON t.ID  = d.IDMERE
    JOIN LOT l                   ON l.ID  = t.IDLOT
    JOIN SOUCHE s                ON s.ID  = l.IDSOUCHE
    JOIN SEXE sx                 ON sx.ID = d.IDSEXE
    LEFT JOIN PARQUET p          ON p.ID  = d.IDPARQUET
    WHERE UPPER(sx.VAL) LIKE 'F%'
      AND NVL(d.SANTE, 10) > 0
      AND NVL(d.QTE, 0)    > 0
      AND NVL(s.FREQUENCE_VAL, 0)  > 0
      AND NVL(s.FREQUENCE_JOUR, 0) > 0
      AND NVL(s.POTENTIEL_PONTE, 0) > 0
      AND s.AGE_ENTREE_PONTE_JOUR IS NOT NULL
      AND s.DUREE_INCUBATION_JOUR IS NOT NULL
      AND NVL(l.DATEARRIVEE, t.DATY) IS NOT NULL
),
jours AS (
    SELECT LEVEL - 1 AS K FROM DUAL CONNECT BY LEVEL <= 2000
),
calc AS (
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
)
SELECT
    c.IDDETAIL, c.IDTRIAGE, c.IDLOT, c.NOMLOT, c.IDBATIMENT, c.IDPARQUET, c.PARQUET,
    c.IDSOUCHE, c.SOUCHE,
    ROUND(c.NB_FEMELLES, 2)                                   AS NB_FEMELLES,
    c.DATE_PONTE,
    c.DATE_PONTE + c.DUREE_INCUBATION_JOUR                    AS DATE_ECLOSION,
    c.NB_FEMELLES * LEAST(c.TAUX_PONTE_JOUR, c.POTENTIEL_PONTE - c.K * c.TAUX_PONTE_JOUR)
                                                              AS NB_OEUFS_ESTIMES,
    c.NB_FEMELLES * LEAST(c.TAUX_PONTE_JOUR, c.POTENTIEL_PONTE - c.K * c.TAUX_PONTE_JOUR)
        * (1 - c.PRC_LAMOKANY / 100)                          AS NB_POUSSINS_ESTIMES
FROM calc c;


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
        NB_FEMELLES,
        ROUND(SUM(NB_OEUFS_ESTIMES))    AS NB_OEUFS_ESTIMES,
        ROUND(SUM(NB_POUSSINS_ESTIMES)) AS NB_POUSSINS_ESTIMES
    FROM V_ESTIMATION_POUSSIN
    GROUP BY DATE_ECLOSION, IDDETAIL, IDTRIAGE, IDLOT, NOMLOT, IDBATIMENT, IDPARQUET, PARQUET, SOUCHE, NB_FEMELLES;
