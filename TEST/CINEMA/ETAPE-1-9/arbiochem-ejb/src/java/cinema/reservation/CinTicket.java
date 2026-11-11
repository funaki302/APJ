package cinema.reservation;

import bean.ClassFille;
import bean.ClassMere;
import cinema.utils.CinUtils;
import constante.ConstanteEtat;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import utilitaire.UtilDB;

/**
 * Reservation (ticket) d'un client pour une seance : CIN_TICKET + une ligne CIN_TICKET_DETAIL par place.
 * etat : 1 = reserve, 11 = paye (etape 7), 0 = annule. Un ticket reserve expire DELAI_EXPIRATION_MIN minutes avant
 * la seance (calcul dans les vues) : ses places redeviennent libres.
 * La reservation passe par reserver(...), qui verrouille la seance pour que deux caisses ne prennent pas la meme place.
 */
public class CinTicket extends ClassMere {

    public static final int RESERVE = 1;
    public static final int PAYE = 11;
    public static final int ANNULE = 0;

    private String id;
    private String idclient;
    private String iddiffusion;
    private Date daty_reservation;
    private String heure_reservation;
    private double montant;
    private String remarque;

    public CinTicket() throws Exception {
        this.setNomTable("CIN_TICKET");
        this.setNomClasseFille("cinema.reservation.CinTicketDetail");
        this.setLiaisonFille("idticket");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINTKT", "GETSEQCINTICKET");
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
    public String getNomClasseFille() {
        return "cinema.reservation.CinTicketDetail";
    }

    @Override
    public String getLiaisonFille() {
        return "idticket";
    }

    /**
     * Reserve des places pour un client (sa propre connexion et sa propre transaction).
     */
    public static CinTicket reserver(String idDiffusion, String idClient, String[] idPlaces, String remarque, String refUser) throws Exception {
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            CinTicket t = reserver(idDiffusion, idClient, idPlaces, remarque, refUser, c);
            c.commit();
            return t;
        } catch (Exception e) {
            if (c != null) c.rollback();
            throw e;
        } finally {
            if (c != null) c.close();
        }
    }

    /**
     * Reserve des places pour un client, dans la transaction de l'appelant (pas de commit).
     * Verrouille la seance (SELECT ... FOR UPDATE) puis verifie que chaque place est libre ; prix figes.
     */
    public static CinTicket reserver(String idDiffusion, String idClient, String[] idPlaces, String remarque, String refUser, Connection c) throws Exception {
        if (CinUtils.estVide(idClient)) throw new Exception("Choisissez le client");
        if (CinUtils.entier(c, "select count(*) from CLIENT where id = ?", idClient) == 0) throw new Exception("Client introuvable");
        if (CinUtils.estVide(idDiffusion)) throw new Exception("S&eacute;ance non pr&eacute;cis&eacute;e");

        // verrou : deux reservations simultanees de la meme seance passent l'une apres l'autre
        try (PreparedStatement verrou = c.prepareStatement("select id from CIN_DIFFUSION where id = ? for update")) {
            verrou.setString(1, idDiffusion);
            try (ResultSet rs = verrou.executeQuery()) {
                if (!rs.next()) throw new Exception("S&eacute;ance introuvable");
            }
        }
        if (CinUtils.entier(c, "select count(*) from CIN_DIFFUSION where id = ? and etat = 1", idDiffusion) == 0) {
            throw new Exception("Cette s&eacute;ance est annul&eacute;e");
        }
        if (!reservationOuverte(idDiffusion, c)) {
            throw new Exception("Les r&eacute;servations sont closes pour cette s&eacute;ance (elles ferment "
                    + cinema.utils.CinParametre.getDelaiExpirationMinutes(c) + " min avant le d&eacute;but)");
        }

        Set<String> places = new LinkedHashSet<String>();
        if (idPlaces != null) for (String p : idPlaces) if (!CinUtils.estVide(p)) places.add(p.trim());
        if (places.isEmpty()) throw new Exception("Choisissez au moins une place sur le plan");

        List<ClassFille> lignes = new ArrayList<ClassFille>();
        double total = 0;
        String sql = "select numero, statut, idclasse, prix from CIN_PLACE_DIFFUSION where iddiffusion = ? and idplace = ?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            for (String idPlace : places) {
                ps.setString(1, idDiffusion);
                ps.setString(2, idPlace);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new Exception("La place " + idPlace + " n'est pas dans la salle de cette s&eacute;ance");
                    String statut = rs.getString("statut");
                    if (CinPlaceDiffusion.HS.equals(statut)) throw new Exception("La place " + rs.getString("numero") + " est hors service");
                    if (!CinPlaceDiffusion.LIBRE.equals(statut)) throw new Exception("La place " + rs.getString("numero") + " vient d'&ecirc;tre prise : choisissez-en une autre");
                    CinTicketDetail d = new CinTicketDetail();
                    d.setIddiffusion(idDiffusion);
                    d.setIdplace(idPlace);
                    d.setIdclasse(rs.getString("idclasse"));
                    d.setPrix(rs.getDouble("prix"));
                    total += d.getPrix();
                    lignes.add(d);
                }
            }
        }

        CinTicket t = new CinTicket();
        t.setIdclient(idClient);
        t.setIddiffusion(idDiffusion);
        t.setDaty_reservation(new Date(System.currentTimeMillis()));
        t.setHeure_reservation(new java.text.SimpleDateFormat("HH:mm:ss").format(new java.util.Date()));
        t.setMontant(total);
        t.setRemarque(CinUtils.estVide(remarque) ? null : remarque.trim());
        t.setEtat(RESERVE);
        t.setFille(lignes.toArray(new ClassFille[0]));
        t.createObject(refUser, c);
        return t;
    }

    /**
     * Vrai si la seance est programmee et qu'on est avant sa date limite (debut - DELAI_EXPIRATION_MIN) :
     * apres, une reservation expirerait aussitot.
     */
    public static boolean reservationOuverte(String idDiffusion, Connection c) throws Exception {
        int delai = cinema.utils.CinParametre.getDelaiExpirationMinutes(c);
        return CinUtils.entier(c, "select count(*) from CIN_DIFFUSION_LIB where id = ? and etat = 1 and sysdate <= date_debut - "
                + delai + " / 1440", idDiffusion) > 0;
    }

    /**
     * Le paiement (etat 11) se fait par la page Paiement (etape 7), pas par un visa direct.
     */
    @Override
    public Object validerObject(String refUser, Connection c) throws Exception {
        throw new Exception("Un ticket se valide par son paiement (page Paiement)");
    }

    /**
     * Annulation (etat 0) : seulement un ticket reserve ; un ticket paye ne s'annule pas ici.
     */
    @Override
    public void controleAnnule(Connection c) throws Exception {
        int etatBase = CinUtils.entier(c, "select nvl(max(etat), -1) from CIN_TICKET where id = ?", id);
        if (etatBase == PAYE) throw new Exception("Un ticket pay&eacute; ne peut pas &ecirc;tre annul&eacute;");
        if (etatBase == ANNULE) throw new Exception("Ce ticket est d&eacute;j&agrave; annul&eacute;");
        super.controleAnnule(c);
    }

    @Override
    public void controlerDelete(Connection c) throws Exception {
        throw new Exception("Un ticket ne se supprime pas : annulez-le");
    }

    /**
     * Places de la salle pour une seance, avec leur statut (plan de reservation), triees par rangee puis colonne.
     */
    public static CinPlaceDiffusion[] getPlacesDiffusion(String idDiffusion, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                canClose = true;
            }
            List<CinPlaceDiffusion> places = new ArrayList<CinPlaceDiffusion>();
            String sql = "select idplace, numero, rangee, colonne, idclasse, idclasselib, couleur, prix, idticket, statut"
                    + " from CIN_PLACE_DIFFUSION where iddiffusion = ? order by rangee, colonne";
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, idDiffusion);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        CinPlaceDiffusion p = new CinPlaceDiffusion();
                        p.setIddiffusion(idDiffusion);
                        p.setId(rs.getString("idplace"));
                        p.setNumero(rs.getString("numero"));
                        p.setRangee(rs.getInt("rangee"));
                        p.setColonne(rs.getInt("colonne"));
                        p.setIdclasse(rs.getString("idclasse"));
                        p.setIdclasselib(rs.getString("idclasselib"));
                        p.setCouleur(rs.getString("couleur"));
                        p.setPrix(rs.getDouble("prix"));
                        p.setIdticket(rs.getString("idticket"));
                        p.setStatut(rs.getString("statut"));
                        p.setEtat(CinPlaceDiffusion.HS.equals(p.getStatut()) ? 0 : 1);
                        places.add(p);
                    }
                }
            }
            return places.toArray(new CinPlaceDiffusion[0]);
        } finally {
            if (canClose) c.close();
        }
    }

    /**
     * Places d'un ticket (numero, classe, prix fige), dans l'ordre du plan.
     */
    public static CinTicketDetailLib[] getDetails(String idTicket, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                canClose = true;
            }
            List<CinTicketDetailLib> details = new ArrayList<CinTicketDetailLib>();
            String sql = "select id, iddiffusion, idplace, numero, idclasse, idclasselib, couleur, prix from CIN_TICKET_DETAIL_LIB"
                    + " where idticket = ? order by rangee, colonne";
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, idTicket);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        CinTicketDetailLib d = new CinTicketDetailLib();
                        d.setId(rs.getString("id"));
                        d.setIdticket(idTicket);
                        d.setIddiffusion(rs.getString("iddiffusion"));
                        d.setIdplace(rs.getString("idplace"));
                        d.setNumero(rs.getString("numero"));
                        d.setIdclasse(rs.getString("idclasse"));
                        d.setIdclasselib(rs.getString("idclasselib"));
                        d.setCouleur(rs.getString("couleur"));
                        d.setPrix(rs.getDouble("prix"));
                        details.add(d);
                    }
                }
            }
            return details.toArray(new CinTicketDetailLib[0]);
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

    public String getIdclient() {
        return idclient;
    }

    public void setIdclient(String idclient) {
        this.idclient = idclient;
    }

    public String getIddiffusion() {
        return iddiffusion;
    }

    public void setIddiffusion(String iddiffusion) {
        this.iddiffusion = iddiffusion;
    }

    public Date getDaty_reservation() {
        return daty_reservation;
    }

    public void setDaty_reservation(Date daty_reservation) {
        this.daty_reservation = daty_reservation;
    }

    public String getHeure_reservation() {
        return heure_reservation;
    }

    public void setHeure_reservation(String heure_reservation) {
        this.heure_reservation = heure_reservation;
    }

    public double getMontant() {
        return montant;
    }

    public void setMontant(double montant) {
        this.montant = montant;
    }

    public String getRemarque() {
        return remarque;
    }

    public void setRemarque(String remarque) {
        this.remarque = remarque;
    }
}
