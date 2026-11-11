<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.film.CinFilm"%>
<%@page import="cinema.film.CinCategorieFilm"%>
<%@page import="cinema.film.CinActeur"%>
<%@page import="affichage.PageInsert"%>
<%@page import="affichage.Liste"%>
<%@page import="user.UserEJB"%>
<%-- Saisie d'un film. La photo s'ajoute ensuite sur la fiche du film. --%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        String mapping = "cinema.film.CinFilm",
               nomtable = "CIN_FILM",
               apres = "cinema/film/film-fiche.jsp",
               titre = "Saisie d'un film";

        PageInsert pi = new PageInsert(new CinFilm(), request, u);
        pi.setLien((String) session.getValue("lien"));

        Liste[] liste = new Liste[3];
        liste[0] = new Liste("idcategorie", new CinCategorieFilm(), "val", "id");
        liste[0].setApresW(" and etat = 1");
        liste[1] = new Liste("idacteur", new CinActeur(), "nom", "id");
        liste[2] = new Liste("etat", new String[]{"Actif", "Inactif"}, new String[]{"1", "0"});
        pi.getFormu().changerEnChamp(liste);

        pi.getFormu().getChamp("titre").setLibelle("Titre");
        pi.getFormu().getChamp("idcategorie").setLibelle("Cat&eacute;gorie");
        pi.getFormu().getChamp("idacteur").setLibelle("Acteur principal");
        pi.getFormu().getChamp("duree").setLibelle("Dur&eacute;e (minutes)");
        pi.getFormu().getChamp("duree").setType("number");
        pi.getFormu().getChamp("duree").setAutre("min='1' max='600'");
        pi.getFormu().getChamp("pa").setLibelle("Prix d'achat (Ar)");
        pi.getFormu().getChamp("pa").setType("number");
        pi.getFormu().getChamp("pa").setAutre("min='0'");
        pi.getFormu().getChamp("description").setLibelle("Description");
        pi.getFormu().getChamp("description").setType("textarea");
        pi.getFormu().getChamp("etat").setLibelle("&Eacute;tat");
        pi.getFormu().getChamp("date_creation").setVisible(false);
        pi.preparerDataFormu();
%>
<div class="content-wrapper">
    <h1><%= titre %></h1>
    <p class="text-muted">Apr&egrave;s l'enregistrement, la fiche du film s'ouvre : vous pourrez y ajouter la photo (affiche).
        Si l'acteur n'existe pas encore, cr&eacute;ez-le d'abord dans
        <a href="module.jsp?but=cinema/film/acteur-saisie.jsp">Configurations &gt; Acteurs</a>.</p>
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
