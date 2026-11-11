package cinema.film;

import bean.ClassMAPTable;
import cinema.utils.CinUtils;
import java.sql.Connection;
import java.sql.Date;

/**
 * Acteur (table CIN_ACTEUR) : un film a un acteur principal.
 * nom = nom civil, nom_acteur = nom de scene.
 */
public class CinActeur extends ClassMAPTable {

    private String id;
    private String nom;
    private String nom_acteur;
    private Date date_naissance;

    public CinActeur() {
        this.setNomTable("CIN_ACTEUR");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINACT", "GETSEQCINACTEUR");
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
        verifier();
        super.controler(c);
    }

    /**
     * La modification standard (apresTarif.jsp -> UserEJB.updateObject) n'appelle pas controlerUpdate :
     * les controles sont donc faits ici.
     */
    @Override
    public int updateToTableWithHisto(String refUser, Connection c) throws Exception {
        verifier();
        return super.updateToTableWithHisto(refUser, c);
    }

    private void verifier() throws Exception {
        if (CinUtils.estVide(nom)) throw new Exception("Le nom de l'acteur est obligatoire");
        if (date_naissance != null && date_naissance.after(new Date(System.currentTimeMillis()))) {
            throw new Exception("La date de naissance ne peut pas &ecirc;tre dans le futur");
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
            throw new Exception("Le nom de l'acteur est obligatoire");
        }
        this.nom = nom;
    }

    public String getNom_acteur() {
        return nom_acteur;
    }

    public void setNom_acteur(String nom_acteur) {
        this.nom_acteur = nom_acteur;
    }

    public Date getDate_naissance() {
        return date_naissance;
    }

    public void setDate_naissance(Date date_naissance) {
        this.date_naissance = date_naissance;
    }
}
