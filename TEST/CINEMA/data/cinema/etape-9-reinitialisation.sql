-- =====================================================================
-- CINEMA - Etape 9 : menu "Reinitialiser les donnees" du cinema
-- Page cinema/parametre/reinitialisation.jsp : efface toutes les donnees du cinema sauf la configuration
-- (cinema, classes de place, categories, parametres, caisses par mode) et peut recharger la demonstration.
-- Le traitement est dans le Java (cinema.utils.CinReinitialisation) : ce script ne fait qu'ajouter le menu.
-- Prerequis : etape-8-clients-tableau.sql. Se reconnecter apres execution (menu en session).
-- =====================================================================

SET DEFINE OFF;

INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA11', 'R&eacute;initialiser les donn&eacute;es', 'restart_alt', 'module.jsp?but=cinema/parametre/reinitialisation.jsp', 11, 2, 'MENDYNCINEMA');

COMMIT;
