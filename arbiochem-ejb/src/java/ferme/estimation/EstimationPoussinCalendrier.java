package ferme.estimation;

import bean.ClassMAPTable;
import java.sql.Date;

/**
 * Classe de la vue V_ESTIM_POUSSIN_CALENDRIER :
 * poussins (et oeufs) estimes par date d'eclosion et par ligne de triage detail FEMELLE.
 *
 * Les attributs portent EXACTEMENT le nom des colonnes de la vue (en minuscules,
 * underscores compris) pour que le mapping bean <-> ResultSet fonctionne sans alias.
 * La vue n'a pas de cle primaire : IDDETAIL sert d'identifiant technique (non unique,
 * une ligne de triage donne une ligne par date d'eclosion) - la classe est en lecture seule.
 */
public class EstimationPoussinCalendrier extends ClassMAPTable {

    private Date date_eclosion;
    private String iddetail;
    private String idtriage;
    private String idlot;
    private String nomlot;
    private String idbatiment;
    private String idparquet;
    private String parquet;
    private String souche;
    private double nb_femelles;
    private double nb_oeufs_estimes;
    private double nb_poussins_estimes;
    private int generation;           // 1 = poussins a venir des poussins recus, 2 = des poussins estimes
    private double qte_existants;     // poussins existants du lot (stock a ce jour)

    public EstimationPoussinCalendrier() {
        this.setNomTable("V_ESTIM_POUSSIN_CALENDRIER");
    }

    @Override
    public String getTuppleID() {
        return iddetail;
    }

    @Override
    public String getAttributIDName() {
        return "iddetail";
    }

    public Date getDate_eclosion() {
        return date_eclosion;
    }

    public void setDate_eclosion(Date date_eclosion) {
        this.date_eclosion = date_eclosion;
    }

    public String getIddetail() {
        return iddetail;
    }

    public void setIddetail(String iddetail) {
        this.iddetail = iddetail;
    }

    public String getIdtriage() {
        return idtriage;
    }

    public void setIdtriage(String idtriage) {
        this.idtriage = idtriage;
    }

    public String getIdlot() {
        return idlot;
    }

    public void setIdlot(String idlot) {
        this.idlot = idlot;
    }

    public String getNomlot() {
        return nomlot;
    }

    public void setNomlot(String nomlot) {
        this.nomlot = nomlot;
    }

    public String getIdbatiment() {
        return idbatiment;
    }

    public void setIdbatiment(String idbatiment) {
        this.idbatiment = idbatiment;
    }

    public String getIdparquet() {
        return idparquet;
    }

    public void setIdparquet(String idparquet) {
        this.idparquet = idparquet;
    }

    public String getParquet() {
        return parquet;
    }

    public void setParquet(String parquet) {
        this.parquet = parquet;
    }

    public String getSouche() {
        return souche;
    }

    public void setSouche(String souche) {
        this.souche = souche;
    }

    public double getNb_femelles() {
        return nb_femelles;
    }

    public void setNb_femelles(double nb_femelles) {
        this.nb_femelles = nb_femelles;
    }

    public double getNb_oeufs_estimes() {
        return nb_oeufs_estimes;
    }

    public void setNb_oeufs_estimes(double nb_oeufs_estimes) {
        this.nb_oeufs_estimes = nb_oeufs_estimes;
    }

    public double getNb_poussins_estimes() {
        return nb_poussins_estimes;
    }

    public void setNb_poussins_estimes(double nb_poussins_estimes) {
        this.nb_poussins_estimes = nb_poussins_estimes;
    }

    public int getGeneration() {
        return generation;
    }

    public void setGeneration(int generation) {
        this.generation = generation;
    }

    public double getQte_existants() {
        return qte_existants;
    }

    public void setQte_existants(double qte_existants) {
        this.qte_existants = qte_existants;
    }
}
