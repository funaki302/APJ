package cinema.salle;

import bean.ClassMAPTable;
import java.sql.Connection;

/**
 * Place d'une salle (table CIN_PLACE). Generee par CinSalle a la creation de la salle.
 * Le prix n'est pas stocke : c'est celui de la classe (vue CIN_PLACE_LIB).
 * etat : 1 = en service, 0 = hors service.
 */
public class CinPlace extends ClassMAPTable {

    public static final int EN_SERVICE = 1;
    public static final int HORS_SERVICE = 0;

    private String id;
    private String idsalle;
    private String idclasse;
    private String numero;
    private int rangee;
    private int colonne;
    private int etat = EN_SERVICE;

    public CinPlace() {
        this.setNomTable("CIN_PLACE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINPLA", "GETSEQCINPLACE");
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

    /**
     * Numero affiche d'une place : lettre de la rangee + colonne (rangee 1 = A).
     */
    public static String numeroPlace(int rangee, int colonne) {
        return String.valueOf((char) ('A' + rangee - 1)) + colonne;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdsalle() {
        return idsalle;
    }

    public void setIdsalle(String idsalle) {
        this.idsalle = idsalle;
    }

    public String getIdclasse() {
        return idclasse;
    }

    public void setIdclasse(String idclasse) {
        this.idclasse = idclasse;
    }

    public String getNumero() {
        return numero;
    }

    public void setNumero(String numero) {
        this.numero = numero;
    }

    public int getRangee() {
        return rangee;
    }

    public void setRangee(int rangee) {
        this.rangee = rangee;
    }

    public int getColonne() {
        return colonne;
    }

    public void setColonne(int colonne) {
        this.colonne = colonne;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }
}
