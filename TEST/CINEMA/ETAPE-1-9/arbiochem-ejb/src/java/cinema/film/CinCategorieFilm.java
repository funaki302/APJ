package cinema.film;

import bean.ClassMAPTable;
import cinema.utils.CinUtils;
import java.sql.Connection;
import java.sql.Date;

/**
 * Categorie de film (table CIN_CATEGORIE_FILM) : action, comedie...
 */
public class CinCategorieFilm extends ClassMAPTable {

    private String id;
    private String val;
    private String desce;
    private Date date_creation;
    private int etat = CinUtils.ETAT_ACTIF;

    public CinCategorieFilm() {
        this.setNomTable("CIN_CATEGORIE_FILM");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINCAT", "GETSEQCINCATEGORIEFILM");
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
        if (CinUtils.estVide(val)) throw new Exception("Le libell&eacute; de la cat&eacute;gorie est obligatoire");
        CinUtils.verifierEtat(etat);
        if (CinUtils.valeurExiste("CIN_CATEGORIE_FILM", "VAL", val, id, c)) {
            throw new Exception("La cat&eacute;gorie " + val + " existe d&eacute;j&agrave;");
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
            throw new Exception("Le libell&eacute; de la cat&eacute;gorie est obligatoire");
        }
        this.val = val;
    }

    public String getDesce() {
        return desce;
    }

    public void setDesce(String desce) {
        this.desce = desce;
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
