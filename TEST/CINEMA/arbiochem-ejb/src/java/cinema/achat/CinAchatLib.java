package cinema.achat;

/**
 * Lecture d'un achat avec caisse, mode de paiement, libelle de l'etat et nombre de lignes (vue CIN_ACHAT_LIB).
 */
public class CinAchatLib extends CinAchat {

    private String idcaisselib;
    private String idmodepaiementlib;
    private String etatlib;
    private int nb_lignes;

    public CinAchatLib() throws Exception {
        this.setNomTable("CIN_ACHAT_LIB");
    }

    public String getIdcaisselib() {
        return idcaisselib;
    }

    public void setIdcaisselib(String idcaisselib) {
        this.idcaisselib = idcaisselib;
    }

    public String getIdmodepaiementlib() {
        return idmodepaiementlib;
    }

    public void setIdmodepaiementlib(String idmodepaiementlib) {
        this.idmodepaiementlib = idmodepaiementlib;
    }

    public String getEtatlib() {
        return etatlib;
    }

    public void setEtatlib(String etatlib) {
        this.etatlib = etatlib;
    }

    public int getNb_lignes() {
        return nb_lignes;
    }

    public void setNb_lignes(int nb_lignes) {
        this.nb_lignes = nb_lignes;
    }
}
