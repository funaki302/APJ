package cinema.film;

/**
 * Lecture d'un film avec categorie, acteur, duree lisible, etat et presence d'une photo (vue CIN_FILM_LIB).
 */
public class CinFilmLib extends CinFilm {

    private String idcategorielib;
    private String idacteurlib;
    private String dureelib;
    private String etatlib;
    private int a_photo;

    public CinFilmLib() {
        this.setNomTable("CIN_FILM_LIB");
    }

    public String getIdcategorielib() {
        return idcategorielib;
    }

    public void setIdcategorielib(String idcategorielib) {
        this.idcategorielib = idcategorielib;
    }

    public String getIdacteurlib() {
        return idacteurlib;
    }

    public void setIdacteurlib(String idacteurlib) {
        this.idacteurlib = idacteurlib;
    }

    public String getDureelib() {
        return dureelib;
    }

    public void setDureelib(String dureelib) {
        this.dureelib = dureelib;
    }

    public String getEtatlib() {
        return etatlib;
    }

    public void setEtatlib(String etatlib) {
        this.etatlib = etatlib;
    }

    public int getA_photo() {
        return a_photo;
    }

    public void setA_photo(int a_photo) {
        this.a_photo = a_photo;
    }
}
