package cinema.paiement;

/**
 * Lecture d'un mode de paiement et de sa caisse avec leurs libelles (vue CIN_MODE_CAISSE_LIB).
 */
public class CinModeCaisseLib extends CinModeCaisse {

    private String idmodepaiementlib;
    private String idcaisselib;
    private String actiflib;

    public CinModeCaisseLib() {
        this.setNomTable("CIN_MODE_CAISSE_LIB");
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

    public String getActiflib() {
        return actiflib;
    }

    public void setActiflib(String actiflib) {
        this.actiflib = actiflib;
    }
}
