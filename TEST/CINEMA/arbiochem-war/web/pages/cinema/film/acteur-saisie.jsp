<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.film.CinActeur"%>
<%@page import="affichage.PageInsert"%>
<%@page import="user.UserEJB"%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        String mapping = "cinema.film.CinActeur",
               nomtable = "CIN_ACTEUR",
               apres = "cinema/film/acteur-fiche.jsp",
               titre = "Saisie d'un acteur";

        PageInsert pi = new PageInsert(new CinActeur(), request, u);
        pi.setLien((String) session.getValue("lien"));
        pi.getFormu().getChamp("nom").setLibelle("Nom");
        pi.getFormu().getChamp("nom_acteur").setLibelle("Nom de sc&egrave;ne");
        pi.getFormu().getChamp("date_naissance").setLibelle("Date de naissance");
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
