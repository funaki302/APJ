<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.achat.CinAchat"%>
<%@page import="cinema.achat.CinAchatLib"%>
<%@page import="cinema.achat.CinAchatFilleLib"%>
<%@page import="affichage.PageConsulte"%>
<%@page import="constante.ConstanteEtat"%>
<%@page import="user.UserEJB"%>
<%-- Fiche d'un achat : lignes, visa (sortie de caisse), annulation avant visa --%>
<%!
    static String html(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        PageConsulte pc = new PageConsulte(new CinAchatLib(), request, u);
        pc.setTitre("Fiche de l'achat");
        CinAchatLib achat = (CinAchatLib) pc.getBase();
        String id = achat.getTuppleID();
        pc.getChampByName("id").setLibelle("ID");
        pc.getChampByName("daty").setLibelle("Date");
        pc.getChampByName("fournisseur").setLibelle("Fournisseur");
        pc.getChampByName("idcaisselib").setLibelle("Caisse qui paie");
        pc.getChampByName("idmodepaiementlib").setLibelle("Mode de paiement");
        pc.getChampByName("montant").setLibelle("Montant (Ar)");
        pc.getChampByName("remarque").setLibelle("Remarque");
        pc.getChampByName("idmvtcaisse").setLibelle("Mouvement de caisse");
        pc.getChampByName("etatlib").setLibelle("&Eacute;tat");
        pc.getChampByName("nb_lignes").setLibelle("Nombre de lignes");
        pc.getChampByName("idcaisse").setVisible(false);
        pc.getChampByName("idmodepaiement").setVisible(false);
        pc.getChampByName("etat").setVisible(false);
        String lien = (String) session.getValue("lien");
        String pageFiche = "cinema/achat/achat-fiche.jsp";
        String classe = "cinema.achat.CinAchat";
        boolean vise = achat.getEtat() >= ConstanteEtat.getEtatValider();
        boolean annule = achat.getEtat() == ConstanteEtat.getEtatAnnuler();
        CinAchatFilleLib[] lignes = CinAchat.getLignes(id, null);
        java.text.DecimalFormat fmt = new java.text.DecimalFormat("#,##0");
%>
<div class="content-wrapper">
    <h1 class="box-title"><a href="<%= lien %>?but=cinema/achat/achat-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a><%= pc.getTitre() %></h1>
    <div class="row">
        <div class="col-md-5">
            <div class="box-fiche">
                <div class="box">
                    <div class="box-body">
                        <% out.println(pc.getHtml()); %>
                        <% if (vise && achat.getIdmvtcaisse() != null) { %>
                        <p><a href="<%= lien %>?but=caisse/mvt/mvtCaisse-fiche.jsp&id=<%= achat.getIdmvtcaisse() %>">Voir le mouvement de caisse</a></p>
                        <% } %>
                        <div class="box-footer">
                            <% if (!vise && !annule) { %>
                            <a class="btn btn-primary pull-right" href="<%= lien %>?but=apresTarif.jsp&id=<%= id %>&acte=valider&bute=<%= pageFiche %>&classe=<%= classe %>"
                               onclick="return confirm('Viser cet achat ? <%= fmt.format(achat.getMontant()) %> Ar vont sortir de la caisse <%= html(achat.getIdcaisselib()).replace("'", "\\'") %>.');">Viser (sortie de caisse)</a>
                            <a class="btn btn-secondary pull-right" style="margin-right: 10px" href="<%= lien %>?but=apresTarif.jsp&id=<%= id %>&acte=annuler&bute=<%= pageFiche %>&classe=<%= classe %>"
                               onclick="return confirm('Annuler cet achat ?');">Annuler</a>
                            <% } else if (vise) { %>
                            <span class="text-success"><b>Achat vis&eacute;</b> : <%= fmt.format(achat.getMontant()) %> Ar sortis de la caisse.</span>
                            <% } else { %>
                            <span class="text-muted"><b>Achat annul&eacute;</b> : aucune sortie de caisse.</span>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-7">
            <div class="box">
                <div class="box-header with-border"><h3 class="box-title">Lignes de l'achat</h3></div>
                <div class="box-body">
                    <table class="table table-bordered table-condensed">
                        <thead><tr><th>Type</th><th>D&eacute;signation</th><th style="text-align: right">Qt&eacute;</th>
                            <th style="text-align: right">Prix unitaire (Ar)</th><th style="text-align: right">Montant (Ar)</th></tr></thead>
                        <tbody>
                        <% for (CinAchatFilleLib l : lignes) { %>
                        <tr>
                            <td><%= l.getTypelib() %></td>
                            <td><% if (l.getIdfilm() != null) { %><a href="<%= lien %>?but=cinema/film/film-fiche.jsp&id=<%= l.getIdfilm() %>"><%= html(l.getDesignationlib()) %></a><% } else { %><%= html(l.getDesignationlib()) %><% } %></td>
                            <td style="text-align: right"><%= l.getQte() %></td>
                            <td style="text-align: right"><%= fmt.format(l.getPu()) %></td>
                            <td style="text-align: right"><%= fmt.format(l.getMontant()) %></td>
                        </tr>
                        <% } %>
                        </tbody>
                        <tfoot><tr><th colspan="4" style="text-align: right">Total</th><th style="text-align: right"><%= fmt.format(achat.getMontant()) %></th></tr></tfoot>
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
