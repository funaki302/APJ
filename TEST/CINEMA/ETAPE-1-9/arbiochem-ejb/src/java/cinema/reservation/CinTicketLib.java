package cinema.reservation;

import java.sql.Date;

/**
 * Lecture d'un ticket avec client, seance, date limite de paiement et statut calcule
 * (Reserve / Paye / Expire / Annule) - vue CIN_TICKET_LIB.
 */
public class CinTicketLib extends CinTicket {

    private String idclientlib;
    private String telephone;
    private String idfilm;
    private String idfilmlib;
    private String idsalle;
    private String idsallelib;
    private Date daty_diffusion;
    private String heure;
    private String heure_fin;
    private int etat_diffusion;
    private String etatlib;
    private int actif;
    private String date_limitelib;
    private int nb_places;

    public CinTicketLib() throws Exception {
        this.setNomTable("CIN_TICKET_LIB");
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

    public String getIdfilm() {
        return idfilm;
    }

    public void setIdfilm(String idfilm) {
        this.idfilm = idfilm;
    }

    public String getIdfilmlib() {
        return idfilmlib;
    }

    public void setIdfilmlib(String idfilmlib) {
        this.idfilmlib = idfilmlib;
    }

    public String getIdsalle() {
        return idsalle;
    }

    public void setIdsalle(String idsalle) {
        this.idsalle = idsalle;
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

    public String getHeure_fin() {
        return heure_fin;
    }

    public void setHeure_fin(String heure_fin) {
        this.heure_fin = heure_fin;
    }

    public int getEtat_diffusion() {
        return etat_diffusion;
    }

    public void setEtat_diffusion(int etat_diffusion) {
        this.etat_diffusion = etat_diffusion;
    }

    public String getEtatlib() {
        return etatlib;
    }

    public void setEtatlib(String etatlib) {
        this.etatlib = etatlib;
    }

    public int getActif() {
        return actif;
    }

    public void setActif(int actif) {
        this.actif = actif;
    }

    public String getDate_limitelib() {
        return date_limitelib;
    }

    public void setDate_limitelib(String date_limitelib) {
        this.date_limitelib = date_limitelib;
    }

    public int getNb_places() {
        return nb_places;
    }

    public void setNb_places(int nb_places) {
        this.nb_places = nb_places;
    }
}
