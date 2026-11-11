package cinema.achat;

import bean.ClassFille;
import bean.ClassMAPTable;
import bean.ClassMere;
import caisse.MvtCaisse;
import cinema.utils.CinUtils;
import constante.ConstanteEtat;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.util.ArrayList;
import java.util.List;

/**
 * Achat de films et de materiel (table CIN_ACHAT, lignes CIN_ACHAT_FILLE).
 * Saisie : etat 1 (cree). Visa : etat 11, sortie d'argent = mouvement de caisse vise (DEBIT) dans MOUVEMENTCAISSE,
 * et le prix d'achat (PA) des films achetes prend le prix de la ligne. Annulation possible seulement avant le visa.
 * L'achat est toujours accepte, meme si la caisse n'a pas assez d'argent (decision du 11/11/2026).
 */
public class CinAchat extends ClassMere {

    public static final String CAISSE_CINEMA = "CAICINEMA";
    public static final String MODE_ESPECE = "0002";

    private String id;
    private Date daty;
    private String fournisseur;
    private String idcaisse;
    private String idmodepaiement;
    private double montant;
    private String remarque;
    private String idmvtcaisse;

    public CinAchat() throws Exception {
        this.setNomTable("CIN_ACHAT");
        this.setNomClasseFille("cinema.achat.CinAchatFille");
        this.setLiaisonFille("idachat");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINACH", "GETSEQCINACHAT");
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
    public String getNomClasseFille() {
        return "cinema.achat.CinAchatFille";
    }

    @Override
    public String getLiaisonFille() {
        return "idachat";
    }

    /**
     * Insertion de l'achat et de ses lignes : les lignes vides du tableau sont retirees,
     * chaque ligne est controlee et le montant de l'achat = somme des lignes.
     */
    @Override
    public ClassMAPTable createObject(String refUser, Connection c) throws Exception {
        List<ClassFille> lignes = new ArrayList<ClassFille>();
        if (getFille() != null) {
            for (ClassFille f : getFille()) {
                if (f != null && !((CinAchatFille) f).estVide()) lignes.add(f);
            }
        }
        if (lignes.isEmpty()) throw new Exception("Ajoutez au moins une ligne (un film ou du mat&eacute;riel)");
        double total = 0;
        for (int i = 0; i < lignes.size(); i++) {
            CinAchatFille ligne = (CinAchatFille) lignes.get(i);
            ligne.verifier(i + 1, c);
            total += ligne.getMontant();
        }
        setFille(lignes.toArray(new ClassFille[0]));
        montant = total;
        setEtat(ConstanteEtat.getEtatCreer());
        if (daty == null) daty = new Date(System.currentTimeMillis());
        verifierEntete(c);
        return super.createObject(refUser, c);
    }

    private void verifierEntete(Connection c) throws Exception {
        if (CinUtils.estVide(fournisseur)) throw new Exception("Le fournisseur est obligatoire");
        if (CinUtils.estVide(idcaisse)) throw new Exception("La caisse est obligatoire");
        if (CinUtils.entier(c, "select count(*) from CAISSE where id = ? and actif = 1", idcaisse) == 0) {
            throw new Exception("La caisse choisie n'existe pas ou est inactive");
        }
        if (CinUtils.estVide(idmodepaiement)) throw new Exception("Le mode de paiement est obligatoire");
        if (CinUtils.entier(c, "select count(*) from MODEPAIEMENT where id = ?", idmodepaiement) == 0) {
            throw new Exception("Mode de paiement inconnu");
        }
        if (montant <= 0) throw new Exception("Le montant de l'achat doit &ecirc;tre sup&eacute;rieur &agrave; 0");
    }

    /**
     * Visa : etat 11, puis sortie de caisse et mise a jour du PA des films, dans la transaction du visa.
     * APJ appelle cette methode sur l'achat recharge depuis la base avec ses lignes.
     */
    @Override
    public Object validerObject(String refUser, Connection c) throws Exception {
        if (getEtat() == ConstanteEtat.getEtatAnnuler()) throw new Exception("Cet achat est annul&eacute;");
        verifierEntete(c);
        Object retour = super.validerObject(refUser, c);
        genererSortieCaisse(refUser, c);
        mettreAJourPaFilms(c);
        return retour;
    }

    /**
     * Mouvement de caisse vise : DEBIT = montant de l'achat, IDORIGINE = id de l'achat.
     * Pas d'ecriture comptable generale (MvtCaisse.validerObject n'est pas appele : il exige un tiers comptable).
     */
    public MvtCaisse genererSortieCaisse(String refUser, Connection c) throws Exception {
        if (!CinUtils.estVide(CinUtils.valeur(c, "select idmvtcaisse from CIN_ACHAT where id = ?", id))) {
            throw new Exception("La sortie de caisse de cet achat existe d&eacute;j&agrave;");
        }
        MvtCaisse mvt = new MvtCaisse();
        mvt.setDesignation("Achat cin&eacute;ma " + id + " - " + fournisseur);
        mvt.setIdCaisse(idcaisse);
        mvt.setDaty(daty);
        mvt.setDebit(montant);
        mvt.setCredit(0);
        mvt.setIdModePaiement(idmodepaiement);
        mvt.setIdOrigine(id);
        mvt.setIdDevise("AR");
        mvt.setTaux(1);
        mvt.setDatycomptabilisation(new Date(System.currentTimeMillis()));
        mvt.setHeure(utilitaire.Utilitaire.heureCouranteHMS());
        mvt.createObject(refUser, c);
        mvt.setEtat(ConstanteEtat.getEtatValider());
        mvt.updateToTableWithHisto(refUser, c);
        try (PreparedStatement ps = c.prepareStatement("update CIN_ACHAT set idmvtcaisse = ? where id = ?")) {
            ps.setString(1, mvt.getId());
            ps.setString(2, id);
            ps.executeUpdate();
        }
        idmvtcaisse = mvt.getId();
        return mvt;
    }

    /**
     * Le prix d'achat (PA) d'un film achete prend le prix unitaire de la ligne.
     */
    private void mettreAJourPaFilms(Connection c) throws Exception {
        try (PreparedStatement ps = c.prepareStatement(
                "update CIN_FILM f set pa = (select max(l.pu) from CIN_ACHAT_FILLE l where l.idachat = ? and l.idfilm = f.id)"
                + " where f.id in (select idfilm from CIN_ACHAT_FILLE where idachat = ? and type = 'FILM')")) {
            ps.setString(1, id);
            ps.setString(2, id);
            ps.executeUpdate();
        }
    }

    /**
     * Annulation (etat 0) : seulement si l'achat n'est pas vise (sinon la sortie de caisse existe deja).
     */
    @Override
    public void controleAnnule(Connection c) throws Exception {
        if (CinUtils.entier(c, "select nvl(max(etat), 0) from CIN_ACHAT where id = ?", id) >= ConstanteEtat.getEtatValider()) {
            throw new Exception("Un achat vis&eacute; ne peut pas &ecirc;tre annul&eacute; (la sortie de caisse est d&eacute;j&agrave; faite)");
        }
        super.controleAnnule(c);
    }

    @Override
    public void controlerDelete(Connection c) throws Exception {
        if (CinUtils.entier(c, "select nvl(max(etat), 0) from CIN_ACHAT where id = ?", id) >= ConstanteEtat.getEtatValider()) {
            throw new Exception("Un achat vis&eacute; ne peut pas &ecirc;tre supprim&eacute;");
        }
        super.controlerDelete(c);
    }

    /**
     * Lignes d'un achat avec titre du film et montant (vue CIN_ACHAT_FILLE_LIB), dans l'ordre de saisie.
     */
    public static CinAchatFilleLib[] getLignes(String idAchat, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new utilitaire.UtilDB().GetConn();
                canClose = true;
            }
            List<CinAchatFilleLib> lignes = new ArrayList<CinAchatFilleLib>();
            try (PreparedStatement ps = c.prepareStatement(
                    "select id, type, typelib, idfilm, idfilmlib, designationlib, qte, pu, montant from CIN_ACHAT_FILLE_LIB where idachat = ? order by id")) {
                ps.setString(1, idAchat);
                try (java.sql.ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        CinAchatFilleLib l = new CinAchatFilleLib();
                        l.setId(rs.getString("id"));
                        l.setIdachat(idAchat);
                        l.setType(rs.getString("type"));
                        l.setTypelib(rs.getString("typelib"));
                        l.setIdfilm(rs.getString("idfilm"));
                        l.setIdfilmlib(rs.getString("idfilmlib"));
                        l.setDesignationlib(rs.getString("designationlib"));
                        l.setQte(rs.getInt("qte"));
                        l.setPu(rs.getDouble("pu"));
                        l.setMontant(rs.getDouble("montant"));
                        lignes.add(l);
                    }
                }
            }
            return lignes.toArray(new CinAchatFilleLib[0]);
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

    public Date getDaty() {
        return daty;
    }

    public void setDaty(Date daty) {
        this.daty = daty;
    }

    public String getFournisseur() {
        return fournisseur;
    }

    public void setFournisseur(String fournisseur) throws Exception {
        if (this.getMode().compareToIgnoreCase("modif") == 0 && CinUtils.estVide(fournisseur)) {
            throw new Exception("Le fournisseur est obligatoire");
        }
        this.fournisseur = fournisseur;
    }

    public String getIdcaisse() {
        return idcaisse;
    }

    public void setIdcaisse(String idcaisse) {
        this.idcaisse = idcaisse;
    }

    public String getIdmodepaiement() {
        return idmodepaiement;
    }

    public void setIdmodepaiement(String idmodepaiement) {
        this.idmodepaiement = idmodepaiement;
    }

    public double getMontant() {
        return montant;
    }

    public void setMontant(double montant) {
        this.montant = montant;
    }

    public String getRemarque() {
        return remarque;
    }

    public void setRemarque(String remarque) {
        this.remarque = remarque;
    }

    public String getIdmvtcaisse() {
        return idmvtcaisse;
    }

    public void setIdmvtcaisse(String idmvtcaisse) {
        this.idmvtcaisse = idmvtcaisse;
    }
}
