package cinema.paiement;

import bean.ClassMAPTable;
import java.sql.Connection;

/**
 * Ligne d'une facture cinema (table CIN_FACTURE_DETAIL) : une place, avec sa designation complete et son prix.
 */
public class CinFactureDetail extends ClassMAPTable {

    private String id;
    private String idfacture;
    private String idplace;
    private String designation;
    private double prix;

    public CinFactureDetail() {
        this.setNomTable("CIN_FACTURE_DETAIL");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINFAD", "GETSEQCINFACTUREDETAIL");
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

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdfacture() {
        return idfacture;
    }

    public void setIdfacture(String idfacture) {
        this.idfacture = idfacture;
    }

    public String getIdplace() {
        return idplace;
    }

    public void setIdplace(String idplace) {
        this.idplace = idplace;
    }

    public String getDesignation() {
        return designation;
    }

    public void setDesignation(String designation) {
        this.designation = designation;
    }

    public double getPrix() {
        return prix;
    }

    public void setPrix(double prix) {
        this.prix = prix;
    }
}
