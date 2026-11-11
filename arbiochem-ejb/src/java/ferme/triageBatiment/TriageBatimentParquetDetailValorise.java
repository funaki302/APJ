package ferme.triageBatiment;

import java.sql.Date;

public class TriageBatimentParquetDetailValorise extends TriageBatimentParquetDetail {
    private Date daty;
    private String idlot;
    private String idrfa;
    private String idbl;
    private String idParquetLib;
    private double qteTheorique;
    private double qteReelle;
    private double valeurTheoriqueUnitaire;
    private double valeurUnitaireReelle;
    private double valeurTotaleTheorique;
    private double valeurTotaleReelle;

    public TriageBatimentParquetDetailValorise() throws Exception {
        this.setNomTable("TRIAGEBATPARQUETDETAIL_VALO");
    }

    public Date getDaty() {
        return daty;
    }

    public void setDaty(Date daty) {
        this.daty = daty;
    }

    public String getIdlot() {
        return idlot;
    }

    public void setIdlot(String idlot) {
        this.idlot = idlot;
    }

    public String getIdrfa() {
        return idrfa;
    }

    public void setIdrfa(String idrfa) {
        this.idrfa = idrfa;
    }

    public String getIdbl() {
        return idbl;
    }

    public void setIdbl(String idbl) {
        this.idbl = idbl;
    }

    public String getIdParquetLib() {
        return idParquetLib;
    }

    public void setIdParquetLib(String idParquetLib) {
        this.idParquetLib = idParquetLib;
    }

    public double getQteTheorique() {
        return qteTheorique;
    }

    public void setQteTheorique(double qteTheorique) {
        this.qteTheorique = qteTheorique;
    }

    public double getQteReelle() {
        return qteReelle;
    }

    public void setQteReelle(double qteReelle) {
        this.qteReelle = qteReelle;
    }

    public double getValeurTheoriqueUnitaire() {
        return valeurTheoriqueUnitaire;
    }

    public void setValeurTheoriqueUnitaire(double valeurTheoriqueUnitaire) {
        this.valeurTheoriqueUnitaire = valeurTheoriqueUnitaire;
    }

    public double getValeurUnitaireReelle() {
        return valeurUnitaireReelle;
    }

    public void setValeurUnitaireReelle(double valeurUnitaireReelle) {
        this.valeurUnitaireReelle = valeurUnitaireReelle;
    }

    public double getValeurTotaleTheorique() {
        return valeurTotaleTheorique;
    }

    public void setValeurTotaleTheorique(double valeurTotaleTheorique) {
        this.valeurTotaleTheorique = valeurTotaleTheorique;
    }

    public double getValeurTotaleReelle() {
        return valeurTotaleReelle;
    }

    public void setValeurTotaleReelle(double valeurTotaleReelle) {
        this.valeurTotaleReelle = valeurTotaleReelle;
    }
}
