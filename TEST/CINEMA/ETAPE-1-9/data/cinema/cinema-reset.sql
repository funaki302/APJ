-- =====================================================================
-- CINEMA - Suppression complete du module (retour a l'etat d'avant le cinema)
-- Supprime : toutes les vues, tables, sequences et fonctions dont le nom commence par CIN_,
--            GETSEQCIN ou SEQ_CIN_, les menus MENDYNCINEMA%,
--            la caisse CAICINEMA (etape 4) avec ses reports et mouvements,
--            les mouvements de caisse generes par le cinema (IDORIGINE LIKE 'CIN%')
--            les clients crees pour le cinema (ID LIKE 'CLICIN%', ex. donnees de demo)
--            et le mode de paiement Mobile money (MPCINMOB, etape 7).
-- Ne touche a rien d'autre (CLIENT, les autres caisses et leurs mouvements sont conserves).
-- Etape 11 : les factures des tickets (VENTE, facturation existante), leurs encaissements, les produits "Place ..."
--            (AS_INGREDIENTS IGCIN...) qu'elles utilisent et les clients qui ont une facture sont conserves.
-- Complete a chaque etape si un objet ne suit pas ces prefixes.
-- =====================================================================

-- Etape 4 : mouvements et reports de la caisse du cinema (avant de supprimer la caisse)
DELETE FROM MOUVEMENTCAISSE WHERE (IDORIGINE LIKE 'CIN%' OR IDCAISSE = 'CAICINEMA')
                             AND (IDORIGINE IS NULL OR IDORIGINE NOT IN (SELECT ID FROM VENTE));
DELETE FROM REPORTCAISSE WHERE IDCAISSE = 'CAICINEMA'
                           AND NOT EXISTS (SELECT 1 FROM MOUVEMENTCAISSE WHERE IDCAISSE = 'CAICINEMA');

BEGIN
    FOR o IN (SELECT OBJECT_NAME, OBJECT_TYPE FROM USER_OBJECTS
              WHERE (OBJECT_NAME LIKE 'CIN\_%' ESCAPE '\'
                     OR OBJECT_NAME LIKE 'SEQ\_CIN\_%' ESCAPE '\'
                     OR OBJECT_NAME LIKE 'GETSEQCIN%')
                AND OBJECT_TYPE IN ('VIEW', 'TABLE', 'SEQUENCE', 'FUNCTION')
              ORDER BY DECODE(OBJECT_TYPE, 'VIEW', 1, 'TABLE', 2, 'SEQUENCE', 3, 4)) LOOP
        IF o.OBJECT_TYPE = 'TABLE' THEN
            EXECUTE IMMEDIATE 'DROP TABLE "' || o.OBJECT_NAME || '" CASCADE CONSTRAINTS PURGE';
        ELSE
            EXECUTE IMMEDIATE 'DROP ' || o.OBJECT_TYPE || ' "' || o.OBJECT_NAME || '"';
        END IF;
    END LOOP;
END;
/

DELETE FROM USERMENU WHERE IDMENU LIKE 'MENDYNCINEMA%';
DELETE FROM MENUDYNAMIQUE WHERE ID LIKE 'MENDYNCINEMA%' AND NIVEAU > 1;
DELETE FROM MENUDYNAMIQUE WHERE ID LIKE 'MENDYNCINEMA%';
DELETE FROM CAISSE WHERE ID = 'CAICINEMA' AND NOT EXISTS (SELECT 1 FROM MOUVEMENTCAISSE WHERE IDCAISSE = 'CAICINEMA');
DELETE FROM CLIENT WHERE ID LIKE 'CLICIN%' AND ID NOT IN (SELECT IDCLIENT FROM VENTE WHERE IDCLIENT IS NOT NULL);
DELETE FROM COMPTA_COMPTE WHERE ID LIKE 'COMCIN%' AND COMPTE NOT IN (SELECT COMPTE FROM CLIENT WHERE COMPTE IS NOT NULL);
DELETE FROM AS_INGREDIENTS WHERE ID LIKE 'IGCIN%' AND ID NOT IN (SELECT IDPRODUIT FROM VENTE_DETAILS WHERE IDPRODUIT IS NOT NULL);
DELETE FROM MODEPAIEMENT WHERE ID = 'MPCINMOB';
COMMIT;
