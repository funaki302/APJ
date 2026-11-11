package cinema.salle;

import bean.ClassMAPTable;
import cinema.utils.CinUtils;
import java.sql.Connection;
import java.sql.Date;

/**
 * Classe de place (table CIN_CLASSE_PLACE) : standard, moyen, premium...
 * Le prix d'une place vient de sa classe ; la couleur sert au plan de salle.
 */
public class CinClassePlace extends ClassMAPTable {

    private String id;
    private String val;
    private String desce;
    private double prix;
    private String couleur;
    private Date date_creation;
    private int etat = CinUtils.ETAT_ACTIF;

    public CinClassePlace() {
        this.setNomTable("CIN_CLASSE_PLACE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINCLA", "GETSEQCINCLASSEPLACE");
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
        super.controler(c);
    }

    /**
     * La modification standard (apresTarif.jsp -> UserEJB.updateObject) n'appelle pas controlerUpdate :
     * les controles sont donc faits ici.
     */
    @Override
    public int updateToTableWithHisto(String refUser, Connection c) throws Exception {
        verifier(c);
        return super.updateToTableWithHisto(refUser, c);
    }

    private void verifier(Connection c) throws Exception {
        if (CinUtils.estVide(val)) throw new Exception("Le libell&eacute; de la classe est obligatoire");
        if (prix <= 0) throw new Exception("Le prix de la classe doit &ecirc;tre sup&eacute;rieur &agrave; 0");
        if (couleur == null || !couleur.matches("#[0-9A-Fa-f]{6}")) {
            throw new Exception("La couleur doit &ecirc;tre au format #RRGGBB (ex. #F4C430)");
        }
        CinUtils.verifierEtat(etat);
        if (CinUtils.valeurExiste("CIN_CLASSE_PLACE", "VAL", val, id, c)) {
            throw new Exception("La classe " + val + " existe d&eacute;j&agrave;");
        }
    }

    /**
     * Classes actives triees par prix (legende et palette du plan de salle).
     */
    public static CinClassePlace[] getClassesActives(Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new utilitaire.UtilDB().GetConn();
                canClose = true;
            }
            java.util.List<CinClassePlace> classes = new java.util.ArrayList<CinClassePlace>();
            try (java.sql.PreparedStatement ps = c.prepareStatement(
                    "select id, val, desce, prix, couleur from CIN_CLASSE_PLACE where etat = 1 order by prix, val");
                 java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    CinClassePlace cl = new CinClassePlace();
                    cl.setId(rs.getString("id"));
                    cl.val = rs.getString("val");
                    cl.setDesce(rs.getString("desce"));
                    cl.prix = rs.getDouble("prix");
                    cl.setCouleur(rs.getString("couleur"));
                    classes.add(cl);
                }
            }
            return classes.toArray(new CinClassePlace[0]);
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

    public String getVal() {
        return val;
    }

    public void setVal(String val) throws Exception {
        if (this.getMode().compareToIgnoreCase("modif") == 0 && CinUtils.estVide(val)) {
            throw new Exception("Le libell&eacute; de la classe est obligatoire");
        }
        this.val = val;
    }

    public String getDesce() {
        return desce;
    }

    public void setDesce(String desce) {
        this.desce = desce;
    }

    public double getPrix() {
        return prix;
    }

    public void setPrix(double prix) throws Exception {
        if (this.getMode().compareToIgnoreCase("modif") == 0 && prix <= 0) {
            throw new Exception("Le prix de la classe doit &ecirc;tre sup&eacute;rieur &agrave; 0");
        }
        this.prix = prix;
    }

    public String getCouleur() {
        return couleur;
    }

    public void setCouleur(String couleur) {
        this.couleur = couleur == null ? null : couleur.trim().toUpperCase();
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
