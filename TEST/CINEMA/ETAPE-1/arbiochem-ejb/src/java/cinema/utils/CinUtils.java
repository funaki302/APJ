package cinema.utils;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

/**
 * Outils communs du module cinema.
 */
public class CinUtils {

    public static final int ETAT_INACTIF = 0;
    public static final int ETAT_ACTIF = 1;

    public static boolean estVide(String valeur) {
        return valeur == null || valeur.trim().isEmpty();
    }

    /**
     * Vrai si une autre ligne de la table a deja cette valeur (comparaison sans tenir compte de la casse).
     * table et colonne sont des constantes du code, jamais une saisie utilisateur.
     */
    public static boolean valeurExiste(String table, String colonne, String valeur, String idExclu, Connection c) throws Exception {
        if (estVide(valeur)) return false;
        // Oracle : '' vaut NULL, d'ou le test "? is null" pour une insertion (pas encore d'id)
        String sql = "select count(*) from " + table + " where upper(trim(" + colonne + ")) = upper(trim(?)) and (? is null or id <> ?)";
        String id = estVide(idExclu) ? null : idExclu;
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, valeur);
            ps.setString(2, id);
            ps.setString(3, id);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        }
    }

    public static void verifierEtat(int etat) throws Exception {
        if (etat != ETAT_ACTIF && etat != ETAT_INACTIF) {
            throw new Exception("L'&eacute;tat doit &ecirc;tre Actif ou Inactif");
        }
    }
}
