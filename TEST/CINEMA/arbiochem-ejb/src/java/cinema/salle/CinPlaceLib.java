package cinema.salle;

/**
 * Lecture d'une place avec sa salle et sa classe (vue CIN_PLACE_LIB) : libelle, couleur et prix de la classe.
 */
public class CinPlaceLib extends CinPlace {

    private String idsallelib;
    private String idclasselib;
    private String couleur;
    private double prix;
    private String etatlib;

    public CinPlaceLib() {
        this.setNomTable("CIN_PLACE_LIB");
    }

    public String getIdsallelib() {
        return idsallelib;
    }

    public void setIdsallelib(String idsallelib) {
        this.idsallelib = idsallelib;
    }

    public String getIdclasselib() {
        return idclasselib;
    }

    public void setIdclasselib(String idclasselib) {
        this.idclasselib = idclasselib;
    }

    public String getCouleur() {
        return couleur;
    }

    public void setCouleur(String couleur) {
        this.couleur = couleur;
    }

    public double getPrix() {
        return prix;
    }

    public void setPrix(double prix) {
        this.prix = prix;
    }

    public String getEtatlib() {
        return etatlib;
    }

    public void setEtatlib(String etatlib) {
        this.etatlib = etatlib;
    }
}
