package cinema.paiement;

import bean.ClassMAPTable;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import utilitaire.UtilDB;

/**
 * Lecture seule : facture (vente de la facturation existante) d'un ticket du cinema (vue CIN_FACTURE_VENTE).
 * id = id de la vente ; montantpaye / montantreste viennent de VENTE_CPL.
 */
public class CinFactureVente extends ClassMAPTable {
    private String id;
    private String numerofacture;
    private Date daty;
    private String idticket;
    private String idclient;
    private String idclientlib;
    private String idfilmlib;
    private String idsallelib;
    private Date daty_diffusion;
    private String heure;
    private double montant;
    private double montantpaye;
    private double montantreste;
    private int etat;
    private String etatlib;

    public CinFactureVente() {
        this.setNomTable("CIN_FACTURE_VENTE");
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
     * Factures des tickets d'un client, de la plus recente a la plus ancienne.
     */
    public static CinFactureVente[] getParClient(String idClient, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                canClose = true;
            }
            List<CinFactureVente> factures = new ArrayList<CinFactureVente>();
            try (PreparedStatement ps = c.prepareStatement("select id, numerofacture, daty, idticket, idfilmlib, idsallelib, daty_diffusion, heure,"
                    + " montant, montantpaye, montantreste, etat, etatlib from CIN_FACTURE_VENTE where idclient = ? order by daty desc, id desc")) {
                ps.setString(1, idClient);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        CinFactureVente f = new CinFactureVente();
                        f.id = rs.getString("id");
                        f.numerofacture = rs.getString("numerofacture");
                        f.daty = rs.getDate("daty");
                        f.idticket = rs.getString("idticket");
                        f.idclient = idClient;
                        f.idfilmlib = rs.getString("idfilmlib");
                        f.idsallelib = rs.getString("idsallelib");
                        f.daty_diffusion = rs.getDate("daty_diffusion");
                        f.heure = rs.getString("heure");
                        f.montant = rs.getDouble("montant");
                        f.montantpaye = rs.getDouble("montantpaye");
                        f.montantreste = rs.getDouble("montantreste");
                        f.etat = rs.getInt("etat");
                        f.etatlib = rs.getString("etatlib");
                        factures.add(f);
                    }
                }
            }
            return factures.toArray(new CinFactureVente[0]);
        } finally {
            if (canClose) c.close();
        }
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getNumerofacture() {
        return numerofacture;
    }

    public void setNumerofacture(String numerofacture) {
        this.numerofacture = numerofacture;
    }

    public Date getDaty() {
        return daty;
    }

    public void setDaty(Date daty) {
        this.daty = daty;
    }

    public String getIdticket() {
        return idticket;
    }

    public void setIdticket(String idticket) {
        this.idticket = idticket;
    }

    public String getIdclient() {
        return idclient;
    }

    public void setIdclient(String idclient) {
        this.idclient = idclient;
    }

    public String getIdclientlib() {
        return idclientlib;
    }

    public void setIdclientlib(String idclientlib) {
        this.idclientlib = idclientlib;
    }

    public String getIdfilmlib() {
        return idfilmlib;
    }

    public void setIdfilmlib(String idfilmlib) {
        this.idfilmlib = idfilmlib;
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

    public double getMontant() {
        return montant;
    }

    public void setMontant(double montant) {
        this.montant = montant;
    }

    public double getMontantpaye() {
        return montantpaye;
    }

    public void setMontantpaye(double montantpaye) {
        this.montantpaye = montantpaye;
    }

    public double getMontantreste() {
        return montantreste;
    }

    public void setMontantreste(double montantreste) {
        this.montantreste = montantreste;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }

    public String getEtatlib() {
        return etatlib;
    }

    public void setEtatlib(String etatlib) {
        this.etatlib = etatlib;
    }
}
