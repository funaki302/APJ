package cinema.diffusion;

import bean.ClassMAPTable;
import cinema.utils.CinUtils;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;
import utilitaire.UtilDB;

/**
 * Diffusion (seance) : un film dans une salle, a une date et une heure (table CIN_DIFFUSION).
 * Fin de la seance = debut + duree du film. Deux seances actives d'une meme salle ne se chevauchent pas
 * (sans marge de nettoyage en v1). etat : 1 = programmee, 0 = annulee.
 */
public class CinDiffusion extends ClassMAPTable {

    public static final int PROGRAMMEE = 1;
    public static final int ANNULEE = 0;

    private String id;
    private String idfilm;
    private String idsalle;
    private Date daty;
    private String heure;
    private Date date_creation;
    private int etat = PROGRAMMEE;

    public CinDiffusion() {
        this.setNomTable("CIN_DIFFUSION");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINDIF", "GETSEQCINDIFFUSION");
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
    public void controler(Connection c) throws Exception {
        // APJ insere toutes les colonnes : sans valeur, DATE_CREATION serait NULL (le DEFAULT SYSDATE ne joue pas)
        if (date_creation == null) date_creation = new Date(System.currentTimeMillis());
        etat = PROGRAMMEE;
        verifier(c);
        super.controler(c);
    }

    /**
     * La modification standard (apresTarif.jsp -> UserEJB.updateObject) n'appelle pas controlerUpdate :
     * les controles sont donc faits ici. Une seance deja commencee ne se modifie plus.
     */
    @Override
    public int updateToTableWithHisto(String refUser, Connection c) throws Exception {
        if (dejaCommencee(id, c)) throw new Exception("Une s&eacute;ance commenc&eacute;e ou termin&eacute;e ne peut plus &ecirc;tre modifi&eacute;e");
        if (etat != ANNULEE) verifier(c);
        return super.updateToTableWithHisto(refUser, c);
    }

    @Override
    public void controlerDelete(Connection c) throws Exception {
        if (dejaCommencee(id, c)) throw new Exception("Une s&eacute;ance commenc&eacute;e ou termin&eacute;e ne peut pas &ecirc;tre supprim&eacute;e");
        super.controlerDelete(c);
    }

    private void verifier(Connection c) throws Exception {
        if (CinUtils.estVide(idfilm)) throw new Exception("Le film est obligatoire");
        if (CinUtils.estVide(idsalle)) throw new Exception("La salle est obligatoire");
        if (daty == null) throw new Exception("La date de la s&eacute;ance est obligatoire");
        heure = normaliserHeure(heure);
        if (etat != PROGRAMMEE && etat != ANNULEE) throw new Exception("&Eacute;tat inconnu");

        String duree = CinUtils.valeur(c, "select duree from CIN_FILM where id = ? and etat = 1", idfilm);
        if (duree == null) throw new Exception("Le film choisi n'existe pas ou est inactif");
        if (CinUtils.entier(c, "select count(*) from CIN_SALLE where id = ? and etat = 1", idsalle) == 0) {
            throw new Exception("La salle choisie n'existe pas ou est inactive");
        }
        if (CinUtils.entier(c, "select count(*) from CIN_PLACE where idsalle = ? and etat = 1", idsalle) == 0) {
            throw new Exception("La salle n'a aucune place en service");
        }

        Timestamp debut = getDebut();
        Timestamp fin = new Timestamp(debut.getTime() + Integer.parseInt(duree) * 60000L);
        if (!debut.after(new Timestamp(System.currentTimeMillis()))) {
            throw new Exception("La s&eacute;ance doit &ecirc;tre dans le futur");
        }
        verifierChevauchement(debut, fin, c);
    }

    /**
     * Refuse une seance qui chevauche une autre seance programmee de la meme salle :
     * debut < fin de l'autre ET fin > debut de l'autre.
     */
    private void verifierChevauchement(Timestamp debut, Timestamp fin, Connection c) throws Exception {
        String sql = "select idfilmlib, to_char(date_debut, 'DD/MM/YYYY'), heure, heure_fin, idsallelib from CIN_DIFFUSION_LIB"
                + " where idsalle = ? and etat = 1 and (? is null or id <> ?) and date_debut < ? and date_fin > ? order by date_debut";
        String idExclu = CinUtils.estVide(id) ? null : id;
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, idsalle);
            ps.setString(2, idExclu);
            ps.setString(3, idExclu);
            ps.setTimestamp(4, fin);
            ps.setTimestamp(5, debut);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    throw new Exception("La salle " + rs.getString(5) + " est d&eacute;j&agrave; occup&eacute;e le " + rs.getString(2)
                            + " de " + rs.getString(3) + " &agrave; " + rs.getString(4) + " par &laquo; " + rs.getString(1) + " &raquo;");
                }
            }
        }
    }

    /**
     * Heure au format HH:MM (accepte H:MM et HH:MM:SS venant d'un champ "time").
     */
    public static String normaliserHeure(String h) throws Exception {
        if (CinUtils.estVide(h) || !h.trim().matches("\\d{1,2}:\\d{2}(:\\d{2})?")) {
            throw new Exception("L'heure de la s&eacute;ance doit &ecirc;tre au format HH:MM (ex. 18:30)");
        }
        String[] p = h.trim().split(":");
        int hh = Integer.parseInt(p[0]), mm = Integer.parseInt(p[1]);
        if (hh > 23 || mm > 59) throw new Exception("Heure invalide : " + h);
        return String.format("%02d:%02d", hh, mm);
    }

    public Timestamp getDebut() throws Exception {
        String[] p = normaliserHeure(heure).split(":");
        java.util.Calendar cal = java.util.Calendar.getInstance();
        cal.setTime(daty);
        cal.set(java.util.Calendar.HOUR_OF_DAY, Integer.parseInt(p[0]));
        cal.set(java.util.Calendar.MINUTE, Integer.parseInt(p[1]));
        cal.set(java.util.Calendar.SECOND, 0);
        cal.set(java.util.Calendar.MILLISECOND, 0);
        return new Timestamp(cal.getTimeInMillis());
    }

    /**
     * Vrai si la seance (telle qu'elle est en base) a deja commence.
     */
    public static boolean dejaCommencee(String idDiffusion, Connection c) throws Exception {
        if (CinUtils.estVide(idDiffusion)) return false;
        return CinUtils.entier(c, "select count(*) from CIN_DIFFUSION_LIB where id = ? and date_debut <= sysdate", idDiffusion) > 0;
    }

    /**
     * Seances (annulees comprises) dont le debut est entre debut (inclus) et fin (exclu), triees par debut puis salle.
     * Sert au calendrier.
     */
    public static CinDiffusionLib[] getDiffusionsEntre(Date debut, Date fin, String idCinema, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                canClose = true;
            }
            List<CinDiffusionLib> liste = new ArrayList<CinDiffusionLib>();
            String sql = "select id, idfilm, idfilmlib, duree, dureelib, idsalle, idsallelib, idcinema, idcinemalib, daty, heure, heure_fin,"
                    + " nb_places, etat, etatlib from CIN_DIFFUSION_LIB where date_debut >= ? and date_debut < ?"
                    + " and (? is null or idcinema = ?) order by date_debut, idsallelib";
            String cinema = CinUtils.estVide(idCinema) ? null : idCinema;
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setDate(1, debut);
                ps.setDate(2, fin);
                ps.setString(3, cinema);
                ps.setString(4, cinema);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        CinDiffusionLib d = new CinDiffusionLib();
                        d.setId(rs.getString("id"));
                        d.setIdfilm(rs.getString("idfilm"));
                        d.setIdfilmlib(rs.getString("idfilmlib"));
                        d.setDuree(rs.getInt("duree"));
                        d.setDureelib(rs.getString("dureelib"));
                        d.setIdsalle(rs.getString("idsalle"));
                        d.setIdsallelib(rs.getString("idsallelib"));
                        d.setIdcinema(rs.getString("idcinema"));
                        d.setIdcinemalib(rs.getString("idcinemalib"));
                        d.setDaty(rs.getDate("daty"));
                        d.setHeure(rs.getString("heure"));
                        d.setHeure_fin(rs.getString("heure_fin"));
                        d.setNb_places(rs.getInt("nb_places"));
                        d.setEtat(rs.getInt("etat"));
                        d.setEtatlib(rs.getString("etatlib"));
                        liste.add(d);
                    }
                }
            }
            return liste.toArray(new CinDiffusionLib[0]);
        } finally {
            if (canClose) c.close();
        }
    }

    public static String formatDate(Date d) {
        return d == null ? "" : new SimpleDateFormat("dd/MM/yyyy").format(d);
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdfilm() {
        return idfilm;
    }

    public void setIdfilm(String idfilm) {
        this.idfilm = idfilm;
    }

    public String getIdsalle() {
        return idsalle;
    }

    public void setIdsalle(String idsalle) {
        this.idsalle = idsalle;
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

    public Date getDate_creation() {
        return date_creation;
    }

    public void setDate_creation(Date date_creation) {
        this.date_creation = date_creation;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }
}
