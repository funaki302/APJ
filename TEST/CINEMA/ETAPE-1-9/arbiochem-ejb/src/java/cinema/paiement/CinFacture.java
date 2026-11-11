package cinema.paiement;

import bean.ClassMAPTable;
import cinema.utils.CinUtils;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import utilitaire.UtilDB;

/**
 * Facture cinema (table CIN_FACTURE), creee automatiquement au paiement complet d'un ticket (CinPaiement.payer).
 * Une ligne par place (CinFactureDetail). Numero : FC + annee + numero sequentiel (FC2026-00001).
 */
public class CinFacture extends ClassMAPTable {

    private String id;
    private String numero;
    private String idclient;
    private String idticket;
    private String idpaiement;
    private Date daty;
    private double montant;
    private int etat = 11;

    public CinFacture() {
        this.setNomTable("CIN_FACTURE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINFAC", "GETSEQCINFACTURE");
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
    public void controlerDelete(Connection c) throws Exception {
        throw new Exception("Une facture ne se supprime pas");
    }

    @Override
    public int updateToTableWithHisto(String refUser, Connection c) throws Exception {
        throw new Exception("Une facture ne se modifie pas");
    }

    /**
     * Prochain numero de facture : FC + annee + 5 chiffres (sequence unique, jamais reutilisee).
     */
    public static String prochainNumero(Connection c) throws Exception {
        return CinUtils.valeur(c, "select 'FC' || to_char(sysdate, 'YYYY') || '-' || lpad(SEQ_CIN_FACTURE_NUMERO.nextval, 5, '0') from dual");
    }

    /**
     * Lignes d'une facture, dans l'ordre des places.
     */
    public static CinFactureDetail[] getDetails(String idFacture, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                canClose = true;
            }
            List<CinFactureDetail> lignes = new ArrayList<CinFactureDetail>();
            try (PreparedStatement ps = c.prepareStatement(
                    "select fd.id, fd.idplace, fd.designation, fd.prix from CIN_FACTURE_DETAIL fd join CIN_PLACE p on p.id = fd.idplace"
                    + " where fd.idfacture = ? order by p.rangee, p.colonne")) {
                ps.setString(1, idFacture);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        CinFactureDetail d = new CinFactureDetail();
                        d.setId(rs.getString(1));
                        d.setIdfacture(idFacture);
                        d.setIdplace(rs.getString(2));
                        d.setDesignation(rs.getString(3));
                        d.setPrix(rs.getDouble(4));
                        lignes.add(d);
                    }
                }
            }
            return lignes.toArray(new CinFactureDetail[0]);
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

    public String getNumero() {
        return numero;
    }

    public void setNumero(String numero) {
        this.numero = numero;
    }

    public String getIdclient() {
        return idclient;
    }

    public void setIdclient(String idclient) {
        this.idclient = idclient;
    }

    public String getIdticket() {
        return idticket;
    }

    public void setIdticket(String idticket) {
        this.idticket = idticket;
    }

    public String getIdpaiement() {
        return idpaiement;
    }

    public void setIdpaiement(String idpaiement) {
        this.idpaiement = idpaiement;
    }

    public Date getDaty() {
        return daty;
    }

    public void setDaty(Date daty) {
        this.daty = daty;
    }

    public double getMontant() {
        return montant;
    }

    public void setMontant(double montant) {
        this.montant = montant;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }
}
