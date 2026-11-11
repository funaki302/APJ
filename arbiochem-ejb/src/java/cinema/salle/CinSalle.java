package cinema.salle;

import bean.ClassMAPTable;
import cinema.utils.CinUtils;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import utilitaire.UtilDB;

/**
 * Salle d'un cinema (table CIN_SALLE).
 * A la creation, les places sont generees automatiquement : nb_rangees x nb_colonnes,
 * numerotees A1, A2... dans la classe active la moins chere (Standard).
 * La structure (rangees, colonnes) ne change plus ensuite ; seules la classe et l'etat des places se modifient.
 */
public class CinSalle extends ClassMAPTable {

    public static final int RANGEES_MAX = 26;
    public static final int COLONNES_MAX = 40;
    /** Valeur speciale dans modifierPlaces : mettre la place hors service */
    public static final String HORS_SERVICE = "HS";

    private String id;
    private String idcinema;
    private String nom;
    private int nb_rangees;
    private int nb_colonnes;
    private int capacite;
    private Date date_creation;
    private int etat = CinUtils.ETAT_ACTIF;

    public CinSalle() {
        this.setNomTable("CIN_SALLE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINSAL", "GETSEQCINSALLE");
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
        verifier(c);
        if (getIdClasseParDefaut(c) == null) {
            throw new Exception("Aucune classe de place active : cr&eacute;ez d'abord une classe (Cin&eacute;ma &gt; Configurations &gt; Classes de place)");
        }
        super.controler(c);
    }

    /**
     * Insertion de la salle puis generation de ses places, dans la meme transaction.
     */
    @Override
    public ClassMAPTable createObject(String refUser, Connection c) throws Exception {
        ClassMAPTable retour = super.createObject(refUser, c);
        genererPlaces(c);
        return retour;
    }

    /**
     * La modification standard (apresTarif.jsp -> UserEJB.updateObject) n'appelle pas controlerUpdate :
     * les controles sont donc faits ici.
     */
    @Override
    public int updateToTableWithHisto(String refUser, Connection c) throws Exception {
        verifier(c);
        String ancienne = CinUtils.valeur(c, "select nb_rangees || 'x' || nb_colonnes from CIN_SALLE where id = ?", id);
        if (ancienne != null && !ancienne.equals(nb_rangees + "x" + nb_colonnes)) {
            throw new Exception("Le nombre de rang&eacute;es et de colonnes ne peut pas changer apr&egrave;s la cr&eacute;ation de la salle"
                    + " (supprimer la salle et la recr&eacute;er)");
        }
        return super.updateToTableWithHisto(refUser, c);
    }

    private void verifier(Connection c) throws Exception {
        if (CinUtils.estVide(nom)) throw new Exception("Le nom de la salle est obligatoire");
        if (CinUtils.estVide(idcinema)) throw new Exception("Le cin&eacute;ma de la salle est obligatoire");
        if (CinUtils.entier(c, "select count(*) from CIN_CINEMA where id = ? and etat = 1", idcinema) == 0) {
            throw new Exception("Le cin&eacute;ma choisi n'existe pas ou est inactif");
        }
        if (nb_rangees < 1 || nb_rangees > RANGEES_MAX) {
            throw new Exception("Le nombre de rang&eacute;es doit &ecirc;tre entre 1 et " + RANGEES_MAX + " (rang&eacute;es A &agrave; Z)");
        }
        if (nb_colonnes < 1 || nb_colonnes > COLONNES_MAX) {
            throw new Exception("Le nombre de places par rang&eacute;e doit &ecirc;tre entre 1 et " + COLONNES_MAX);
        }
        CinUtils.verifierEtat(etat);
        capacite = nb_rangees * nb_colonnes;
        String sql = "select count(*) from CIN_SALLE where idcinema = ? and upper(trim(nom)) = upper(trim(?)) and (? is null or id <> ?)";
        String idExclu = CinUtils.estVide(id) ? null : id;
        if (CinUtils.entier(c, sql, idcinema, nom, idExclu, idExclu) > 0) {
            throw new Exception("Ce cin&eacute;ma a d&eacute;j&agrave; une salle nomm&eacute;e " + nom);
        }
    }

    /**
     * Classe des places generees : la classe active la moins chere (en principe Standard).
     */
    public static String getIdClasseParDefaut(Connection c) throws Exception {
        return CinUtils.valeur(c, "select id from (select id from CIN_CLASSE_PLACE where etat = 1 order by prix, val) where rownum = 1");
    }

    /**
     * Cree les places de la salle : rangee 1..nb_rangees (A..Z) x colonne 1..nb_colonnes.
     */
    public void genererPlaces(Connection c) throws Exception {
        if (CinUtils.entier(c, "select count(*) from CIN_PLACE where idsalle = ?", id) > 0) {
            throw new Exception("Les places de la salle " + nom + " existent d&eacute;j&agrave;");
        }
        String idClasse = getIdClasseParDefaut(c);
        String sql = "insert into CIN_PLACE (id, idsalle, idclasse, numero, rangee, colonne, etat)"
                + " values ('CINPLA' || lpad(GETSEQCINPLACE, 8, '0'), ?, ?, ?, ?, ?, 1)";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            for (int r = 1; r <= nb_rangees; r++) {
                for (int col = 1; col <= nb_colonnes; col++) {
                    ps.setString(1, id);
                    ps.setString(2, idClasse);
                    ps.setString(3, CinPlace.numeroPlace(r, col));
                    ps.setInt(4, r);
                    ps.setInt(5, col);
                    ps.addBatch();
                }
            }
            ps.executeBatch();
        }
    }

    /**
     * Places de la salle, triees par rangee puis colonne, avec classe, couleur et prix.
     */
    public static CinPlaceLib[] getPlaces(String idSalle, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                canClose = true;
            }
            List<CinPlaceLib> places = new ArrayList<CinPlaceLib>();
            String sql = "select id, idsalle, idclasse, idclasselib, couleur, prix, numero, rangee, colonne, etat, etatlib"
                    + " from CIN_PLACE_LIB where idsalle = ? order by rangee, colonne";
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, idSalle);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        CinPlaceLib p = new CinPlaceLib();
                        p.setId(rs.getString("id"));
                        p.setIdsalle(rs.getString("idsalle"));
                        p.setIdclasse(rs.getString("idclasse"));
                        p.setIdclasselib(rs.getString("idclasselib"));
                        p.setCouleur(rs.getString("couleur"));
                        p.setPrix(rs.getDouble("prix"));
                        p.setNumero(rs.getString("numero"));
                        p.setRangee(rs.getInt("rangee"));
                        p.setColonne(rs.getInt("colonne"));
                        p.setEtat(rs.getInt("etat"));
                        p.setEtatlib(rs.getString("etatlib"));
                        places.add(p);
                    }
                }
            }
            return places.toArray(new CinPlaceLib[0]);
        } finally {
            if (canClose) c.close();
        }
    }

    /**
     * Applique les changements faits sur le plan de salle.
     * modifs = "idplace:valeur;idplace:valeur..." ou valeur = id d'une classe active (la place passe dans
     * cette classe et revient en service) ou HS (la place passe hors service, sa classe ne change pas).
     * Retourne le nombre de places modifiees. Pas de commit : c'est l'appelant qui gere la transaction.
     */
    public static int modifierPlaces(String idSalle, String modifs, Connection c) throws Exception {
        if (CinUtils.estVide(idSalle)) throw new Exception("Salle non pr&eacute;cis&eacute;e");
        if (CinUtils.entier(c, "select count(*) from CIN_SALLE where id = ?", idSalle) == 0) {
            throw new Exception("Salle introuvable");
        }
        Map<String, String> changements = lireModifs(modifs);
        if (changements.isEmpty()) return 0;

        Set<String> placesSalle = lireIds(c, "select id from CIN_PLACE where idsalle = ?", idSalle);
        Set<String> classesActives = lireIds(c, "select id from CIN_CLASSE_PLACE where etat = 1");
        try (PreparedStatement psClasse = c.prepareStatement("update CIN_PLACE set idclasse = ?, etat = 1 where id = ? and idsalle = ?");
             PreparedStatement psHs = c.prepareStatement("update CIN_PLACE set etat = 0 where id = ? and idsalle = ?")) {
            for (Map.Entry<String, String> e : changements.entrySet()) {
                String idPlace = e.getKey();
                String valeur = e.getValue();
                if (!placesSalle.contains(idPlace)) throw new Exception("La place " + idPlace + " n'appartient pas &agrave; cette salle");
                if (HORS_SERVICE.equals(valeur)) {
                    psHs.setString(1, idPlace);
                    psHs.setString(2, idSalle);
                    psHs.addBatch();
                } else {
                    if (!classesActives.contains(valeur)) throw new Exception("Classe de place inconnue ou inactive : " + valeur);
                    psClasse.setString(1, valeur);
                    psClasse.setString(2, idPlace);
                    psClasse.setString(3, idSalle);
                    psClasse.addBatch();
                }
            }
            psClasse.executeBatch();
            psHs.executeBatch();
        }
        return changements.size();
    }

    /**
     * Version avec sa propre connexion et sa propre transaction (appelee par la page apres-salle-plan.jsp).
     */
    public static int modifierPlaces(String idSalle, String modifs) throws Exception {
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            int nb = modifierPlaces(idSalle, modifs, c);
            c.commit();
            return nb;
        } catch (Exception e) {
            if (c != null) c.rollback();
            throw e;
        } finally {
            if (c != null) c.close();
        }
    }

    private static Map<String, String> lireModifs(String modifs) throws Exception {
        Map<String, String> changements = new LinkedHashMap<String, String>();
        if (CinUtils.estVide(modifs)) return changements;
        for (String paire : modifs.split(";")) {
            if (paire.trim().isEmpty()) continue;
            String[] kv = paire.split(":");
            if (kv.length != 2 || kv[0].trim().isEmpty() || kv[1].trim().isEmpty()) {
                throw new Exception("Modification de place mal form&eacute;e : " + paire);
            }
            changements.put(kv[0].trim(), kv[1].trim());
        }
        return changements;
    }

    private static Set<String> lireIds(Connection c, String sql, String... parametres) throws Exception {
        Set<String> ids = new HashSet<String>();
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < parametres.length; i++) ps.setString(i + 1, parametres[i]);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) ids.add(rs.getString(1));
            }
        }
        return ids;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdcinema() {
        return idcinema;
    }

    public void setIdcinema(String idcinema) {
        this.idcinema = idcinema;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) throws Exception {
        if (this.getMode().compareToIgnoreCase("modif") == 0 && CinUtils.estVide(nom)) {
            throw new Exception("Le nom de la salle est obligatoire");
        }
        this.nom = nom;
    }

    public int getNb_rangees() {
        return nb_rangees;
    }

    public void setNb_rangees(int nb_rangees) {
        this.nb_rangees = nb_rangees;
    }

    public int getNb_colonnes() {
        return nb_colonnes;
    }

    public void setNb_colonnes(int nb_colonnes) {
        this.nb_colonnes = nb_colonnes;
    }

    public int getCapacite() {
        return capacite;
    }

    public void setCapacite(int capacite) {
        this.capacite = capacite;
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
