package cinema.salle;

/**
 * Lecture d'une classe de place avec le libelle de son etat (vue CIN_CLASSE_PLACE_LIB).
 */
public class CinClassePlaceLib extends CinClassePlace {

    private String etatlib;

    public CinClassePlaceLib() {
        this.setNomTable("CIN_CLASSE_PLACE_LIB");
    }

    public String getEtatlib() {
        return etatlib;
    }

    public void setEtatlib(String etatlib) {
        this.etatlib = etatlib;
    }
}
