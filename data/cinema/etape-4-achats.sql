-- =====================================================================
-- CINEMA - Etape 4 : achats de films et de materiel -> sortie de caisse
-- Tables : CIN_ACHAT (mere), CIN_ACHAT_FILLE (lignes) ; vues : CIN_ACHAT_LIB, CIN_ACHAT_FILLE_LIB
-- Caisse : ajout de la caisse "Caisse Cinema" (CAICINEMA) dans la table existante CAISSE.
-- Menus Cinema > Achats.
-- Prerequis : etape-3-films.sql. Se reconnecter apres execution (menu en session).
--
-- Cycle : saisie (ETAT 1 = cree) -> visa (ETAT 11) : le Java cree un mouvement de caisse VISE
-- dans MOUVEMENTCAISSE (DEBIT = montant de l'achat, IDORIGINE = id de l'achat) et met a jour le PA
-- des films achetes. Annulation possible seulement avant le visa (ETAT 0).
-- TYPE d'une ligne : FILM (IDFILM obligatoire) ou MATERIEL (DESIGNATION obligatoire).
-- =====================================================================

SET DEFINE OFF;

-- Caisse du cinema (meme parametrage que les caisses especes existantes : type TCA003, categorie CTC003)
INSERT INTO CAISSE (ID, VAL, DESCE, IDTYPECAISSE, IDPOINT, IDPOMPISTE, ETAT, IDCATEGORIECAISSE, COMPTE,
                    IDMAGASIN, IDDEVISE, IDTYPEBANQUE, ESTRIB, ACTIF)
VALUES ('CAICINEMA', 'Caisse Cin&eacute;ma', 'Caisse du cin&eacute;ma', 'TCA003', 'PNT000084', NULL, 11, 'CTC003', NULL,
        NULL, 'AR', NULL, 0, 1);

CREATE TABLE CIN_ACHAT (
    ID              VARCHAR2(50)  NOT NULL,
    DATY            DATE          NOT NULL,
    FOURNISSEUR     VARCHAR2(255) NOT NULL,
    IDCAISSE        VARCHAR2(255) NOT NULL,
    IDMODEPAIEMENT  VARCHAR2(255) NOT NULL,
    MONTANT         NUMBER(15, 2) DEFAULT 0 NOT NULL,
    REMARQUE        VARCHAR2(500),
    IDMVTCAISSE     VARCHAR2(255),
    ETAT            NUMBER(2) DEFAULT 1,
    CONSTRAINT PK_CIN_ACHAT PRIMARY KEY (ID),
    CONSTRAINT FK_CIN_ACHAT_CAISSE FOREIGN KEY (IDCAISSE) REFERENCES CAISSE (ID),
    CONSTRAINT CK_CIN_ACHAT_MONTANT CHECK (MONTANT >= 0),
    CONSTRAINT CK_CIN_ACHAT_ETAT CHECK (ETAT IN (0, 1, 11))
);

CREATE TABLE CIN_ACHAT_FILLE (
    ID          VARCHAR2(50)  NOT NULL,
    IDACHAT     VARCHAR2(50)  NOT NULL,
    TYPE        VARCHAR2(10)  NOT NULL,
    IDFILM      VARCHAR2(50),
    DESIGNATION VARCHAR2(255),
    QTE         NUMBER(10)    NOT NULL,
    PU          NUMBER(15, 2) NOT NULL,
    ETAT        NUMBER(2) DEFAULT 1,
    CONSTRAINT PK_CIN_ACHAT_FILLE PRIMARY KEY (ID),
    CONSTRAINT FK_CIN_ACHAT_FILLE_ACHAT FOREIGN KEY (IDACHAT) REFERENCES CIN_ACHAT (ID) ON DELETE CASCADE,
    CONSTRAINT FK_CIN_ACHAT_FILLE_FILM FOREIGN KEY (IDFILM) REFERENCES CIN_FILM (ID),
    CONSTRAINT CK_CIN_ACHAT_FILLE_TYPE CHECK (TYPE IN ('FILM', 'MATERIEL')),
    CONSTRAINT CK_CIN_ACHAT_FILLE_QTE CHECK (QTE > 0),
    CONSTRAINT CK_CIN_ACHAT_FILLE_PU CHECK (PU >= 0)
);

CREATE INDEX IX_CIN_ACHAT_FILLE_ACHAT ON CIN_ACHAT_FILLE (IDACHAT);
CREATE INDEX IX_CIN_ACHAT_FILLE_FILM ON CIN_ACHAT_FILLE (IDFILM);

CREATE SEQUENCE SEQ_CIN_ACHAT START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_CIN_ACHAT_FILLE START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE OR REPLACE FUNCTION GETSEQCINACHAT RETURN NUMBER IS
    retour NUMBER;
BEGIN
    SELECT SEQ_CIN_ACHAT.NEXTVAL INTO retour FROM DUAL;
    RETURN retour;
END;
/

CREATE OR REPLACE FUNCTION GETSEQCINACHATFILLE RETURN NUMBER IS
    retour NUMBER;
BEGIN
    SELECT SEQ_CIN_ACHAT_FILLE.NEXTVAL INTO retour FROM DUAL;
    RETURN retour;
END;
/

-- Achat avec caisse, mode de paiement, libelle de l'etat et nombre de lignes
CREATE OR REPLACE VIEW CIN_ACHAT_LIB AS
SELECT a.ID, a.DATY, a.FOURNISSEUR, a.IDCAISSE, c.VAL AS IDCAISSELIB, a.IDMODEPAIEMENT, m.VAL AS IDMODEPAIEMENTLIB,
       a.MONTANT, a.REMARQUE, a.IDMVTCAISSE, a.ETAT,
       DECODE(a.ETAT, 0, 'Annul&eacute;', 1, 'Cr&eacute;&eacute;', 11, 'Vis&eacute;', TO_CHAR(a.ETAT)) AS ETATLIB,
       (SELECT COUNT(*) FROM CIN_ACHAT_FILLE f WHERE f.IDACHAT = a.ID) AS NB_LIGNES
FROM CIN_ACHAT a
LEFT JOIN CAISSE c ON c.ID = a.IDCAISSE
LEFT JOIN MODEPAIEMENT m ON m.ID = a.IDMODEPAIEMENT;

-- Ligne d'achat avec le titre du film et le montant de la ligne
CREATE OR REPLACE VIEW CIN_ACHAT_FILLE_LIB AS
SELECT f.ID, f.IDACHAT, f.TYPE, DECODE(f.TYPE, 'FILM', 'Film', 'Mat&eacute;riel') AS TYPELIB,
       f.IDFILM, fi.TITRE AS IDFILMLIB, NVL(f.DESIGNATION, fi.TITRE) AS DESIGNATIONLIB, f.DESIGNATION,
       f.QTE, f.PU, f.QTE * f.PU AS MONTANT, f.ETAT
FROM CIN_ACHAT_FILLE f
LEFT JOIN CIN_FILM fi ON fi.ID = f.IDFILM;

-- ---------------------------------------------------------------------
-- Menus : Cinema > Achats > (Saisie, Liste)
-- ---------------------------------------------------------------------
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA04', 'Achats', 'shopping_bag', NULL, 4, 2, 'MENDYNCINEMA');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA0401', 'Saisie', 'add', 'module.jsp?but=cinema/achat/achat-saisie.jsp', 1, 3, 'MENDYNCINEMA04');
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
VALUES ('MENDYNCINEMA0402', 'Liste', 'list', 'module.jsp?but=cinema/achat/achat-liste.jsp', 2, 3, 'MENDYNCINEMA04');

COMMIT;

-- Controle
-- SELECT * FROM CIN_ACHAT_LIB;
-- SELECT ID, DESIGNATION, DEBIT, ETAT FROM MOUVEMENTCAISSE WHERE IDORIGINE LIKE 'CINACH%';
