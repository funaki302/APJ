<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.reservation.CinTicketLib"%>
<%@page import="cinema.film.CinFilm"%>
<%@page import="cinema.salle.CinSalle"%>
<%@page import="affichage.PageRecherche"%>
<%@page import="affichage.Liste"%>
<%-- Liste des reservations (tickets) : client, date de reservation, seance, salle, montant, statut --%>
<%
    try {
        CinTicketLib t = new CinTicketLib();
        String listeCrt[] = {"id", "idclientlib", "daty_reservation", "idfilm", "idsalle", "daty_diffusion", "iddiffusion", "etat"};
        String listeInt[] = {"daty_reservation", "daty_diffusion"};
        String libEntete[] = {"id", "idclientlib", "daty_reservation", "idfilmlib", "idsallelib", "daty_diffusion", "heure", "nb_places", "montant", "etatlib"};
        String libEnteteAffiche[] = {"ID", "Client", "R&eacute;serv&eacute; le", "Film", "Salle", "S&eacute;ance", "Heure", "Places", "Montant (Ar)", "Statut"};

        PageRecherche pr = new PageRecherche(t, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
        pr.setTitre("Liste des r&eacute;servations");
        pr.setUtilisateur((user.UserEJB) session.getValue("u"));
        pr.setLien((String) session.getValue("lien"));
        pr.setApres("cinema/reservation/reservation-liste.jsp");

        Liste[] liste = new Liste[3];
        liste[0] = new Liste("idfilm", new CinFilm(), "titre", "id");
        liste[1] = new Liste("idsalle", new CinSalle(), "nom", "id");
        liste[2] = new Liste("etat", new String[]{"Tous", "R&eacute;serv&eacute; / expir&eacute;", "Pay&eacute;", "Annul&eacute;"}, new String[]{"", "1", "11", "0"});
        pr.getFormu().changerEnChamp(liste);
        pr.getFormu().getChamp("id").setLibelle("ID");
        pr.getFormu().getChamp("idclientlib").setLibelle("Client");
        pr.getFormu().getChamp("daty_reservation1").setLibelle("R&eacute;serv&eacute; apr&egrave;s le");
        pr.getFormu().getChamp("daty_reservation2").setLibelle("R&eacute;serv&eacute; avant le");
        pr.getFormu().getChamp("idfilm").setLibelle("Film");
        pr.getFormu().getChamp("idsalle").setLibelle("Salle");
        pr.getFormu().getChamp("daty_diffusion1").setLibelle("S&eacute;ance apr&egrave;s le");
        pr.getFormu().getChamp("daty_diffusion2").setLibelle("S&eacute;ance avant le");
        pr.getFormu().getChamp("iddiffusion").setLibelle("S&eacute;ance (id)");
        pr.getFormu().getChamp("etat").setLibelle("&Eacute;tat");

        pr.creerObjetPage(libEntete, new String[]{"montant"});

        pr.getTableau().setLien(new String[]{pr.getLien() + "?but=cinema/reservation/reservation-fiche.jsp"});
        pr.getTableau().setColonneLien(new String[]{"id"});
        pr.getTableau().setLibelleAffiche(libEnteteAffiche);
        pr.getFormu().setAnotherButton(
            "<a class=\"btn btn-primary pull-right btn-small\" href=\"module.jsp?but=cinema/reservation/reservation-saisie.jsp&currentMenu=MENDYNCINEMA0601\">"
            + "<i class=\"material-symbols-rounded\">add</i>Nouvelle r&eacute;servation</a>");
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
