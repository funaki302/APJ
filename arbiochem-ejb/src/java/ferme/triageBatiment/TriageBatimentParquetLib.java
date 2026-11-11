package ferme.triageBatiment;

public class TriageBatimentParquetLib extends TriageBatimentParquet{
    private String idLotLib;
    private String idSoucheLib;
    private String etatLib;
    private double ecartFemelle;
    private double ecartMale;
    private double qte_depart;
    private double qte_mort;
    private double qte_actuel;
    private double qte_actuel_femelle;
    private double qte_actuel_male;

    public TriageBatimentParquetLib() throws Exception {
        this.setNomTable("TRIAGEBATIMENTPARQUET_LIB");
    }


    public String getIdLotLib() {
        return idLotLib;
    }
    public void setIdLotLib(String idLotLib) {
        this.idLotLib = idLotLib;
    }

    public String getIdSoucheLib() {
        return idSoucheLib;
    }
    public void setIdSoucheLib(String idSoucheLib) {
        this.idSoucheLib = idSoucheLib;
    }

    public String getEtatLib() {
        return etatLib;
    }
    public void setEtatLib(String etatLib) {
        this.etatLib = etatLib;
    }

    public double getEcartFemelle() {
        return ecartFemelle;
    }
    public void setEcartFemelle(double ecartFemelle) {
        this.ecartFemelle = ecartFemelle;
    }

    public double getEcartMale() {
        return ecartMale;
    }
    public void setEcartMale(double ecartMale) {
        this.ecartMale = ecartMale;
    }

    public double getQte_depart() {
        return qte_depart;
    }
    public void setQte_depart(double qte_depart) {
        this.qte_depart = qte_depart;
    }

    public double getQte_mort() {
        return qte_mort;
    }
    public void setQte_mort(double qte_mort) {
        this.qte_mort = qte_mort;
    }

    public double getQte_actuel() {
        return qte_actuel;
    }
    public void setQte_actuel(double qte_actuel) {
        this.qte_actuel = qte_actuel;
    }

    public double getQte_actuel_femelle() {
        return qte_actuel_femelle;
    }
    public void setQte_actuel_femelle(double qte_actuel_femelle) {
        this.qte_actuel_femelle = qte_actuel_femelle;
    }

    public double getQte_actuel_male() {
        return qte_actuel_male;
    }
    public void setQte_actuel_male(double qte_actuel_male) {
        this.qte_actuel_male = qte_actuel_male;
    }
}
