-- Ajouter un id Bon De Livraison dans reception.
ALTER TABLE RECEPTIONPOUSSINAEROPORT ADD (IDBL VARCHAR2(255));

-- Ajouter IDBL dans une zone de texte avec recherche (ID Bon De Livraison) dans reception aeroport. ferme/receptionaeroport/receptionaeroport-saisie.jsp

-- Sexe deja NULLABLE.

-- Ajouter une colonne pour les poussins perdus dans reception aeroport. Calculer par difference entre Quantite depuis l'IDBL et Quantite Recu.
ALTER TABLE RECEPTIONPOUSSINAEROPORT ADD (PERDUS NUMBER(10,0) DEFAULT 0);
ALTER TABLE RECEPTIONPOUSSINAEROPORT ADD (MORTS INTEGER DEFAULT 0);

-- Modifier code pour creer un Lot a chaque nouvelle reception aeroport, ce Lot sera utilisee pour la reception aeroport et triage :
-- Completer nom du lot par nom du produit depuis la table asingredients + IDBL, date eclosion et arrivee = date de reception aeroport.
-- Ferme et ORigine vides, reference = "Livraison + IDBL"


-- AS_INGREDIENTS, RECEPTIONPOUSSINAEROPORT, LOT, AS_BONDELIVRAISON


-- Lier chaque triage a une reception aeroport.
ALTER TABLE TRIAGEBATIMENTPARQUET ADD (IDRFA VARCHAR2(255));

-- Ajouter la une sante variable de 0 a 10 pour le triage batiment parquet detail. Ajouter un input number de 1 a 10 default 10 (pas 0 min car 0 est mort)
-- dans la formulaire de saisie du triage batiment parquet detail. Tu controlleras quand meme la valeur cote backend si jamais quelqu'un contourne le javascript.
-- Ajouter aussi un valeur de sexe " - " pour dire null. (Par convention on saisira qualite = "CONFORME" pour sante="10" 
-- et qualite = "FAIble" pour sante<10) -- mais 
-- pas besoin de check comme ca mais juste un convention pour le moment. On pourra ajouter un check plus tard si besoin.)

-- ALTER TABLE TRIAGEBATIMENTPARQUETDETAIL ADD (PERDUS INTEGER DEFAULT 0); -- Inutile
-- ALTER TABLE TRIAGEBATIMENTPARQUETDETAIL ADD (MORTS INTEGER DEFAULT 0); -- Inutile

ALTER TABLE TRIAGEBATIMENTPARQUETDETAIL ADD (SANTE INTEGER DEFAULT 10);
-- QTERECUS stocke la quantite vivante theorique de la reception aeroport.
-- MORTS et PERDUS sont les quantites constatees au triage; le vivant
-- restant est QTERECUS - MORTS - PERDUS. La repartition en details ne
-- peut pas depasser ce restant.
ALTER TABLE TRIAGEBATIMENTPARQUET ADD (QTERECUS NUMBER(10,2) DEFAULT 0);
ALTER TABLE TRIAGEBATIMENTPARQUET ADD (MORTS NUMBER(10,0) DEFAULT 0);
ALTER TABLE TRIAGEBATIMENTPARQUET ADD (PERDUS NUMBER(10,2) DEFAULT 0);

-- Vue de lecture pour valoriser les poussins repartis par parquet.
-- La quantite theorique et la valeur theorique sont reparties
-- proportionnellement a la quantite reelle saisie dans chaque parquet.
CREATE OR REPLACE VIEW TRIAGEBATPARQUETDETAIL_VALO AS
SELECT
    d.ID,
    d.IDMERE,
    d.IDBATIMENT,
    d.IDPARQUET,
    d.IDSEXE,
    d.IDQUALITE,
    d.QTE,
    d.SANTE,
    t.DATY,
    t.IDLOT,
    t.IDRFA,
    r.IDBL,
    NVL(p.VAL, d.IDPARQUET) AS IDPARQUETLIB,
    CASE
        WHEN NVL(t.QTEREELLETOTAL, 0) > 0 THEN NVL(d.QTE, 0) * NVL(bl.QTETHEORIQUETOTAL, 0) / t.QTEREELLETOTAL
        ELSE 0
    END AS QTETHEORIQUE,
    NVL(d.QTE, 0) AS QTEREELLE,
    NVL(bl.VALEURTHEORIQUEUNITAIRE, 0) AS VALEURTHEORIQUEUNITAIRE,
    CASE
        WHEN NVL(t.QTEREELLETOTAL, 0) > 0 THEN NVL(bl.VALEURTOTALETHEORIQUE, 0) / t.QTEREELLETOTAL
        ELSE 0
    END AS VALEURUNITAIREREELLE,
    CASE
        WHEN NVL(t.QTEREELLETOTAL, 0) > 0 THEN
            NVL(d.QTE, 0) * NVL(bl.QTETHEORIQUETOTAL, 0) / t.QTEREELLETOTAL * NVL(bl.VALEURTHEORIQUEUNITAIRE, 0)
        ELSE 0
    END AS VALEURTOTALETHEORIQUE,
    CASE
        WHEN NVL(t.QTEREELLETOTAL, 0) > 0 THEN NVL(d.QTE, 0) * NVL(bl.VALEURTOTALETHEORIQUE, 0) / t.QTEREELLETOTAL
        ELSE 0
    END AS VALEURTOTALEREELLE
FROM TRIAGEBATIMENTPARQUETDETAIL d
JOIN (
    SELECT
        tbp.*,
        GREATEST(NVL(tbp.QTERECUS, 0) - NVL(tbp.MORTS, 0) - NVL(tbp.PERDUS, 0), 0) AS QTEREELLETOTAL
    FROM TRIAGEBATIMENTPARQUET tbp
) t ON t.ID = d.IDMERE
LEFT JOIN RECEPTIONPOUSSINAEROPORT r ON r.ID = t.IDRFA
LEFT JOIN (
    SELECT
        NUMBL,
        SUM(NVL(QUANTITE, 0)) AS QTETHEORIQUETOTAL,
        SUM(NVL(QUANTITE, 0) * NVL(PU, 0)) AS VALEURTOTALETHEORIQUE,
        CASE
            WHEN SUM(NVL(QUANTITE, 0)) > 0 THEN SUM(NVL(QUANTITE, 0) * NVL(PU, 0)) / SUM(NVL(QUANTITE, 0))
            ELSE 0
        END AS VALEURTHEORIQUEUNITAIRE
    FROM AS_BONDELIVRAISON_FILLE
    GROUP BY NUMBL
) bl ON bl.NUMBL = r.IDBL
LEFT JOIN PARQUET p ON p.ID = d.IDPARQUET;
