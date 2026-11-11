<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.diffusion.CinDiffusionLib"%>
<%@page import="cinema.film.CinFilm"%>
<%@page import="cinema.salle.CinSalle"%>
<%@page import="affichage.PageRecherche"%>
<%@page import="affichage.Liste"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.HashMap"%>
<%-- Liste des diffusions (tableau APJ standard, comme les autres listes). Vue par semaine : diffusion-calendrier.jsp. --%>
<%
    try {
        CinDiffusionLib t = new CinDiffusionLib();
        String listeCrt[] = {"id", "daty", "idfilm", "idsalle", "etat"};
        String listeInt[] = {"daty"};
        String libEntete[] = {"id", "idfilmlib", "idsallelib", "daty", "heure", "heure_fin", "dureelib", "nb_places", "etatlib"};
        String libEnteteAffiche[] = {"ID", "Film", "Salle", "Date", "D&eacute;but", "Fin", "Dur&eacute;e", "Places", "&Eacute;tat"};

        PageRecherche pr = new PageRecherche(t, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
        pr.setTitre("Liste des diffusions");
        pr.setUtilisateur((user.UserEJB) session.getValue("u"));
        pr.setLien((String) session.getValue("lien"));
        pr.setApres("cinema/diffusion/diffusion-liste.jsp");

        Liste[] liste = new Liste[3];
        liste[0] = new Liste("idfilm", new CinFilm(), "titre", "id");
        liste[1] = new Liste("idsalle", new CinSalle(), "nom", "id");
        liste[2] = new Liste("etat", new String[]{"Tous", "Programm&eacute;e", "Annul&eacute;e"}, new String[]{"", "1", "0"});
        pr.getFormu().changerEnChamp(liste);
        pr.getFormu().getChamp("id").setLibelle("ID");
        pr.getFormu().getChamp("daty1").setLibelle("Date min");
        pr.getFormu().getChamp("daty2").setLibelle("Date max");
        pr.getFormu().getChamp("idfilm").setLibelle("Film");
        pr.getFormu().getChamp("idsalle").setLibelle("Salle");
        pr.getFormu().getChamp("etat").setLibelle("&Eacute;tat");

        pr.creerObjetPage(libEntete, null);

        Map<String, String> lienTab = new HashMap();
        lienTab.put("modifier", pr.getLien() + "?but=cinema/diffusion/diffusion-modif.jsp");
        pr.getTableau().setLienClicDroite(lienTab);
        pr.getTableau().setLien(new String[]{pr.getLien() + "?but=cinema/diffusion/diffusion-fiche.jsp"});
        pr.getTableau().setColonneLien(new String[]{"id"});
        pr.getTableau().setLibelleAffiche(libEnteteAffiche);
        pr.getFormu().setAnotherButton(
            "<a class=\"btn btn-primary pull-right btn-small\" href=\"module.jsp?but=cinema/diffusion/diffusion-saisie.jsp&currentMenu=MENDYNCINEMA0501\">"
            + "<i class=\"material-symbols-rounded\">add</i>Programmer une diffusion</a>"
            + "<a class=\"btn btn-secondary pull-right btn-small\" style=\"margin-right: 8px\" href=\"module.jsp?but=cinema/diffusion/diffusion-calendrier.jsp&currentMenu=MENDYNCINEMA0503\">"
            + "<i class=\"material-symbols-rounded\">calendar_month</i>Calendrier</a>");
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
