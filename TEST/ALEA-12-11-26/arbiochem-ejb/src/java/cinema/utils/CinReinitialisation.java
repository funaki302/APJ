package cinema.utils;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.util.LinkedHashMap;
import java.util.Map;
import utilitaire.UtilDB;

/**
 * Reinitialisation des donnees du cinema (page Cinema > Reinitialiser les donnees).
 * Efface tout sauf la configuration : tickets, paiements, factures, achats, seances, salles et places, films et photos,
 * acteurs, clients crees pour le cinema (CLICIN...), mouvements et reports de la Caisse Cinema
 * (+ mouvements de caisse dont l'origine est une piece du cinema).
 * Garde : cinema, classes de place, categories, parametres, caisses par mode, Caisse Cinema, menus, et tout le reste
 * de l'application. Une seule transaction : si une etape echoue, rien n'est efface.
 * Les suppressions se font en SQL : la suppression APJ (deleteToTable) ferait un commit au milieu.
 */
public class CinReinitialisation {

    /** { libelle, requete de suppression, requete de comptage } dans l'ordre des cles etrangeres */
    private static final String[][] ETAPES = {
        {"Mouvements de caisse du cin&eacute;ma", "delete from MOUVEMENTCAISSE where idorigine like 'CIN%' or idcaisse = 'CAICINEMA'",
                "select count(*) from MOUVEMENTCAISSE where idorigine like 'CIN%' or idcaisse = 'CAICINEMA'"},
        {"Reports de la Caisse Cin&eacute;ma", "delete from REPORTCAISSE where idcaisse = 'CAICINEMA'",
                "select count(*) from REPORTCAISSE where idcaisse = 'CAICINEMA'"},
        {"Lignes de facture", "delete from CIN_FACTURE_DETAIL", "select count(*) from CIN_FACTURE_DETAIL"},
        {"Factures", "delete from CIN_FACTURE", "select count(*) from CIN_FACTURE"},
        {"Lignes de paiement", "delete from CIN_PAIEMENT_DETAIL", "select count(*) from CIN_PAIEMENT_DETAIL"},
        {"Paiements", "delete from CIN_PAIEMENT", "select count(*) from CIN_PAIEMENT"},
        {"Places r&eacute;serv&eacute;es", "delete from CIN_TICKET_DETAIL", "select count(*) from CIN_TICKET_DETAIL"},
        {"Tickets (r&eacute;servations)", "delete from CIN_TICKET", "select count(*) from CIN_TICKET"},
        {"S&eacute;ances", "delete from CIN_DIFFUSION", "select count(*) from CIN_DIFFUSION"},
        {"Lignes d'achat", "delete from CIN_ACHAT_FILLE", "select count(*) from CIN_ACHAT_FILLE"},
        {"Achats", "delete from CIN_ACHAT", "select count(*) from CIN_ACHAT"},
        {"Photos des films", "delete from CIN_FILM_PHOTO", "select count(*) from CIN_FILM_PHOTO"},
        {"Films", "delete from CIN_FILM", "select count(*) from CIN_FILM"},
        {"Acteurs", "delete from CIN_ACTEUR", "select count(*) from CIN_ACTEUR"},
        {"Places des salles", "delete from CIN_PLACE", "select count(*) from CIN_PLACE"},
        {"Salles", "delete from CIN_SALLE", "select count(*) from CIN_SALLE"},
        {"Clients cr&eacute;&eacute;s pour le cin&eacute;ma (CLICIN...)", "delete from CLIENT where id like 'CLICIN%'",
                "select count(*) from CLIENT where id like 'CLICIN%'"},
    };

    /**
     * Nombre de lignes concernees par etape (avant de reinitialiser).
     */
    public static Map<String, Integer> apercu(Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                canClose = true;
            }
            Map<String, Integer> res = new LinkedHashMap<String, Integer>();
            for (String[] e : ETAPES) res.put(e[0], CinUtils.entier(c, e[2]));
            return res;
        } finally {
            if (canClose) c.close();
        }
    }

    /**
     * Efface les donnees du cinema dans la transaction de l'appelant (pas de commit). Retourne les lignes effacees par etape.
     */
    public static Map<String, Integer> reinitialiser(Connection c) throws Exception {
        Map<String, Integer> res = new LinkedHashMap<String, Integer>();
        for (String[] e : ETAPES) {
            try (PreparedStatement ps = c.prepareStatement(e[1])) {
                res.put(e[0], ps.executeUpdate());
            } catch (Exception ex) {
                throw new Exception("&Eacute;tape &laquo; " + e[0] + " &raquo; impossible : " + ex.getMessage()
                        + " (rien n'a &eacute;t&eacute; effac&eacute;)");
            }
        }
        return res;
    }

    /**
     * Reinitialise (et, si scriptDemo n'est pas vide, recharge les donnees de demonstration) dans une seule transaction,
     * puis remet a 1 le compteur des numeros de facture.
     */
    public static Map<String, Integer> executer(String scriptDemo) throws Exception {
        Connection c = null;
        Map<String, Integer> res;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            res = reinitialiser(c);
            if (!CinUtils.estVide(scriptDemo)) {
                res.put("Instructions du script de donn&eacute;es ex&eacute;cut&eacute;es", CinScriptSql.executer(scriptDemo, c));
            }
            c.commit();
        } catch (Exception e) {
            if (c != null) c.rollback();
            throw e;
        } finally {
            if (c != null) c.close();
        }
        remettreNumerosFacture();
        return res;
    }

    /**
     * Plus aucune facture numerotee : les numeros repartent de FCaaaa-00001 (DDL, donc hors transaction).
     */
    private static void remettreNumerosFacture() {
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            if (CinUtils.entier(c, "select count(*) from CIN_FACTURE where numero not like '%-D%'") > 0) return;
            try (Statement st = c.createStatement()) {
                st.execute("drop sequence SEQ_CIN_FACTURE_NUMERO");
                st.execute("create sequence SEQ_CIN_FACTURE_NUMERO start with 1 increment by 1 nocache");
            }
        } catch (Exception e) {
            System.out.println("Cinema : compteur des factures non remis a 1 (" + e.getMessage() + ")");
        } finally {
            if (c != null) try { c.close(); } catch (Exception ignore) { }
        }
    }
}
