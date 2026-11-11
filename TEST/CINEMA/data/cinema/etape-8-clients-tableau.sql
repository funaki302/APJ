-- =====================================================================
-- CINEMA - Etape 8 : consultation client et tableau de bord
-- Vue : CIN_CLIENT_LIB (clients de la table CLIENT qui ont au moins un ticket, avec leurs totaux)
-- Menus Cinema > Clients, Cinema > Tableau de bord.
-- Prerequis : etape-7-paiements.sql. Se reconnecter apres execution (menu en session).
-- Le tableau de bord lit directement les tables du cinema et MOUVEMENTCAISSE (pas de table en plus).
-- =====================================================================

SET DEFINE OFF;

-- Un client par ligne : nombre de tickets, tickets payes, places payees, montant paye, derniere reservation
CREATE OR REPLACE VIEW CIN_CLIENT_LIB AS
SELECT cl.ID, cl.NOM, cl.TELEPHONE, cl.MAIL,
       COUNT(t.ID) AS NB_TICKETS,
       SUM(CASE WHEN t.ETAT = 11 THEN 1 ELSE 0 END) AS NB_PAYES,
       SUM(CASE WHEN t.ETAT = 1 AND t.ACTIF = 1 THEN 1 ELSE 0 END) AS NB_EN_ATTENTE,
       SUM(CASE WHEN t.ETAT = 11 THEN t.NB_PLACES ELSE 0 END) AS NB_PLACES_PAYEES,
       SUM(CASE WHEN t.ETAT = 11 THEN t.MONTANT ELSE 0 END) AS MONTANT_PAYE,
       MAX(t.DATY_RESERVATION) AS DERNIERE_RESERVATION
FROM CLIENT cl
JOIN CIN_TICKET_LIB t ON t.IDCLIENT = cl.ID
GROUP BY cl.ID, cl.NOM, cl.TELEPHONE, cl.MAIL;

-- ---------------------------------------------------------------------
-- Menus : Cinema > Clients, Cinema > Tableau de bord
-- ---------------------------------------------------------------------
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA09', 'Clients', 'group', 'module.jsp?but=cinema/client/client-liste.jsp', 9, 2, 'MENDYNCINEMA');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA10', 'Tableau de bord', 'bar_chart', 'module.jsp?but=cinema/tableau/tableau-bord.jsp', 10, 2, 'MENDYNCINEMA');

COMMIT;

-- Controle
-- SELECT * FROM CIN_CLIENT_LIB ORDER BY MONTANT_PAYE DESC;
