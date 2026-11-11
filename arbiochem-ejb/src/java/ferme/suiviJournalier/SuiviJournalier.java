package ferme.suiviJournalier;

import bean.CGenUtil;
import bean.ClassMAPTable;
import bean.ClassMere;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

public class SuiviJournalier extends ClassMere {
    private String id;
    private Date daty;
    private String idlot;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
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

    public SuiviJournalier() throws Exception {
        this.setNomTable("SUIVIJOURNALIER");
        this.setNomClasseFille("ferme.suiviJournalier.SuiviJournalierDetail");
        this.setLiaisonFille("idmere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("SJ", "getseq_suivijournalier");
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

    private static boolean estVide(String valeur) {
        return valeur == null || valeur.trim().isEmpty();
    }

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        if (estVide(idlot)) {
            throw new Exception("Le lot est obligatoire");
        }
        if (daty == null) {
            throw new Exception("La date est obligatoire");
        }
        idlot = idlot.trim();

        // 1. Un seul suivi par lot et par date
        verifierUnicite(c);

        // 2. Quantites triees du lot, par (batiment, parquet) : seuls les poussins vivants comptent
        Map<String, Double> qteTriee = getQuantiteTrieeParParquet(c);
        if (qteTriee.isEmpty()) {
            throw new Exception("Le LOT choisi n'a pas encore ete trier");
        }

        // 3. Controle de chaque ligne du suivi
        SuiviJournalierDetail[] details = (SuiviJournalierDetail[]) this.getFille();
        Set<String> dejaVus = new HashSet<String>();
        int nbLignes = 0;
        if (details != null) {
            for (SuiviJournalierDetail d : details) {
                if (d == null || estVide(d.getIdbatiment()) && estVide(d.getIdparquet())) {
                    continue;
                }
                if (estVide(d.getIdbatiment()) || estVide(d.getIdparquet())) {
                    throw new Exception("Le batiment et le parquet sont obligatoires pour chaque ligne");
                }
                String cle = d.getIdbatiment().trim() + "|" + d.getIdparquet().trim();
                Double qte = qteTriee.get(cle);
                if (qte == null) {
                    throw new Exception("Le batiment " + d.getIdbatiment() + " / parquet " + d.getIdparquet()
                            + " ne fait pas partie du triage du lot " + idlot);
                }
                if (!dejaVus.add(cle)) {
                    throw new Exception("Le parquet " + d.getIdparquet() + " est saisi plusieurs fois");
                }
                verifierValeurs(d);
                double sorties = d.getTri() + d.getMortalite() + d.getCulls();
                if (sorties - qte > 0.000001) {
                    throw new Exception("Parquet " + d.getIdparquet() + " : tri + mortalite + culls (" + sorties
                            + ") depasse la quantite triee (" + qte + ")");
                }
                nbLignes++;
            }
        }
        if (nbLignes == 0) {
            throw new Exception("Aucune ligne de suivi a enregistrer");
        }
        return super.createObject(u, c);
    }

    // Valeurs numeriques jamais negatives (0 = valeur par defaut autorisee)
    private void verifierValeurs(SuiviJournalierDetail d) throws Exception {
        String[] noms = {"Age en jour", "Entree", "Tri", "Mortalite", "Culls", "Consigne sur aliment", "Eau",
            "Temperature min", "Temperature max"};
        double[] vals = {d.getAgejour(), d.getEntree(), d.getTri(), d.getMortalite(), d.getCulls(),
            d.getConsignesuraliment(), d.getEau(), d.getTemperaturemin(), d.getTemperaturemax()};
        for (int i = 0; i < vals.length; i++) {
            if (vals[i] < 0) {
                throw new Exception(noms[i] + " ne peut pas etre negatif(ve) (parquet " + d.getIdparquet() + ")");
            }
        }
        if (d.getTemperaturemin() > d.getTemperaturemax()) {
            throw new Exception("La temperature min depasse la temperature max (parquet " + d.getIdparquet() + ")");
        }
    }

    private void verifierUnicite(Connection c) throws Exception {
        boolean exclure = !estVide(this.id);
        String sql = "SELECT COUNT(*) FROM SUIVIJOURNALIER WHERE IDLOT = ? AND TRUNC(DATY) = TRUNC(?)"
                + (exclure ? " AND ID <> ?" : "");
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, idlot);
            ps.setDate(2, daty);
            if (exclure) {
                ps.setString(3, this.id);
            }
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) {
                    throw new Exception("Un suivi journalier existe deja pour ce lot a cette date");
                }
            }
        }
    }

    // Quantite triee (poussins vivants) du lot, cle = idbatiment|idparquet
    private Map<String, Double> getQuantiteTrieeParParquet(Connection c) throws Exception {
        Map<String, Double> res = new LinkedHashMap<String, Double>();
        String sql = "SELECT d.IDBATIMENT, d.IDPARQUET, SUM(d.QTE) FROM TRIAGEBATIMENTPARQUETDETAIL d"
                + " JOIN TRIAGEBATIMENTPARQUET t ON t.ID = d.IDMERE"
                + " WHERE t.IDLOT = ? AND NVL(d.SANTE, 10) > 0 AND d.QTE > 0"
                + " GROUP BY d.IDBATIMENT, d.IDPARQUET";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, idlot);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    res.put(rs.getString(1) + "|" + rs.getString(2), rs.getDouble(3));
                }
            }
        }
        return res;
    }
}
