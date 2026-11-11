package annexe;

import bean.TypeObjet;
import java.sql.Connection;

public class Categorieexercice extends TypeObjet{

    String idExercice;
    String val;
    String desce;

    public Categorieexercice() {
        this.setNomTable("CATEGORIEEXERCICE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CTE", "getSeqCategorieExercice");
        this.setId(makePK(c));
    }

    public String getIdExercice() {
        return idExercice;
    }

    public void setIdExercice(String idExercice) {
        this.idExercice = idExercice;
    }

    public String getVal() {
        return val;
    }

    public void setVal(String val) {
        this.val = val;
    }

    public String getDesce() {
        return desce;
    }

    public void setDesce(String desce) {
        this.desce = desce;
    }

//    @Override
//    public String getAttributIDName() {
//        return "idExercice";
//    }
//
//    @Override
//    public  String getTuppleID(){
//        return idExercice;
//    }
}