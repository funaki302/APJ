<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.paiement.CinFactureLib"%>
<%@page import="affichage.PageRecherche"%>
<%-- Liste des factures cinema (creees automatiquement au paiement d'un ticket) --%>
<%
    try {
        CinFactureLib t = new CinFactureLib();
        String listeCrt[] = {"numero", "idclientlib", "daty", "montant"};
        String listeInt[] = {"daty", "montant"};
        String libEntete[] = {"id", "numero", "daty", "idclientlib", "idfilmlib", "idsallelib", "daty_diffusion", "heure", "nb_places", "montant"};
        String libEnteteAffiche[] = {"ID", "Num&eacute;ro", "Date", "Client", "Film", "Salle", "S&eacute;ance", "Heure", "Places", "Montant (Ar)"};

        PageRecherche pr = new PageRecherche(t, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
        pr.setTitre("Factures du cin&eacute;ma");
        pr.setUtilisateur((user.UserEJB) session.getValue("u"));
        pr.setLien((String) session.getValue("lien"));
        pr.setApres("cinema/facture/facture-liste.jsp");
        pr.getFormu().getChamp("numero").setLibelle("Num&eacute;ro");
        pr.getFormu().getChamp("idclientlib").setLibelle("Client");
        pr.getFormu().getChamp("daty1").setLibelle("Date min");
        pr.getFormu().getChamp("daty2").setLibelle("Date max");
        pr.getFormu().getChamp("montant1").setLibelle("Montant min");
        pr.getFormu().getChamp("montant2").setLibelle("Montant max");

        pr.creerObjetPage(libEntete, new String[]{"montant"});

        pr.getTableau().setLien(new String[]{pr.getLien() + "?but=cinema/facture/facture-fiche.jsp"});
        pr.getTableau().setColonneLien(new String[]{"id"});
        pr.getTableau().setLibelleAffiche(libEnteteAffiche);
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
