<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.paiement.CinFacturation"%>
<%@page import="user.UserEJB"%>
<%--
    Bouton "Payer" d'une reservation : cree la facture du ticket dans la facturation existante (VENTE) et la vise
    (cinema.paiement.CinFacturation), puis ouvre la fiche de la vente pour l'encaissement.
--%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        String lien = (String) session.getValue("lien");
        String idVente = CinFacturation.facturer(request.getParameter("idticket"), u.getUser().getTuppleID());
%>
<script language="JavaScript">
    document.location.replace("<%= lien %>?but=vente/vente-arbiochem-fiche.jsp&id=<%= idVente %>");
</script>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">
    alert('<%= e.getMessage() == null ? "Erreur" : e.getMessage().replace("&eacute;", "é").replace("&egrave;", "è").replace("&ecirc;", "ê").replace("&agrave;", "à").replace("&gt;", ">").replace("'", "\'").replace("\n", " ") %>');
    history.back();
</script>
<% } %>
