package ferme.suiviJournalier;

import bean.ClassFille;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class SuiviJournalierDetail extends ClassFille {
    private String id;
    private String idmere;
    private String idbatiment;
    private String idparquet;
    private double agejour;
    private double entree;
    private double tri;
    private double mortalite;
    private double culls;
    private double consignesuraliment;
    private double eau;
    private double temperaturemin;
    private double temperaturemax;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdmere() {
        return idmere;
    }

    public void setIdmere(String idmere) {
        this.idmere = idmere;
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

    public double getAgejour() {
        return agejour;
    }

    public void setAgejour(double agejour) {
        this.agejour = agejour;
    }

    public double getEntree() {
        return entree;
    }

    public void setEntree(double entree) {
        this.entree = entree;
    }

    public double getTri() {
        return tri;
    }

    public void setTri(double tri) {
        this.tri = tri;
    }

    public double getMortalite() {
        return mortalite;
    }

    public void setMortalite(double mortalite) {
        this.mortalite = mortalite;
    }

    public double getCulls() {
        return culls;
    }

    public void setCulls(double culls) {
        this.culls = culls;
    }

    public double getConsignesuraliment() {
        return consignesuraliment;
    }

    public void setConsignesuraliment(double consignesuraliment) {
        this.consignesuraliment = consignesuraliment;
    }

    public double getEau() {
        return eau;
    }

    public void setEau(double eau) {
        this.eau = eau;
    }

    public double getTemperaturemin() {
        return temperaturemin;
    }

    public void setTemperaturemin(double temperaturemin) {
        this.temperaturemin = temperaturemin;
    }

    public double getTemperaturemax() {
        return temperaturemax;
    }

    public void setTemperaturemax(double temperaturemax) {
        this.temperaturemax = temperaturemax;
    }


    @Override
    public String getNomClasseMere() {
        return "ferme.suiviJournalier.SuiviJournalier";
    }

    @Override
    public String getLiaisonMere() {
        return "idmere";
    }

    public SuiviJournalierDetail() throws Exception {
        this.setNomTable("SUIVIJOURNALIERDETAIL");
        this.setNomClasseMere("ferme.suiviJournalier.SuiviJournalier");
        this.setLiaisonMere("idmere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("SJD","getseq_suivijournalierdetail");
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

    /**
     * Lignes de suivi pre-remplies a partir du triage d'un lot : une ligne par (batiment, parquet)
     * contenant des poussins vivants (SANTE > 0). Batiment, parquet et age en jour sont renseignes,
     * toutes les autres valeurs valent 0. Liste vide si le lot n'a pas encore ete trie.
     * L'age = dateSuivi - date d'arrivee du lot (a defaut, date du triage).
     */
    public static SuiviJournalierDetail[] genererDepuisTriage(String idlot, java.util.Date dateSuivi, Connection c) throws Exception {
        List<SuiviJournalierDetail> lignes = new ArrayList<SuiviJournalierDetail>();
        if (idlot == null || idlot.trim().isEmpty()) {
            return new SuiviJournalierDetail[0];
        }
        if (dateSuivi == null) {
            dateSuivi = new java.util.Date();
        }
        boolean canClose = false;
        try {
            if (c == null) {
                c = new utilitaire.UtilDB().GetConn();
                canClose = true;
            }
            String sql = "SELECT d.IDBATIMENT, d.IDPARQUET, MIN(NVL(l.DATEARRIVEE, t.DATY))"
                    + " FROM TRIAGEBATIMENTPARQUETDETAIL d"
                    + " JOIN TRIAGEBATIMENTPARQUET t ON t.ID = d.IDMERE"
                    + " LEFT JOIN LOT l ON l.ID = t.IDLOT"
                    + " WHERE t.IDLOT = ? AND NVL(d.SANTE, 10) > 0 AND d.QTE > 0"
                    + " GROUP BY d.IDBATIMENT, d.IDPARQUET ORDER BY d.IDBATIMENT, d.IDPARQUET";
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, idlot.trim());
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        SuiviJournalierDetail l = new SuiviJournalierDetail();
                        l.setIdbatiment(rs.getString(1));
                        l.setIdparquet(rs.getString(2));
                        java.sql.Date entree = rs.getDate(3);
                        double age = 0;
                        if (entree != null) {
                            age = Math.floor((dateSuivi.getTime() - entree.getTime()) / 86400000.0);
                            if (age < 0) {
                                age = 0;
                            }
                        }
                        l.setAgejour(age);
                        lignes.add(l);
                    }
                }
            }
        } finally {
            if (canClose && c != null) {
                c.close();
            }
        }
        return lignes.toArray(new SuiviJournalierDetail[0]);
    }
}

