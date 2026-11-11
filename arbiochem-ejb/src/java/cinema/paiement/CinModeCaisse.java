package cinema.paiement;

import bean.ClassMAPTable;
import cinema.utils.CinUtils;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import utilitaire.UtilDB;

/**
 * Caisse proposee pour un mode de paiement (table CIN_MODE_CAISSE) : espece -> Caisse Cinema, Mobile money -> caisse Mvola...
 * Seuls les modes actifs sont proposes au paiement d'un ticket ; la caisse reste modifiable ligne par ligne.
 */
public class CinModeCaisse extends ClassMAPTable {

    private String id;
    private String idmodepaiement;
    private String idcaisse;
    private int actif = 1;

    public CinModeCaisse() {
        this.setNomTable("CIN_MODE_CAISSE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINMCA", "GETSEQCINMODECAISSE");
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
        verifier(c);
        super.controler(c);
    }

    /**
     * La modification standard (apresTarif.jsp -> UserEJB.updateObject) n'appelle pas controlerUpdate :
     * les controles sont donc faits ici.
     */
    @Override
    public int updateToTableWithHisto(String refUser, Connection c) throws Exception {
        verifier(c);
        return super.updateToTableWithHisto(refUser, c);
    }

    private void verifier(Connection c) throws Exception {
        if (CinUtils.estVide(idmodepaiement)) throw new Exception("Le mode de paiement est obligatoire");
        if (CinUtils.entier(c, "select count(*) from MODEPAIEMENT where id = ?", idmodepaiement) == 0) throw new Exception("Mode de paiement inconnu");
        if (CinUtils.estVide(idcaisse)) throw new Exception("La caisse est obligatoire");
        if (CinUtils.entier(c, "select count(*) from CAISSE where id = ? and actif = 1", idcaisse) == 0) {
            throw new Exception("La caisse choisie n'existe pas ou est inactive");
        }
        if (actif != 0 && actif != 1) throw new Exception("Actif : Oui ou Non");
        if (CinUtils.valeurExiste("CIN_MODE_CAISSE", "IDMODEPAIEMENT", idmodepaiement, id, c)) {
            throw new Exception("Ce mode de paiement a d&eacute;j&agrave; une caisse");
        }
    }

    /**
     * Modes proposes au paiement d'un ticket (actifs), avec leur caisse par defaut, tries par libelle.
     */
    public static CinModeCaisseLib[] getModesActifs(Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                canClose = true;
            }
            List<CinModeCaisseLib> modes = new ArrayList<CinModeCaisseLib>();
            String sql = "select id, idmodepaiement, idmodepaiementlib, idcaisse, idcaisselib from CIN_MODE_CAISSE_LIB where actif = 1 order by idmodepaiementlib";
            try (PreparedStatement ps = c.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    CinModeCaisseLib m = new CinModeCaisseLib();
                    m.setId(rs.getString(1));
                    m.setIdmodepaiement(rs.getString(2));
                    m.setIdmodepaiementlib(rs.getString(3));
                    m.setIdcaisse(rs.getString(4));
                    m.setIdcaisselib(rs.getString(5));
                    modes.add(m);
                }
            }
            return modes.toArray(new CinModeCaisseLib[0]);
        } finally {
            if (canClose) c.close();
        }
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdmodepaiement() {
        return idmodepaiement;
    }

    public void setIdmodepaiement(String idmodepaiement) {
        this.idmodepaiement = idmodepaiement;
    }

    public String getIdcaisse() {
        return idcaisse;
    }

    public void setIdcaisse(String idcaisse) {
        this.idcaisse = idcaisse;
    }

    public int getActif() {
        return actif;
    }

    public void setActif(int actif) {
        this.actif = actif;
    }
}
