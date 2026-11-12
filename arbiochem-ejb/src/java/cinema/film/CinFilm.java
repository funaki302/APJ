package cinema.film;

import bean.ClassMAPTable;
import cinema.utils.CinUtils;
import java.sql.Connection;
import java.sql.Date;

/**
 * Film (table CIN_FILM) : titre, categorie, realisateur, acteur principal (facultatif), classification
 * (Tous publics, -12, -16, -18), duree en minutes, prix d'achat (pa).
 * La photo est dans CIN_FILM_PHOTO (voir CinFilmPhoto).
 */
public class CinFilm extends ClassMAPTable {

    public static final int DUREE_MAX = 600;
    /** Classifications acceptees (contrainte CK_CIN_FILM_CLASSIFICATION) */
    public static final String[] CLASSIFICATIONS = {"Tous publics", "-12", "-16", "-18"};

    private String id;
    private String titre;
    private String idcategorie;
    private String realisateur;
    private String idacteur;
    private String classification;
    private int duree;
    private double pa;
    private String description;
    private Date date_creation;
    private int etat = CinUtils.ETAT_ACTIF;

    public CinFilm() {
        this.setNomTable("CIN_FILM");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINFIL", "GETSEQCINFILM");
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

    @Override
    public void controlerDelete(Connection c) throws Exception {
        if (CinUtils.entier(c, "select count(*) from CIN_DIFFUSION where idfilm = ?", id) > 0) {
            throw new Exception("Ce film a des diffusions : il ne peut pas &ecirc;tre supprim&eacute; (le passer en Inactif)");
        }
        if (CinUtils.entier(c, "select count(*) from CIN_ACHAT_FILLE where idfilm = ?", id) > 0) {
            throw new Exception("Ce film figure dans un achat : il ne peut pas &ecirc;tre supprim&eacute; (le passer en Inactif)");
        }
        super.controlerDelete(c);
    }

    private void verifier(Connection c) throws Exception {
        if (CinUtils.estVide(titre)) throw new Exception("Le titre du film est obligatoire");
        if (CinUtils.estVide(idcategorie)) throw new Exception("La cat&eacute;gorie du film est obligatoire");
        if (CinUtils.entier(c, "select count(*) from CIN_CATEGORIE_FILM where id = ? and etat = 1", idcategorie) == 0) {
            throw new Exception("La cat&eacute;gorie choisie n'existe pas ou est inactive");
        }
        // acteur principal facultatif (les donnees du programme ne donnent que le realisateur)
        if (CinUtils.estVide(idacteur)) {
            idacteur = null;
        } else if (CinUtils.entier(c, "select count(*) from CIN_ACTEUR where id = ?", idacteur) == 0) {
            throw new Exception("L'acteur choisi n'existe pas");
        }
        if (realisateur != null && realisateur.length() > 255) throw new Exception("Le nom du r&eacute;alisateur d&eacute;passe 255 caract&egrave;res");
        if (CinUtils.estVide(classification)) {
            classification = null;
        } else if (!java.util.Arrays.asList(CLASSIFICATIONS).contains(classification)) {
            throw new Exception("Classification inconnue : Tous publics, -12, -16 ou -18");
        }
        if (duree < 1 || duree > DUREE_MAX) throw new Exception("La dur&eacute;e doit &ecirc;tre entre 1 et " + DUREE_MAX + " minutes");
        if (pa < 0) throw new Exception("Le prix d'achat ne peut pas &ecirc;tre n&eacute;gatif");
        if (description != null && description.length() > 1000) throw new Exception("La description d&eacute;passe 1000 caract&egrave;res");
        CinUtils.verifierEtat(etat);
    }

    /**
     * Films actifs tries par titre (listes deroulantes : achat, diffusion).
     */
    public static CinFilm[] getFilmsActifs(Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new utilitaire.UtilDB().GetConn();
                canClose = true;
            }
            java.util.List<CinFilm> films = new java.util.ArrayList<CinFilm>();
            try (java.sql.PreparedStatement ps = c.prepareStatement("select id, titre, duree, pa from CIN_FILM where etat = 1 order by upper(titre)");
                 java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    CinFilm f = new CinFilm();
                    f.setId(rs.getString("id"));
                    f.titre = rs.getString("titre");
                    f.setDuree(rs.getInt("duree"));
                    f.setPa(rs.getDouble("pa"));
                    films.add(f);
                }
            }
            return films.toArray(new CinFilm[0]);
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

    public String getTitre() {
        return titre;
    }

    public void setTitre(String titre) throws Exception {
        if (this.getMode().compareToIgnoreCase("modif") == 0 && CinUtils.estVide(titre)) {
            throw new Exception("Le titre du film est obligatoire");
        }
        this.titre = titre;
    }

    public String getIdcategorie() {
        return idcategorie;
    }

    public void setIdcategorie(String idcategorie) {
        this.idcategorie = idcategorie;
    }

    public String getRealisateur() {
        return realisateur;
    }

    public void setRealisateur(String realisateur) {
        this.realisateur = realisateur;
    }

    public String getClassification() {
        return classification;
    }

    public void setClassification(String classification) {
        this.classification = classification;
    }

    public String getIdacteur() {
        return idacteur;
    }

    public void setIdacteur(String idacteur) {
        this.idacteur = idacteur;
    }

    public int getDuree() {
        return duree;
    }

    public void setDuree(int duree) {
        this.duree = duree;
    }

    public double getPa() {
        return pa;
    }

    public void setPa(double pa) {
        this.pa = pa;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
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
