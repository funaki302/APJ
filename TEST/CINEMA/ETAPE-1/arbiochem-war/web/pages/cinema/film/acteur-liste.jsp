<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.film.CinActeur"%>
<%@page import="affichage.PageRecherche"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.HashMap"%>
<%
    try {
        CinActeur t = new CinActeur();
        String listeCrt[] = {"id", "nom", "nom_acteur", "date_naissance"};
        String listeInt[] = {"date_naissance"};
        String libEntete[] = {"id", "nom", "nom_acteur", "date_naissance"};
        String libEnteteAffiche[] = {"ID", "Nom", "Nom de sc&egrave;ne", "Date de naissance"};

        PageRecherche pr = new PageRecherche(t, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
        pr.setTitre("Liste des acteurs");
        pr.setUtilisateur((user.UserEJB) session.getValue("u"));
        pr.setLien((String) session.getValue("lien"));
        pr.setApres("cinema/film/acteur-liste.jsp");
        pr.getFormu().getChamp("id").setLibelle("ID");
        pr.getFormu().getChamp("nom").setLibelle("Nom");
        pr.getFormu().getChamp("nom_acteur").setLibelle("Nom de sc&egrave;ne");
        pr.getFormu().getChamp("date_naissance1").setLibelle("N&eacute;(e) apr&egrave;s le");
        pr.getFormu().getChamp("date_naissance2").setLibelle("N&eacute;(e) avant le");

        pr.creerObjetPage(libEntete, null);

        Map<String, String> lienTab = new HashMap();
        lienTab.put("modifier", pr.getLien() + "?but=cinema/film/acteur-modif.jsp");
        pr.getTableau().setLienClicDroite(lienTab);
        pr.getTableau().setLien(new String[]{pr.getLien() + "?but=cinema/film/acteur-fiche.jsp"});
        pr.getTableau().setColonneLien(new String[]{"id"});
        pr.getTableau().setLibelleAffiche(libEnteteAffiche);
        pr.getFormu().setAnotherButton(
            "<a class=\"btn btn-primary pull-right btn-small\" href=\"module.jsp?but=cinema/film/acteur-saisie.jsp&currentMenu=MENDYNCINEMA0104\">"
            + "<i class=\"material-symbols-rounded\">add</i>Saisie d'un acteur</a>");
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
