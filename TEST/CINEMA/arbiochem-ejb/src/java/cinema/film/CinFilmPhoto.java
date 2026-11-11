package cinema.film;

import cinema.utils.CinUtils;
import java.io.OutputStream;
import java.sql.Blob;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import utilitaire.UtilDB;

/**
 * Photo (affiche) d'un film, stockee en base dans CIN_FILM_PHOTO (BLOB).
 * Le type d'image est reconnu sur les premiers octets du fichier, pas sur son nom.
 */
public class CinFilmPhoto {

    public static final int TAILLE_MAX = 2 * 1024 * 1024;

    private final byte[] contenu;
    private final String typeMime;

    public CinFilmPhoto(byte[] contenu, String typeMime) {
        this.contenu = contenu;
        this.typeMime = typeMime;
    }

    public byte[] getContenu() {
        return contenu;
    }

    public String getTypeMime() {
        return typeMime;
    }

    /**
     * Type MIME d'apres la signature du fichier : JPEG, PNG ou WEBP ; null sinon.
     */
    public static String detecterType(byte[] o) {
        if (o == null || o.length < 12) return null;
        if ((o[0] & 0xFF) == 0xFF && (o[1] & 0xFF) == 0xD8 && (o[2] & 0xFF) == 0xFF) return "image/jpeg";
        if ((o[0] & 0xFF) == 0x89 && o[1] == 'P' && o[2] == 'N' && o[3] == 'G') return "image/png";
        if (o[0] == 'R' && o[1] == 'I' && o[2] == 'F' && o[3] == 'F' && o[8] == 'W' && o[9] == 'E' && o[10] == 'B' && o[11] == 'P') return "image/webp";
        return null;
    }

    /**
     * Enregistre (ou remplace) la photo d'un film. Pas de commit : c'est l'appelant qui gere la transaction.
     */
    public static void enregistrer(String idFilm, byte[] contenu, String nomFichier, Connection c) throws Exception {
        if (CinUtils.estVide(idFilm) || CinUtils.entier(c, "select count(*) from CIN_FILM where id = ?", idFilm) == 0) {
            throw new Exception("Film introuvable");
        }
        if (contenu == null || contenu.length == 0) throw new Exception("Choisissez une image");
        if (contenu.length > TAILLE_MAX) throw new Exception("L'image d&eacute;passe 2 Mo");
        String type = detecterType(contenu);
        if (type == null) throw new Exception("Format non accept&eacute; : l'image doit &ecirc;tre en JPG, PNG ou WEBP");
        String nom = nomFichier == null ? null : nomFichier.replaceAll(".*[\\\\/]", "");
        if (nom != null && nom.length() > 255) nom = nom.substring(nom.length() - 255);

        try (PreparedStatement del = c.prepareStatement("delete from CIN_FILM_PHOTO where idfilm = ?")) {
            del.setString(1, idFilm);
            del.executeUpdate();
        }
        // Le pilote Oracle du projet (ojdbc6-11.jar) est ancien : setBinaryStream / setBytes echouent au-dela de
        // quelques Ko (ORA-01460). Methode compatible avec tous les pilotes : EMPTY_BLOB puis ecriture dans le BLOB verrouille.
        try (PreparedStatement ins = c.prepareStatement(
                "insert into CIN_FILM_PHOTO (idfilm, contenu, type_mime, nom_fichier, taille, date_maj) values (?, EMPTY_BLOB(), ?, ?, ?, sysdate)")) {
            ins.setString(1, idFilm);
            ins.setString(2, type);
            ins.setString(3, nom);
            ins.setInt(4, contenu.length);
            ins.executeUpdate();
        }
        try (PreparedStatement sel = c.prepareStatement("select contenu from CIN_FILM_PHOTO where idfilm = ? for update")) {
            sel.setString(1, idFilm);
            try (ResultSet rs = sel.executeQuery()) {
                rs.next();
                ecrireBlob(rs.getBlob(1), contenu);
            }
        }
    }

    private static void ecrireBlob(Blob blob, byte[] contenu) throws Exception {
        java.lang.reflect.Method flux;
        try {
            // pilote Oracle (ancien ou recent) : oracle.sql.BLOB.getBinaryOutputStream()
            flux = blob.getClass().getMethod("getBinaryOutputStream");
        } catch (NoSuchMethodException e) {
            blob.setBytes(1, contenu);
            return;
        }
        try (OutputStream os = (OutputStream) flux.invoke(blob)) {
            os.write(contenu);
        }
    }

    private static byte[] lireBlob(Blob blob) throws Exception {
        if (blob == null) return new byte[0];
        long taille = blob.length();
        return taille == 0 ? new byte[0] : blob.getBytes(1, (int) taille);
    }

    /**
     * Version avec sa propre connexion et sa propre transaction (appelee par la servlet).
     */
    public static void enregistrer(String idFilm, byte[] contenu, String nomFichier) throws Exception {
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            enregistrer(idFilm, contenu, nomFichier, c);
            c.commit();
        } catch (Exception e) {
            if (c != null) c.rollback();
            throw e;
        } finally {
            if (c != null) c.close();
        }
    }

    /**
     * Supprime la photo d'un film (sa propre transaction).
     */
    public static void supprimer(String idFilm) throws Exception {
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            try (PreparedStatement del = c.prepareStatement("delete from CIN_FILM_PHOTO where idfilm = ?")) {
                del.setString(1, idFilm);
                del.executeUpdate();
            }
            c.commit();
        } catch (Exception e) {
            if (c != null) c.rollback();
            throw e;
        } finally {
            if (c != null) c.close();
        }
    }

    /**
     * Photo d'un film, ou null s'il n'en a pas.
     */
    public static CinFilmPhoto lire(String idFilm, Connection c) throws Exception {
        boolean canClose = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                canClose = true;
            }
            try (PreparedStatement ps = c.prepareStatement("select contenu, type_mime from CIN_FILM_PHOTO where idfilm = ?")) {
                ps.setString(1, idFilm);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) return null;
                    return new CinFilmPhoto(lireBlob(rs.getBlob(1)), rs.getString(2));
                }
            }
        } finally {
            if (canClose) c.close();
        }
    }
}
