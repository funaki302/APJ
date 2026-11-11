package cinema.salle;

/**
 * Lecture d'une salle avec le nom du cinema, le libelle de l'etat et le nombre de places en service (vue CIN_SALLE_LIB).
 */
public class CinSalleLib extends CinSalle {

    private String idcinemalib;
    private String etatlib;
    private int nb_places_service;

    public CinSalleLib() {
        this.setNomTable("CIN_SALLE_LIB");
    }

    public String getIdcinemalib() {
        return idcinemalib;
    }

    public void setIdcinemalib(String idcinemalib) {
        this.idcinemalib = idcinemalib;
    }

    public String getEtatlib() {
        return etatlib;
    }

    public void setEtatlib(String etatlib) {
        this.etatlib = etatlib;
    }

    public int getNb_places_service() {
        return nb_places_service;
    }

    public void setNb_places_service(int nb_places_service) {
        this.nb_places_service = nb_places_service;
    }
}
