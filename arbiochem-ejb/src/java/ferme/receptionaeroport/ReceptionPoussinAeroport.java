package ferme.receptionaeroport;

import java.sql.Connection;
import bean.ClassMere;
import java.sql.Date;
import bean.ClassMAPTable;
import bean.CGenUtil;
import faturefournisseur.As_BonDeLivraison_Fille;
import ferme.lot.Lot;
import produits.Ingredients;
/**
 *
 * @author Safidy
 */
public class ReceptionPoussinAeroport extends ClassMere {
    private String id,idLot,idBl,remarque, heureDepart, heureArrive;
    private int perdus,morts;
    private Date daty;
    private double qteRecus;
    private int nbrCartonMale,nbrCartonFemelle,etat;
    public ReceptionPoussinAeroport()throws Exception {
        super.setNomTable("receptionPoussinAeroport");
        this.setNomClasseFille("ferme.receptionaeroport.ReceptionPoussinAeroportDetail");
        this.setLiaisonFille("idMere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("RPA", "GETSEQRECEPTIONPOUSSINAEROPORT");
        this.setId(this.makePK(c));
    }
    @Override
    public String getTuppleID() {
        return id;
    }

    public int getNbrCartonMale() {
        return nbrCartonMale;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }

    public void setNbrCartonMale(int nbrCartonMale) {
        this.nbrCartonMale = nbrCartonMale;
    }

    public int getNbrCartonFemelle() {
        return nbrCartonFemelle;
    }

    public void setNbrCartonFemelle(int nbrCartonFemelle) {
        this.nbrCartonFemelle = nbrCartonFemelle;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public String getNomClasseFille() {
        return "ferme.receptionaeroport.ReceptionPoussinAeroportDetail";
    }

    @Override
    public String getLiaisonFille() {
        return "idMere";
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdLot() {
        return idLot;
    }

    public String getIdBl() {
        return idBl;
    }

    public void setIdBl(String idBl) {
        this.idBl = idBl;
    }

    public int getPerdus() {
        return perdus;
    }

    public int getMorts() {
        return morts;
    }

    public void setMorts(int morts) {
        this.morts = morts;
    }

    public void setPerdus(int perdus) {
        this.perdus = perdus;
    }

    public void setIdLot(String idLot) {
        this.idLot = idLot;
    }

    public String getRemarque() {
        return remarque;
    }

    public void setRemarque(String remarque) {
        this.remarque = remarque;
    }

    public Date getDaty() {
        return daty;
    }

    public void setDaty(Date daty) {
        this.daty = daty;
    }

    public double getQteRecus() {
        return qteRecus;
    }

    public void setQteRecus(double qteRecus) {
        this.qteRecus = qteRecus;
    }

    public String getHeureDepart() {
        return heureDepart;
    }

    public void setHeureDepart(String heureDepart) {
        this.heureDepart = heureDepart;
    }

    public String getHeureArrive() {
        return heureArrive;
    }

    public void setHeureArrive(String heureArrive) {
        this.heureArrive = heureArrive;
    }

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        checkQteFille();
        if (idBl == null || idBl.trim().isEmpty()) {
            throw new Exception("Le bon de livraison est obligatoire");
        }
        if (daty == null) {
            throw new Exception("La date de r�ception est obligatoire");
        }

        BonLivraisonInfo livraison = getBonLivraisonInfo(idBl.trim(), c);
        if (qteRecus < 0 || Math.abs(qteRecus - Math.rint(qteRecus)) > 0.000001
                || qteRecus - livraison.quantite > 0.000001) {
            throw new Exception("La quantit� re�ue ne peut pas d�passer la quantit� du bon de livraison (" + livraison.quantite + ")");
        }
        double quantitePerdue = livraison.quantite - qteRecus;
        long quantitePerdueArrondie = Math.round(quantitePerdue);
        if (Math.abs(quantitePerdue - quantitePerdueArrondie) > 0.000001 || quantitePerdueArrondie > Integer.MAX_VALUE) {
            throw new Exception("La quantit� perdue doit �tre un nombre entier positif");
        }
        this.perdus = (int) quantitePerdueArrondie;

        // Chaque nouvelle r�ception dispose de son propre lot. La cr�ation
        // utilise la m�me connexion que la r�ception et ses lignes filles.
        if (id == null || id.trim().isEmpty()) {
            Ingredients produit = (Ingredients) new Ingredients().getById(livraison.idProduit, "AS_INGREDIENTS", c);
            if (produit == null || produit.getLibelle() == null || produit.getLibelle().trim().isEmpty()) {
                throw new Exception("Le produit du bon de livraison est introuvable dans AS_INGREDIENTS");
            }
            String nomLot = produit.getLibelle().trim() + " - " + idBl.trim();
            String referenceLot = "Livraison " + idBl.trim();
            if (nomLot.length() > 200 || referenceLot.length() > 200) {
                throw new Exception("Le nom ou la r�f�rence du lot d�passe la longueur autoris�e (200 caract�res)");
            }

            Lot lot = new Lot();
            lot.setNomlot(nomLot);
            lot.setReference(referenceLot);
            lot.setDateeclosion(daty);
            lot.setDatearrivee(daty);
            lot.setIdarticle(livraison.idProduit);
            lot.setIdferme(null);
            lot.setSource(null);
            // Origine, programme zootechnique et souche necessaires pour la suite
            // (triage, estimation de poussins...) : deduits de l'article du bon de livraison.
            lot.setIdorigine(ORIGINE_IMPORT);
            appliquerProgrammeEtSouche(lot, livraison.idProduit, produit.getLibelle());
            lot = (Lot) lot.createObject(u, c);
            this.idLot = lot.getId();
        }

        return super.createObject(u, c);
    }

    // Origine par defaut des receptions aeroport : ORI001 (Import)
    private static final String ORIGINE_IMPORT = "ORI001";

    /**
     * Renseigne idprogramme et idsouche du lot selon l'article (poussin) recu :
     *   INGR00000100 (Poussin Ross 308)  -> PZn0001 (PZ-ROSS-2026)    / SOU001 (Ross 308)
     *   INGR00000103 (Poussin Cobb 500)  -> PZn0002 (PZ-COBB-2026)    / SOU002 (Cobb 500)
     *   INGR000001 (Poussin Hubbard)   -> PZn0003 (PZ-HUBBARD-2026) / SOU003 (Hubbard)
     * Tout autre article : erreur, la creation du lot (donc de la reception) est annulee.
     */
    private static void appliquerProgrammeEtSouche(Lot lot, String idArticle, String libelleArticle) throws Exception {
        String article = idArticle == null ? "" : idArticle.trim();
        if (article.equalsIgnoreCase("INGR00000100")) {
            lot.setIdprogramme("PZn0001");
            lot.setIdSouche("SOU001");
        } else if (article.equalsIgnoreCase("INGR00000103")) {
            lot.setIdprogramme("PZn0002");
            lot.setIdSouche("SOU002");
        } else if (article.equalsIgnoreCase("INGR000001")) {
            lot.setIdprogramme("PZn0003");
            lot.setIdSouche("SOU003");
        } else {
            throw new Exception("Le produit " + libelleArticle + " (" + article + ") n'a pas de souche correspondante");
        }
    }

    private BonLivraisonInfo getBonLivraisonInfo(String idBonLivraison, Connection c) throws Exception {
        if (!idBonLivraison.matches("[A-Za-z0-9._/-]+")) {
            throw new Exception("L'identifiant du bon de livraison est invalide");
        }
        As_BonDeLivraison_Fille critere = new As_BonDeLivraison_Fille();
        critere.setNumbl(idBonLivraison);
        As_BonDeLivraison_Fille[] lignes = (As_BonDeLivraison_Fille[]) CGenUtil.rechercher(
            critere, null, null, c, "");
        if (lignes == null || lignes.length == 0) {
            throw new Exception("Aucune ligne trouv�e pour le bon de livraison " + idBonLivraison);
        }

        String idProduit = null;
        double quantite = 0;
        for (As_BonDeLivraison_Fille ligne : lignes) {
            if (ligne.getProduit() == null || ligne.getProduit().trim().isEmpty()) {
                throw new Exception("Une ligne du bon de livraison n'a pas de produit");
            }
            if (idProduit == null) {
                idProduit = ligne.getProduit().trim();
            } else if (!idProduit.equalsIgnoreCase(ligne.getProduit().trim())) {
                throw new Exception("Le bon de livraison contient plusieurs produits; une r�ception doit correspondre � un seul produit");
            }
            if (ligne.getQuantite() < 0) {
                throw new Exception("Une quantit� n�gative est pr�sente sur le bon de livraison");
            }
            quantite += ligne.getQuantite();
        }
        if (quantite <= 0) {
            throw new Exception("La quantit� du bon de livraison doit �tre positive");
        }
        return new BonLivraisonInfo(idProduit, quantite);
    }

    private static final class BonLivraisonInfo {
        private final String idProduit;
        private final double quantite;

        private BonLivraisonInfo(String idProduit, double quantite) {
            this.idProduit = idProduit;
            this.quantite = quantite;
        }
    }

    public void checkQteFille() throws Exception {
        if (morts < 0) {
            throw new Exception("Le nombre de poussins morts ne peut pas etre negatif");
        }
        ReceptionPoussinAeroportDetail[] fille = (ReceptionPoussinAeroportDetail[]) this.getFille();
        if (fille == null || fille.length == 0) {
            throw new Exception("Ajoutez au moins une ligne de qualit�/sexe/quantit�");
        }
        double qteFille = 0;
        for (ReceptionPoussinAeroportDetail f : fille) {
            if (f != null) {
                if (f.getQte() < 0) {
                    throw new Exception("La quantit� d'une ligne ne peut pas �tre n�gative");
                }
                qteFille += f.getQte();
            }
        }
        if (Math.abs(this.getQteRecus() - (qteFille + morts)) > 0.000001) {
            throw new Exception("La somme des quantites vivantes (" + qteFille + ") et mortes (" + morts + ") doit correspondre a la quantite recue (" + this.getQteRecus() + ")");
        }
    }

}