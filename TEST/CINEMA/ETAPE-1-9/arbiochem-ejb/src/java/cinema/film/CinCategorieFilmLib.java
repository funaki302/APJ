package cinema.film;

/**
 * Lecture d'une categorie de film avec le libelle de son etat (vue CIN_CATEGORIE_FILM_LIB).
 */
public class CinCategorieFilmLib extends CinCategorieFilm {

    private String etatlib;

    public CinCategorieFilmLib() {
        this.setNomTable("CIN_CATEGORIE_FILM_LIB");
    }

    public String getEtatlib() {
        return etatlib;
    }

    public void setEtatlib(String etatlib) {
        this.etatlib = etatlib;
    }
}
