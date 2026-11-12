package cinema.paiement;

import bean.ClassFille;
import java.sql.Connection;

/**
 * Une ligne d'un paiement (table CIN_PAIEMENT_DETAIL) : un mode, une caisse, un montant ;
 * idmvtcaisse = mouvement de caisse (credit) cree pour cette ligne.
 */
public class CinPaiementDetail extends ClassFille {

    private String id;
    private String idpaiement;
    private String idmodepaiement;
    private String idcaisse;
    private double montant;
    private String idmvtcaisse;

    public CinPaiementDetail() throws Exception {
        this.setNomTable("CIN_PAIEMENT_DETAIL");
        this.setNomClasseMere("cinema.paiement.CinPaiement");
        this.setLiaisonMere("idpaiement");
    }
   // les sceance a partir de 8h a 12h seront -50% le prix om mettra le pourcentage dans la base
    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINPAD", "GETSEQCINPAIEMENTDETAIL");
        this.setId(makePK(c));
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public String getNomClasseMere() {
        return "cinema.paiement.CinPaiement";
    }

    @Override
    public String getLiaisonMere() {
        return "idpaiement";
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdpaiement() {
        return idpaiement;
    }

    public void setIdpaiement(String idpaiement) {
        this.idpaiement = idpaiement;
    }

    public String getIdmodepaiement() {
        return idmodepaiement;
    }

    public void setIdmodepaiement(String idmodepaiement) {
        this.idmodepaiement = idmodepaiement;
    }

    public String getIdcaisse() {
        return idcaisse;
    }

    public void setIdcaisse(String idcaisse) {
        this.idcaisse = idcaisse;
    }

    public double getMontant() {
        return montant;
    }

    public void setMontant(double montant) {
        this.montant = montant;
    }

    public String getIdmvtcaisse() {
        return idmvtcaisse;
    }

    public void setIdmvtcaisse(String idmvtcaisse) {
        this.idmvtcaisse = idmvtcaisse;
    }
}
