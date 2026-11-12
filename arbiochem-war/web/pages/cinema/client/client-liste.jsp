<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.reservation.CinClient"%>
<%@page import="affichage.PageRecherche"%>
<%-- Clients du cinema (clients de la table CLIENT ayant au moins un ticket) avec leurs totaux. Tableau APJ standard. --%>
<%
    try {
        CinClient t = new CinClient();
        String listeCrt[] = {"id", "nom", "telephone", "montant_paye"};
        String listeInt[] = {"montant_paye"};
        String libEntete[] = {"id", "nom", "telephone", "nb_tickets", "nb_payes", "nb_en_attente", "nb_places_payees", "montant_paye", "derniere_reservation"};
        String libEnteteAffiche[] = {"ID", "Client", "T&eacute;l&eacute;phone", "Tickets", "Factur&eacute;s", "En attente", "Places vendues", "Montant factur&eacute; (Ar)", "Derni&egrave;re r&eacute;servation"};

        PageRecherche pr = new PageRecherche(t, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
        pr.setTitre("Clients du cin&eacute;ma");
        pr.setUtilisateur((user.UserEJB) session.getValue("u"));
        pr.setLien((String) session.getValue("lien"));
        pr.setApres("cinema/client/client-liste.jsp");
        pr.getFormu().getChamp("id").setLibelle("ID");
        pr.getFormu().getChamp("nom").setLibelle("Client");
        pr.getFormu().getChamp("telephone").setLibelle("T&eacute;l&eacute;phone");
        pr.getFormu().getChamp("montant_paye1").setLibelle("Montant factur&eacute; min");
        pr.getFormu().getChamp("montant_paye2").setLibelle("Montant factur&eacute; max");

        pr.creerObjetPage(libEntete, new String[]{"montant_paye"});

        pr.getTableau().setLien(new String[]{pr.getLien() + "?but=cinema/client/client-fiche.jsp"});
        pr.getTableau().setColonneLien(new String[]{"id"});
        pr.getTableau().setLibelleAffiche(libEnteteAffiche);
%>
<div class="content-wrapper">
    <section class="content-header">
        <h1><%= pr.getTitre() %></h1>
        <p class="text-muted">Clients qui ont au moins une r&eacute;servation. Les clients se cr&eacute;ent et se modifient dans les pages client de l'application.</p>
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
