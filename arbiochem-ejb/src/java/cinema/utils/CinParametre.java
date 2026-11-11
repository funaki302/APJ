package cinema.utils;

import bean.ClassMAPTable;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import utilitaire.UtilDB;

/**
 * Parametre du module cinema (table CIN_PARAMETRE).
 * Le CODE est fixe et lu par le Java ; seule la VALEUR se modifie dans l'ecran Parametres.
 */
public class CinParametre extends ClassMAPTable {

    public static final String DELAI_EXPIRATION_MIN = "DELAI_EXPIRATION_MIN";
    public static final int DELAI_EXPIRATION_DEFAUT = 30;

    private String id;
    private String code;
    private String valeur;
    private String desce;

    public CinParametre() {
        this.setNomTable("CIN_PARAMETRE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINPAR", "GETSEQCINPARAMETRE");
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
        verifier();
        super.controler(c);
    }

    /**
     * La modification standard (apresTarif.jsp -> UserEJB.updateObject) n'appelle pas controlerUpdate :
     * les controles sont donc faits ici.
     */
    @Override
    public int updateToTableWithHisto(String refUser, Connection c) throws Exception {
        verifier();
        return super.updateToTableWithHisto(refUser, c);
    }

    @Override
    public void controlerDelete(Connection c) throws Exception {
        throw new Exception("Un param&egrave;tre du cin&eacute;ma ne peut pas &ecirc;tre supprim&eacute;, seulement modifi&eacute;");
    }

    private void verifier() throws Exception {
        if (CinUtils.estVide(valeur)) throw new Exception("La valeur du param&egrave;tre est obligatoire");
        if (DELAI_EXPIRATION_MIN.equals(code)) {
            int delai;
            try {
                delai = Integer.parseInt(valeur.trim());
            } catch (NumberFormatException e) {
                throw new Exception("Le d&eacute;lai d'expiration doit &ecirc;tre un nombre entier de minutes");
            }
            if (delai < 0) throw new Exception("Le d&eacute;lai d'expiration ne peut pas &ecirc;tre n&eacute;gatif");
        }
    }

    /**
     * Valeur d'un parametre, ou null s'il n'existe pas.
     */
    public static String getValeur(String code, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                canClose = true;
            }
            try (PreparedStatement ps = c.prepareStatement("select valeur from CIN_PARAMETRE where code = ?")) {
                ps.setString(1, code);
                try (ResultSet rs = ps.executeQuery()) {
                    return rs.next() ? rs.getString(1) : null;
                }
            }
        } finally {
            if (canClose) c.close();
        }
    }

    /**
     * Minutes avant le debut de la seance apres lesquelles une reservation non payee expire (30 par defaut).
     */
    public static int getDelaiExpirationMinutes(Connection c) throws Exception {
        String valeur = getValeur(DELAI_EXPIRATION_MIN, c);
        if (CinUtils.estVide(valeur)) return DELAI_EXPIRATION_DEFAUT;
        try {
            return Math.max(0, Integer.parseInt(valeur.trim()));
        } catch (NumberFormatException e) {
            return DELAI_EXPIRATION_DEFAUT;
        }
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getValeur() {
        return valeur;
    }

    public void setValeur(String valeur) {
        this.valeur = valeur;
    }

    public String getDesce() {
        return desce;
    }

    public void setDesce(String desce) {
        this.desce = desce;
    }
}
