package cinema.salle;

import bean.ClassMAPTable;
import cinema.utils.CinUtils;
import java.sql.Connection;
import java.sql.Date;

/**
 * Cinema (table CIN_CINEMA). Un cinema contient des salles.
 */
public class CinCinema extends ClassMAPTable {

    private String id;
    private String nom;
    private String localisation;
    private Date date_creation;
    private int etat = CinUtils.ETAT_ACTIF;

    public CinCinema() {
        this.setNomTable("CIN_CINEMA");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINCIN", "GETSEQCINCINEMA");
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
        if (CinUtils.estVide(nom)) throw new Exception("Le nom du cin&eacute;ma est obligatoire");
        CinUtils.verifierEtat(etat);
        if (CinUtils.valeurExiste("CIN_CINEMA", "NOM", nom, id, c)) {
            throw new Exception("Un cin&eacute;ma porte d&eacute;j&agrave; le nom " + nom);
        }
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) throws Exception {
        if (this.getMode().compareToIgnoreCase("modif") == 0 && CinUtils.estVide(nom)) {
            throw new Exception("Le nom du cin&eacute;ma est obligatoire");
        }
        this.nom = nom;
    }

    public String getLocalisation() {
        return localisation;
    }

    public void setLocalisation(String localisation) {
        this.localisation = localisation;
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
