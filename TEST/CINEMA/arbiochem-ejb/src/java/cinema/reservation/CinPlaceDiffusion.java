package cinema.reservation;

import cinema.salle.CinPlaceLib;

/**
 * Place d'une salle vue pour une seance (vue CIN_PLACE_DIFFUSION) : statut LIBRE, RESERVEE, PAYEE ou HS
 * et ticket qui l'occupe. Utilisee par le plan de reservation (fragment plan-salle.jspf).
 */
public class CinPlaceDiffusion extends CinPlaceLib {

    public static final String LIBRE = "LIBRE";
    public static final String RESERVEE = "RESERVEE";
    public static final String PAYEE = "PAYEE";
    public static final String HS = "HS";

    private String iddiffusion;
    private String idticket;
    private String statut;

    public CinPlaceDiffusion() {
        this.setNomTable("CIN_PLACE_DIFFUSION");
    }

    public boolean estLibre() {
        return LIBRE.equals(statut);
    }

    public String getIddiffusion() {
        return iddiffusion;
    }

    public void setIddiffusion(String iddiffusion) {
        this.iddiffusion = iddiffusion;
    }

    public String getIdticket() {
        return idticket;
    }

    public void setIdticket(String idticket) {
        this.idticket = idticket;
    }

    public String getStatut() {
        return statut;
    }

    public void setStatut(String statut) {
        this.statut = statut;
    }
}
