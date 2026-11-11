<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.achat.CinAchatLib"%>
<%@page import="affichage.PageRecherche"%>
<%@page import="affichage.Liste"%>
<%
    try {
        CinAchatLib t = new CinAchatLib();
        String listeCrt[] = {"id", "daty", "fournisseur", "idcaisse", "montant", "etat"};
        String listeInt[] = {"daty", "montant"};
        String libEntete[] = {"id", "daty", "fournisseur", "idcaisselib", "idmodepaiementlib", "nb_lignes", "montant", "etatlib"};
        String libEnteteAffiche[] = {"ID", "Date", "Fournisseur", "Caisse", "Mode", "Lignes", "Montant (Ar)", "&Eacute;tat"};

        PageRecherche pr = new PageRecherche(t, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
        pr.setTitre("Liste des achats du cin&eacute;ma");
        pr.setUtilisateur((user.UserEJB) session.getValue("u"));
        pr.setLien((String) session.getValue("lien"));
        pr.setApres("cinema/achat/achat-liste.jsp");

        Liste[] liste = new Liste[2];
        liste[0] = new Liste("idcaisse", new caisse.Caisse(), "val", "id");
        liste[0].setApresW(" and actif = 1");
        liste[1] = new Liste("etat", new String[]{"Tous", "Cr&eacute;&eacute;", "Vis&eacute;", "Annul&eacute;"}, new String[]{"", "1", "11", "0"});
        pr.getFormu().changerEnChamp(liste);
        pr.getFormu().getChamp("id").setLibelle("ID");
        pr.getFormu().getChamp("daty1").setLibelle("Date min");
        pr.getFormu().getChamp("daty2").setLibelle("Date max");
        pr.getFormu().getChamp("fournisseur").setLibelle("Fournisseur");
        pr.getFormu().getChamp("idcaisse").setLibelle("Caisse");
        pr.getFormu().getChamp("montant1").setLibelle("Montant min");
        pr.getFormu().getChamp("montant2").setLibelle("Montant max");
        pr.getFormu().getChamp("etat").setLibelle("&Eacute;tat");

        pr.creerObjetPage(libEntete, new String[]{"montant"});

        pr.getTableau().setLien(new String[]{pr.getLien() + "?but=cinema/achat/achat-fiche.jsp"});
        pr.getTableau().setColonneLien(new String[]{"id"});
        pr.getTableau().setLibelleAffiche(libEnteteAffiche);
        pr.getFormu().setAnotherButton(
            "<a class=\"btn btn-primary pull-right btn-small\" href=\"module.jsp?but=cinema/achat/achat-saisie.jsp&currentMenu=MENDYNCINEMA0401\">"
            + "<i class=\"material-symbols-rounded\">add</i>Saisie d'un achat</a>");
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
