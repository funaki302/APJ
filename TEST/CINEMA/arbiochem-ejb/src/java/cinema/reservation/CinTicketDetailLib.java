package cinema.reservation;

/**
 * Place d'un ticket avec son numero et sa classe (vue CIN_TICKET_DETAIL_LIB).
 */
public class CinTicketDetailLib extends CinTicketDetail {

    private String numero;
    private String idclasselib;
    private String couleur;

    public CinTicketDetailLib() throws Exception {
        this.setNomTable("CIN_TICKET_DETAIL_LIB");
    }

    public String getNumero() {
        return numero;
    }

    public void setNumero(String numero) {
        this.numero = numero;
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
}
