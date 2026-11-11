<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.paiement.CinPaiementLib"%>
<%@page import="affichage.PageRecherche"%>
<%-- Liste des paiements de tickets : client, seance, date, montant, modes utilises, facture --%>
<%
    try {
        CinPaiementLib t = new CinPaiementLib();
        String listeCrt[] = {"id", "idclientlib", "daty", "idticket", "numero_facture"};
        String listeInt[] = {"daty"};
        String libEntete[] = {"id", "daty", "heure_paiement", "idclientlib", "idfilmlib", "daty_diffusion", "idticket", "modes", "montant", "numero_facture"};
        String libEnteteAffiche[] = {"ID", "Pay&eacute; le", "&agrave;", "Client", "Film", "S&eacute;ance", "Ticket", "Modes", "Montant (Ar)", "Facture"};

        PageRecherche pr = new PageRecherche(t, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
        pr.setTitre("Liste des paiements");
        pr.setUtilisateur((user.UserEJB) session.getValue("u"));
        pr.setLien((String) session.getValue("lien"));
        pr.setApres("cinema/paiement/paiement-liste.jsp");
        pr.getFormu().getChamp("id").setLibelle("ID");
        pr.getFormu().getChamp("idclientlib").setLibelle("Client");
        pr.getFormu().getChamp("daty1").setLibelle("Pay&eacute; apr&egrave;s le");
        pr.getFormu().getChamp("daty2").setLibelle("Pay&eacute; avant le");
        pr.getFormu().getChamp("idticket").setLibelle("Ticket");
        pr.getFormu().getChamp("numero_facture").setLibelle("N&deg; facture");

        pr.creerObjetPage(libEntete, new String[]{"montant"});

        pr.getTableau().setLien(new String[]{pr.getLien() + "?but=cinema/paiement/paiement-fiche.jsp"});
        pr.getTableau().setColonneLien(new String[]{"id"});
        pr.getTableau().setLibelleAffiche(libEnteteAffiche);
%>
<div class="content-wrapper">
    <section class="content-header">
        <h1><%= pr.getTitre() %></h1>
        <p class="text-muted">Pour encaisser un ticket : ouvrez la r&eacute;servation et cliquez sur &laquo; Payer &raquo;.</p>
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
