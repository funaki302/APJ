<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.utils.CinReinitialisation"%>
<%@page import="java.util.Map"%>
<%--
    Execute la reinitialisation (une seule transaction) ; action=demo recharge ensuite les donnees de demonstration
    depuis /WEB-INF/cinema/donnees-demo.sql (copie de data/cinema/donnees-demo.sql).
--%>
<%
    try {
        String lien = (String) session.getValue("lien");
        if (!"REINITIALISER".equals(request.getParameter("confirmation"))) throw new Exception("Confirmation manquante : tapez REINITIALISER");
        boolean demo = "demo".equals(request.getParameter("action"));
        String script = null;
        if (demo) {
            java.io.InputStream in = application.getResourceAsStream("/WEB-INF/cinema/donnees-demo.sql");
            if (in == null) throw new Exception("Fichier de d&eacute;monstration introuvable (WEB-INF/cinema/donnees-demo.sql)");
            try {
                java.io.ByteArrayOutputStream buf = new java.io.ByteArrayOutputStream();
                byte[] b = new byte[8192];
                int n;
                while ((n = in.read(b)) > 0) buf.write(b, 0, n);
                script = new String(buf.toByteArray(), "UTF-8");
            } finally {
                in.close();
            }
        }
        Map<String, Integer> resultat = CinReinitialisation.executer(script);
%>
<div class="content-wrapper">
    <h1>Donn&eacute;es du cin&eacute;ma r&eacute;initialis&eacute;es</h1>
    <div class="row m-0">
        <div class="col-md-8 col-md-offset-2">
            <div class="box box-success">
                <div class="box-body">
                    <p><%= demo ? "Les donn&eacute;es ont &eacute;t&eacute; effac&eacute;es puis la d&eacute;monstration a &eacute;t&eacute; recharg&eacute;e (dates calcul&eacute;es &agrave; partir d'aujourd'hui)."
                                : "Les donn&eacute;es du cin&eacute;ma ont &eacute;t&eacute; effac&eacute;es. La configuration est conserv&eacute;e." %></p>
                    <table class="table table-bordered table-condensed">
                        <thead><tr><th>&Eacute;tape</th><th style="text-align: right">Lignes</th></tr></thead>
                        <tbody>
                        <% for (Map.Entry<String, Integer> ligne : resultat.entrySet()) { %>
                        <tr><td><%= ligne.getKey() %></td><td style="text-align: right"><%= ligne.getValue() %></td></tr>
                        <% } %>
                        </tbody>
                    </table>
                    <a class="btn btn-primary" href="<%= lien %>?but=cinema/cinema-accueil.jsp">Retour &agrave; l'accueil du cin&eacute;ma</a>
                    <a class="btn btn-secondary" href="<%= lien %>?but=cinema/tableau/tableau-bord.jsp">Tableau de bord</a>
                </div>
            </div>
        </div>
    </div>
</div>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">
    alert('<%= e.getMessage() == null ? "Erreur" : e.getMessage().replace("&eacute;", "é").replace("&Eacute;", "É").replace("&laquo;", "«").replace("&raquo;", "»").replace("'", "\\'").replace("\n", " ") %>');
    history.back();
</script>
<% } %>
