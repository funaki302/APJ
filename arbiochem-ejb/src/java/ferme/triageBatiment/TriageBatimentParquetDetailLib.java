package ferme.triageBatiment;

import bean.CGenUtil;
import faturefournisseur.As_BonDeLivraison_Fille;
import ferme.receptionaeroport.ReceptionPoussinAeroport;
import java.sql.Connection;

public class TriageBatimentParquetDetailLib extends TriageBatimentParquetDetail{
    private String idBatimentLib;
    private String idParquetLib;
    private String idQualiteLib;
    private String idSexeLib;
    private String idLot;
    private double qte_depart;
    private double qte_mort;
    private double qte_actuel;

    private double pu;
    private boolean valorisationChargee;

    public TriageBatimentParquetDetailLib() throws Exception {
        this.setNomTable("TRIAGEBATPARQUETDETAIL_LIB");
    }

    public String getIdBatimentLib() {
        return idBatimentLib;
    }
    public void setIdBatimentLib(String idBatimentLib) {
        this.idBatimentLib = idBatimentLib;
    }

    public String getIdParquetLib() {
        return idParquetLib;
    }
    public void setIdParquetLib(String idParquetLib) {
        this.idParquetLib = idParquetLib;
    }

    public String getIdQualiteLib() {
        return idQualiteLib;
    }
    public void setIdQualiteLib(String idQualiteLib) {
        this.idQualiteLib = idQualiteLib;
    }

    public String getIdSexeLib() {
        return idSexeLib;
    }
    public void setIdSexeLib(String idSexeLib) {
        this.idSexeLib = idSexeLib;
    }

    public String getIdLot() {
        return idLot;
    }
    public void setIdLot(String idLot) {
        this.idLot = idLot;
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

    public double getPu() throws Exception {
        chargerValorisation();
        return pu;
    }
    public void setPu(double pu) {
        this.pu = pu;
        this.valorisationChargee = true;
    }

    public double getValeur() throws Exception {
        return getQte() * getPu();
    }

    // Valeur des poussins encore vivants (apres mortalite / culls / tri des suivis valides)
    public double getValeur_actuelle() throws Exception {
        return getQte_actuel() * getPu();
    }
    private void chargerValorisation() throws Exception {
        if (valorisationChargee || getIdmere() == null || getIdmere().trim().isEmpty()) {
            return;
        }

        Connection connexion = null;
        try {
            connexion = new utilitaire.UtilDB().GetConn();
                TriageBatimentParquet critereTriage = new TriageBatimentParquet();
                critereTriage.setId(getIdmere());
                TriageBatimentParquet[] triages = (TriageBatimentParquet[]) CGenUtil.rechercher(
                    critereTriage, null, null, connexion, "");
                if (triages == null || triages.length == 0 || triages[0].getIdRfa() == null
                    || triages[0].getIdRfa().trim().isEmpty()) {
                return;
            }

                ReceptionPoussinAeroport critereReception = new ReceptionPoussinAeroport();
                critereReception.setId(triages[0].getIdRfa());
                ReceptionPoussinAeroport[] receptions = (ReceptionPoussinAeroport[]) CGenUtil.rechercher(
                    critereReception, null, null, connexion, "");
                if (receptions == null || receptions.length == 0 || receptions[0].getIdBl() == null
                    || receptions[0].getIdBl().trim().isEmpty()) {
                return;
            }

            As_BonDeLivraison_Fille critere = new As_BonDeLivraison_Fille();
                critere.setNumbl(receptions[0].getIdBl());
            As_BonDeLivraison_Fille[] lignes = (As_BonDeLivraison_Fille[]) CGenUtil.rechercher(
                    critere, null, null, connexion, "");
            double quantite = 0;
            double montant = 0;
            if (lignes != null) {
                for (As_BonDeLivraison_Fille ligne : lignes) {
                    if (ligne.getQuantite() > 0) {
                        quantite += ligne.getQuantite();
                        montant += ligne.getQuantite() * ligne.getPu();
                    }
                }
            }
            if (quantite > 0) {
                pu = montant / quantite;
            }
            valorisationChargee = true;
        } finally {
            if (connexion != null) {
                connexion.close();
            }
        }
    }
}
