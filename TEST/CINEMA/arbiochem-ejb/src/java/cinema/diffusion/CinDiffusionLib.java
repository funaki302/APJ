package cinema.diffusion;

/**
 * Lecture d'une diffusion avec film, salle, cinema, heure de fin, places de la salle et statut calcule
 * (Programmee / En cours / Terminee / Annulee) - vue CIN_DIFFUSION_LIB.
 */
public class CinDiffusionLib extends CinDiffusion {

    private String idfilmlib;
    private int duree;
    private String dureelib;
    private String idsallelib;
    private String idcinema;
    private String idcinemalib;
    private String heure_fin;
    private int nb_places;
    private String etatlib;

    public CinDiffusionLib() {
        this.setNomTable("CIN_DIFFUSION_LIB");
    }

    public String getIdfilmlib() {
        return idfilmlib;
    }

    public void setIdfilmlib(String idfilmlib) {
        this.idfilmlib = idfilmlib;
    }

    public int getDuree() {
        return duree;
    }

    public void setDuree(int duree) {
        this.duree = duree;
    }

    public String getDureelib() {
        return dureelib;
    }

    public void setDureelib(String dureelib) {
        this.dureelib = dureelib;
    }

    public String getIdsallelib() {
        return idsallelib;
    }

    public void setIdsallelib(String idsallelib) {
        this.idsallelib = idsallelib;
    }

    public String getIdcinema() {
        return idcinema;
    }

    public void setIdcinema(String idcinema) {
        this.idcinema = idcinema;
    }

    public String getIdcinemalib() {
        return idcinemalib;
    }

    public void setIdcinemalib(String idcinemalib) {
        this.idcinemalib = idcinemalib;
    }

    public String getHeure_fin() {
        return heure_fin;
    }

    public void setHeure_fin(String heure_fin) {
        this.heure_fin = heure_fin;
    }

    public int getNb_places() {
        return nb_places;
    }

    public void setNb_places(int nb_places) {
        this.nb_places = nb_places;
    }

    public String getEtatlib() {
        return etatlib;
    }

    public void setEtatlib(String etatlib) {
        this.etatlib = etatlib;
    }
}
