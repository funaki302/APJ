package cinema.utils;

import java.sql.Connection;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * Execute un script SQL au format des scripts du cinema (comme dans SQL*Plus), dans la transaction de l'appelant :
 * - lignes "--" (commentaires), SET ... et COMMIT ignorees (la transaction est geree par l'appelant) ;
 * - une instruction SQL se termine par ";" en fin de ligne ;
 * - un bloc PL/SQL (DECLARE / BEGIN ...) se termine par une ligne "/".
 * Utilise pour recharger les donnees de demonstration depuis l'application.
 */
public class CinScriptSql {

    public static List<String> decouper(String script) {
        List<String> instructions = new ArrayList<String>();
        StringBuilder courante = new StringBuilder();
        boolean plsql = false;
        for (String ligne : script.replace("\r", "").split("\n")) {
            String t = ligne.trim();
            if (!plsql) {
                if (t.isEmpty() || t.startsWith("--")) continue;
                String haut = t.toUpperCase();
                if (courante.length() == 0 && (haut.startsWith("SET ") || haut.equals("COMMIT;") || haut.equals("/"))) continue;
                if (courante.length() == 0 && (haut.startsWith("DECLARE") || haut.startsWith("BEGIN"))) plsql = true;
            }
            if (plsql) {
                if (t.equals("/")) {
                    instructions.add(courante.toString().trim());
                    courante.setLength(0);
                    plsql = false;
                } else {
                    courante.append(ligne).append('\n');
                }
                continue;
            }
            courante.append(ligne).append('\n');
            if (t.endsWith(";")) {
                String sql = courante.toString().trim();
                instructions.add(sql.substring(0, sql.length() - 1).trim());
                courante.setLength(0);
            }
        }
        if (courante.toString().trim().length() > 0) throw new IllegalArgumentException("Script incomplet : instruction sans fin");
        return instructions;
    }

    /**
     * Execute toutes les instructions ; en cas d'erreur, l'exception indique le numero et le debut de l'instruction.
     * Pas de commit.
     */
    public static int executer(String script, Connection c) throws Exception {
        List<String> instructions = decouper(script);
        try (Statement st = c.createStatement()) {
            st.setEscapeProcessing(false);
            for (int i = 0; i < instructions.size(); i++) {
                try {
                    st.execute(instructions.get(i));
                } catch (Exception e) {
                    String debut = instructions.get(i).replaceAll("\\s+", " ");
                    if (debut.length() > 90) debut = debut.substring(0, 90) + "...";
                    throw new Exception("Instruction " + (i + 1) + " du script (" + debut + ") : " + e.getMessage());
                }
            }
        }
        return instructions.size();
    }
}
