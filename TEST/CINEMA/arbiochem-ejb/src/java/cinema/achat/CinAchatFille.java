package cinema.achat;

import bean.ClassFille;
import cinema.utils.CinUtils;
import java.sql.Connection;

/**
 * Ligne d'un achat (table CIN_ACHAT_FILLE) : un film (type FILM, idfilm obligatoire)
 * ou du materiel (type MATERIEL, designation obligatoire).
 */
public class CinAchatFille extends ClassFille {

    public static final String TYPE_FILM = "FILM";
    public static final String TYPE_MATERIEL = "MATERIEL";

    private String id;
    private String idachat;
    private String type;
    private String idfilm;
    private String designation;
    private int qte;
    private double pu;

    public CinAchatFille() throws Exception {
        this.setNomTable("CIN_ACHAT_FILLE");
        this.setNomClasseMere("cinema.achat.CinAchat");
        this.setLiaisonMere("idachat");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CINACF", "GETSEQCINACHATFILLE");
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
    public String getNomClasseMere() {
        return "cinema.achat.CinAchat";
    }

    @Override
    public String getLiaisonMere() {
        return "idachat";
    }

    /**
     * Une ligne laissee vide dans le tableau de saisie (ni film ni designation) est ignoree.
     */
    public boolean estVide() {
        return CinUtils.estVide(idfilm) && CinUtils.estVide(designation);
    }

    public double getMontant() {
        return qte * pu;
    }

    /**
     * Controle d'une ligne ; numero = position de la ligne dans le message d'erreur.
     */
    public void verifier(int numero, Connection c) throws Exception {
        String ligne = "Ligne " + numero + " : ";
        if (CinUtils.estVide(type)) type = CinUtils.estVide(idfilm) ? TYPE_MATERIEL : TYPE_FILM;
        if (TYPE_FILM.equals(type)) {
            if (CinUtils.estVide(idfilm)) throw new Exception(ligne + "choisissez le film achet&eacute;");
            if (CinUtils.entier(c, "select count(*) from CIN_FILM where id = ?", idfilm) == 0) {
                throw new Exception(ligne + "film introuvable");
            }
        } else if (TYPE_MATERIEL.equals(type)) {
            if (CinUtils.estVide(designation)) throw new Exception(ligne + "la d&eacute;signation du mat&eacute;riel est obligatoire");
            idfilm = null;
        } else {
            throw new Exception(ligne + "type inconnu (Film ou Mat&eacute;riel)");
        }
        if (qte <= 0) throw new Exception(ligne + "la quantit&eacute; doit &ecirc;tre sup&eacute;rieure &agrave; 0");
        if (pu < 0) throw new Exception(ligne + "le prix unitaire ne peut pas &ecirc;tre n&eacute;gatif");
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdachat() {
        return idachat;
    }

    public void setIdachat(String idachat) {
        this.idachat = idachat;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getIdfilm() {
        return idfilm;
    }

    public void setIdfilm(String idfilm) {
        this.idfilm = idfilm;
    }

    public String getDesignation() {
        return designation;
    }

    public void setDesignation(String designation) {
        this.designation = designation;
    }

    public int getQte() {
        return qte;
    }

    public void setQte(int qte) {
        this.qte = qte;
    }

    public double getPu() {
        return pu;
    }

    public void setPu(double pu) {
        this.pu = pu;
    }
}
