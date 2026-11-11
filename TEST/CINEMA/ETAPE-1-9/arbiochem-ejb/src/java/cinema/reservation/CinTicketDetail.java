package cinema.reservation;

import bean.ClassFille;
import java.sql.Connection;

/**
 * Place reservee d'un ticket (table CIN_TICKET_DETAIL). Le prix est fige au moment de la reservation
 * (prix de la classe de la place a ce moment-la).
 */
public class CinTicketDetail extends ClassFille {

    private String id;
    private String idticket;
    private String iddiffusion;
    private String idplace;
    private String idclasse;
    private double prix;

    public CinTicketDetail() throws Exception {
        this.setNomTable("CIN_TICKET_DETAIL");
        this.setNomClasseMere("cinema.reservation.CinTicket");
        this.setLiaisonMere("idticket");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINTKD", "GETSEQCINTICKETDETAIL");
        this.setId(makePK(c));
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public String getNomClasseMere() {
        return "cinema.reservation.CinTicket";
    }

    @Override
    public String getLiaisonMere() {
        return "idticket";
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdticket() {
        return idticket;
    }

    public void setIdticket(String idticket) {
        this.idticket = idticket;
    }

    public String getIddiffusion() {
        return iddiffusion;
    }

    public void setIddiffusion(String iddiffusion) {
        this.iddiffusion = iddiffusion;
    }

    public String getIdplace() {
        return idplace;
    }

    public void setIdplace(String idplace) {
        this.idplace = idplace;
    }

    public String getIdclasse() {
        return idclasse;
    }

    public void setIdclasse(String idclasse) {
        this.idclasse = idclasse;
    }

    public double getPrix() {
        return prix;
    }

    public void setPrix(double prix) {
        this.prix = prix;
    }
}
