package ferme.estimation;

import bean.ClassMAPTable;

/**
 * Classe de la vue V_POUSSINS_EXISTANTS : stock de poussins existants par lot
 * (recus a l'aeroport - morts - pertes du triage - pertes des suivis valides). Lecture seule.
 */
public class PoussinExistant extends ClassMAPTable {

    private String idlot;
    private String nomlot;
    private String souche;
    private double qte_recue;
    private double morts_reception;
    private double perdus_reception;
    private double pertes_triage;
    private double pertes_suivi;
    private double qte_existants;

    public PoussinExistant() {
        this.setNomTable("V_POUSSINS_EXISTANTS");
    }

    @Override
    public String getTuppleID() {
        return idlot;
    }

    @Override
    public String getAttributIDName() {
        return "idlot";
    }

    public String getIdlot() { return idlot; }
    public void setIdlot(String idlot) { this.idlot = idlot; }
    public String getNomlot() { return nomlot; }
    public void setNomlot(String nomlot) { this.nomlot = nomlot; }
    public String getSouche() { return souche; }
    public void setSouche(String souche) { this.souche = souche; }
    public double getQte_recue() { return qte_recue; }
    public void setQte_recue(double qte_recue) { this.qte_recue = qte_recue; }
    public double getMorts_reception() { return morts_reception; }
    public void setMorts_reception(double morts_reception) { this.morts_reception = morts_reception; }
    public double getPerdus_reception() { return perdus_reception; }
    public void setPerdus_reception(double perdus_reception) { this.perdus_reception = perdus_reception; }
    public double getPertes_triage() { return pertes_triage; }
    public void setPertes_triage(double pertes_triage) { this.pertes_triage = pertes_triage; }
    public double getPertes_suivi() { return pertes_suivi; }
    public void setPertes_suivi(double pertes_suivi) { this.pertes_suivi = pertes_suivi; }
    public double getQte_existants() { return qte_existants; }
    public void setQte_existants(double qte_existants) { this.qte_existants = qte_existants; }
}
