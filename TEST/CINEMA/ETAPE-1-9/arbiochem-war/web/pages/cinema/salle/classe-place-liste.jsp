<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.salle.CinClassePlaceLib"%>
<%@page import="affichage.PageRecherche"%>
<%@page import="affichage.Liste"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.HashMap"%>
<%
    try {
        CinClassePlaceLib t = new CinClassePlaceLib();
        String listeCrt[] = {"id", "val", "prix", "etat"};
        String listeInt[] = {"prix"};
        String libEntete[] = {"id", "val", "desce", "prix", "couleur", "etatlib"};
        String libEnteteAffiche[] = {"ID", "Classe", "Description", "Prix (Ar)", "Couleur", "&Eacute;tat"};

        PageRecherche pr = new PageRecherche(t, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
        pr.setTitre("Liste des classes de place");
        pr.setUtilisateur((user.UserEJB) session.getValue("u"));
        pr.setLien((String) session.getValue("lien"));
        pr.setApres("cinema/salle/classe-place-liste.jsp");

        Liste[] liste = new Liste[1];
        liste[0] = new Liste("etat", new String[]{"Tous", "Actif", "Inactif"}, new String[]{"", "1", "0"});
        pr.getFormu().changerEnChamp(liste);
        pr.getFormu().getChamp("id").setLibelle("ID");
        pr.getFormu().getChamp("val").setLibelle("Classe");
        pr.getFormu().getChamp("prix1").setLibelle("Prix min");
        pr.getFormu().getChamp("prix2").setLibelle("Prix max");
        pr.getFormu().getChamp("etat").setLibelle("&Eacute;tat");

        pr.creerObjetPage(libEntete, null);

        Map<String, String> lienTab = new HashMap();
        lienTab.put("modifier", pr.getLien() + "?but=cinema/salle/classe-place-modif.jsp");
        pr.getTableau().setLienClicDroite(lienTab);
        pr.getTableau().setLien(new String[]{pr.getLien() + "?but=cinema/salle/classe-place-fiche.jsp"});
        pr.getTableau().setColonneLien(new String[]{"id"});
        pr.getTableau().setLibelleAffiche(libEnteteAffiche);
        pr.getFormu().setAnotherButton(
            "<a class=\"btn btn-primary pull-right btn-small\" href=\"module.jsp?but=cinema/salle/classe-place-saisie.jsp&currentMenu=MENDYNCINEMA0102\">"
            + "<i class=\"material-symbols-rounded\">add</i>Saisie d'une classe</a>");
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
<%@ include file="../inc/couleur-apercu.jspf" %>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
