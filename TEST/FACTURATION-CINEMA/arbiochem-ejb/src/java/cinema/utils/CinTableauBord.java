package cinema.utils;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

/**
 * Chiffres du tableau de bord du cinema, calcules directement sur les tables du cinema et MOUVEMENTCAISSE.
 * Periode = du "debut" au "fin" inclus (dates de paiement, d'achat et de seance).
 * Le solde de la Caisse Cinema est calcule ici (credit - debit des mouvements vises) car la vue V_ETATCAISSE
 * de la base locale ne compte que les mouvements rattaches a un report.
 */
public class CinTableauBord {

    /** Une ligne de graphique / tableau : libelle, une ou deux valeurs, deux details et l'id de l'objet lie. */
    public static class Ligne {
        public String id;
        public String libelle;
        public String detail;
        public String detail2;
        public double valeur1;
        public double valeur2;
        public double total;
    }

    public double recettes;
    public int nbPaiements;
    public int placesVendues;
    public double achats;
    public int nbAchats;
    public int reservationsEnAttente;
    public double montantEnAttente;
    public double soldeCaisseCinema;
    public List<Ligne> recettesParFilm = new ArrayList<Ligne>();
    public List<Ligne> remplissage = new ArrayList<Ligne>();
    public List<Ligne> mouvements = new ArrayList<Ligne>();

    public double getResultat() {
        return recettes - achats;
    }

    /**
     * Calcule tout le tableau de bord pour la periode.
     */
    public static CinTableauBord calculer(Date debut, Date fin, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new utilitaire.UtilDB().GetConn();
                canClose = true;
            }
            CinTableauBord tb = new CinTableauBord();
            String periode = " between ? and ?";

            // recettes = tickets factures (ventes visees) + anciens paiements du cinema (vue CIN_RECETTE)
            try (PreparedStatement ps = c.prepareStatement("select nvl(sum(montant), 0), count(*) from CIN_RECETTE where trunc(daty)" + periode)) {
                periodeParam(ps, debut, fin, 1);
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    tb.recettes = rs.getDouble(1);
                    tb.nbPaiements = rs.getInt(2);
                }
            }
            try (PreparedStatement ps = c.prepareStatement("select count(*) from CIN_TICKET_DETAIL td join CIN_RECETTE p on p.idticket = td.idticket"
                    + " where trunc(p.daty)" + periode)) {
                periodeParam(ps, debut, fin, 1);
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    tb.placesVendues = rs.getInt(1);
                }
            }
            try (PreparedStatement ps = c.prepareStatement("select nvl(sum(montant), 0), count(*) from CIN_ACHAT where etat = 11 and trunc(daty)" + periode)) {
                periodeParam(ps, debut, fin, 1);
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    tb.achats = rs.getDouble(1);
                    tb.nbAchats = rs.getInt(2);
                }
            }
            try (PreparedStatement ps = c.prepareStatement("select count(*), nvl(sum(montant), 0) from CIN_TICKET_LIB where etat = 1 and actif = 1");
                 ResultSet rs = ps.executeQuery()) {
                rs.next();
                tb.reservationsEnAttente = rs.getInt(1);
                tb.montantEnAttente = rs.getDouble(2);
            }
            try (PreparedStatement ps = c.prepareStatement("select nvl(sum(nvl(credit, 0) - nvl(debit, 0)), 0) from MOUVEMENTCAISSE where idcaisse = 'CAICINEMA' and etat >= 11");
                 ResultSet rs = ps.executeQuery()) {
                rs.next();
                tb.soldeCaisseCinema = rs.getDouble(1);
            }

            // recettes par film (paiements de la periode)
            try (PreparedStatement ps = c.prepareStatement("select t.idfilm, t.idfilmlib, sum(p.montant), sum(t.nb_places) from CIN_RECETTE p"
                    + " join CIN_TICKET_LIB t on t.id = p.idticket where trunc(p.daty)" + periode
                    + " group by t.idfilm, t.idfilmlib order by 3 desc, 2")) {
                periodeParam(ps, debut, fin, 1);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Ligne l = new Ligne();
                        l.id = rs.getString(1);
                        l.libelle = rs.getString(2);
                        l.valeur1 = rs.getDouble(3);
                        l.valeur2 = rs.getDouble(4);
                        tb.recettesParFilm.add(l);
                    }
                }
            }

            // remplissage des seances programmees de la periode : places payees / reservees sur les places en service
            String sqlRemplissage = "select d.id, d.idfilmlib, d.idsallelib || ' - ' || to_char(d.daty, 'DD/MM') || ' ' || d.heure, d.nb_places,"
                    + " (select count(*) from CIN_PLACE_DIFFUSION pd where pd.iddiffusion = d.id and pd.statut = 'PAYEE'),"
                    + " (select count(*) from CIN_PLACE_DIFFUSION pd where pd.iddiffusion = d.id and pd.statut = 'RESERVEE')"
                    + " from CIN_DIFFUSION_LIB d where d.etat = 1 and d.daty" + periode + " order by d.date_debut";
            try (PreparedStatement ps = c.prepareStatement(sqlRemplissage)) {
                periodeParam(ps, debut, fin, 1);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Ligne l = new Ligne();
                        l.id = rs.getString(1);
                        l.libelle = rs.getString(2);
                        l.detail = rs.getString(3);
                        l.total = rs.getInt(4);
                        l.valeur1 = rs.getInt(5);
                        l.valeur2 = rs.getInt(6);
                        tb.remplissage.add(l);
                    }
                }
            }

            // derniers mouvements de caisse du cinema (entrees des tickets, sorties des achats, Caisse Cinema)
            String sqlMvt = "select * from (select m.id, to_char(m.daty, 'DD/MM/YYYY'), m.designation, c.val, nvl(m.credit, 0), nvl(m.debit, 0)"
                    + " from MOUVEMENTCAISSE m join CAISSE c on c.id = m.idcaisse"
                    + " where m.etat >= 11 and (m.idorigine like 'CIN%' or m.idcaisse = 'CAICINEMA'"
                    + " or m.idorigine in (select idvente from CIN_TICKET where idvente is not null)) order by m.daty desc, m.id desc) where rownum <= 10";
            try (PreparedStatement ps = c.prepareStatement(sqlMvt); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Ligne l = new Ligne();
                    l.id = rs.getString(1);
                    l.detail = rs.getString(2);
                    l.libelle = rs.getString(3);
                    l.detail2 = rs.getString(4);
                    l.valeur1 = rs.getDouble(5);
                    l.valeur2 = rs.getDouble(6);
                    tb.mouvements.add(l);
                }
            }
            return tb;
        } finally {
            if (canClose) c.close();
        }
    }

    private static void periodeParam(PreparedStatement ps, Date debut, Date fin, int premier) throws Exception {
        ps.setDate(premier, debut);
        ps.setDate(premier + 1, fin);
    }
}
