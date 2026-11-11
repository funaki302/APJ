<%@page import="vente.ReinitialisationVente"%>
<%@page import="user.UserEJB"%>
<%@page import="java.util.Map"%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        String lien = (String) session.getValue("lien");
        if (!"REINITIALISER".equals(request.getParameter("confirmation"))) {
            throw new Exception("Confirmation invalide : tapez REINITIALISER");
        }
        Map<String, Integer> resultat = ReinitialisationVente.reinitialiser(u.getUser().getTuppleID());
%>
<div class="content-wrapper">
    <h1>R&eacute;initialisation termin&eacute;e</h1>
    <div class="row m-0">
        <div class="col-md-8 col-md-offset-2">
            <div class="box box-success">
                <div class="box-body">
                    <table class="table table-bordered table-condensed">
                        <thead><tr><th>&Eacute;tape</th><th style="text-align: right">Lignes</th></tr></thead>
                        <tbody>
                        <% for (Map.Entry<String, Integer> ligne : resultat.entrySet()) { %>
                            <tr>
                                <td><%= ligne.getKey() %></td>
                                <td style="text-align: right"><%= ligne.getValue() < 0 ? "ignor&eacute;e (table absente)" : String.valueOf(ligne.getValue()) %></td>
                            </tr>
                        <% } %>
                        </tbody>
                    </table>
                    <a class="btn btn-primary pull-right" href="<%= lien %>?but=vente/vente-arbiochem-liste.jsp">Retour aux factures</a>
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
    alert('<%= e.getMessage() == null ? "Erreur" : e.getMessage().replace("'", "\\'").replace("\n", " ") %>');
    history.back();
</script>
<% } %>
