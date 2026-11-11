package cinema.paiement;

/**
 * Ligne de paiement avec les libelles du mode et de la caisse (vue CIN_PAIEMENT_DETAIL_LIB).
 */
public class CinPaiementDetailLib extends CinPaiementDetail {

    private String idmodepaiementlib;
    private String idcaisselib;

    public CinPaiementDetailLib() throws Exception {
        this.setNomTable("CIN_PAIEMENT_DETAIL_LIB");
    }

    public String getIdmodepaiementlib() {
        return idmodepaiementlib;
    }

    public void setIdmodepaiementlib(String idmodepaiementlib) {
        this.idmodepaiementlib = idmodepaiementlib;
    }

    public String getIdcaisselib() {
        return idcaisselib;
    }

    public void setIdcaisselib(String idcaisselib) {
        this.idcaisselib = idcaisselib;
    }
}
