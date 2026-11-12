-- =====================================================================
-- CINEMA - Etape 11 (12/11/2026) : la facturation du cinema passe par la facturation existante (VENTE)
--   "Payer" sur une reservation cree une vente (vente.VenteArbiochem) et la vise : ecritures comptables,
--   prevision, imputation des avoirs et des avances du client. Le paiement se fait ensuite sur la fiche
--   de la vente (vente/vente-arbiochem-fiche.jsp), comme pour toute facture.
--   Une ligne de vente par classe de place : produit "Place <classe>" (AS_INGREDIENTS, categorie service,
--   compte 706, TVA 0), quantite = nombre de chaises, designation = seance + numeros des chaises.
--   Le ticket est acquis (etat 11, plus d'expiration) des que la vente est visee ; si la vente est
--   annulee dans la facturation, les chaises redeviennent libres.
--   L'ancienne facturation du cinema (CIN_PAIEMENT, CIN_FACTURE, CIN_MODE_CAISSE) est gardee en base
--   (historique) mais ses menus sont retires.
-- Prerequis : etapes 0 a 10. Rejouable partiellement : ne pas rejouer les ALTER TABLE.
-- =====================================================================

SET DEFINE OFF;

-- ---------- lien classe de place -> produit, ticket -> vente ----------
ALTER TABLE CIN_CLASSE_PLACE ADD (IDPRODUIT VARCHAR2(50));
ALTER TABLE CIN_TICKET ADD (IDVENTE VARCHAR2(255));
ALTER TABLE CIN_TICKET ADD CONSTRAINT FK_CIN_TICKET_VENTE FOREIGN KEY (IDVENTE) REFERENCES VENTE (ID);
CREATE INDEX IX_CIN_TICKET_VENTE ON CIN_TICKET (IDVENTE);

-- ---------- un produit "Place <classe>" par classe existante ----------
-- (les classes creees ensuite recoivent leur produit automatiquement : CinClassePlace)
INSERT INTO AS_INGREDIENTS (ID, LIBELLE, LIBELLEVENTE, UNITE, PU, PV, TVA, COMPTE_VENTE, CATEGORIEINGREDIENT, ISVENTE, ISACHAT, ACTIF, COMPOSE, DATY)
SELECT 'IG' || c.ID, 'Place ' || c.VAL, 'Place ' || c.VAL, 'UNT00005', 0, c.PRIX, 0, '706', 'CATINGSERVICE', 1, 0, 1, 0, SYSDATE
FROM CIN_CLASSE_PLACE c
WHERE NOT EXISTS (SELECT 1 FROM AS_INGREDIENTS i WHERE i.ID = 'IG' || c.ID);
UPDATE CIN_CLASSE_PLACE SET IDPRODUIT = 'IG' || ID WHERE IDPRODUIT IS NULL;

-- ---------- parametre : magasin des ventes du cinema ----------
INSERT INTO CIN_PARAMETRE (ID, CODE, VALEUR, DESCE)
SELECT 'CINPAR' || LPAD(GETSEQCINPARAMETRE, 6, '0'), 'MAGASIN_VENTE', 'MAGA0008',
       'Magasin (point de vente) inscrit sur les factures du cinema (id de MAGASINVENTE)' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM CIN_PARAMETRE WHERE CODE = 'MAGASIN_VENTE');

-- ---------- vue des classes : produit lie ----------
CREATE OR REPLACE VIEW CIN_CLASSE_PLACE_LIB AS
SELECT c.ID, c.VAL, c.DESCE, c.PRIX, c.COULEUR, c.DATE_CREATION, c.ETAT, DECODE(c.ETAT, 1, 'Actif', 'Inactif') AS ETATLIB,
       c.IDPRODUIT
FROM CIN_CLASSE_PLACE c;

-- ---------- tickets : facture liee ----------
-- ETAT 11 = acquis : facture (vente visee) ou paye par l'ancienne facturation du cinema (IDVENTE vide).
-- Une vente annulee (VENTE.ETAT = 0) rend le ticket inactif : ses chaises sont de nouveau libres.
CREATE OR REPLACE VIEW CIN_TICKET_LIB AS
SELECT x.*,
       CASE WHEN x.ETAT = 0 THEN 'Annul&eacute;'
            WHEN x.ETAT = 11 AND x.IDVENTE IS NULL THEN 'Pay&eacute;'
            WHEN x.ETAT = 11 AND x.ETAT_VENTE = 0 THEN 'Facture annul&eacute;e'
            WHEN x.ETAT = 11 AND (SELECT v.MONTANTRESTE FROM VENTE_CPL v WHERE v.ID = x.IDVENTE) <= 0 THEN 'Factur&eacute; et pay&eacute;'
            WHEN x.ETAT = 11 THEN 'Factur&eacute;'
            WHEN SYSDATE > x.DATE_LIMITE THEN 'Expir&eacute;'
            ELSE 'R&eacute;serv&eacute;' END AS ETATLIB,
       CASE WHEN x.ETAT = 11 AND NVL(x.ETAT_VENTE, 11) <> 0 THEN 1
            WHEN x.ETAT = 1 AND SYSDATE <= x.DATE_LIMITE THEN 1
            ELSE 0 END AS ACTIF,
       TO_CHAR(x.DATE_LIMITE, 'DD/MM/YYYY HH24:MI') AS DATE_LIMITELIB
FROM (
    SELECT t.ID, t.IDCLIENT, cl.NOM AS IDCLIENTLIB, cl.TELEPHONE, t.IDDIFFUSION,
           d.IDFILM, d.IDFILMLIB, d.IDSALLE, d.IDSALLELIB, d.DATY AS DATY_DIFFUSION, d.HEURE, d.HEURE_FIN,
           d.DATE_DEBUT, d.ETAT AS ETAT_DIFFUSION,
           d.DATE_DEBUT - NVL((SELECT TO_NUMBER(p.VALEUR) FROM CIN_PARAMETRE p WHERE p.CODE = 'DELAI_EXPIRATION_MIN'), 30) / 1440 AS DATE_LIMITE,
           t.DATY_RESERVATION, t.HEURE_RESERVATION, t.MONTANT, t.REMARQUE, t.ETAT,
           (SELECT COUNT(*) FROM CIN_TICKET_DETAIL td WHERE td.IDTICKET = t.ID) AS NB_PLACES,
           t.IDVENTE, v.NUMEROFACTURE, v.ETAT AS ETAT_VENTE
    FROM CIN_TICKET t
    JOIN CLIENT cl ON cl.ID = t.IDCLIENT
    JOIN CIN_DIFFUSION_LIB d ON d.ID = t.IDDIFFUSION
    LEFT JOIN VENTE v ON v.ID = t.IDVENTE
) x;

-- CIN_PLACE_DIFFUSION s'appuie sur CIN_TICKET_LIB.ACTIF : recompilee pour prendre la nouvelle definition
CREATE OR REPLACE VIEW CIN_PLACE_DIFFUSION AS
SELECT d.ID AS IDDIFFUSION, p.ID AS IDPLACE, p.NUMERO, p.RANGEE, p.COLONNE, p.IDCLASSE, p.IDCLASSELIB, p.COULEUR, p.PRIX,
       occ.IDTICKET,
       CASE WHEN p.ETAT = 0 THEN 'HS'
            WHEN occ.ETAT = 11 THEN 'PAYEE'
            WHEN occ.ETAT = 1 THEN 'RESERVEE'
            ELSE 'LIBRE' END AS STATUT
FROM CIN_DIFFUSION d
JOIN CIN_PLACE_LIB p ON p.IDSALLE = d.IDSALLE
LEFT JOIN (
    SELECT td.IDDIFFUSION, td.IDPLACE, MAX(t.ID) AS IDTICKET, MAX(t.ETAT) AS ETAT
    FROM CIN_TICKET_DETAIL td
    JOIN CIN_TICKET_LIB t ON t.ID = td.IDTICKET
    WHERE t.ACTIF = 1
    GROUP BY td.IDDIFFUSION, td.IDPLACE
) occ ON occ.IDDIFFUSION = d.ID AND occ.IDPLACE = p.ID;

-- ---------- factures (ventes) des tickets du cinema ----------
CREATE OR REPLACE VIEW CIN_FACTURE_VENTE AS
SELECT v.ID, v.NUMEROFACTURE, v.DATY, t.ID AS IDTICKET, t.IDCLIENT, cl.NOM AS IDCLIENTLIB,
       d.IDFILMLIB, d.IDSALLELIB, d.DATY AS DATY_DIFFUSION, d.HEURE,
       t.MONTANT, NVL(vc.MONTANTPAYE, 0) AS MONTANTPAYE, NVL(vc.MONTANTRESTE, 0) AS MONTANTRESTE,
       v.ETAT, vc.ETATLIB
FROM CIN_TICKET t
JOIN VENTE v ON v.ID = t.IDVENTE
JOIN CLIENT cl ON cl.ID = t.IDCLIENT
JOIN CIN_DIFFUSION_LIB d ON d.ID = t.IDDIFFUSION
LEFT JOIN VENTE_CPL vc ON vc.ID = v.ID;

-- ---------- recettes du cinema : ancienne facturation + ventes visees ----------
CREATE OR REPLACE VIEW CIN_RECETTE AS
SELECT p.ID AS IDORIGINE, p.IDTICKET, p.DATY, p.MONTANT FROM CIN_PAIEMENT p
UNION ALL
SELECT v.ID, t.ID, v.DATY, t.MONTANT
FROM CIN_TICKET t JOIN VENTE v ON v.ID = t.IDVENTE
WHERE t.ETAT = 11 AND v.ETAT >= 11;

-- ---------- clients : "payes" = tickets acquis (factures ou payes), hors factures annulees ----------
CREATE OR REPLACE VIEW CIN_CLIENT_LIB AS
SELECT cl.ID, cl.NOM, cl.TELEPHONE, cl.MAIL,
       COUNT(t.ID) AS NB_TICKETS,
       SUM(CASE WHEN t.ETAT = 11 AND t.ACTIF = 1 THEN 1 ELSE 0 END) AS NB_PAYES,
       SUM(CASE WHEN t.ETAT = 1 AND t.ACTIF = 1 THEN 1 ELSE 0 END) AS NB_EN_ATTENTE,
       SUM(CASE WHEN t.ETAT = 11 AND t.ACTIF = 1 THEN t.NB_PLACES ELSE 0 END) AS NB_PLACES_PAYEES,
       SUM(CASE WHEN t.ETAT = 11 AND t.ACTIF = 1 THEN t.MONTANT ELSE 0 END) AS MONTANT_PAYE,
       MAX(t.DATY_RESERVATION) AS DERNIERE_RESERVATION
FROM CLIENT cl
JOIN CIN_TICKET_LIB t ON t.IDCLIENT = cl.ID
GROUP BY cl.ID, cl.NOM, cl.TELEPHONE, cl.MAIL;

-- ---------- menus : retrait de l'ancienne facturation du cinema ----------
DELETE FROM MENUDYNAMIQUE WHERE ID IN ('MENDYNCINEMA07', 'MENDYNCINEMA08', 'MENDYNCINEMA0106');
DELETE FROM MENUDYNAMIQUE WHERE ID_PERE IN ('MENDYNCINEMA07', 'MENDYNCINEMA08');

COMMIT;

-- Controle
-- SELECT ID, VAL, PRIX, IDPRODUIT FROM CIN_CLASSE_PLACE_LIB;
-- SELECT ID, LIBELLE, PV, COMPTE_VENTE, CATEGORIEINGREDIENT FROM AS_INGREDIENTS WHERE ID LIKE 'IGCIN%';
