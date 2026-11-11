package cinema.film;

import bean.ClassMAPTable;
import cinema.utils.CinUtils;
import java.sql.Connection;
import java.sql.Date;

/**
 * Film (table CIN_FILM) : titre, categorie, acteur principal, duree en minutes, prix d'achat (pa).
 * La photo est dans CIN_FILM_PHOTO (voir CinFilmPhoto).
 */
public class CinFilm extends ClassMAPTable {

    public static final int DUREE_MAX = 600;

    private String id;
    private String titre;
    private String idcategorie;
    private String idacteur;
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

    private void verifier(Connection c) throws Exception {
        if (CinUtils.estVide(titre)) throw new Exception("Le titre du film est obligatoire");
        if (CinUtils.estVide(idcategorie)) throw new Exception("La cat&eacute;gorie du film est obligatoire");
        if (CinUtils.entier(c, "select count(*) from CIN_CATEGORIE_FILM where id = ? and etat = 1", idcategorie) == 0) {
            throw new Exception("La cat&eacute;gorie choisie n'existe pas ou est inactive");
        }
        if (CinUtils.estVide(idacteur)) throw new Exception("L'acteur principal est obligatoire");
        if (CinUtils.entier(c, "select count(*) from CIN_ACTEUR where id = ?", idacteur) == 0) {
            throw new Exception("L'acteur choisi n'existe pas");
        }
        if (duree < 1 || duree > DUREE_MAX) throw new Exception("La dur&eacute;e doit &ecirc;tre entre 1 et " + DUREE_MAX + " minutes");
        if (pa < 0) throw new Exception("Le prix d'achat ne peut pas &ecirc;tre n&eacute;gatif");
        if (description != null && description.length() > 1000) throw new Exception("La description d&eacute;passe 1000 caract&egrave;res");
        CinUtils.verifierEtat(etat);
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
