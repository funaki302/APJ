package cinema.salle;

/**
 * Lecture d'un cinema avec le libelle de son etat (vue CIN_CINEMA_LIB).
 */
public class CinCinemaLib extends CinCinema {

    private String etatlib;

    public CinCinemaLib() {
        this.setNomTable("CIN_CINEMA_LIB");
    }

    public String getEtatlib() {
        return etatlib;
    }

    public void setEtatlib(String etatlib) {
        this.etatlib = etatlib;
    }
}
