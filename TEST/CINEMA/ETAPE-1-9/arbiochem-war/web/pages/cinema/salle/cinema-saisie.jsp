<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.salle.CinCinema"%>
<%@page import="affichage.PageInsert"%>
<%@page import="affichage.Liste"%>
<%@page import="user.UserEJB"%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        String mapping = "cinema.salle.CinCinema",
               nomtable = "CIN_CINEMA",
               apres = "cinema/salle/cinema-fiche.jsp",
               titre = "Saisie d'un cin&eacute;ma";

        CinCinema cinema = new CinCinema();
        PageInsert pi = new PageInsert(cinema, request, u);
        pi.setLien((String) session.getValue("lien"));

        Liste[] liste = new Liste[1];
        liste[0] = new Liste("etat", new String[]{"Actif", "Inactif"}, new String[]{"1", "0"});
        pi.getFormu().changerEnChamp(liste);

        pi.getFormu().getChamp("nom").setLibelle("Nom");
        pi.getFormu().getChamp("localisation").setLibelle("Localisation");
        pi.getFormu().getChamp("etat").setLibelle("&Eacute;tat");
        pi.getFormu().getChamp("date_creation").setVisible(false);
        pi.preparerDataFormu();
%>
<div class="content-wrapper">
    <h1><%= titre %></h1>
    <form action="<%= pi.getLien() %>?but=apresTarif.jsp" method="post" name="<%= nomtable %>" id="<%= nomtable %>">
        <%
            pi.getFormu().makeHtmlInsertTabIndex();
            out.println(pi.getFormu().getHtmlInsert());
        %>
        <input name="acte" type="hidden" value="insert">
        <input name="bute" type="hidden" value="<%= apres %>">
        <input name="classe" type="hidden" value="<%= mapping %>">
        <input name="nomtable" type="hidden" value="<%= nomtable %>">
    </form>
</div>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
