<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.paiement.CinPaiement"%>
<%@page import="user.UserEJB"%>
<%-- Enregistre le paiement (CinPaiement.payer, sa propre transaction) puis ouvre la facture generee --%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        String lien = (String) session.getValue("lien");
        CinPaiement p = CinPaiement.payer(request.getParameter("idticket"), request.getParameterValues("mode"),
                request.getParameterValues("caisse"), request.getParameterValues("montant"), u.getUser().getTuppleID());
%>
<script language="JavaScript">
    document.location.replace("<%= lien %>?but=cinema/facture/facture-fiche.jsp&id=<%= p.getIdfacture() %>&nouvelle=1");
</script>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">
    alert('<%= e.getMessage() == null ? "Erreur" : e.getMessage().replace("&eacute;", "é").replace("&ecirc;", "ê").replace("&agrave;", "à").replace("'", "\\'").replace("\n", " ") %>');
    history.back();
</script>
<% } %>
