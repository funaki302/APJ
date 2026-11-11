package cinema.paiement;

import java.sql.Date;

/**
 * Lecture d'une facture avec client et seance (vue CIN_FACTURE_LIB).
 */
public class CinFactureLib extends CinFacture {

    private String idclientlib;
    private String telephone;
    private String iddiffusion;
    private String idfilmlib;
    private String idsallelib;
    private Date daty_diffusion;
    private String heure;
    private int nb_places;

    public CinFactureLib() {
        this.setNomTable("CIN_FACTURE_LIB");
    }

    public String getIdclientlib() {
        return idclientlib;
    }

    public void setIdclientlib(String idclientlib) {
        this.idclientlib = idclientlib;
    }

    public String getTelephone() {
        return telephone;
    }

    public void setTelephone(String telephone) {
        this.telephone = telephone;
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

    public String getHeure() {
        return heure;
    }

    public void setHeure(String heure) {
        this.heure = heure;
    }

    public int getNb_places() {
        return nb_places;
    }

    public void setNb_places(int nb_places) {
        this.nb_places = nb_places;
    }
}
