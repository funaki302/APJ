package cinema.reservation;

import bean.ClassMAPTable;
import cinema.paiement.CinPaiementLib;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import utilitaire.UtilDB;

/**
 * Client du cinema en lecture seule (vue CIN_CLIENT_LIB) : un client de la table CLIENT existante qui a au moins
 * un ticket, avec ses totaux. Ses reservations et ses paiements s'obtiennent par getTickets / getPaiements.
 * La creation et la modification d'un client se font dans les pages client existantes de l'application.
 */
public class CinClient extends ClassMAPTable {

    private String id;
    private String nom;
    private String telephone;
    private String mail;
    private int nb_tickets;
    private int nb_payes;
    private int nb_en_attente;
    private int nb_places_payees;
    private double montant_paye;
    private Date derniere_reservation;

    public CinClient() {
        this.setNomTable("CIN_CLIENT_LIB");
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
    public void controler(Connection c) throws Exception {
        throw new Exception("Les clients se cr&eacute;ent et se modifient dans les pages client de l'application");
    }

    /**
     * Tickets du client, du plus recent au plus ancien (statut calcule : Reserve / Paye / Expire / Annule).
     */
    public static CinTicketLib[] getTickets(String idClient, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                canClose = true;
            }
            List<CinTicketLib> tickets = new ArrayList<CinTicketLib>();
            String sql = "select id, iddiffusion, idfilmlib, idsallelib, daty_diffusion, heure, daty_reservation, nb_places, montant, etat, etatlib"
                    + " from CIN_TICKET_LIB where idclient = ? order by date_debut desc, id desc";
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, idClient);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        CinTicketLib t = new CinTicketLib();
                        t.setId(rs.getString("id"));
                        t.setIddiffusion(rs.getString("iddiffusion"));
                        t.setIdfilmlib(rs.getString("idfilmlib"));
                        t.setIdsallelib(rs.getString("idsallelib"));
                        t.setDaty_diffusion(rs.getDate("daty_diffusion"));
                        t.setHeure(rs.getString("heure"));
                        t.setDaty_reservation(rs.getDate("daty_reservation"));
                        t.setNb_places(rs.getInt("nb_places"));
                        t.setMontant(rs.getDouble("montant"));
                        t.setEtat(rs.getInt("etat"));
                        t.setEtatlib(rs.getString("etatlib"));
                        tickets.add(t);
                    }
                }
            }
            return tickets.toArray(new CinTicketLib[0]);
        } finally {
            if (canClose) c.close();
        }
    }

    /**
     * Paiements du client, du plus recent au plus ancien, avec les modes utilises et le numero de facture.
     */
    public static CinPaiementLib[] getPaiements(String idClient, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                canClose = true;
            }
            List<CinPaiementLib> paiements = new ArrayList<CinPaiementLib>();
            String sql = "select id, idticket, idfilmlib, daty, heure_paiement, montant, modes, idfacture, numero_facture"
                    + " from CIN_PAIEMENT_LIB where idclient = ? order by daty desc, id desc";
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, idClient);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        CinPaiementLib p = new CinPaiementLib();
                        p.setId(rs.getString("id"));
                        p.setIdticket(rs.getString("idticket"));
                        p.setIdfilmlib(rs.getString("idfilmlib"));
                        p.setDaty(rs.getDate("daty"));
                        p.setHeure_paiement(rs.getString("heure_paiement"));
                        p.setMontant(rs.getDouble("montant"));
                        p.setModes(rs.getString("modes"));
                        p.setIdfacture(rs.getString("idfacture"));
                        p.setNumero_facture(rs.getString("numero_facture"));
                        paiements.add(p);
                    }
                }
            }
            return paiements.toArray(new CinPaiementLib[0]);
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

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public String getTelephone() {
        return telephone;
    }

    public void setTelephone(String telephone) {
        this.telephone = telephone;
    }

    public String getMail() {
        return mail;
    }

    public void setMail(String mail) {
        this.mail = mail;
    }

    public int getNb_tickets() {
        return nb_tickets;
    }

    public void setNb_tickets(int nb_tickets) {
        this.nb_tickets = nb_tickets;
    }

    public int getNb_payes() {
        return nb_payes;
    }

    public void setNb_payes(int nb_payes) {
        this.nb_payes = nb_payes;
    }

    public int getNb_en_attente() {
        return nb_en_attente;
    }

    public void setNb_en_attente(int nb_en_attente) {
        this.nb_en_attente = nb_en_attente;
    }

    public int getNb_places_payees() {
        return nb_places_payees;
    }

    public void setNb_places_payees(int nb_places_payees) {
        this.nb_places_payees = nb_places_payees;
    }

    public double getMontant_paye() {
        return montant_paye;
    }

    public void setMontant_paye(double montant_paye) {
        this.montant_paye = montant_paye;
    }

    public Date getDerniere_reservation() {
        return derniere_reservation;
    }

    public void setDerniere_reservation(Date derniere_reservation) {
        this.derniere_reservation = derniere_reservation;
    }
}
