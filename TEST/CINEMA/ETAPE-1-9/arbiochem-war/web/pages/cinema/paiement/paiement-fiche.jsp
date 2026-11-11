<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.paiement.CinPaiement"%>
<%@page import="cinema.paiement.CinPaiementLib"%>
<%@page import="cinema.paiement.CinPaiementDetailLib"%>
<%@page import="affichage.PageConsulte"%>
<%@page import="user.UserEJB"%>
<%-- Fiche d'un paiement : modes, caisses, mouvements de caisse crees, facture --%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        PageConsulte pc = new PageConsulte(new CinPaiementLib(), request, u);
        pc.setTitre("Fiche du paiement");
        CinPaiementLib p = (CinPaiementLib) pc.getBase();
        String id = p.getTuppleID();
        pc.getChampByName("id").setLibelle("Paiement");
        pc.getChampByName("idclientlib").setLibelle("Client");
        pc.getChampByName("idticket").setLibelle("Ticket");
        pc.getChampByName("idfilmlib").setLibelle("Film");
        pc.getChampByName("idsallelib").setLibelle("Salle");
        pc.getChampByName("daty_diffusion").setLibelle("S&eacute;ance le");
        pc.getChampByName("heure").setLibelle("&agrave;");
        pc.getChampByName("daty").setLibelle("Pay&eacute; le");
        pc.getChampByName("heure_paiement").setLibelle("&agrave;");
        pc.getChampByName("montant").setLibelle("Montant (Ar)");
        pc.getChampByName("modes").setLibelle("Modes");
        pc.getChampByName("numero_facture").setLibelle("Facture");
        for (String cache : new String[]{"idclient", "iddiffusion", "idfacture", "etat"}) pc.getChampByName(cache).setVisible(false);
        String lien = (String) session.getValue("lien");
        CinPaiementDetailLib[] lignes = CinPaiement.getDetails(id, null);
        java.text.DecimalFormat fmt = new java.text.DecimalFormat("#,##0");
%>
<div class="content-wrapper">
    <h1 class="box-title"><a href="<%= lien %>?but=cinema/paiement/paiement-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a><%= pc.getTitre() %></h1>
    <div class="row">
        <div class="col-md-5">
            <div class="box-fiche"><div class="box"><div class="box-body">
                <% out.println(pc.getHtml()); %>
                <div class="box-footer">
                    <a class="btn btn-primary pull-right" href="<%= lien %>?but=cinema/facture/facture-fiche.jsp&id=<%= p.getIdfacture() %>">Voir la facture</a>
                    <a class="btn btn-secondary pull-left" href="<%= lien %>?but=cinema/reservation/reservation-fiche.jsp&id=<%= p.getIdticket() %>">Voir le ticket</a>
                </div>
            </div></div></div>
        </div>
        <div class="col-md-7">
            <div class="box">
                <div class="box-header with-border"><h3 class="box-title">R&eacute;partition et entr&eacute;es de caisse</h3></div>
                <div class="box-body">
                    <table class="table table-bordered table-condensed">
                        <thead><tr><th>Mode</th><th>Caisse</th><th style="text-align: right">Montant (Ar)</th><th>Mouvement de caisse</th></tr></thead>
                        <tbody>
                        <% for (CinPaiementDetailLib l : lignes) { %>
                        <tr><td><%= l.getIdmodepaiementlib() %></td><td><%= l.getIdcaisselib() %></td>
                            <td style="text-align: right"><%= fmt.format(l.getMontant()) %></td>
                            <td><a href="<%= lien %>?but=caisse/mvt/mvtCaisse-fiche.jsp&id=<%= l.getIdmvtcaisse() %>"><%= l.getIdmvtcaisse() %></a></td></tr>
                        <% } %>
                        </tbody>
                        <tfoot><tr><th colspan="2" style="text-align: right">Total</th><th style="text-align: right"><%= fmt.format(p.getMontant()) %></th><th></th></tr></tfoot>
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
