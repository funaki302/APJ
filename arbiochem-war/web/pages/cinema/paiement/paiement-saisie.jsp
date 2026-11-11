<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.reservation.CinTicket"%>
<%@page import="cinema.reservation.CinTicketDetailLib"%>
<%@page import="cinema.paiement.CinModeCaisse"%>
<%@page import="cinema.paiement.CinModeCaisseLib"%>
<%@page import="cinema.utils.CinCaisse"%>
<%@page import="cinema.utils.CinUtils"%>
<%@page import="java.sql.Connection"%>
<%@page import="utilitaire.UtilDB"%>
<%--
    Paiement d'un ticket en UNE fois, avec un ou plusieurs modes (une ligne par mode).
    La caisse de chaque ligne est pre-remplie selon le mode (Configurations > Caisses par mode) et reste modifiable.
    Envoi vers apres-paiement.jsp -> CinPaiement.payer : entrees de caisse + facture + ticket paye.
--%>
<%!
    static String html(String s) {
        if (s == null) return "";
        // les textes de la base contiennent deja des entites HTML (ex. &eacute;) : on garde les entites valides, on neutralise le reste
        return s.replaceAll("&(?!#?[a-zA-Z0-9]+;)", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    try {
        String lien = (String) session.getValue("lien");
        String idTicket = request.getParameter("idticket");
        String[] infos;
        CinTicketDetailLib[] places;
        CinModeCaisseLib[] modes;
        String[][] caisses;
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            String sql = "select idclientlib, idfilmlib, idsallelib, to_char(daty_diffusion, 'DD/MM/YYYY'), heure, montant, etat, actif, date_limitelib"
                    + " from CIN_TICKET_LIB where id = ?";
            infos = new String[9];
            try (java.sql.PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, idTicket);
                try (java.sql.ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new Exception("Ticket introuvable");
                    for (int i = 0; i < 9; i++) infos[i] = rs.getString(i + 1);
                }
            }
            places = CinTicket.getDetails(idTicket, c);
            modes = CinModeCaisse.getModesActifs(c);
            caisses = CinCaisse.getCaissesActives(c);
        } finally {
            if (c != null) c.close();
        }
        double montant = Double.parseDouble(infos[5]);
        boolean payable = "1".equals(infos[6]) && "1".equals(infos[7]);
        java.text.DecimalFormat fmt = new java.text.DecimalFormat("#,##0");
        int nbLignes = 4;
%>
<style>
    .cin-paie td, .cin-paie th { vertical-align: middle !important; }
    .cin-reste { font-size: 18px; font-weight: 600; }
    .cin-reste.ok { color: #1E8449; }
    .cin-reste.ko { color: #C0392B; }
</style>
<div class="content-wrapper">
    <h1 class="box-title"><a href="<%= lien %>?but=cinema/reservation/reservation-fiche.jsp&id=<%= html(idTicket) %>"><i class="fa fa-arrow-circle-left"></i></a>
        Paiement du ticket <%= html(idTicket) %></h1>
    <div class="box">
        <div class="box-body">
            <p style="font-size: 16px; margin: 0;"><b><%= html(infos[0]) %></b> &mdash; <%= html(infos[1]) %>, <%= html(infos[2]) %>, le <%= infos[3] %> &agrave; <%= infos[4] %></p>
            <p class="text-muted" style="margin: 4px 0 0;">Places :
                <% for (CinTicketDetailLib p : places) { %><b><%= p.getNumero() %></b> (<%= p.getIdclasselib() %>, <%= fmt.format(p.getPrix()) %> Ar) <% } %></p>
            <h3 style="margin: 10px 0 0;">Montant &agrave; payer : <b><%= fmt.format(montant) %> Ar</b></h3>
            <% if (!payable) { %>
            <div class="alert alert-warning" style="margin-top: 10px;">Ce ticket n'est pas payable (d&eacute;j&agrave; pay&eacute;, annul&eacute; ou expir&eacute; &mdash; limite : <%= html(infos[8]) %>).</div>
            <% } else { %>
            <p class="text-muted">&Agrave; payer avant le <%= html(infos[8]) %>. Le paiement se fait <b>en une seule fois</b> : la somme des lignes doit &ecirc;tre &eacute;gale au montant.</p>
            <% } %>
        </div>
    </div>
    <% if (payable) { %>
    <form action="<%= lien %>?but=cinema/paiement/apres-paiement.jsp" method="post" id="cinFormPaie">
        <input type="hidden" name="idticket" value="<%= html(idTicket) %>">
        <div class="box">
            <div class="box-body">
                <table class="table cin-paie">
                    <thead><tr><th style="width: 30%">Mode de paiement</th><th style="width: 40%">Caisse</th><th style="width: 30%">Montant (Ar)</th></tr></thead>
                    <tbody>
                    <% for (int i = 0; i < nbLignes; i++) { %>
                    <tr class="cin-ligne" <%= i >= 2 ? "style=\"display: none\"" : "" %>>
                        <td><select name="mode" class="form-control cin-mode">
                            <% for (CinModeCaisseLib m : modes) { %>
                            <option value="<%= m.getIdmodepaiement() %>" data-caisse="<%= m.getIdcaisse() %>"
                                <%= (i == 0 && "0002".equals(m.getIdmodepaiement())) || (i == 1 && "MPCINMOB".equals(m.getIdmodepaiement())) ? "selected" : "" %>><%= m.getIdmodepaiementlib() %></option>
                            <% } %>
                        </select></td>
                        <td><select name="caisse" class="form-control cin-caisse">
                            <% for (String[] ca : caisses) { %><option value="<%= ca[0] %>"><%= ca[1] %></option><% } %>
                        </select></td>
                        <td><input type="number" name="montant" class="form-control cin-montant" min="0" step="1"
                                   value="<%= i == 0 ? String.valueOf((long) montant) : "" %>" placeholder="0"></td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
                <button type="button" class="btn btn-link" id="cinAjouterLigne">+ Ajouter un mode de paiement</button>
                <div style="display: flex; align-items: center; gap: 16px; margin-top: 8px;">
                    <span>Saisi : <b id="cinSaisi">0</b> Ar</span>
                    <span class="cin-reste" id="cinReste"></span>
                    <button type="submit" class="btn btn-primary" id="cinValider" style="margin-left: auto;">Valider le paiement</button>
                </div>
            </div>
        </div>
    </form>
    <% } %>
</div>
<% if (payable) { %>
<script>
    (function () {
        var total = <%= (long) montant %>;
        var lignes = document.querySelectorAll('.cin-ligne');
        function caisseDuMode(ligne) {
            var mode = ligne.querySelector('.cin-mode');
            var opt = mode.options[mode.selectedIndex];
            if (opt) ligne.querySelector('.cin-caisse').value = opt.getAttribute('data-caisse');
        }
        function maj() {
            var saisi = 0;
            for (var i = 0; i < lignes.length; i++) {
                if (lignes[i].style.display === 'none') continue;
                saisi += parseFloat(lignes[i].querySelector('.cin-montant').value) || 0;
            }
            var reste = total - saisi, el = document.getElementById('cinReste');
            document.getElementById('cinSaisi').textContent = saisi.toLocaleString('fr-FR');
            if (Math.abs(reste) < 0.005) { el.textContent = 'Compte juste'; el.className = 'cin-reste ok'; }
            else if (reste > 0) { el.textContent = 'Reste à répartir : ' + reste.toLocaleString('fr-FR') + ' Ar'; el.className = 'cin-reste ko'; }
            else { el.textContent = 'Trop saisi : ' + (-reste).toLocaleString('fr-FR') + ' Ar'; el.className = 'cin-reste ko'; }
            document.getElementById('cinValider').disabled = Math.abs(reste) >= 0.005;
        }
        for (var i = 0; i < lignes.length; i++) {
            caisseDuMode(lignes[i]);
            lignes[i].querySelector('.cin-mode').addEventListener('change', function () { caisseDuMode(this.closest('tr')); });
        }
        document.getElementById('cinAjouterLigne').addEventListener('click', function () {
            for (var i = 0; i < lignes.length; i++) if (lignes[i].style.display === 'none') { lignes[i].style.display = ''; break; }
        });
        document.getElementById('cinFormPaie').addEventListener('input', maj);
        document.getElementById('cinFormPaie').addEventListener('submit', function () {
            // une ligne cachee ne compte pas : on vide son montant
            for (var i = 0; i < lignes.length; i++) if (lignes[i].style.display === 'none') lignes[i].querySelector('.cin-montant').value = '';
        });
        maj();
    })();
</script>
<% } %>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
