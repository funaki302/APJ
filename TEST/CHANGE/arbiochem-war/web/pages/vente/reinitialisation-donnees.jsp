<%@page import="vente.ReinitialisationVente"%>
<%@page import="java.util.Map"%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    try {
        String lien = (String) session.getValue("lien");
        Map<String, Integer> apercu = ReinitialisationVente.apercu();
%>
<div class="content-wrapper">
    <h1>R&eacute;initialiser les donn&eacute;es clients</h1>
    <div class="row m-0">
        <div class="col-md-8 col-md-offset-2">
            <div class="box box-danger">
                <div class="box-body">
                    <p>
                        Cette action supprime <b>d&eacute;finitivement</b> tous les <b>clients</b>, toutes les <b>factures</b>
                        et tous les <b>avoirs</b>, ainsi que ce qui en d&eacute;pend : d&eacute;tails, liaisons de paiement,
                        &eacute;critures comptables et lettrages des factures/avoirs, plans de paiement, ristournes,
                        bons de commande client, bons de livraison client, proformas, encaissements et ch&egrave;ques clients.
                    </p>
                    <p>
                        <b>Conserv&eacute;s :</b> produits, tarifs, remises, magasins, caisses, fournisseurs et achats, utilisateurs, menus.
                        Les mouvements de stock et de caisse sont gard&eacute;s (soldes inchang&eacute;s) mais d&eacute;tach&eacute;s des ventes supprim&eacute;es.
                    </p>
                    <table class="table table-bordered table-condensed">
                        <thead><tr><th>Donn&eacute;es</th><th style="text-align: right">Nombre actuel</th></tr></thead>
                        <tbody>
                        <% for (Map.Entry<String, Integer> ligne : apercu.entrySet()) { %>
                            <tr><td><%= ligne.getKey() %></td><td style="text-align: right"><%= ligne.getValue() %></td></tr>
                        <% } %>
                        </tbody>
                    </table>
                    <form action="<%= lien %>?but=vente/apres-reinitialisation.jsp" method="post" onsubmit="return confirmerReinitialisation();">
                        <div class="form-group">
                            <label for="confirmation">Pour confirmer, tapez <b>REINITIALISER</b></label>
                            <input type="text" class="form-control" id="confirmation" name="confirmation" autocomplete="off">
                        </div>
                        <button type="submit" class="btn btn-danger pull-right">R&eacute;initialiser les donn&eacute;es</button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
<script>
    function confirmerReinitialisation() {
        if (document.getElementById('confirmation').value !== 'REINITIALISER') {
            alert('Tapez REINITIALISER pour confirmer.');
            return false;
        }
        return confirm('Supprimer définitivement les clients, factures et avoirs ? Cette action est irréversible.');
    }
</script>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">
    alert('<%= e.getMessage() == null ? "Erreur" : e.getMessage().replace("'", "\\'").replace("\n", " ") %>');
    history.back();
</script>
<% } %>
