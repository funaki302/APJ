package ferme.suiviJournalier;

import java.sql.Date;

public class SuiviJournalieLib extends SuiviJournalier{
    private String id;
    private String idferme;
    private String idlot;
    private String idfermelib;
    private String idlotlib;
    private String idsouchelib;
    private String idetat;
    private String etatlib;
    private Date daty;

    public SuiviJournalieLib() throws Exception {
        this.setNomTable("SUIVIJOURNALIER_LIB");
    }

    public String getId() {
        return id;
    }
    public void setId(String id) {
        this.id = id;
    }

    public String getIdferme() {
        return idferme;
    }
    public void setIdferme(String idferme) {
        this.idferme = idferme;
    }

    public String getIdlot() {
        return idlot;
    }
    public void setIdlot(String idlot) {
        this.idlot = idlot;
    }

    public String getIdlotlib() {
        return idlotlib;
    }
    public void setIdlotlib(String idlotlib) {
        this.idlotlib = idlotlib;
    }

    public String getIdsouchelib() {
        return idsouchelib;
    }
    public void setIdsouchelib(String idsouchelib) {
        this.idsouchelib = idsouchelib;
    }

    public String getIdetat() {
        return idetat;
    }
    public void setIdetat(String idetat) {
        this.idetat = idetat;
    }

    public String getEtatlib() {
        return etatlib;
    }
    public void setEtatlib(String etatlib) {
        this.etatlib = etatlib;
    }

    public Date getDaty() {
        return daty;
    }
    public void setDaty(Date daty) {
        this.daty = daty;
    }
}
