package cinema.paiement;

import cinema.reservation.CinTicket;
import cinema.salle.CinClassePlace;
import cinema.utils.CinParametre;
import cinema.utils.CinUtils;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import utilitaire.UtilDB;
import vente.VenteArbiochem;
import vente.VenteDetailsArbiochem;

/**
 * Facturation d'un ticket par la facturation existante de l'application (VENTE / vente.VenteArbiochem).
 *
 * facturer(...) fait tout dans la meme transaction :
 *  - controles du ticket (verrou, reserve et non expire) ;
 *  - creation d'une vente : une ligne par classe de place (produit "Place classe" lie a CIN_CLASSE_PLACE.IDPRODUIT),
 *    quantite = nombre de chaises, prix = prix de la chaise a la reservation, TVA 0, designation = seance + chaises ;
 *  - visa de la vente (VenteArbiochem.validerObject : ecritures, prevision, avoirs et avances du client) ;
 *  - ticket a l'etat 11 (acquis) avec CIN_TICKET.IDVENTE.
 * Le paiement se fait ensuite sur la fiche de la vente (vente/vente-arbiochem-fiche.jsp), sans code propre au cinema.
 * Aucune classe de la facturation existante n'est modifiee.
 */
public class CinFacturation {

    public static final String PARAM_MAGASIN = "MAGASIN_VENTE";
    public static final String MAGASIN_DEFAUT = "MAGA0008";
    public static final String DEVISE = "AR";
    /** VENTE.MODELIVRAISON : 2 = recuperation (pas de livraison pour un ticket) */
    public static final int MODE_RECUPERATION = 2;

    private CinFacturation() {
    }

    /**
     * Facture un ticket (sa propre connexion et sa propre transaction). Renvoie l'id de la vente creee et visee.
     */
    public static String facturer(String idTicket, String refUser) throws Exception {
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            String idVente = facturer(idTicket, refUser, c);
            c.commit();
            return idVente;
        } catch (Exception e) {
            if (c != null) c.rollback();
            throw e;
        } finally {
            if (c != null) c.close();
        }
    }

    /**
     * Facture un ticket dans la transaction de l'appelant (pas de commit).
     */
    public static String facturer(String idTicket, String refUser, Connection c) throws Exception {
        if (CinUtils.estVide(idTicket)) throw new Exception("Ticket non pr&eacute;cis&eacute;");
        // verrou : deux clics simultanes sur Payer ne creent pas deux factures
        String idClient;
        int etat;
        String idVenteExistante;
        try (PreparedStatement ps = c.prepareStatement("select idclient, etat, idvente from CIN_TICKET where id = ? for update")) {
            ps.setString(1, idTicket);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new Exception("Ticket introuvable");
                idClient = rs.getString(1);
                etat = rs.getInt(2);
                idVenteExistante = rs.getString(3);
            }
        }
        if (etat == CinTicket.PAYE) {
            throw new Exception(idVenteExistante == null ? "Ce ticket est d&eacute;j&agrave; pay&eacute;" : "Ce ticket est d&eacute;j&agrave; factur&eacute; (" + idVenteExistante + ")");
        }
        if (etat == CinTicket.ANNULE) throw new Exception("Ce ticket est annul&eacute;");
        if (CinUtils.entier(c, "select actif from CIN_TICKET_LIB where id = ?", idTicket) != 1) {
            throw new Exception("La r&eacute;servation a expir&eacute; : elle ne peut plus &ecirc;tre factur&eacute;e (refaire une r&eacute;servation)");
        }

        // la facture passe en comptabilite sur le compte du client (411...) : un client cree hors de la fiche client n'en a pas
        if (CinUtils.estVide(CinUtils.valeur(c, "select compte from CLIENT where id = ?", idClient))) {
            throw new Exception("Le client " + idClient + " n'a pas de compte comptable : la facture ne peut pas &ecirc;tre cr&eacute;&eacute;e"
                    + " (cr&eacute;er le client depuis la fiche client, qui lui attribue un compte 411...)");
        }
        String magasin = getMagasin(c);
        String seance = descriptionSeance(idTicket, c);
        VenteDetailsArbiochem[] lignes = construireLignes(idTicket, seance, c);

        VenteArbiochem vente = new VenteArbiochem();
        vente.setNomTable("VENTE");
        Date aujourdhui = new Date(System.currentTimeMillis());
        vente.setDaty(aujourdhui);
        vente.setDatyPrevu(aujourdhui);
        vente.setEstPrevu(0);
        vente.setDesignation("Cinema - " + seance);
        vente.setRemarque("Ticket cinema " + idTicket);
        vente.setIdMagasin(magasin);
        vente.setIdClient(idClient);
        vente.setModelivraison(MODE_RECUPERATION);
        vente.setTauxdechange(1);
        vente.setFille(lignes);
        vente.createObject(refUser, c);
        // visa : ecritures comptables, prevision, imputation des avoirs et avances du client (code existant)
        vente.validerObject(refUser, c);

        try (PreparedStatement ps = c.prepareStatement("update CIN_TICKET set etat = ?, idvente = ? where id = ?")) {
            ps.setInt(1, CinTicket.PAYE);
            ps.setString(2, vente.getId());
            ps.setString(3, idTicket);
            ps.executeUpdate();
        }
        return vente.getId();
    }

    /**
     * Une ligne par classe de place du ticket, dans l'ordre des chaises.
     */
    static VenteDetailsArbiochem[] construireLignes(String idTicket, String seance, Connection c) throws Exception {
        Map<String, Object[]> parClasse = new LinkedHashMap<String, Object[]>();   // idclasse -> {libelle, chaises, qte, montant}
        try (PreparedStatement ps = c.prepareStatement("select td.idclasse, cl.val, p.numero, td.prix from CIN_TICKET_DETAIL td"
                + " join CIN_PLACE p on p.id = td.idplace join CIN_CLASSE_PLACE cl on cl.id = td.idclasse"
                + " where td.idticket = ? order by p.rangee, p.colonne")) {
            ps.setString(1, idTicket);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Object[] l = parClasse.get(rs.getString(1));
                    if (l == null) {
                        l = new Object[]{rs.getString(2), new StringBuilder(), 0, 0.0};
                        parClasse.put(rs.getString(1), l);
                    }
                    StringBuilder chaises = (StringBuilder) l[1];
                    if (chaises.length() > 0) chaises.append(", ");
                    chaises.append(rs.getString(3));
                    l[2] = (Integer) l[2] + 1;
                    l[3] = (Double) l[3] + rs.getDouble(4);
                }
            }
        }
        if (parClasse.isEmpty()) throw new Exception("Ce ticket n'a aucune place");

        List<VenteDetailsArbiochem> lignes = new ArrayList<VenteDetailsArbiochem>();
        for (Map.Entry<String, Object[]> e : parClasse.entrySet()) {
            String idProduit = CinClassePlace.synchroniserProduit(e.getKey(), c);
            String[] produit = produit(idProduit, c);
            int qte = (Integer) e.getValue()[2];
            double montant = (Double) e.getValue()[3];
            VenteDetailsArbiochem d = new VenteDetailsArbiochem();
            d.setIdProduit(idProduit);
            d.setDesignation(couper("Place " + e.getValue()[0] + " - " + seance + " - " + e.getValue()[1], 250));
            d.setQte(qte);
            d.setPu(montant / qte);
            d.setTva(0);
            d.setIdDevise(DEVISE);
            d.setTauxDeChange(1);
            d.setCompte(produit[0]);
            d.setUnite(produit[1]);
            lignes.add(d);
        }
        return lignes.toArray(new VenteDetailsArbiochem[0]);
    }

    /**
     * "Film jj/mm/aaaa hh:mm - Salle"
     */
    static String descriptionSeance(String idTicket, Connection c) throws Exception {
        try (PreparedStatement ps = c.prepareStatement("select f.titre, d.daty, d.heure, s.nom from CIN_TICKET t"
                + " join CIN_DIFFUSION d on d.id = t.iddiffusion join CIN_FILM f on f.id = d.idfilm join CIN_SALLE s on s.id = d.idsalle"
                + " where t.id = ?")) {
            ps.setString(1, idTicket);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new Exception("S&eacute;ance du ticket introuvable");
                return rs.getString(1) + " " + new SimpleDateFormat("dd/MM/yyyy").format(rs.getDate(2)) + " " + rs.getString(3) + " - " + rs.getString(4);
            }
        }
    }

    /**
     * {compte de vente, unite} du produit.
     */
    static String[] produit(String idProduit, Connection c) throws Exception {
        try (PreparedStatement ps = c.prepareStatement("select compte_vente, unite from AS_INGREDIENTS where id = ?")) {
            ps.setString(1, idProduit);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new Exception("Produit " + idProduit + " introuvable");
                return new String[]{rs.getString(1), rs.getString(2)};
            }
        }
    }

    /**
     * Magasin des ventes du cinema (parametre MAGASIN_VENTE), qui doit exister dans MAGASINVENTE.
     */
    public static String getMagasin(Connection c) throws Exception {
        String magasin = CinParametre.getValeur(PARAM_MAGASIN, c);
        if (CinUtils.estVide(magasin)) magasin = MAGASIN_DEFAUT;
        magasin = magasin.trim();
        if (CinUtils.entier(c, "select count(*) from MAGASINVENTE where id = ?", magasin) == 0) {
            throw new Exception("Le magasin des ventes du cin&eacute;ma (" + magasin + ") n'existe pas : corriger le param&egrave;tre "
                    + PARAM_MAGASIN + " (Cin&eacute;ma &gt; Configurations &gt; Param&egrave;tres)");
        }
        return magasin;
    }

    private static String couper(String s, int max) {
        return s.length() <= max ? s : s.substring(0, max);
    }
}
