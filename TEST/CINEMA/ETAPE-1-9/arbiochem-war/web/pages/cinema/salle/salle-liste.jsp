<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.salle.CinSalleLib"%>
<%@page import="cinema.salle.CinCinema"%>
<%@page import="affichage.PageRecherche"%>
<%@page import="affichage.Liste"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.HashMap"%>
<%
    try {
        CinSalleLib t = new CinSalleLib();
        String listeCrt[] = {"id", "nom", "idcinema", "capacite", "etat"};
        String listeInt[] = {"capacite"};
        String libEntete[] = {"id", "nom", "idcinemalib", "nb_rangees", "nb_colonnes", "capacite", "nb_places_service", "etatlib"};
        String libEnteteAffiche[] = {"ID", "Salle", "Cin&eacute;ma", "Rang&eacute;es", "Places / rang&eacute;e", "Capacit&eacute;", "En service", "&Eacute;tat"};

        PageRecherche pr = new PageRecherche(t, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
        pr.setTitre("Liste des salles");
        pr.setUtilisateur((user.UserEJB) session.getValue("u"));
        pr.setLien((String) session.getValue("lien"));
        pr.setApres("cinema/salle/salle-liste.jsp");

        Liste[] liste = new Liste[2];
        liste[0] = new Liste("idcinema", new CinCinema(), "nom", "id");
        liste[1] = new Liste("etat", new String[]{"Tous", "Active", "Inactive"}, new String[]{"", "1", "0"});
        pr.getFormu().changerEnChamp(liste);
        pr.getFormu().getChamp("id").setLibelle("ID");
        pr.getFormu().getChamp("nom").setLibelle("Salle");
        pr.getFormu().getChamp("idcinema").setLibelle("Cin&eacute;ma");
        pr.getFormu().getChamp("capacite1").setLibelle("Capacit&eacute; min");
        pr.getFormu().getChamp("capacite2").setLibelle("Capacit&eacute; max");
        pr.getFormu().getChamp("etat").setLibelle("&Eacute;tat");

        pr.creerObjetPage(libEntete, null);

        Map<String, String> lienTab = new HashMap();
        lienTab.put("modifier", pr.getLien() + "?but=cinema/salle/salle-modif.jsp");
        lienTab.put("plan des places", pr.getLien() + "?but=cinema/salle/salle-plan.jsp");
        pr.getTableau().setLienClicDroite(lienTab);
        pr.getTableau().setLien(new String[]{pr.getLien() + "?but=cinema/salle/salle-fiche.jsp"});
        pr.getTableau().setColonneLien(new String[]{"id"});
        pr.getTableau().setLibelleAffiche(libEnteteAffiche);
        pr.getFormu().setAnotherButton(
            "<a class=\"btn btn-primary pull-right btn-small\" href=\"module.jsp?but=cinema/salle/salle-saisie.jsp&currentMenu=MENDYNCINEMA0201\">"
            + "<i class=\"material-symbols-rounded\">add</i>Saisie d'une salle</a>");
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
