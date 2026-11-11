-- =====================================================================
-- CINEMA - Suppression complete du module (retour a l'etat d'avant le cinema)
-- Supprime : toutes les vues, tables, sequences et fonctions dont le nom commence par CIN_,
--            GETSEQCIN ou SEQ_CIN_, les menus MENDYNCINEMA%,
--            la caisse CAICINEMA (etape 4) avec ses reports et mouvements,
--            et les mouvements de caisse generes par le cinema (IDORIGINE LIKE 'CIN%').
-- Ne touche a rien d'autre (CLIENT, les autres caisses et leurs mouvements sont conserves).
-- Complete a chaque etape si un objet ne suit pas ces prefixes.
-- =====================================================================

-- Etape 4 : mouvements et reports de la caisse du cinema (avant de supprimer la caisse)
DELETE FROM MOUVEMENTCAISSE WHERE IDORIGINE LIKE 'CIN%' OR IDCAISSE = 'CAICINEMA';
DELETE FROM REPORTCAISSE WHERE IDCAISSE = 'CAICINEMA';

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
DELETE FROM CAISSE WHERE ID = 'CAICINEMA';
COMMIT;
