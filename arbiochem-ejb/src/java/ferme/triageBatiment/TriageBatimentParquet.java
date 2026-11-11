package ferme.triageBatiment;

import bean.CGenUtil;
import bean.ClassMAPTable;
import bean.ClassMere;
import ferme.configuration.Parquet;
import ferme.receptionaeroport.ReceptionPoussinAeroport;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.LinkedHashMap;
import java.util.Map;

public class TriageBatimentParquet extends ClassMere {
    private String id;
    private Date daty;
    private String idlot;
    private String idRfa;
    private double qterecus;
    private double perdus;
    private int morts;
    private int dispomale;
    private int dispofemelle, etat;

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

    public String getIdlot() {
        return idlot;
    }

    public void setIdlot(String idlot) {
        this.idlot = idlot;
    }

    public String getIdRfa() {
        return idRfa;
    }

    public void setIdRfa(String idRfa) {
        this.idRfa = idRfa;
    }

    public double getQterecus() {
        return qterecus;
    }

    public void setQterecus(double qterecus) {
        this.qterecus = qterecus;
    }

    public double getPerdus() {
        return perdus;
    }

    public void setPerdus(double perdus) {
        this.perdus = perdus;
    }

    public int getMorts() {
        return morts;
    }

    public void setMorts(int morts) {
        this.morts = morts;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }

    public int getDispomale() {
        return dispomale;
    }

    public void setDispomale(int dispomale) {
        this.dispomale = dispomale;
    }

    public int getDispofemelle() {
        return dispofemelle;
    }

    public void setDispofemelle(int dispofemelle) {
        this.dispofemelle = dispofemelle;
    }

    public TriageBatimentParquet() throws Exception {
        this.setNomTable("TRIAGEBATIMENTPARQUET");
        this.setNomClasseFille("ferme.triageBatiment.TriageBatimentParquetDetail");
        this.setLiaisonFille("idmere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("TB", "getseq_triagebatimentparquet");
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
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        if (idRfa == null || idRfa.trim().isEmpty()) {
            throw new Exception("La reception aeroport est obligatoire");
        }
        idRfa = idRfa.trim();
        ReceptionPoussinAeroport critereReception = new ReceptionPoussinAeroport();
        critereReception.setId(idRfa);
        ReceptionPoussinAeroport[] receptions = (ReceptionPoussinAeroport[]) CGenUtil.rechercher(
            critereReception, null, null, c,
            "");
        if (receptions == null || receptions.length != 1) {
            throw new Exception("La reception aeroport selectionnee est introuvable");
        }
        ReceptionPoussinAeroport reception = receptions[0];
        if (reception.getIdLot() == null || reception.getIdLot().trim().isEmpty()) {
            throw new Exception("La reception selectionnee n'est pas liee a un lot");
        }

        // La quantite theorique du triage est le nombre de poussins vivants
        // a la sortie de la reception aeroport.
        this.idRfa = reception.getId();
        this.idlot = reception.getIdLot();
        if (reception.getQteRecus() < 0 || reception.getMorts() < 0
                || reception.getMorts() > reception.getQteRecus()) {
            throw new Exception("Les quantites de la reception aeroport sont invalides");
        }
        this.qterecus = reception.getQteRecus() - reception.getMorts();
        if (this.morts < 0) {
            throw new Exception("Le nombre de morts au triage ne peut pas etre negatif");
        }
        if (this.perdus < 0) {
            throw new Exception("Le nombre de pertes au triage ne peut pas etre negatif");
        }
        double quantiteVivanteRestante = this.qterecus - this.morts - this.perdus;
        if (quantiteVivanteRestante < 0) {
            throw new Exception("Les morts et les pertes au triage depassent la quantite theorique vivante");
        }

        TriageBatimentParquetDetail[] details = (TriageBatimentParquetDetail[]) this.getFille();
        double quantiteTriagee = 0;
        // Pour voir si un meme parquet est vise par un meme sexe
        Map<String, Double> quantiteParParquet = new LinkedHashMap<String, Double>();
        Map<String, String> sexeParParquet = new LinkedHashMap<String, String>();

        if (details != null) {
            for (TriageBatimentParquetDetail detail : details) {
                if (detail == null) {
                    continue;
                }
                if (detail.getSante() < 1 || detail.getSante() > 10) {
                    throw new Exception("La sante doit etre comprise entre 1 et 10");
                }
                boolean ligneRenseignee = detail.getQte() != 0
                        || !estVide(detail.getIdbatiment())
                        || !estVide(detail.getIdparquet())
                        || !estVide(detail.getIdsexe())
                        || !estVide(detail.getIdqualite());
                if (!ligneRenseignee) {
                    continue;
                }
                if (estVide(detail.getIdsexe())) {
                    throw new Exception("Le sexe est obligatoire pour chaque ligne de triage");
                }
                if (detail.getQte() < 0) {
                    throw new Exception("La quantite triee ne peut pas etre negative");
                }
                if (!estVide(detail.getIdparquet()) && detail.getQte() > 0) {
                    String cleParquet = detail.getIdparquet().trim();
                    String sexe = detail.getIdsexe().trim();

                    // un parquet ne peut contenir qu'un seul sexe
                    String sexeDejaDansParquet = sexeParParquet.get(cleParquet);
                    if (sexeDejaDansParquet != null && !sexeDejaDansParquet.equalsIgnoreCase(sexe)) {
                        throw new Exception("Le parquet " + cleParquet
                                + " ne peut pas contenir des poussins de sexes differents");
                    }
                    sexeParParquet.put(cleParquet, sexe);

                    Double deja = quantiteParParquet.get(cleParquet);
                    quantiteParParquet.put(cleParquet, (deja == null ? 0 : deja) + detail.getQte());
                }
                quantiteTriagee += detail.getQte();
            }
        }

        // Chaque parquet choisi doit etre libre (aucun poussin a l'interieur)
        // et assez grand pour la quantite repartie dedans par ce triage.
        for (Map.Entry<String, Double> e : quantiteParParquet.entrySet()) {
            verifierParquetDisponible(e.getKey(), e.getValue(), c);
        }

        if (quantiteTriagee - quantiteVivanteRestante > 0.000001) {
            throw new Exception("La quantite repartie dans les parquets depasse la quantite vivante restante ("
                    + quantiteVivanteRestante + ")");
        }
        return super.createObject(u, c);
    }

    private static boolean estVide(String valeur) {
        return valeur == null || valeur.trim().isEmpty();
    }

    private Parquet chargerParquet(String idparquet, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new utilitaire.UtilDB().GetConn();
                canClose = true;
            }
            Parquet p = new Parquet();
            p.setId(idparquet);
            Parquet[] resultats = (Parquet[]) CGenUtil.rechercher(p, null, null, c, "");
            return resultats != null && resultats.length > 0 ? resultats[0] : null;
        } finally {
            if (canClose) {
                c.close();
            }
        }
    }

    // Capacite du parquet (0 si le parquet est introuvable)
    private double getCapaciteParquet(String idparquet, Connection c) throws Exception {
        Parquet p = chargerParquet(idparquet, c);
        return p != null ? p.getCapacite() : 0;
    }

    /**
     * Nombre de poussins vivants (SANTE > 0) deja presents dans le parquet, issus des
     * autres triages dont le lot n'est pas cloture. Ce triage-ci est exclu (cas de modification).
     */
    private double getQuantiteOccupee(String idparquet, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new utilitaire.UtilDB().GetConn();
                canClose = true;
            }
            boolean exclureCourant = !estVide(this.id);
            String sql = "SELECT NVL(SUM(d.QTE), 0) FROM TRIAGEBATIMENTPARQUETDETAIL d"
                    + " JOIN TRIAGEBATIMENTPARQUET t ON t.ID = d.IDMERE"
                    + " LEFT JOIN LOT l ON l.ID = t.IDLOT"
                    + " WHERE d.IDPARQUET = ? AND NVL(d.SANTE, 10) > 0 AND l.DATECLOTURE IS NULL"
                    + (exclureCourant ? " AND t.ID <> ?" : "");
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, idparquet);
                if (exclureCourant) {
                    ps.setString(2, this.id);
                }
                try (ResultSet rs = ps.executeQuery()) {
                    return rs.next() ? rs.getDouble(1) : 0;
                }
            }
        } finally {
            if (canClose) {
                c.close();
            }
        }
    }

    private void verifierParquetDisponible(String idparquet, double quantiteDemandee, Connection c) throws Exception {
        Parquet parquet = chargerParquet(idparquet, c);
        if (parquet == null) {
            throw new Exception("Le parquet " + idparquet + " est introuvable");
        }
        String nom = estVide(parquet.getVal()) ? idparquet : parquet.getVal();
        double occupee = getQuantiteOccupee(idparquet, c);
        if (occupee > 0.000001) {
            throw new Exception("Le parquet " + nom + " n'est pas disponible : il contient deja "
                    + (long) occupee + " poussin(s)");
        }
        double capacite = parquet.getCapacite();
        if (capacite <= 0) {
            throw new Exception("La capacite du parquet " + nom + " n'est pas renseignee");
        }
        if (quantiteDemandee - capacite > 0.000001) {
            throw new Exception("La quantite repartie dans le parquet " + nom + " (" + (long) quantiteDemandee
                    + ") depasse sa capacite (" + (long) capacite + ")");
        }
    }

    public double getDisponnible(String idLot, String idSexe, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new utilitaire.UtilDB().GetConn();
                canClose = true;
            }
            TriageLotSexeQualite critere = new TriageLotSexeQualite();
            critere.setIdLot(idLot);
            critere.setIdsexe(idSexe);
            critere.setIdqualite(ferme.utils.ConstanteFerme.qualiteConforme);
            TriageLotSexeQualite[] resultats = (TriageLotSexeQualite[]) CGenUtil.rechercher(critere, null, null, c, "");
            return resultats != null && resultats.length > 0 ? resultats[0].getQte() : 0;
        } finally {
            if (canClose) {
                c.close();
            }
        }
    }

    public double getDisponnibleLib(String idLot, String idSexe, String idQualite, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new utilitaire.UtilDB().GetConn();
                canClose = true;
            }
            TriageLotSexeQualiteLib critere = new TriageLotSexeQualiteLib();
            critere.setIdLot(idLot);
            critere.setIdSexe(idSexe);
            critere.setIdQualite(idQualite);
            TriageLotSexeQualiteLib[] resultats = (TriageLotSexeQualiteLib[]) CGenUtil.rechercher(critere, null, null, c, "");
            return resultats != null && resultats.length > 0 ? resultats[0].getQte() : 0;
        } finally {
            if (canClose) {
                c.close();
            }
        }
    }

}