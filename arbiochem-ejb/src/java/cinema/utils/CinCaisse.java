package cinema.utils;

import caisse.MvtCaisse;
import constante.ConstanteEtat;
import java.sql.Connection;
import java.sql.Date;

/**
 * Mouvements de caisse du cinema dans la table existante MOUVEMENTCAISSE (classe caisse.MvtCaisse).
 * Le mouvement est cree puis passe a l'etat vise (11), sans ecriture comptable generale :
 * MvtCaisse.validerObject n'est pas appele (il exige un tiers avec compte comptable, journal et lettrage).
 */
public class CinCaisse {

    /**
     * Caisses actives : { id, libelle } triees par libelle (listes deroulantes du paiement).
     */
    public static String[][] getCaissesActives(Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new utilitaire.UtilDB().GetConn();
                canClose = true;
            }
            java.util.List<String[]> caisses = new java.util.ArrayList<String[]>();
            try (java.sql.PreparedStatement ps = c.prepareStatement("select id, val from CAISSE where actif = 1 order by upper(val)");
                 java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) caisses.add(new String[]{rs.getString(1), rs.getString(2)});
            }
            return caisses.toArray(new String[0][]);
        } finally {
            if (canClose) c.close();
        }
    }

    /**
     * Cree un mouvement vise : debit = sortie d'argent (achat), credit = entree (paiement de ticket).
     * idOrigine = id de la piece du cinema (achat, paiement). Pas de commit.
     */
    public static MvtCaisse creerMouvementVise(String designation, String idCaisse, Date daty, double debit, double credit,
                                               String idModePaiement, String idOrigine, String idTiers, String refUser, Connection c) throws Exception {
        MvtCaisse mvt = new MvtCaisse();
        mvt.setDesignation(designation);
        mvt.setIdCaisse(idCaisse);
        mvt.setDaty(daty);
        mvt.setDebit(debit);
        mvt.setCredit(credit);
        mvt.setIdModePaiement(idModePaiement);
        mvt.setIdOrigine(idOrigine);
        if (!CinUtils.estVide(idTiers)) mvt.setIdTiers(idTiers);
        mvt.setIdDevise("AR");
        mvt.setTaux(1);
        mvt.setDatycomptabilisation(new Date(System.currentTimeMillis()));
        mvt.setHeure(utilitaire.Utilitaire.heureCouranteHMS());
        mvt.createObject(refUser, c);
        mvt.setEtat(ConstanteEtat.getEtatValider());
        mvt.updateToTableWithHisto(refUser, c);
        return mvt;
    }
}
