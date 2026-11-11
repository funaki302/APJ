SET DEFINE OFF;  -- evite que SQL*Plus traite &Eacute; comme une variable de substitution
-- =====================================================================
-- 1) TRIAGEBATPARQUETDETAIL_LIB : ajout de QTE_DEPART, QTE_MORT, QTE_ACTUEL
--    Le suivi (SUIVIJOURNALIERDETAIL) est rattache a une ligne de triage par
--    (lot, batiment, parquet). Si un parquet a plusieurs lignes de triage
--    (qualites differentes), les pertes sont reparties au prorata de QTE.
--    Seuls les suivis VALIDES (ETAT = 11) comptent.
--      QTE_DEPART : QTE de la ligne de triage
--      QTE_MORT   : somme de MORTALITE saisie dans les suivis
--      QTE_ACTUEL : QTE_DEPART - (MORTALITE + CULLS + TRI), jamais < 0 ; 0 si SANTE = 0
-- =====================================================================
CREATE OR REPLACE VIEW TRIAGEBATPARQUETDETAIL_LIB AS
WITH base AS (
    SELECT d.ID, d.IDMERE, d.IDBATIMENT, d.IDPARQUET, d.IDSEXE, d.IDQUALITE, d.QTE, d.SANTE,
           t.IDLOT,
           SUM(CASE WHEN NVL(d.SANTE, 10) > 0 THEN d.QTE ELSE 0 END)
               OVER (PARTITION BY t.IDLOT, d.IDBATIMENT, d.IDPARQUET) AS QTE_PARQUET
    FROM TRIAGEBATIMENTPARQUETDETAIL d
             LEFT JOIN TRIAGEBATIMENTPARQUET t ON t.ID = d.IDMERE
),
suivi AS (
    SELECT s.IDLOT, sd.IDBATIMENT, sd.IDPARQUET,
           SUM(NVL(sd.MORTALITE, 0)) AS MORT,
           SUM(NVL(sd.CULLS, 0))     AS CULLS,
           SUM(NVL(sd.TRI, 0))       AS TRI
    FROM SUIVIJOURNALIER s
             JOIN SUIVIJOURNALIERDETAIL sd ON sd.IDMERE = s.ID
    WHERE s.ETAT = 11
    GROUP BY s.IDLOT, sd.IDBATIMENT, sd.IDPARQUET
)
SELECT b.ID, b.IDMERE, b.IDBATIMENT, b.IDPARQUET, b.IDSEXE, b.IDQUALITE, b.QTE,
       bt.NOMBATIMENT AS IDBATIMENTLIB,
       p.VAL          AS IDPARQUETLIB,
       sx.VAL         AS IDSEXELIB,
       q.VAL          AS IDQUALITELIB,
       b.IDLOT        AS IDLOT,
       b.QTE          AS QTE_DEPART,
       ROUND(CASE WHEN NVL(b.SANTE, 10) > 0 AND b.QTE_PARQUET > 0
                  THEN NVL(su.MORT, 0) * b.QTE / b.QTE_PARQUET ELSE 0 END, 2) AS QTE_MORT,
       ROUND(CASE WHEN NVL(b.SANTE, 10) > 0 AND b.QTE_PARQUET > 0
                  THEN GREATEST(0, b.QTE - (NVL(su.MORT, 0) + NVL(su.CULLS, 0) + NVL(su.TRI, 0)) * b.QTE / b.QTE_PARQUET)
                  ELSE 0 END, 2) AS QTE_ACTUEL
FROM base b
         LEFT JOIN BATIMENT bt       ON bt.ID = b.IDBATIMENT
         LEFT JOIN PARQUET p         ON p.ID = b.IDPARQUET
         LEFT JOIN SEXE sx           ON sx.ID = b.IDSEXE
         LEFT JOIN QUALITEPOUSSIN q  ON q.ID = b.IDQUALITE
         LEFT JOIN suivi su          ON su.IDLOT = b.IDLOT
                                    AND su.IDBATIMENT = b.IDBATIMENT
                                    AND su.IDPARQUET = b.IDPARQUET;

-- =====================================================================
-- 2) TRIAGEBATIMENTPARQUET_LIB : colonnes d'origine conservees + totaux reactifs
--    (a creer APRES la vue ci-dessus, car elle s'appuie dessus)
--      QTE_DEPART, QTE_MORT, QTE_ACTUEL : totaux du triage
--      QTE_ACTUEL_FEMELLE / QTE_ACTUEL_MALE : vivants restants par sexe (0 = femelle, 1 = male)
-- =====================================================================
CREATE OR REPLACE VIEW TRIAGEBATIMENTPARQUET_LIB AS
SELECT t.ID, t.DATY, t.IDLOT, t.DISPOMALE, t.DISPOFEMELLE,
       l.NOMLOT AS IDLOTLIB,
       s.VAL    AS IDSOUCHELIB,
       t.ETAT   AS ETAT,
       CASE
           WHEN t.ETAT = 1  THEN 'CR&Eacute;&Eacute;'
           WHEN t.ETAT = 11 THEN 'VALID&Eacute;'
       END AS ETATLIB,
       NVL(t.DISPOFEMELLE - (SELECT SUM(d.QTE)
                             FROM TRIAGEBATIMENTPARQUETDETAIL d
                             WHERE d.IDMERE = t.ID
                               AND d.IDQUALITE = 'QP000001'
                               AND d.IDSEXE = '0'), 0) AS ECARTFEMELLE,
       NVL(t.DISPOMALE - (SELECT SUM(d.QTE)
                          FROM TRIAGEBATIMENTPARQUETDETAIL d
                          WHERE d.IDMERE = t.ID
                            AND d.IDQUALITE = 'QP000001'
                            AND d.IDSEXE = '1'), 0) AS ECARTMALE,
       NVL(x.QTE_DEPART, 0)         AS QTE_DEPART,
       NVL(x.QTE_MORT, 0)           AS QTE_MORT,
       NVL(x.QTE_ACTUEL, 0)         AS QTE_ACTUEL,
       NVL(x.QTE_ACTUEL_FEMELLE, 0) AS QTE_ACTUEL_FEMELLE,
       NVL(x.QTE_ACTUEL_MALE, 0)    AS QTE_ACTUEL_MALE
FROM TRIAGEBATIMENTPARQUET t
         LEFT JOIN LOT l    ON l.ID = t.IDLOT
         LEFT JOIN SOUCHE s ON s.ID = l.IDSOUCHE
         LEFT JOIN (SELECT IDMERE,
                           SUM(QTE_DEPART) AS QTE_DEPART,
                           SUM(QTE_MORT)   AS QTE_MORT,
                           SUM(QTE_ACTUEL) AS QTE_ACTUEL,
                           SUM(CASE WHEN IDSEXE = '0' THEN QTE_ACTUEL ELSE 0 END) AS QTE_ACTUEL_FEMELLE,
                           SUM(CASE WHEN IDSEXE = '1' THEN QTE_ACTUEL ELSE 0 END) AS QTE_ACTUEL_MALE
                    FROM TRIAGEBATPARQUETDETAIL_LIB
                    GROUP BY IDMERE) x ON x.IDMERE = t.ID;

-- Verification
SELECT OBJECT_NAME, STATUS FROM USER_OBJECTS
WHERE OBJECT_NAME IN ('TRIAGEBATPARQUETDETAIL_LIB', 'TRIAGEBATIMENTPARQUET_LIB');