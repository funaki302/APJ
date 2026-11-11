package ferme.configuration;

import bean.ClassMAPTable;
import java.sql.Connection;

/**
 *
 * @author Safidy
 */
public class Parquet extends ClassMAPTable {
    private String id;
    private String val;
    private String desce;
    private double capacite;

    public Parquet() {
        super.setNomTable("PARQUET");
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    public String getId(){
        return id;
    }
    public void setId(String id){
        this.id = id;
    }
    public String getVal(){
        return val;
    }
    public void setVal(String val){
        this.val = val;
    }
    public String getDesce(){
        return desce;
    }
    public void setDesce(String desce){
        this.desce = desce;
    }
    public double getCapacite(){
        return capacite;
    }
    public void setCapacite(double capacite) throws Exception{
        if(capacite > 0){
            this.capacite = capacite;
        }else{
            throw new Exception("Capacite doit etre > 0");
        }
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        super.setNomTable("PARQUET");
        this.preparePk("PRQ", "GETSEQPARQUET");
        this.setId(this.makePK(c));
    }
}