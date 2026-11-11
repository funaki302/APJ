<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.utils.CinReinitialisation"%>
<%@page import="java.util.Map"%>
<%-- Reinitialisation des donnees du cinema (tout sauf la configuration), avec option de rechargement de la demonstration --%>
<%
    try {
        String lien = (String) session.getValue("lien");
        Map<String, Integer> apercu = CinReinitialisation.apercu(null);
        int total = 0;
        for (Integer n : apercu.values()) total += n;
%>
<div class="content-wrapper">
    <h1>R&eacute;initialiser les donn&eacute;es du cin&eacute;ma</h1>
    <div class="row m-0">
        <div class="col-md-8 col-md-offset-2">
            <div class="box box-danger">
                <div class="box-body">
                    <p>Cette action efface <b>d&eacute;finitivement</b> toutes les donn&eacute;es du cin&eacute;ma : tickets, paiements, factures,
                        achats, s&eacute;ances, salles et places, films et leurs photos, acteurs, clients cr&eacute;&eacute;s pour le cin&eacute;ma
                        (<code>CLICIN...</code>), mouvements et reports de la Caisse Cin&eacute;ma.</p>
                    <p><b>Conserv&eacute;s :</b> le cin&eacute;ma, les classes de place, les cat&eacute;gories de film, les param&egrave;tres,
                        les caisses par mode de paiement, la Caisse Cin&eacute;ma, les menus et tout le reste de l'application
                        (ventes, autres caisses, vrais clients...).</p>
                    <table class="table table-bordered table-condensed">
                        <thead><tr><th>Donn&eacute;es</th><th style="text-align: right">Nombre actuel</th></tr></thead>
                        <tbody>
                        <% for (Map.Entry<String, Integer> ligne : apercu.entrySet()) { %>
                        <tr><td><%= ligne.getKey() %></td><td style="text-align: right"><%= ligne.getValue() %></td></tr>
                        <% } %>
                        </tbody>
                        <tfoot><tr><th>Total</th><th style="text-align: right"><%= total %></th></tr></tfoot>
                    </table>
                    <form action="<%= lien %>?but=cinema/parametre/apres-reinitialisation.jsp" method="post" onsubmit="return cinConfirmer();">
                        <div class="form-group">
                            <label><input type="radio" name="action" value="reinitialiser" checked> R&eacute;initialiser seulement (le cin&eacute;ma repart vide)</label><br>
                            <label><input type="radio" name="action" value="demo"> R&eacute;initialiser puis <b>recharger les donn&eacute;es de d&eacute;monstration</b>
                                (films, salles, s&eacute;ances de demain, tickets, un ticket pay&eacute;...)</label>
                        </div>
                        <div class="form-group">
                            <label for="cinConfirmation">Pour confirmer, tapez <b>REINITIALISER</b></label>
                            <input type="text" class="form-control" id="cinConfirmation" name="confirmation" autocomplete="off">
                        </div>
                        <button type="submit" class="btn btn-danger pull-right">Valider</button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
<script>
    function cinConfirmer() {
        if (document.getElementById('cinConfirmation').value !== 'REINITIALISER') {
            alert('Tapez REINITIALISER pour confirmer.');
            return false;
        }
        return confirm('Effacer définitivement les données du cinéma ? Cette action est irréversible.');
    }
</script>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
