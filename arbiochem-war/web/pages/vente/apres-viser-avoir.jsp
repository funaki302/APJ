<%@page import="avoir.ImputationAvoirFC"%>
<%@page import="user.UserEJB"%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    Etape avant le visa d'une facture : enregistre le choix "Ne pas appliquer l'avoir"
    puis enchaine sur le visa standard (apresTarif.jsp, acte=valider) sans le modifier.
--%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        String lien = (String) session.getValue("lien");
        String id = request.getParameter("id");
        String bute = request.getParameter("bute");
        String classe = request.getParameter("classe");
        boolean nePasAppliquer = "1".equals(request.getParameter("nePasAppliquerAvoir"));
        if (id == null || id.trim().isEmpty()) throw new Exception("Facture non pr\u00e9cis\u00e9e");

        ImputationAvoirFC.setAvoirNonApplique(id, nePasAppliquer, u.getUser().getTuppleID(), null);
        String urlVisa = lien + "?but=apresTarif.jsp&acte=valider&id=" + id + "&bute=" + bute + "&classe=" + classe;
%>
<script language="JavaScript">
    document.location.replace("<%= urlVisa %>");
</script>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">
    alert('<%= e.getMessage() == null ? "Erreur" : e.getMessage().replace("'", "\\'").replace("\n", " ") %>');
    history.back();
</script>
<% } %>
