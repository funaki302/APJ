<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.reservation.CinTicket"%>
<%@page import="cinema.reservation.CinTicketLib"%>
<%@page import="cinema.reservation.CinTicketDetailLib"%>
<%@page import="cinema.reservation.CinPlaceDiffusion"%>
<%@page import="cinema.salle.CinClassePlace"%>
<%@page import="affichage.PageConsulte"%>
<%@page import="user.UserEJB"%>
<%-- Fiche d'une reservation (ticket) : infos, places reservees, plan de la seance, facturation (vente existante), annulation. --%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        PageConsulte pc = new PageConsulte(new CinTicketLib(), request, u);
        pc.setTitre("Fiche de la r&eacute;servation");
        CinTicketLib t = (CinTicketLib) pc.getBase();
        String id = t.getTuppleID();
        pc.getChampByName("id").setLibelle("Ticket");
        pc.getChampByName("idclientlib").setLibelle("Client");
        pc.getChampByName("telephone").setLibelle("T&eacute;l&eacute;phone");
        pc.getChampByName("idfilmlib").setLibelle("Film");
        pc.getChampByName("idsallelib").setLibelle("Salle");
        pc.getChampByName("daty_diffusion").setLibelle("Date de la s&eacute;ance");
        pc.getChampByName("heure").setLibelle("D&eacute;but");
        pc.getChampByName("heure_fin").setLibelle("Fin");
        pc.getChampByName("daty_reservation").setLibelle("R&eacute;serv&eacute; le");
        pc.getChampByName("heure_reservation").setLibelle("&agrave;");
        pc.getChampByName("nb_places").setLibelle("Nombre de places");
        pc.getChampByName("montant").setLibelle("Montant (Ar)");
        pc.getChampByName("date_limitelib").setLibelle("&Agrave; payer avant le");
        pc.getChampByName("numerofacture").setLibelle("Facture");
        pc.getChampByName("remarque").setLibelle("Remarque");
        pc.getChampByName("etatlib").setLibelle("Statut");
        for (String cache : new String[]{"idclient", "iddiffusion", "idfilm", "idsalle", "etat", "etat_diffusion", "actif", "idvente", "etat_vente"}) {
            pc.getChampByName(cache).setVisible(false);
        }
        String lien = (String) session.getValue("lien");
        java.text.DecimalFormat fmt = new java.text.DecimalFormat("#,##0");

        CinTicketDetailLib[] details = CinTicket.getDetails(id, null);
        CinPlaceDiffusion[] planPlaces = CinTicket.getPlacesDiffusion(t.getIddiffusion(), null);
        int planColonnes = 0;
        for (CinPlaceDiffusion p : planPlaces) planColonnes = Math.max(planColonnes, p.getColonne());
        CinClassePlace[] planClasses = CinClassePlace.getClassesActives(null);
        boolean planEditable = false;
        request.setAttribute("cinTicketCourant", id);
        boolean reserveActif = t.getEtat() == CinTicket.RESERVE && t.getActif() == 1;
%>
<div class="content-wrapper">
    <h1 class="box-title"><a href="<%= lien %>?but=cinema/reservation/reservation-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a><%= pc.getTitre() %></h1>
    <div class="row">
        <div class="col-md-5">
            <div class="box-fiche">
                <div class="box">
                    <div class="box-body">
                        <% out.println(pc.getHtml()); %>
                        <h4>Places r&eacute;serv&eacute;es</h4>
                        <table class="table table-bordered table-condensed">
                            <thead><tr><th>Place</th><th>Classe</th><th style="text-align: right">Prix (Ar)</th></tr></thead>
                            <tbody>
                            <% for (CinTicketDetailLib dt : details) { %>
                            <tr><td><b><%= dt.getNumero() %></b></td>
                                <td><span style="display: inline-block; width: 12px; height: 12px; border-radius: 3px; background: <%= dt.getCouleur() %>; margin-right: 6px;"></span><%= dt.getIdclasselib() %></td>
                                <td style="text-align: right"><%= fmt.format(dt.getPrix()) %></td></tr>
                            <% } %>
                            </tbody>
                            <tfoot><tr><th colspan="2" style="text-align: right">Total</th><th style="text-align: right"><%= fmt.format(t.getMontant()) %></th></tr></tfoot>
                        </table>
                        <div class="box-footer">
                            <% if (t.getEtat() == CinTicket.RESERVE) { %>
                            <% if (reserveActif) { %>
                            <a class="btn btn-primary pull-right" href="<%= lien %>?but=cinema/reservation/apres-facturation.jsp&idticket=<%= id %>"
                               onclick="return confirm('Cr&eacute;er et viser la facture de ce ticket (<%= fmt.format(t.getMontant()) %> Ar) ? Le paiement se fera ensuite sur la fiche de la facture.');">Payer</a>
                            <% } %>
                            <a class="btn btn-secondary pull-left" href="<%= lien %>?but=apresTarif.jsp&id=<%= id %>&acte=annuler&bute=cinema/reservation/reservation-fiche.jsp&classe=cinema.reservation.CinTicket"
                               onclick="return confirm('Annuler cette r&eacute;servation ? Les places seront lib&eacute;r&eacute;es.');">Annuler la r&eacute;servation</a>
                            <% if (!reserveActif) { %><p class="text-danger" style="clear: both; padding-top: 8px;">R&eacute;servation expir&eacute;e : ses places sont de nouveau libres.</p><% } %>
                            <% } else if (t.getEtat() == CinTicket.PAYE && t.getIdvente() != null) { %>
                            <span class="<%= t.getActif() == 1 ? "text-success" : "text-danger" %>"><b>Ticket <%= t.getEtatlib() %>.</b></span>
                            <% if (t.getActif() != 1) { %><p class="text-danger">La facture a &eacute;t&eacute; annul&eacute;e : les places sont de nouveau libres.</p><% } %>
                            <a class="btn btn-primary pull-right" href="<%= lien %>?but=vente/vente-arbiochem-fiche.jsp&id=<%= t.getIdvente() %>">Voir la facture <%= t.getNumerofacture() == null ? "" : t.getNumerofacture() %></a>
                            <% } else if (t.getEtat() == CinTicket.PAYE) {
                                   String[] paie = new String[2];
                                   java.sql.Connection cx = null;
                                   try {
                                       cx = new utilitaire.UtilDB().GetConn();
                                       paie[0] = cinema.utils.CinUtils.valeur(cx, "select id from CIN_PAIEMENT where idticket = ?", id);
                                       paie[1] = cinema.utils.CinUtils.valeur(cx, "select idfacture from CIN_PAIEMENT where idticket = ?", id);
                                   } finally {
                                       if (cx != null) cx.close();
                                   } %>
                            <span class="text-success"><b>Ticket pay&eacute;.</b></span>
                            <a class="btn btn-primary pull-right" href="<%= lien %>?but=cinema/facture/facture-fiche.jsp&id=<%= paie[1] %>">Voir la facture</a>
                            <a class="btn btn-secondary pull-right" style="margin-right: 8px" href="<%= lien %>?but=cinema/paiement/paiement-fiche.jsp&id=<%= paie[0] %>">Voir le paiement</a>
                            <% } else { %>
                            <span class="text-muted">R&eacute;servation <%= t.getEtatlib() %>.</span>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-7">
            <div class="box">
                <div class="box-header with-border">
                    <h3 class="box-title">S&eacute;ance : places de ce ticket encadr&eacute;es</h3>
                    <a class="btn btn-secondary btn-sm pull-right" href="<%= lien %>?but=cinema/diffusion/diffusion-fiche.jsp&id=<%= t.getIddiffusion() %>">Voir la s&eacute;ance</a>
                </div>
                <div class="box-body">
                    <%@ include file="../inc/plan-salle.jspf" %>
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
