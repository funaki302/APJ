package cinema.paiement;

import java.sql.Date;

/**
 * Lecture d'un paiement avec client, seance, facture et liste des modes utilises (vue CIN_PAIEMENT_LIB).
 */
public class CinPaiementLib extends CinPaiement {

    private String idclientlib;
    private String iddiffusion;
    private String idfilmlib;
    private String idsallelib;
    private Date daty_diffusion;
    private String heure_paiement;
    private String numero_facture;
    private String modes;

    public CinPaiementLib() throws Exception {
        this.setNomTable("CIN_PAIEMENT_LIB");
    }

    public String getIdclientlib() {
        return idclientlib;
    }

    public void setIdclientlib(String idclientlib) {
        this.idclientlib = idclientlib;
    }

    public String getIddiffusion() {
        return iddiffusion;
    }

    public void setIddiffusion(String iddiffusion) {
        this.iddiffusion = iddiffusion;
    }

    public String getIdfilmlib() {
        return idfilmlib;
    }

    public void setIdfilmlib(String idfilmlib) {
        this.idfilmlib = idfilmlib;
    }

    public String getIdsallelib() {
        return idsallelib;
    }

    public void setIdsallelib(String idsallelib) {
        this.idsallelib = idsallelib;
    }

    public Date getDaty_diffusion() {
        return daty_diffusion;
    }

    public void setDaty_diffusion(Date daty_diffusion) {
        this.daty_diffusion = daty_diffusion;
    }

    public String getHeure_paiement() {
        return heure_paiement;
    }

    public void setHeure_paiement(String heure_paiement) {
        this.heure_paiement = heure_paiement;
    }

    public String getNumero_facture() {
        return numero_facture;
    }

    public void setNumero_facture(String numero_facture) {
        this.numero_facture = numero_facture;
    }

    public String getModes() {
        return modes;
    }

    public void setModes(String modes) {
        this.modes = modes;
    }
}
