<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.paiement.CinFacture"%>
<%@page import="cinema.paiement.CinFactureLib"%>
<%@page import="cinema.paiement.CinFactureDetail"%>
<%@page import="affichage.PageConsulte"%>
<%@page import="user.UserEJB"%>
<%-- Fiche d'une facture cinema : lignes (une par place), lien vers l'impression / export PDF --%>
<%!
    static String html(String s) {
        if (s == null) return "";
        // les textes de la base contiennent deja des entites HTML (ex. &eacute;) : on garde les entites valides, on neutralise le reste
        return s.replaceAll("&(?!#?[a-zA-Z0-9]+;)", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        PageConsulte pc = new PageConsulte(new CinFactureLib(), request, u);
        pc.setTitre("Facture");
        CinFactureLib f = (CinFactureLib) pc.getBase();
        String id = f.getTuppleID();
        pc.getChampByName("numero").setLibelle("Num&eacute;ro");
        pc.getChampByName("daty").setLibelle("Date");
        pc.getChampByName("idclientlib").setLibelle("Client");
        pc.getChampByName("telephone").setLibelle("T&eacute;l&eacute;phone");
        pc.getChampByName("idfilmlib").setLibelle("Film");
        pc.getChampByName("idsallelib").setLibelle("Salle");
        pc.getChampByName("daty_diffusion").setLibelle("S&eacute;ance le");
        pc.getChampByName("heure").setLibelle("&agrave;");
        pc.getChampByName("nb_places").setLibelle("Places");
        pc.getChampByName("montant").setLibelle("Montant (Ar)");
        for (String cache : new String[]{"id", "idclient", "idticket", "idpaiement", "iddiffusion", "etat"}) pc.getChampByName(cache).setVisible(false);
        String lien = (String) session.getValue("lien");
        CinFactureDetail[] lignes = CinFacture.getDetails(id, null);
        java.text.DecimalFormat fmt = new java.text.DecimalFormat("#,##0");
        String urlImpression = request.getContextPath() + "/pages/cinema/facture/facture-impression.jsp?id=" + id;
%>
<div class="content-wrapper">
    <h1 class="box-title"><a href="<%= lien %>?but=cinema/facture/facture-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a>Facture <%= html(f.getNumero()) %></h1>
    <% if ("1".equals(request.getParameter("nouvelle"))) { %>
    <div class="alert alert-success">Paiement enregistr&eacute; : le ticket est pay&eacute;, l'argent est entr&eacute; en caisse et la facture a &eacute;t&eacute; cr&eacute;&eacute;e.</div>
    <% } %>
    <div class="row">
        <div class="col-md-5">
            <div class="box-fiche"><div class="box"><div class="box-body">
                <% out.println(pc.getHtml()); %>
                <div class="box-footer">
                    <a class="btn btn-primary pull-right" target="_blank" href="<%= urlImpression %>">
                        <i class="material-symbols-rounded" style="font-size: 16px; vertical-align: middle;">print</i> Imprimer / exporter en PDF</a>
                    <a class="btn btn-secondary pull-left" href="<%= lien %>?but=cinema/paiement/paiement-fiche.jsp&id=<%= f.getIdpaiement() %>">Voir le paiement</a>
                </div>
            </div></div></div>
        </div>
        <div class="col-md-7">
            <div class="box">
                <div class="box-header with-border"><h3 class="box-title">D&eacute;tail</h3></div>
                <div class="box-body">
                    <table class="table table-bordered table-condensed">
                        <thead><tr><th>D&eacute;signation</th><th style="text-align: right">Prix (Ar)</th></tr></thead>
                        <tbody>
                        <% for (CinFactureDetail l : lignes) { %>
                        <tr><td><%= html(l.getDesignation()) %></td><td style="text-align: right"><%= fmt.format(l.getPrix()) %></td></tr>
                        <% } %>
                        </tbody>
                        <tfoot><tr><th style="text-align: right">Total</th><th style="text-align: right"><%= fmt.format(f.getMontant()) %></th></tr></tfoot>
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
