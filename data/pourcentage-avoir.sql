-- =====================================================================
-- POURCENTAGE D'AVOIR PAR CLIENT  (voir instruction/POURCENTAGE-AVOIR.md)
-- Part maximale d'une facture qui peut etre payee par avoir.
-- Ex : POURCENTAGE = 40, facture 100 000 Ar, avoir 100 000 Ar
--      -> 40 000 Ar payes par avoir, 60 000 Ar a payer en cash / autre moyen.
-- 100 = pas de limite (comportement d'avant), 0 = l'avoir n'est jamais utilise.
-- Prerequis : data/avoir-fc.sql
-- =====================================================================

-- 1) Colonne sur CLIENT (les clients existants recoivent 100 = aucune limite)
ALTER TABLE CLIENT ADD (POURCENTAGE NUMBER(5,2) DEFAULT 100);
UPDATE CLIENT SET POURCENTAGE = 100 WHERE POURCENTAGE IS NULL;
ALTER TABLE CLIENT ADD CONSTRAINT CK_CLIENT_POURCENTAGE CHECK (POURCENTAGE BETWEEN 0 AND 100);
COMMIT;

-- 2) Vue de la fiche client (client-arbiochem-fiche.jsp) : meme definition + POURCENTAGE
CREATE OR REPLACE VIEW CLIENTLIB AS
SELECT
    c.ID,c.NOM,c.TELEPHONE,c.MAIL,c.ADRESSE,c.REMARQUE,c.COMPTE,c.IDNATIONALITE,c.COMPTEAUXILIAIRE,c.IDTYPECLIENT,
    t.val AS idTypeClientLib,
    c.codeclient,c.datecarte,c.taxe,c.idprovince,c.echeance,c.telfixe,c.nif,c.stat,c.carte,p.val AS provincelib,
    c.SEUIL,
    c.POURCENTAGE
FROM CLIENT c
LEFT JOIN typeclient t
ON c.idTypeClient = t.id
LEFT JOIN province p ON c.idprovince=p.id where ESTACTIF=1;

-- Controle : pourcentage et avoir disponible par client
-- SELECT c.ID, c.NOM, c.POURCENTAGE, NVL(SUM(a.RESTEAPAYERAR), 0) AS SOLDE_AVOIR
-- FROM CLIENT c LEFT JOIN AVOIRFCLIB_CPL a ON a.IDCLIENT = c.ID AND a.ETAT >= 11 AND a.RESTEAPAYERAR > 0
-- GROUP BY c.ID, c.NOM, c.POURCENTAGE;
