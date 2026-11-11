package cinema.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import utilitaire.UtilDB;

/**
 * Recherche de clients (table CLIENT existante) pour la page de reservation.
 * GET /cinema/clients?q=texte : JSON [{"id":..,"nom":..,"tel":..}], 15 clients au plus,
 * dont le nom, le telephone ou l'id contient le texte. Reserve aux utilisateurs connectes.
 */
@WebServlet("/cinema/clients")
public class CinClientServlet extends HttpServlet {

    private static String json(String s) {
        if (s == null) return "\"\"";
        StringBuilder sb = new StringBuilder("\"");
        for (char ch : s.toCharArray()) {
            if (ch == '"' || ch == '\\') sb.append('\\').append(ch);
            else if (ch < 0x20) sb.append(String.format("\\u%04x", (int) ch));
            else if (ch == '<') sb.append("\\u003c");
            else sb.append(ch);
        }
        return sb.append('"').toString();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        if (request.getSession(false) == null || request.getSession(false).getAttribute("u") == null) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        String q = request.getParameter("q") == null ? "" : request.getParameter("q").trim();
        response.setContentType("application/json;charset=UTF-8");
        StringBuilder sb = new StringBuilder("[");
        if (q.length() >= 1) {
            String sql = "select id, nom, telephone from (select id, nom, telephone from CLIENT"
                    + " where upper(nom) like ? or telephone like ? or upper(id) like ? order by upper(nom)) where rownum <= 15";
            String motif = "%" + q.toUpperCase().replace("%", "").replace("_", "") + "%";
            Connection c = null;
            try {
                c = new UtilDB().GetConn();
                try (PreparedStatement ps = c.prepareStatement(sql)) {
                    ps.setString(1, motif);
                    ps.setString(2, motif);
                    ps.setString(3, motif);
                    try (ResultSet rs = ps.executeQuery()) {
                        boolean premier = true;
                        while (rs.next()) {
                            if (!premier) sb.append(',');
                            premier = false;
                            sb.append("{\"id\":").append(json(rs.getString(1))).append(",\"nom\":").append(json(rs.getString(2)))
                              .append(",\"tel\":").append(json(rs.getString(3))).append('}');
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                return;
            } finally {
                if (c != null) try { c.close(); } catch (Exception ignore) { }
            }
        }
        response.getWriter().write(sb.append(']').toString());
    }
}
