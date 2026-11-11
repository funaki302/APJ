package vente;

import utilitaire.UtilDB;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Remise a zero des donnees clients : clients, factures (VENTE), avoirs (AVOIRFC) et tout ce qui en depend.
 *
 * Conserves : produits (AS_INGREDIENTS...), tarifs, remises, magasins, caisses, utilisateurs, menus,
 * fournisseurs et achats. Les mouvements de stock et de caisse sont conserves (soldes inchanges)
 * mais detaches des ventes / clients supprimes.
 *
 * Tout est fait dans une seule transaction : en cas d'erreur, rien n'est supprime.
 */
public class ReinitialisationVente {

    static final String VENTES = "(select id from VENTE)";
    static final String VENTES_AVOIRS = "(select id from VENTE union all select id from AVOIRFC)";
    static final String ECRITURES = "(select id from COMPTA_ECRITURE where idobjet in " + VENTES_AVOIRS + ")";
    static final String PREVISIONS = "(select id from PREVISION where idfacture in " + VENTES_AVOIRS + " or idfacture in (select id from VENTE_DETAILS) or idventedetail in (select id from VENTE_DETAILS))";
    static final String ENCAISSEMENTS = "(select id from ENCAISSEMENT where idclient is not null or idorigine in " + VENTES_AVOIRS + ")";
    static final String PRECISIONS = "(select id from PRECISION_DETAIL_ENCAISSEMENT where idclient is not null or idencaissement in " + ENCAISSEMENTS + ")";
    static final String CHEQUES = "(select id from CHEQUE where idclient is not null or idprecisiondetailencaissement in " + PRECISIONS + ")";
    static final String RESERVATIONS = "(select id from RESERVATION where idclient is not null)";
    static final String CHECKINS = "(select id from CHECKIN where idclient is not null or client is not null or reservation in " + RESERVATIONS + ")";
    static final String FACTURECLIENTS = "(select id from FACTURECLIENT where idclient is not null or idreservation in " + RESERVATIONS + ")";

    /** Etapes dans l'ordre d'execution (enfants avant parents). */
    static final String[][] ETAPES = {
        // 1) detacher stock / caisse / fabrication (on garde les mouvements)
        {"Stock : detacher les lignes de mouvement des ventes", "update MVTSTOCKFILLE set idventedetail = null where idventedetail is not null"},
        {"Stock : detacher les mouvements des ventes", "update MVTSTOCK set idvente = null where idvente is not null"},
        {"Caisse : detacher les lignes de vente", "update MOUVEMENTCAISSE set idventedetail = null where idventedetail is not null"},
        {"Caisse : detacher les previsions de factures", "update MOUVEMENTCAISSE set idprevision = null where idprevision in " + PREVISIONS},
        {"Caisse : detacher l'origine facture/avoir", "update MOUVEMENTCAISSE set idorigine = null where idorigine in " + VENTES_AVOIRS},
        {"Caisse : detacher le tiers client", "update MOUVEMENTCAISSE set idtiers = null where idtiers in (select id from CLIENT)"},
        {"Caisse : detacher le tiers client (mere)", "update MOUVEMENTCAISSEMERE set idtiers = null where idtiers in (select id from CLIENT)"},
        {"Fabrication : detacher les lignes de bon de commande client", "update FABRICATIONFILLE set idbcfille = null where idbcfille in (select id from BONDECOMMANDE_CLIENT_FILLE)"},
        {"OF : detacher les lignes de bon de commande client", "update OFFILLE set idbcfille = null where idbcfille in (select id from BONDECOMMANDE_CLIENT_FILLE)"},
        {"Travaux : detacher les lignes de bon de commande client", "update TRAVAUXFILLE set idbcfille = null where idbcfille in (select id from BONDECOMMANDE_CLIENT_FILLE)"},
        {"Ordre travaux : detacher les lignes de bon de commande client", "update ORDRETRAVAUXFILLE set idbcfille = null where idbcfille in (select id from BONDECOMMANDE_CLIENT_FILLE)"},
        {"Fabrication : detacher les bons de commande client", "update FABRICATION set idbc = null where idbc in (select id from BONDECOMMANDE_CLIENT)"},
        {"OF : detacher les bons de commande client", "update OFAB set idbc = null where idbc in (select id from BONDECOMMANDE_CLIENT)"},
        {"Travaux : detacher les bons de commande client", "update TRAVAUX set idbc = null where idbc in (select id from BONDECOMMANDE_CLIENT)"},
        {"Vente lubrifiant : detacher les encaissements clients", "update VENTELUBRIFIANT set idencaissement = null where idencaissement in " + ENCAISSEMENTS},

        // 2) paiements / imputations (avoirs, avances, caisse) des factures et avoirs
        {"Liaisons de paiement des factures et avoirs", "delete from LIAISONPAIEMENT where id1 in " + VENTES_AVOIRS + " or id2 in " + VENTES_AVOIRS},

        // 3) encaissements / cheques clients
        {"Details de versement des cheques clients", "delete from VERSEMENTCHEQUEDETAILS where idcheque in " + CHEQUES},
        {"Cheques clients", "delete from CHEQUE where id in " + CHEQUES},
        {"Details bon de caisse clients", "delete from DETAILSBONCAISSE where idclient is not null or idprecisiondetailencaissement in " + PRECISIONS},
        {"Precisions d'encaissement clients", "delete from PRECISION_DETAIL_ENCAISSEMENT where id in " + PRECISIONS},
        {"Details d'encaissement clients", "delete from ENCAISSEMENT_DETAILS where idencaissement in " + ENCAISSEMENTS},
        {"Prelevements encaisses clients", "delete from PRELEVEMENT_ENCAISSE where idencaissement in " + ENCAISSEMENTS},
        {"Encaissements clients", "delete from ENCAISSEMENT where id in " + ENCAISSEMENTS},

        // 4) ecritures comptables des factures et avoirs (+ lettrages)
        {"Compta : delettrer les lignes conservees", "update COMPTA_SOUS_ECRITURE set lettrage = null where lettrage in (select lettrage from COMPTA_SOUS_ECRITURE where idmere in " + ECRITURES + ") and (idmere is null or idmere not in " + ECRITURES + ")"},
        {"Compta : lettrages des factures et avoirs", "delete from COMPTA_LETTRAGE where id in (select lettrage from COMPTA_SOUS_ECRITURE where idmere in " + ECRITURES + ")"},
        {"Compta : lignes d'ecriture des factures et avoirs", "delete from COMPTA_SOUS_ECRITURE where idmere in " + ECRITURES},
        {"Compta : ecritures des factures et avoirs", "delete from COMPTA_ECRITURE where idobjet in " + VENTES_AVOIRS},

        // 5) previsions (plans de paiement) des factures et avoirs
        {"Previsions scindees", "delete from SCINDERPREVISION where idprevision in " + PREVISIONS},
        {"Previsions multipliees", "delete from MULTIPLICATION_PREVISION where idprevision in " + PREVISIONS},
        {"Liens caisse / prevision", "delete from MVTCAISSEPREVISION where id2 in " + PREVISIONS},
        {"Previsions des factures et avoirs", "delete from PREVISION where idfacture in " + VENTES_AVOIRS + " or idfacture in (select id from VENTE_DETAILS) or idventedetail in (select id from VENTE_DETAILS)"},

        // 6) pieces rattachees aux factures / avoirs
        {"References de facture", "delete from REFERENCEFACTURE where idfacture in " + VENTES},
        {"Commissions sur factures", "delete from COMMISSION where idfacture in " + VENTES},
        {"Fichiers attaches aux factures et avoirs", "delete from ATTACHER_FICHIER where mere in " + VENTES_AVOIRS},

        // 7) ristournes et avoirs
        {"Ristournes (factures)", "delete from RISTOURNEFACTURE"},
        {"Ristournes (details)", "delete from RISTOURNEDETAILS"},
        {"Ristournes", "delete from RISTOURNE"},
        {"Avoirs (details)", "delete from AVOIRFCFILLE"},
        {"Avoirs", "delete from AVOIRFC"},

        // 8) stock engage, livraisons et factures
        {"Stock engage (details)", "delete from STOCK_ENGAGE_FILLE where idmvtstock in (select id from STOCK_ENGAGE where idvente is not null) or idventedetail is not null"},
        {"Stock engage", "delete from STOCK_ENGAGE where idvente is not null"},
        {"Cartons des commandes / livraisons clients", "delete from CARTON where idbc in (select id from BONDECOMMANDE_CLIENT) or idbl in (select id from AS_BONDELIVRAISON_CLIENT)"},
        {"Bons de livraison client (details)", "delete from AS_BONDELIVRAISON_CLIENT_FILLE"},
        {"Bons de livraison client", "delete from AS_BONDELIVRAISON_CLIENT"},
        {"Livraisons des factures", "delete from LIVRAISON where idvente is not null"},
        {"Choix \"ne pas appliquer l'avoir\"", "delete from VENTE_AVOIR_NON_APPLIQUE"},
        {"Factures (details)", "delete from VENTE_DETAILS"},
        {"Factures", "delete from VENTE"},

        // 9) autres documents clients
        {"Bons de commande client (details)", "delete from BONDECOMMANDE_CLIENT_FILLE"},
        {"Bons de commande client", "delete from BONDECOMMANDE_CLIENT"},
        {"Proformas (details)", "delete from PROFORMA_DETAILS"},
        {"Proformas", "delete from PROFORMA"},
        {"Commandes client (details)", "delete from COMMANDEFILLE where idc in (select id from COMMANDE where idclient is not null)"},
        {"Commandes client", "delete from COMMANDE where idclient is not null"},
        {"Check-out", "delete from CHECKOUT where reservation in " + CHECKINS},
        {"Check-in", "delete from CHECKIN where id in " + CHECKINS},
        {"Actes clients", "delete from ACTE where idclient is not null or idreservation in " + RESERVATIONS},
        {"Factures de reservation (details)", "delete from FACTURECLIENTDETAILS where idfactureclient in " + FACTURECLIENTS},
        {"Factures de reservation", "delete from FACTURECLIENT where id in " + FACTURECLIENTS},
        {"Reservations (details)", "delete from RESERVATIONDETAILS where idmere in " + RESERVATIONS},
        {"Reservations", "delete from RESERVATION where idclient is not null"},
        {"Paiements de bons clients", "delete from PAIEMENTBON where idclient is not null"},

        // 10) clients
        {"Clients", "delete from CLIENT"},
    };

    /** Tables comptees sur la page de confirmation. */
    static final String[][] APERCU = {
        {"Clients", "select count(*) from CLIENT"},
        {"Factures", "select count(*) from VENTE"},
        {"Avoirs", "select count(*) from AVOIRFC"},
        {"Liaisons de paiement (factures / avoirs)", "select count(*) from LIAISONPAIEMENT where id1 in " + VENTES_AVOIRS + " or id2 in " + VENTES_AVOIRS},
        {"Bons de commande client", "select count(*) from BONDECOMMANDE_CLIENT"},
        {"Bons de livraison client", "select count(*) from AS_BONDELIVRAISON_CLIENT"},
        {"Proformas", "select count(*) from PROFORMA"},
        {"Ristournes", "select count(*) from RISTOURNE"},
        {"Ecritures comptables (factures / avoirs)", "select count(*) from COMPTA_ECRITURE where idobjet in " + VENTES_AVOIRS},
        {"Mouvements de stock detaches (conserves)", "select count(*) from MVTSTOCK where idvente is not null"},
        {"Mouvements de caisse detaches (conserves)", "select count(*) from MOUVEMENTCAISSE where idorigine in " + VENTES_AVOIRS + " or idtiers in (select id from CLIENT)"},
    };

    // ORA-00942 : table ou vue inexistante, ORA-00904 : colonne inexistante -> etape ignoree (base sans ce module)
    static boolean estObjetAbsent(SQLException e) {
        return e.getErrorCode() == 942 || e.getErrorCode() == 904;
    }

    public static Map<String, Integer> apercu() throws Exception {
        Map<String, Integer> resultat = new LinkedHashMap<>();
        Connection c = null;
        Statement st = null;
        try {
            c = new UtilDB().GetConn();
            st = c.createStatement();
            for (String[] ligne : APERCU) {
                try (ResultSet rs = st.executeQuery(ligne[1])) {
                    resultat.put(ligne[0], rs.next() ? rs.getInt(1) : 0);
                } catch (SQLException e) {
                    if (!estObjetAbsent(e)) throw e;
                }
            }
            return resultat;
        } finally {
            if (st != null) st.close();
            if (c != null) c.close();
        }
    }

    /**
     * Execute toutes les etapes dans une transaction.
     *
     * @return nombre de lignes touchees par etape (-1 = etape ignoree car table absente)
     */
    public static Map<String, Integer> reinitialiser(String u) throws Exception {
        Map<String, Integer> resultat = new LinkedHashMap<>();
        Connection c = null;
        Statement st = null;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            st = c.createStatement();
            for (String[] etape : ETAPES) {
                try {
                    resultat.put(etape[0], st.executeUpdate(etape[1]));
                } catch (SQLException e) {
                    if (!estObjetAbsent(e)) {
                        throw new Exception("Réinitialisation annulée à l'étape \"" + etape[0] + "\" : " + e.getMessage(), e);
                    }
                    resultat.put(etape[0], -1);
                }
            }
            c.commit();
            System.out.println("Reinitialisation clients/factures/avoirs effectuee par " + u + " : " + resultat);
            return resultat;
        } catch (Exception e) {
            if (c != null) c.rollback();
            throw e;
        } finally {
            if (st != null) st.close();
            if (c != null) c.close();
        }
    }
}
