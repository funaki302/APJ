package avoir;

import bean.AdminGen;
import bean.CGenUtil;
import mg.cnaps.compta.ComptaEcriture;
import mg.cnaps.compta.ComptaLettrage;
import mg.cnaps.compta.ComptaSousEcriture;
import paiement.LiaisonPaiement;
import utilitaire.UtilDB;
import vente.FactureCF;
import vente.VenteLib;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Imputation automatique des avoirs clients (AvoirFC) sur une facture client (Vente).
 *
 * Meme mecanisme que le paiement manuel "Payer par Ristourne/Avoir" (LiaisonPaiement.creerPaiementFacture) :
 * une LiaisonPaiement (id1 = avoir, id2 = facture, montant) par avoir consomme. Les vues existantes
 * en tiennent compte : VENTE_CPL.MONTANTRESTE baisse (LIAISONPAIEMENTTOTAL) et
 * AVOIRFCLIB_CPL.RESTEAPAYERAR baisse (MOUVEMENTCAISSEGRPAVOIR_LP), donc le solde d'avoir restant
 * est reporte tout seul sur les factures suivantes jusqu'a epuisement.
 */
public class ImputationAvoirFC {

    public static final String VUE_AVOIR_RESTE = "AVOIRFCLIB_CPL";
    public static final String DEVISE_AR = "AR";
    public static final String TABLE_NON_APPLIQUE = "VENTE_AVOIR_NON_APPLIQUE";

    /**
     * Avoirs vises du client ayant encore un reste a utiliser, du plus ancien au plus recent (FIFO).
     */
    public static AvoirFCLib[] getAvoirsDisponibles(String idClient, Connection c) throws Exception {
        if (idClient == null || idClient.trim().isEmpty()) return new AvoirFCLib[0];
        AvoirFCLib crt = new AvoirFCLib();
        crt.setNomTable(VUE_AVOIR_RESTE);
        String awhere = " and idClient = '" + idClient.replace("'", "''") + "' and etat >= 11 and resteapayerar > 0 order by daty asc, id asc";
        return (AvoirFCLib[]) CGenUtil.rechercher(crt, null, null, c, awhere);
    }

    public static double getSoldeAvoirClient(String idClient, Connection c) throws Exception {
        AvoirFCLib[] avoirs = getAvoirsDisponibles(idClient, c);
        if (avoirs.length == 0) return 0;
        return arrondir(AdminGen.calculSommeDouble(avoirs, "resteapayerar"));
    }

    /**
     * Montant qui serait impute sur une facture de montant donne, sans rien ecrire (affichage saisie / fiche).
     */
    public static double simulerImputation(String idClient, double montantFacture, Connection c) throws Exception {
        if (montantFacture <= 0) return 0;
        return arrondir(Math.min(getSoldeAvoirClient(idClient, c), montantFacture));
    }

    /**
     * Total des avoirs deja imputes (liaisons visees) sur une facture.
     */
    public static double getMontantAvoirImpute(String idVente, Connection c) throws Exception {
        LiaisonPaiement crt = new LiaisonPaiement();
        String awhere = " and id2 = '" + idVente.replace("'", "''") + "' and etat >= 11 and id1 in (select id from AVOIRFC)";
        LiaisonPaiement[] liaisons = (LiaisonPaiement[]) CGenUtil.rechercher(crt, null, null, c, awhere);
        if (liaisons.length == 0) return 0;
        return arrondir(AdminGen.calculSommeDouble(liaisons, "montant"));
    }

    /**
     * Impute les avoirs disponibles du client sur la facture (a appeler lors du visa, dans la transaction du visa).
     * Ne fait pas de commit : c'est l'appelant (visa) qui valide ou annule tout.
     *
     * @return le montant total impute
     */
    public static double imputerSurFacture(String idVente, String u, Connection c) throws Exception {
        // le client a choisi de garder son avoir pour une autre facture
        if (estAvoirNonApplique(idVente, c)) return 0;
        VenteLib[] ventes = (VenteLib[]) CGenUtil.rechercher(new VenteLib(), null, null, c, " and id = '" + idVente.replace("'", "''") + "'");
        if (ventes.length == 0) throw new Exception("Facture " + idVente + " introuvable pour l'imputation des avoirs");
        VenteLib vente = ventes[0];
        // les restes d'avoir sont en Ariary : on n'impute que sur une facture en Ariary
        if (vente.getIdDevise() != null && !vente.getIdDevise().trim().isEmpty()
                && vente.getIdDevise().trim().compareToIgnoreCase(DEVISE_AR) != 0) {
            return 0;
        }
        double resteFacture = arrondir(vente.getMontantreste());
        if (resteFacture <= 0) return 0;

        AvoirFCLib[] avoirs = getAvoirsDisponibles(vente.getIdClient(), c);
        double totalImpute = 0;
        for (AvoirFCLib avoir : avoirs) {
            if (resteFacture <= 0) break;
            double disponible = arrondir(avoir.getResteapayerar());
            if (disponible <= 0) continue;
            double montant = arrondir(Math.min(disponible, resteFacture));

            LiaisonPaiement liaison = new LiaisonPaiement();
            liaison.setId1(avoir.getId());
            liaison.setId2(idVente);
            liaison.setMontant(montant);
            liaison.createObject(u, c);
            liaison.validerObject(u, c);

            lettrer(avoir.getId(), idVente, u, c);

            resteFacture = arrondir(resteFacture - montant);
            totalImpute = arrondir(totalImpute + montant);
        }
        return totalImpute;
    }

    /**
     * Lettrage comptable entre la ligne client (compte 411 + compte auxiliaire) de la facture et celle de l'avoir,
     * comme AvoirFC.genererLettrage le fait avec la facture d'origine.
     * Si la ligne de l'avoir est deja lettree (ex: avec sa facture d'origine), on ne l'ecrase pas.
     */
    public static void lettrer(String idAvoir, String idVente, String u, Connection c) throws Exception {
        ComptaSousEcriture seVente = getSousEcritureTiers(idVente, c);
        ComptaSousEcriture seAvoir = getSousEcritureTiers(idAvoir, c);
        if (seVente == null || seAvoir == null) return;
        if (seAvoir.getLettrage() != null && !seAvoir.getLettrage().trim().isEmpty()) return;
        new ComptaLettrage().createLettrageCSEMF(new String[]{seVente.getId(), seAvoir.getId()}, null, u, c);
    }

    private static ComptaSousEcriture getSousEcritureTiers(String idObjet, Connection c) throws Exception {
        ComptaEcriture ecriture = FactureCF.getEcritureAvecFille(idObjet, null, null, c);
        if (ecriture == null || ecriture.getFille() == null) return null;
        for (ComptaSousEcriture se : (ComptaSousEcriture[]) ecriture.getFille()) {
            if (se.getCompte_aux() != null && !se.getCompte_aux().trim().isEmpty()) return se;
        }
        return null;
    }

    /**
     * Vrai si on a coche "Ne pas appliquer l'avoir" pour cette facture (table VENTE_AVOIR_NON_APPLIQUE).
     * Table absente (script data/avoir-fc.sql pas encore joue) : l'avoir est applique comme avant.
     */
    public static boolean estAvoirNonApplique(String idVente, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                canClose = true;
            }
            try (PreparedStatement ps = c.prepareStatement("select count(*) from " + TABLE_NON_APPLIQUE + " where idvente = ?")) {
                ps.setString(1, idVente);
                try (ResultSet rs = ps.executeQuery()) {
                    return rs.next() && rs.getInt(1) > 0;
                }
            } catch (SQLException e) {
                if (e.getErrorCode() != 942) throw e;
                System.out.println("Table " + TABLE_NON_APPLIQUE + " absente : executer data/avoir-fc.sql");
                return false;
            }
        } finally {
            if (canClose) c.close();
        }
    }

    /**
     * Enregistre le choix fait au visa : nePasAppliquer = true -> l'avoir du client n'est pas deduit de cette facture.
     */
    public static void setAvoirNonApplique(String idVente, boolean nePasAppliquer, String u, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                c.setAutoCommit(false);
                canClose = true;
            }
            try (PreparedStatement ps = c.prepareStatement("delete from " + TABLE_NON_APPLIQUE + " where idvente = ?")) {
                ps.setString(1, idVente);
                ps.executeUpdate();
            }
            if (nePasAppliquer) {
                try (PreparedStatement ps = c.prepareStatement("insert into " + TABLE_NON_APPLIQUE + " (idvente, daty, iduser) values (?, sysdate, ?)")) {
                    ps.setString(1, idVente);
                    ps.setString(2, u);
                    ps.executeUpdate();
                }
            }
            if (canClose) c.commit();
        } catch (Exception e) {
            if (canClose && c != null) c.rollback();
            throw e;
        } finally {
            if (canClose && c != null) c.close();
        }
    }

    private static double arrondir(double valeur) {
        return Math.round(valeur * 100.0) / 100.0;
    }
}
