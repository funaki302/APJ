package cinema.achat;

/**
 * Lecture d'une ligne d'achat avec le titre du film et le montant de la ligne (vue CIN_ACHAT_FILLE_LIB).
 */
public class CinAchatFilleLib extends CinAchatFille {

    private String typelib;
    private String idfilmlib;
    private String designationlib;
    private double montant;

    public CinAchatFilleLib() throws Exception {
        this.setNomTable("CIN_ACHAT_FILLE_LIB");
    }

    public String getTypelib() {
        return typelib;
    }

    public void setTypelib(String typelib) {
        this.typelib = typelib;
    }

    public String getIdfilmlib() {
        return idfilmlib;
    }

    public void setIdfilmlib(String idfilmlib) {
        this.idfilmlib = idfilmlib;
    }

    public String getDesignationlib() {
        return designationlib;
    }

    public void setDesignationlib(String designationlib) {
        this.designationlib = designationlib;
    }

    @Override
    public double getMontant() {
        return montant;
    }

    public void setMontant(double montant) {
        this.montant = montant;
    }
}
