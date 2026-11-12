<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.reservation.CinClient"%>
<%@page import="cinema.reservation.CinTicketLib"%>
<%@page import="cinema.paiement.CinFactureVente"%>
<%@page import="cinema.diffusion.CinDiffusion"%>
<%@page import="affichage.PageConsulte"%>
<%@page import="user.UserEJB"%>
<%-- Fiche client du cinema : totaux, reservations (tickets) et factures (ventes) du client --%>
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
        pc.getChampByName("nb_payes").setLibelle("Tickets factur&eacute;s / pay&eacute;s");
        pc.getChampByName("nb_en_attente").setLibelle("R&eacute;servations en attente");
        pc.getChampByName("nb_places_payees").setLibelle("Places vendues");
        pc.getChampByName("montant_paye").setLibelle("Montant factur&eacute; (Ar)");
        pc.getChampByName("derniere_reservation").setLibelle("Derni&egrave;re r&eacute;servation");
        String lien = (String) session.getValue("lien");
        CinTicketLib[] tickets = CinClient.getTickets(id, null);
        CinFactureVente[] factures = CinClient.getFactures(id, null);
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
                <div class="box-header with-border"><h3 class="box-title">Factures (<%= factures.length %>)</h3></div>
                <div class="box-body">
                    <table class="table table-bordered table-condensed">
                        <thead><tr><th>Facture</th><th>Date</th><th>Ticket</th><th>Film</th><th style="text-align: right">Montant (Ar)</th>
                            <th style="text-align: right">Pay&eacute; (Ar)</th><th style="text-align: right">Reste (Ar)</th><th>&Eacute;tat</th></tr></thead>
                        <tbody>
                        <% if (factures.length == 0) { %><tr><td colspan="8" class="text-muted">Aucune facture.</td></tr><% } %>
                        <% for (CinFactureVente f : factures) { %>
                        <tr>
                            <td><a href="<%= lien %>?but=vente/vente-arbiochem-fiche.jsp&id=<%= f.getId() %>"><%= html(f.getNumerofacture() == null ? f.getId() : f.getNumerofacture()) %></a></td>
                            <td><%= CinDiffusion.formatDate(f.getDaty()) %></td>
                            <td><a href="<%= lien %>?but=cinema/reservation/reservation-fiche.jsp&id=<%= f.getIdticket() %>"><%= f.getIdticket() %></a></td>
                            <td><%= html(f.getIdfilmlib()) %></td>
                            <td style="text-align: right"><%= fmt.format(f.getMontant()) %></td>
                            <td style="text-align: right"><%= fmt.format(f.getMontantpaye()) %></td>
                            <td style="text-align: right"><%= fmt.format(f.getMontantreste()) %></td>
                            <td><%= f.getEtatlib() == null ? "" : f.getEtatlib() %></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
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
