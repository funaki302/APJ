package cinema.paiement;

import bean.ClassFille;
import bean.ClassMere;
import caisse.MvtCaisse;
import cinema.reservation.CinTicket;
import cinema.utils.CinCaisse;
import cinema.utils.CinUtils;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import utilitaire.UtilDB;

/**
 * Paiement d'un ticket (table CIN_PAIEMENT, lignes CIN_PAIEMENT_DETAIL) : en UNE seule fois, avec un ou plusieurs modes.
 * payer(...) fait tout dans la meme transaction : controles, paiement + lignes, un mouvement de caisse vise (CREDIT)
 * par ligne, facture (CIN_FACTURE + une ligne par place), ticket passe a l'etat 11 (paye).
 * Un paiement ne se modifie pas, ne s'annule pas et ne se supprime pas (v1).
 */
public class CinPaiement extends ClassMere {

    public static final int VALIDE = 11;
    private static final double TOLERANCE = 0.005;

    private String id;
    private String idticket;
    private String idclient;
    private Date daty;
    private String heure;
    private double montant;
    private String idfacture;

    public CinPaiement() throws Exception {
        this.setNomTable("CIN_PAIEMENT");
        this.setNomClasseFille("cinema.paiement.CinPaiementDetail");
        this.setLiaisonFille("idpaiement");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINPAI", "GETSEQCINPAIEMENT");
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
        return "cinema.paiement.CinPaiementDetail";
    }

    @Override
    public String getLiaisonFille() {
        return "idpaiement";
    }

    /**
     * Paie un ticket (sa propre connexion et sa propre transaction). montants : texte saisi (espaces acceptes).
     */
    public static CinPaiement payer(String idTicket, String[] modes, String[] caisses, String[] montants, String refUser) throws Exception {
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            CinPaiement p = payer(idTicket, modes, caisses, montants, refUser, c);
            c.commit();
            return p;
        } catch (Exception e) {
            if (c != null) c.rollback();
            throw e;
        } finally {
            if (c != null) c.close();
        }
    }

    /**
     * Paie un ticket dans la transaction de l'appelant (pas de commit). Les lignes sans montant sont ignorees.
     */
    public static CinPaiement payer(String idTicket, String[] modes, String[] caisses, String[] montants, String refUser, Connection c) throws Exception {
        if (CinUtils.estVide(idTicket)) throw new Exception("Ticket non pr&eacute;cis&eacute;");
        // verrou sur le ticket : deux paiements simultanes du meme ticket passent l'un apres l'autre
        String idClient;
        int etat;
        double montantTicket;
        try (PreparedStatement ps = c.prepareStatement("select idclient, etat, montant from CIN_TICKET where id = ? for update")) {
            ps.setString(1, idTicket);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new Exception("Ticket introuvable");
                idClient = rs.getString(1);
                etat = rs.getInt(2);
                montantTicket = rs.getDouble(3);
            }
        }
        if (etat == CinTicket.PAYE) throw new Exception("Ce ticket est d&eacute;j&agrave; pay&eacute;");
        if (etat == CinTicket.ANNULE) throw new Exception("Ce ticket est annul&eacute;");
        if (CinUtils.entier(c, "select actif from CIN_TICKET_LIB where id = ?", idTicket) != 1) {
            throw new Exception("La r&eacute;servation a expir&eacute; : elle n'est plus payable (refaire une r&eacute;servation)");
        }

        // lignes de paiement
        Set<String> modesActifs = new HashSet<String>();
        try (PreparedStatement ps = c.prepareStatement("select idmodepaiement from CIN_MODE_CAISSE where actif = 1"); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) modesActifs.add(rs.getString(1));
        }
        List<ClassFille> lignes = new ArrayList<ClassFille>();
        double total = 0;
        int n = montants == null ? 0 : montants.length;
        for (int i = 0; i < n; i++) {
            double m = lireMontant(montants[i], i + 1);
            if (m == 0) continue;
            String ligne = "Ligne " + (i + 1) + " : ";
            if (m < 0) throw new Exception(ligne + "le montant doit &ecirc;tre positif");
            String mode = modes != null && i < modes.length ? modes[i] : null;
            String caisse = caisses != null && i < caisses.length ? caisses[i] : null;
            if (CinUtils.estVide(mode) || !modesActifs.contains(mode)) throw new Exception(ligne + "mode de paiement non propos&eacute;");
            if (CinUtils.estVide(caisse) || CinUtils.entier(c, "select count(*) from CAISSE where id = ? and actif = 1", caisse) == 0) {
                throw new Exception(ligne + "caisse inconnue ou inactive");
            }
            CinPaiementDetail d = new CinPaiementDetail();
            d.setIdmodepaiement(mode);
            d.setIdcaisse(caisse);
            d.setMontant(m);
            d.setEtat(VALIDE);
            lignes.add(d);
            total += m;
        }
        if (lignes.isEmpty()) throw new Exception("Saisissez au moins une ligne de paiement");
        if (Math.abs(total - montantTicket) > TOLERANCE) {
            throw new Exception("Le ticket se paie en une seule fois : " + format(total) + " Ar saisis pour un ticket de "
                    + format(montantTicket) + " Ar");
        }

        // paiement + lignes
        Date aujourdhui = new Date(System.currentTimeMillis());
        CinPaiement p = new CinPaiement();
        p.setIdticket(idTicket);
        p.setIdclient(idClient);
        p.setDaty(aujourdhui);
        p.setHeure(utilitaire.Utilitaire.heureCouranteHMS());
        p.setMontant(montantTicket);
        p.setEtat(VALIDE);
        p.setFille(lignes.toArray(new ClassFille[0]));
        p.createObject(refUser, c);

        // une entree de caisse (credit) par ligne
        String nomClient = CinUtils.valeur(c, "select nom from CLIENT where id = ?", idClient);
        for (ClassFille f : lignes) {
            CinPaiementDetail d = (CinPaiementDetail) f;
            MvtCaisse mvt = CinCaisse.creerMouvementVise("Ticket cin&eacute;ma " + idTicket + " - " + nomClient, d.getIdcaisse(), aujourdhui,
                    0, d.getMontant(), d.getIdmodepaiement(), p.getId(), idClient, refUser, c);
            d.setIdmvtcaisse(mvt.getId());
            try (PreparedStatement ps = c.prepareStatement("update CIN_PAIEMENT_DETAIL set idmvtcaisse = ? where id = ?")) {
                ps.setString(1, mvt.getId());
                ps.setString(2, d.getId());
                ps.executeUpdate();
            }
        }

        // facture
        CinFacture facture = genererFacture(p, refUser, c);
        p.setIdfacture(facture.getId());
        try (PreparedStatement ps = c.prepareStatement("update CIN_PAIEMENT set idfacture = ? where id = ?")) {
            ps.setString(1, facture.getId());
            ps.setString(2, p.getId());
            ps.executeUpdate();
        }

        // ticket paye
        try (PreparedStatement ps = c.prepareStatement("update CIN_TICKET set etat = ? where id = ?")) {
            ps.setInt(1, CinTicket.PAYE);
            ps.setString(2, idTicket);
            ps.executeUpdate();
        }
        try (PreparedStatement ps = c.prepareStatement("update CIN_TICKET_DETAIL set etat = ? where idticket = ?")) {
            ps.setInt(1, CinTicket.PAYE);
            ps.setString(2, idTicket);
            ps.executeUpdate();
        }
        return p;
    }

    /**
     * Facture du paiement : une ligne par place (film, salle, date et heure, place, classe), montant = paiement.
     */
    private static CinFacture genererFacture(CinPaiement p, String refUser, Connection c) throws Exception {
        CinFacture f = new CinFacture();
        f.setNumero(CinFacture.prochainNumero(c));
        f.setIdclient(p.getIdclient());
        f.setIdticket(p.getIdticket());
        f.setIdpaiement(p.getId());
        f.setDaty(p.getDaty());
        f.setMontant(p.getMontant());
        f.createObject(refUser, c);
        String sql = "select td.idplace, d.idfilmlib || ' - ' || d.idsallelib || ' - ' || to_char(d.daty, 'DD/MM/YYYY') || ' ' || d.heure"
                + " || ' - place ' || td.numero || ' (' || td.idclasselib || ')', td.prix"
                + " from CIN_TICKET_DETAIL_LIB td join CIN_TICKET t on t.id = td.idticket join CIN_DIFFUSION_LIB d on d.id = t.iddiffusion"
                + " where td.idticket = ? order by td.rangee, td.colonne";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, p.getIdticket());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    CinFactureDetail d = new CinFactureDetail();
                    d.setIdfacture(f.getId());
                    d.setIdplace(rs.getString(1));
                    d.setDesignation(rs.getString(2));
                    d.setPrix(rs.getDouble(3));
                    d.createObject(refUser, c);
                }
            }
        }
        return f;
    }

    private static double lireMontant(String texte, int numero) throws Exception {
        if (CinUtils.estVide(texte)) return 0;
        String t = texte.replace(" ", "").replace(String.valueOf((char) 0x00A0), "").replace(String.valueOf((char) 0x202F), "").replace(",", ".");
        try {
            return Double.parseDouble(t);
        } catch (NumberFormatException e) {
            throw new Exception("Ligne " + numero + " : montant invalide (" + texte + ")");
        }
    }

    private static String format(double montant) {
        return new java.text.DecimalFormat("#,##0").format(montant);
    }

    @Override
    public Object validerObject(String refUser, Connection c) throws Exception {
        throw new Exception("Un paiement est valid&eacute; d&egrave;s son enregistrement");
    }

    @Override
    public void controleAnnule(Connection c) throws Exception {
        throw new Exception("Un paiement ne peut pas &ecirc;tre annul&eacute;");
    }

    @Override
    public void controlerDelete(Connection c) throws Exception {
        throw new Exception("Un paiement ne se supprime pas");
    }

    /**
     * Lignes d'un paiement avec mode, caisse et mouvement de caisse.
     */
    public static CinPaiementDetailLib[] getDetails(String idPaiement, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                canClose = true;
            }
            List<CinPaiementDetailLib> lignes = new ArrayList<CinPaiementDetailLib>();
            try (PreparedStatement ps = c.prepareStatement(
                    "select id, idmodepaiement, idmodepaiementlib, idcaisse, idcaisselib, montant, idmvtcaisse from CIN_PAIEMENT_DETAIL_LIB where idpaiement = ? order by id")) {
                ps.setString(1, idPaiement);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        CinPaiementDetailLib d = new CinPaiementDetailLib();
                        d.setId(rs.getString(1));
                        d.setIdpaiement(idPaiement);
                        d.setIdmodepaiement(rs.getString(2));
                        d.setIdmodepaiementlib(rs.getString(3));
                        d.setIdcaisse(rs.getString(4));
                        d.setIdcaisselib(rs.getString(5));
                        d.setMontant(rs.getDouble(6));
                        d.setIdmvtcaisse(rs.getString(7));
                        lignes.add(d);
                    }
                }
            }
            return lignes.toArray(new CinPaiementDetailLib[0]);
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

    public Date getDaty() {
        return daty;
    }

    public void setDaty(Date daty) {
        this.daty = daty;
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

    public String getIdfacture() {
        return idfacture;
    }

    public void setIdfacture(String idfacture) {
        this.idfacture = idfacture;
    }
}
