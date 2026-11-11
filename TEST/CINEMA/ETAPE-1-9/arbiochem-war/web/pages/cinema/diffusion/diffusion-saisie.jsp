<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.diffusion.CinDiffusion"%>
<%@page import="cinema.film.CinFilm"%>
<%@page import="cinema.salle.CinSalle"%>
<%@page import="affichage.PageInsert"%>
<%@page import="affichage.Liste"%>
<%@page import="user.UserEJB"%>
<%-- Saisie d'une diffusion (seance). Parametres optionnels idfilm / idsalle pour pre-remplir (depuis une fiche). --%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        String mapping = "cinema.diffusion.CinDiffusion",
               nomtable = "CIN_DIFFUSION",
               apres = "cinema/diffusion/diffusion-fiche.jsp",
               titre = "Programmer une diffusion";

        PageInsert pi = new PageInsert(new CinDiffusion(), request, u);
        pi.setLien((String) session.getValue("lien"));

        Liste[] liste = new Liste[2];
        liste[0] = new Liste("idfilm", new CinFilm(), "titre", "id");
        liste[0].setApresW(" and etat = 1");
        liste[1] = new Liste("idsalle", new CinSalle(), "nom", "id");
        liste[1].setApresW(" and etat = 1");
        if (request.getParameter("idfilm") != null) liste[0].setDefaultSelected(request.getParameter("idfilm"));
        if (request.getParameter("idsalle") != null) liste[1].setDefaultSelected(request.getParameter("idsalle"));
        pi.getFormu().changerEnChamp(liste);

        pi.getFormu().getChamp("idfilm").setLibelle("Film");
        pi.getFormu().getChamp("idsalle").setLibelle("Salle");
        pi.getFormu().getChamp("daty").setLibelle("Date de la s&eacute;ance");
        pi.getFormu().getChamp("heure").setLibelle("Heure de d&eacute;but");
        pi.getFormu().getChamp("heure").setType("time");
        pi.getFormu().getChamp("etat").setVisible(false);
        pi.getFormu().getChamp("date_creation").setVisible(false);
        pi.preparerDataFormu();
%>
<div class="content-wrapper">
    <h1><%= titre %></h1>
    <p class="text-muted">La fin de la s&eacute;ance est calcul&eacute;e avec la dur&eacute;e du film. Une salle ne peut pas avoir deux s&eacute;ances
        qui se chevauchent. Voir le <a href="module.jsp?but=cinema/diffusion/diffusion-calendrier.jsp">calendrier des diffusions</a>.</p>
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
