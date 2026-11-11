<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.reservation.CinClient"%>
<%@page import="cinema.reservation.CinTicketLib"%>
<%@page import="cinema.paiement.CinPaiementLib"%>
<%@page import="cinema.diffusion.CinDiffusion"%>
<%@page import="affichage.PageConsulte"%>
<%@page import="user.UserEJB"%>
<%-- Fiche client du cinema : totaux, reservations (tickets) et paiements du client --%>
<%!
    static String html(String s) {
        if (s == null) return "";
        // les textes de la base peuvent contenir des entites HTML (ex. &eacute;) : on garde les entites valides, on neutralise le reste
        return s.replaceAll("&(?!#?[a-zA-Z0-9]+;)", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        PageConsulte pc = new PageConsulte(new CinClient(), request, u);
        pc.setTitre("Client du cin&eacute;ma");
        CinClient cl = (CinClient) pc.getBase();
        String id = cl.getTuppleID();
        pc.getChampByName("id").setLibelle("ID");
        pc.getChampByName("nom").setLibelle("Client");
        pc.getChampByName("telephone").setLibelle("T&eacute;l&eacute;phone");
        pc.getChampByName("mail").setLibelle("E-mail");
        pc.getChampByName("nb_tickets").setLibelle("Tickets");
        pc.getChampByName("nb_payes").setLibelle("Tickets pay&eacute;s");
        pc.getChampByName("nb_en_attente").setLibelle("R&eacute;servations en attente");
        pc.getChampByName("nb_places_payees").setLibelle("Places pay&eacute;es");
        pc.getChampByName("montant_paye").setLibelle("Montant pay&eacute; (Ar)");
        pc.getChampByName("derniere_reservation").setLibelle("Derni&egrave;re r&eacute;servation");
        String lien = (String) session.getValue("lien");
        CinTicketLib[] tickets = CinClient.getTickets(id, null);
        CinPaiementLib[] paiements = CinClient.getPaiements(id, null);
        java.text.DecimalFormat fmt = new java.text.DecimalFormat("#,##0");
%>
<div class="content-wrapper">
    <h1 class="box-title"><a href="<%= lien %>?but=cinema/client/client-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a><%= pc.getTitre() %></h1>
    <div class="row">
        <div class="col-md-4">
            <div class="box-fiche"><div class="box"><div class="box-body">
                <% out.println(pc.getHtml()); %>
                <div class="box-footer">
                    <a class="btn btn-primary pull-right" href="<%= lien %>?but=cinema/reservation/reservation-saisie.jsp">Nouvelle r&eacute;servation</a>
                    <a class="btn btn-secondary pull-left" href="<%= lien %>?but=client/client-fiche.jsp&id=<%= id %>">Fiche client compl&egrave;te</a>
                </div>
            </div></div></div>
        </div>
        <div class="col-md-8">
            <div class="box">
                <div class="box-header with-border"><h3 class="box-title">R&eacute;servations (<%= tickets.length %>)</h3></div>
                <div class="box-body">
                    <table class="table table-bordered table-condensed">
                        <thead><tr><th>Ticket</th><th>Film</th><th>Salle</th><th>S&eacute;ance</th><th style="text-align: right">Places</th>
                            <th style="text-align: right">Montant (Ar)</th><th>Statut</th></tr></thead>
                        <tbody>
                        <% if (tickets.length == 0) { %><tr><td colspan="7" class="text-muted">Aucune r&eacute;servation.</td></tr><% } %>
                        <% for (CinTicketLib t : tickets) { %>
                        <tr>
                            <td><a href="<%= lien %>?but=cinema/reservation/reservation-fiche.jsp&id=<%= t.getId() %>"><%= t.getId() %></a></td>
                            <td><%= html(t.getIdfilmlib()) %></td>
                            <td><%= html(t.getIdsallelib()) %></td>
                            <td><%= CinDiffusion.formatDate(t.getDaty_diffusion()) %> <%= t.getHeure() %></td>
                            <td style="text-align: right"><%= t.getNb_places() %></td>
                            <td style="text-align: right"><%= fmt.format(t.getMontant()) %></td>
                            <td><%= t.getEtatlib() %></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
            <div class="box">
                <div class="box-header with-border"><h3 class="box-title">Paiements (<%= paiements.length %>)</h3></div>
                <div class="box-body">
                    <table class="table table-bordered table-condensed">
                        <thead><tr><th>Paiement</th><th>Date</th><th>Film</th><th>Modes</th><th style="text-align: right">Montant (Ar)</th><th>Facture</th></tr></thead>
                        <tbody>
                        <% if (paiements.length == 0) { %><tr><td colspan="6" class="text-muted">Aucun paiement.</td></tr><% } %>
                        <% for (CinPaiementLib p : paiements) { %>
                        <tr>
                            <td><a href="<%= lien %>?but=cinema/paiement/paiement-fiche.jsp&id=<%= p.getId() %>"><%= p.getId() %></a></td>
                            <td><%= CinDiffusion.formatDate(p.getDaty()) %> <%= p.getHeure_paiement() == null ? "" : p.getHeure_paiement() %></td>
                            <td><%= html(p.getIdfilmlib()) %></td>
                            <td><%= html(p.getModes()) %></td>
                            <td style="text-align: right"><%= fmt.format(p.getMontant()) %></td>
                            <td><a href="<%= lien %>?but=cinema/facture/facture-fiche.jsp&id=<%= p.getIdfacture() %>"><%= html(p.getNumero_facture()) %></a></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
