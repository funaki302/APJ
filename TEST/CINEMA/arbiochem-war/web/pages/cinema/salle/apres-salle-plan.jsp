<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.salle.CinSalle"%>
<%-- Enregistre les changements du plan de salle (classe / hors service des places) puis revient a la fiche --%>
<%
    try {
        String lien = (String) session.getValue("lien");
        String idSalle = request.getParameter("idsalle");
        CinSalle.modifierPlaces(idSalle, request.getParameter("modifs"));
%>
<script language="JavaScript">
    document.location.replace("<%= lien %>?but=cinema/salle/salle-fiche.jsp&id=<%= java.net.URLEncoder.encode(idSalle, "UTF-8") %>");
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
