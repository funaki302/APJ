-- =====================================================================
-- AVOIR-FC : reduction automatique par avoir + reinitialisation des donnees clients
-- Voir instruction/AVOIR-FC.md
--
-- Aucune modification de structure : l'imputation automatique reutilise
-- LIAISONPAIEMENT (id1 = avoir, id2 = facture) et les vues existantes
-- (VENTE_CPL.MONTANTRESTE, AVOIRFCLIB_CPL.RESTEAPAYERAR).
-- =====================================================================

-- Entree de menu "Reinitialiser les donnees" sous Vente (le bouton existe aussi en haut de la liste des factures)
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNREINITVENTE01', 'R&eacute;initialiser les donn&eacute;es', 'restart_alt',
        'module.jsp?but=vente/reinitialisation-donnees.jsp', 30, 2, 'MNDN000000001');
COMMIT;

-- Controle : solde d'avoir disponible par client (ce que le systeme deduira au prochain visa)
-- SELECT IDCLIENT, CLIENTLIB, SUM(RESTEAPAYERAR) AS SOLDE_AVOIR
-- FROM AVOIRFCLIB_CPL
-- WHERE ETAT >= 11 AND RESTEAPAYERAR > 0
-- GROUP BY IDCLIENT, CLIENTLIB
-- ORDER BY SOLDE_AVOIR DESC;

-- Controle : avoirs imputes sur une facture
-- SELECT * FROM LIAISONPAIEMENT WHERE ID2 = '<id facture>' AND ID1 IN (SELECT ID FROM AVOIRFC);

-- =====================================================================
-- Choix "Ne pas appliquer l'avoir" au visa d'une facture
-- Une ligne = le client garde son avoir, rien n'est deduit au visa de cette facture.
-- ON DELETE CASCADE : la ligne disparait avec la facture.
-- =====================================================================
CREATE TABLE VENTE_AVOIR_NON_APPLIQUE (
    IDVENTE VARCHAR2(100) NOT NULL,
    DATY    DATE DEFAULT SYSDATE,
    IDUSER  VARCHAR2(100),
    CONSTRAINT PK_VENTE_AVOIR_NON_APPLIQUE PRIMARY KEY (IDVENTE),
    CONSTRAINT FK_VENTE_AVOIR_NON_APPLIQUE FOREIGN KEY (IDVENTE) REFERENCES VENTE (ID) ON DELETE CASCADE
);
