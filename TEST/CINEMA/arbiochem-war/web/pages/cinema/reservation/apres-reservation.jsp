<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.reservation.CinTicket"%>
<%@page import="user.UserEJB"%>
<%-- Enregistre une reservation (CinTicket.reserver, sa propre transaction) puis ouvre la fiche du ticket --%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        String lien = (String) session.getValue("lien");
        String places = request.getParameter("places");
        CinTicket t = CinTicket.reserver(request.getParameter("iddiffusion"), request.getParameter("idclient"),
                places == null ? new String[0] : places.split(","), request.getParameter("remarque"), u.getUser().getTuppleID());
%>
<script language="JavaScript">
    document.location.replace("<%= lien %>?but=cinema/reservation/reservation-fiche.jsp&id=<%= t.getId() %>");
</script>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">
    alert('<%= e.getMessage() == null ? "Erreur" : e.getMessage().replace("&eacute;", "é").replace("&ecirc;", "ê").replace("'", "\\'").replace("\n", " ") %>');
    history.back();
</script>
<% } %>
