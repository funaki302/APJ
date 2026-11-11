package ferme.triageBatiment;

import bean.ClassFille;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class TriageBatimentParquetDetail extends ClassFille {
    private String id;
    private String idmere;
    private String idbatiment;
    private String idparquet;
    private String idsexe;
    private String idqualite;
    private int qte;
    private int sante = 10;

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

    public String getIdsexe() {
        return idsexe;
    }

    public void setIdsexe(String idsexe) throws Exception {
        try {
            if (idsexe != null && !idsexe.isEmpty()) {
                this.idsexe = idsexe;
            }
        } catch(Exception e) {
            e.printStackTrace();
            throw e;
        }
    }

    public String getIdqualite() {
        return idqualite;
    }

    public void setIdqualite(String idqualite) {
        this.idqualite = idqualite;
    }

    public int getQte() {
        return qte;
    }

    public void setQte(int qte) {
        this.qte = qte;
    }

    public int getSante() {
        return sante;
    }

    public void setSante(int sante) {
        this.sante = sante;
    }

    @Override
    public String getNomClasseMere() {
        return "ferme.triageBatiment.TriageBatimentParquet";
    }

    @Override
    public String getLiaisonMere() {
        return "idmere";
    }

    public TriageBatimentParquetDetail() throws Exception {
        this.setNomTable("TRIAGEBATIMENTPARQUETDETAIL");
        this.setNomClasseMere("ferme.triageBatiment.TriageBatimentParquet");
        this.setLiaisonMere("idmere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        String sql = "SELECT getseq_triagebatparquetdetail(?) FROM DUAL";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, this.getIdsexe());
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                this.setId("TBD" + rs.getString(1));
            }
        }
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }
}
