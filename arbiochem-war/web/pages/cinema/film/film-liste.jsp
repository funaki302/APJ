<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.film.CinFilmLib"%>
<%@page import="cinema.film.CinCategorieFilm"%>
<%@page import="cinema.film.CinActeur"%>
<%@page import="affichage.PageRecherche"%>
<%@page import="affichage.Liste"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.HashMap"%>
<%-- Liste des films (tableau APJ standard, comme les autres listes). La photo est visible sur la fiche du film. --%>
<%
    try {
        CinFilmLib t = new CinFilmLib();
        String listeCrt[] = {"id", "titre", "idcategorie", "idacteur", "duree", "etat"};
        String listeInt[] = {"duree"};
        String libEntete[] = {"id", "titre", "idacteurlib", "idcategorielib", "dureelib", "pa", "etatlib"};
        String libEnteteAffiche[] = {"ID", "Titre", "Acteur principal", "Cat&eacute;gorie", "Dur&eacute;e", "Prix d'achat (Ar)", "&Eacute;tat"};

        PageRecherche pr = new PageRecherche(t, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
        pr.setTitre("Liste des films");
        pr.setUtilisateur((user.UserEJB) session.getValue("u"));
        pr.setLien((String) session.getValue("lien"));
        pr.setApres("cinema/film/film-liste.jsp");

        Liste[] liste = new Liste[3];
        liste[0] = new Liste("idcategorie", new CinCategorieFilm(), "val", "id");
        liste[1] = new Liste("idacteur", new CinActeur(), "nom", "id");
        liste[2] = new Liste("etat", new String[]{"Tous", "Actif", "Inactif"}, new String[]{"", "1", "0"});
        pr.getFormu().changerEnChamp(liste);
        pr.getFormu().getChamp("id").setLibelle("ID");
        pr.getFormu().getChamp("titre").setLibelle("Titre");
        pr.getFormu().getChamp("idcategorie").setLibelle("Cat&eacute;gorie");
        pr.getFormu().getChamp("idacteur").setLibelle("Acteur");
        pr.getFormu().getChamp("duree1").setLibelle("Dur&eacute;e min (minutes)");
        pr.getFormu().getChamp("duree2").setLibelle("Dur&eacute;e max (minutes)");
        pr.getFormu().getChamp("etat").setLibelle("&Eacute;tat");

        pr.creerObjetPage(libEntete, null);

        Map<String, String> lienTab = new HashMap();
        lienTab.put("modifier", pr.getLien() + "?but=cinema/film/film-modif.jsp");
        pr.getTableau().setLienClicDroite(lienTab);
        pr.getTableau().setLien(new String[]{pr.getLien() + "?but=cinema/film/film-fiche.jsp"});
        pr.getTableau().setColonneLien(new String[]{"id"});
        pr.getTableau().setLibelleAffiche(libEnteteAffiche);
        pr.getFormu().setAnotherButton(
            "<a class=\"btn btn-primary pull-right btn-small\" href=\"module.jsp?but=cinema/film/film-saisie.jsp&currentMenu=MENDYNCINEMA0301\">"
            + "<i class=\"material-symbols-rounded\">add</i>Saisie d'un film</a>");
%>
<div class="content-wrapper">
    <section class="content-header">
        <h1><%= pr.getTitre() %></h1>
    </section>
    <section class="content">
        <form action="<%= pr.getLien() %>?but=<%= pr.getApres() %>" method="post">
            <% out.println(pr.getFormu().getHtmlEnsemble()); %>
        </form>
        <% out.println(pr.getTableauRecap().getHtml()); %>
        <br>
        <%
            out.println(pr.getTableau().getHtml());
            out.println(pr.getBasPage());
        %>
    </section>
</div>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
