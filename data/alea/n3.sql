    -- ============================================================
    -- Calendrier d'estimation de poussins a venir (Oracle)
    -- ============================================================

    -- 1) Colonnes sur SOUCHE
    -- Corrections par rapport a ta version :
    --  * PRC_LAMokany -> PRC_LAMOKANY (casse/typo)
    --  * DECIMAL(10,6) -> NUMBER(10,6) (type natif Oracle)
    ALTER TABLE SOUCHE ADD (
        AGE_ENTREE_PONTE_JOUR  NUMBER,         -- age (jours) auquel la poule commence a pondre
        DUREE_INCUBATION_JOUR  NUMBER,         -- jours entre mise en incubation et eclosion
        POTENTIEL_PONTE        NUMBER,         -- nb total d'oeufs qu'une poule peut pondre
        FREQUENCE_VAL          NUMBER,         -- nb d'oeufs ...
        FREQUENCE_JOUR         NUMBER,         -- ... tous les N jours (ex: 5 oeufs / 7 jours)
        PRC_LAMOKANY           NUMBER(10,6)    -- % d'oeufs qui n'eclosent pas
    );

    -- Exemple de renseignement :
    -- UPDATE SOUCHE SET AGE_ENTREE_PONTE_JOUR = 182, DUREE_INCUBATION_JOUR = 21,
    --        POTENTIEL_PONTE = 180, FREQUENCE_VAL = 5, FREQUENCE_JOUR = 7,
    --        PRC_LAMOKANY = 15
    --  WHERE ID = '...';

    UPDATE SOUCHE SET AGE_ENTREE_PONTE_JOUR = 182, DUREE_INCUBATION_JOUR = 21,
    POTENTIEL_PONTE = 180, FREQUENCE_VAL = 5, FREQUENCE_JOUR = 7,PRC_LAMOKANY = 0;

    -- 2) Estimation detaillee : une ligne par (ligne de triage detail FEMELLE, jour de ponte)
    -- Angle de perception : TRIAGEBATIMENTPARQUETDETAIL (d) -> TRIAGEBATIMENTPARQUET (t) -> LOT (l) -> SOUCHE (s)
    --  * Seules les lignes dont le sexe est Femelle (SEXE.VAL commence par 'F') et SANTE > 0 (0 = mort) comptent.
    --  * NB_FEMELLES = d.QTE (effectif vivant de cette ligne : batiment / parquet / qualite).
    --  * Si une ligne de triage est modifiee (mort, perte), l'estimation suit.
    -- Modele :
    --   debut ponte         = date arrivee du lot (sinon date du triage) + AGE_ENTREE_PONTE_JOUR
    --   taux / poule / jour = FREQUENCE_VAL / FREQUENCE_JOUR
    --   duree de ponte      = POTENTIEL_PONTE / taux (le potentiel de la poule n'est jamais depasse)
    --   oeufs du jour       = femelles * LEAST(taux, potentiel restant)
    --   date eclosion       = jour de ponte + DUREE_INCUBATION_JOUR
    --   poussins            = oeufs - oeufs * PRC_LAMOKANY / 100
    CREATE OR REPLACE VIEW V_ESTIMATION_POUSSIN AS
    WITH base AS (
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
            d.QTE                                                  AS NB_FEMELLES,
            TRUNC(NVL(l.DATEARRIVEE, t.DATY))
                + s.AGE_ENTREE_PONTE_JOUR                          AS DATE_DEBUT_PONTE,
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
        SELECT LEVEL - 1 AS K FROM DUAL CONNECT BY LEVEL <= 2000   -- max 2000 jours de ponte
    )
    SELECT
        b.IDDETAIL,
        b.IDTRIAGE,
        b.IDLOT,
        b.NOMLOT,
        b.IDBATIMENT,
        b.IDPARQUET,
        b.PARQUET,
        b.IDSOUCHE,
        b.SOUCHE,
        b.NB_FEMELLES,
        b.DATE_DEBUT_PONTE + j.K                                   AS DATE_PONTE,
        b.DATE_DEBUT_PONTE + j.K + b.DUREE_INCUBATION_JOUR         AS DATE_ECLOSION,
        b.NB_FEMELLES * LEAST(b.TAUX_PONTE_JOUR,
                            b.POTENTIEL_PONTE - j.K * b.TAUX_PONTE_JOUR)
                                                                AS NB_OEUFS_ESTIMES,
        b.NB_FEMELLES * LEAST(b.TAUX_PONTE_JOUR,
                            b.POTENTIEL_PONTE - j.K * b.TAUX_PONTE_JOUR)
            * (1 - b.PRC_LAMOKANY / 100)                           AS NB_POUSSINS_ESTIMES
    FROM base b
    JOIN jours j ON j.K < b.NB_JOURS_PONTE;

    -- 3) Calendrier : poussins estimes par date d'eclosion et par ligne de triage detail femelle
    -- Exemple : SELECT * FROM V_ESTIMATION_POUSSIN_CALENDRIER
    --           WHERE DATE_ECLOSION >= TRUNC(SYSDATE) ORDER BY DATE_ECLOSION;
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
    
    -- Total par date d'eclosion (tous lots confondus) :
    -- SELECT DATE_ECLOSION, SUM(NB_POUSSINS_ESTIMES) FROM V_ESTIMATION_POUSSIN_CALENDRIER GROUP BY DATE_ECLOSION ORDER BY 1;
    -- La vue V_LOT_FEMELLES_VIVANTES n'est plus utilisee : DROP VIEW V_LOT_FEMELLES_VIVANTES; (si deja creee)

    --- Ajouter colonne CAPACITE dans la table PARQUET
    ALTER TABLE PARQUET ADD CAPACITE NUMBER;