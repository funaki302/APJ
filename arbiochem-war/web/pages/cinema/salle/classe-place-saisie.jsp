<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.salle.CinClassePlace"%>
<%@page import="affichage.PageInsert"%>
<%@page import="affichage.Liste"%>
<%@page import="user.UserEJB"%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        String mapping = "cinema.salle.CinClassePlace",
               nomtable = "CIN_CLASSE_PLACE",
               apres = "cinema/salle/classe-place-fiche.jsp",
               titre = "Saisie d'une classe de place";

        PageInsert pi = new PageInsert(new CinClassePlace(), request, u);
        pi.setLien((String) session.getValue("lien"));

        Liste[] liste = new Liste[1];
        liste[0] = new Liste("etat", new String[]{"Actif", "Inactif"}, new String[]{"1", "0"});
        pi.getFormu().changerEnChamp(liste);

        pi.getFormu().getChamp("val").setLibelle("Libell&eacute; (ex. Standard)");
        pi.getFormu().getChamp("desce").setLibelle("Description");
        pi.getFormu().getChamp("prix").setLibelle("Prix d'une place (Ar)");
        pi.getFormu().getChamp("couleur").setLibelle("Couleur sur le plan de salle");
        pi.getFormu().getChamp("couleur").setType("color");
        pi.getFormu().getChamp("couleur").setDefaut("#F4C430");
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
