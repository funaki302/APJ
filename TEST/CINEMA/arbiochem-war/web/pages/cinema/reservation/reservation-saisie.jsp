<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.diffusion.CinDiffusion"%>
<%@page import="cinema.diffusion.CinDiffusionLib"%>
<%@page import="cinema.reservation.CinTicket"%>
<%@page import="cinema.reservation.CinPlaceDiffusion"%>
<%@page import="cinema.salle.CinClassePlace"%>
<%@page import="cinema.utils.CinParametre"%>
<%@page import="cinema.utils.CinUtils"%>
<%@page import="affichage.PageInsert"%>
<%@page import="user.UserEJB"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.Date"%>
<%@page import="utilitaire.UtilDB"%>
<%--
    Reservation (maquette du bas) : seance, plan de la salle (places libres cliquables, prises barrees), total,
    client (champ APJ standard : recherche client.Client + bouton "+" de creation, comme les autres saisies), Valider.
    Sans parametre iddiffusion : choix d'une seance ouverte a la reservation.
    Envoi vers apres-reservation.jsp -> CinTicket.reserver (verrou sur la seance, places re-verifiees).
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
        String idDiffusion = request.getParameter("iddiffusion");
        String urlPhoto = request.getContextPath() + "/cinema/film-photo?id=";
        if (CinUtils.estVide(idDiffusion)) {
            // ---------- choix de la seance ----------
            Date aujourdhui = new Date(System.currentTimeMillis());
            Date dans15jours = new Date(System.currentTimeMillis() + 15L * 86400000);
            CinDiffusionLib[] seances = CinDiffusion.getDiffusionsEntre(aujourdhui, dans15jours, null, null);
            Connection c = null;
            java.util.List<CinDiffusionLib> ouvertes = new java.util.ArrayList<CinDiffusionLib>();
            try {
                c = new UtilDB().GetConn();
                for (CinDiffusionLib d : seances) if (CinTicket.reservationOuverte(d.getId(), c)) ouvertes.add(d);
            } finally {
                if (c != null) c.close();
            }
%>
<div class="content-wrapper">
    <h1>Nouvelle r&eacute;servation : choisir la s&eacute;ance</h1>
    <p class="text-muted">S&eacute;ances des 15 prochains jours encore ouvertes &agrave; la r&eacute;servation.</p>
    <% if (ouvertes.isEmpty()) { %>
    <p>Aucune s&eacute;ance ouverte. <a href="<%= lien %>?but=cinema/diffusion/diffusion-saisie.jsp">Programmer une diffusion</a></p>
    <% } %>
    <div style="display: flex; flex-direction: column; gap: 8px;">
        <% for (CinDiffusionLib d : ouvertes) { %>
        <a href="<%= lien %>?but=cinema/reservation/reservation-saisie.jsp&iddiffusion=<%= d.getId() %>"
           style="display: flex; align-items: center; gap: 14px; padding: 8px; border: 1px solid #C3C5C6; border-radius: 12px; background: #fff; color: inherit;">
            <img src="<%= urlPhoto + d.getIdfilm() %>" alt="" style="width: 80px; height: 54px; object-fit: cover; border-radius: 8px; background: #E9ECEF;">
            <div style="flex: 1;"><b><%= html(d.getIdfilmlib()) %></b><br><span class="text-muted"><%= html(d.getIdsallelib()) %></span></div>
            <div style="text-align: right;"><b><%= CinDiffusion.formatDate(d.getDaty()) %></b><br><%= d.getHeure() %> &ndash; <%= d.getHeure_fin() %></div>
            <i class="material-symbols-rounded">arrow_forward</i>
        </a>
        <% } %>
    </div>
</div>
<%
        } else {
            // ---------- reservation sur le plan ----------
            UserEJB u = (UserEJB) session.getValue("u");
            CinDiffusionLib d;
            boolean ouverte;
            int delai;
            CinPlaceDiffusion[] planPlaces;
            CinClassePlace[] planClasses;
            Connection c = null;
            try {
                c = new UtilDB().GetConn();
                d = CinDiffusion.lireLib(idDiffusion, c);
                if (d == null) throw new Exception("S&eacute;ance introuvable");
                ouverte = CinTicket.reservationOuverte(idDiffusion, c);
                delai = CinParametre.getDelaiExpirationMinutes(c);
                planPlaces = CinTicket.getPlacesDiffusion(idDiffusion, c);
                planClasses = CinClassePlace.getClassesActives(c);
            } finally {
                if (c != null) c.close();
            }
            int planColonnes = 0;
            for (CinPlaceDiffusion p : planPlaces) planColonnes = Math.max(planColonnes, p.getColonne());
            boolean planEditable = ouverte;

            // formulaire APJ standard pour le client (meme recherche et meme bouton "+" que les autres saisies)
            PageInsert pi = new PageInsert(new CinTicket(), request, u);
            pi.setLien(lien);
            pi.getFormu().getChamp("idclient").setLibelle("Client");
            pi.getFormu().getChamp("idclient").setPageAppelComplete("client.Client", "id", "Client");
            pi.getFormu().getChamp("idclient").setPageAppelInsert("client/client-saisie.jsp", "idclient;idclientlibelle", "id;nom");
            if (request.getParameter("idclient") != null) pi.getFormu().getChamp("idclient").setDefaut(request.getParameter("idclient"));
            pi.getFormu().getChamp("remarque").setLibelle("Remarque (facultatif)");
            for (String cache : new String[]{"iddiffusion", "daty_reservation", "heure_reservation", "montant", "etat"}) {
                pi.getFormu().getChamp(cache).setVisible(false);
            }
            pi.getFormu().setOrdre(new String[]{"idclient", "remarque"});
            pi.preparerDataFormu();
%>
<div class="content-wrapper">
    <h1><a href="<%= lien %>?but=cinema/diffusion/diffusion-fiche.jsp&id=<%= idDiffusion %>"><i class="fa fa-arrow-circle-left"></i></a>
        R&eacute;servation &mdash; <%= html(d.getIdfilmlib()) %></h1>
    <div class="row">
        <div class="col-md-4">
            <div class="box">
                <div class="box-body">
                    <img src="<%= urlPhoto + d.getIdfilm() %>" alt=""
                         style="width: 100%; max-height: 200px; object-fit: contain; background: #E9ECEF; border-radius: 10px;">
                    <table class="table table-condensed" style="margin-top: 10px;">
                        <tr><th>Film</th><td><%= html(d.getIdfilmlib()) %></td></tr>
                        <tr><th>Salle</th><td><%= html(d.getIdsallelib()) %></td></tr>
                        <tr><th>Date</th><td><%= CinDiffusion.formatDate(d.getDaty()) %></td></tr>
                        <tr><th>Horaire</th><td><%= d.getHeure() %> &ndash; <%= d.getHeure_fin() %> (<%= html(d.getDureelib()) %>)</td></tr>
                    </table>
                    <p class="text-muted">Une r&eacute;servation non pay&eacute;e expire <%= delai %> min avant le d&eacute;but de la s&eacute;ance.</p>
                    <% if (!ouverte) { %>
                    <div class="alert alert-warning">Les r&eacute;servations sont closes pour cette s&eacute;ance
                        (annul&eacute;e, commenc&eacute;e ou moins de <%= delai %> min avant le d&eacute;but).</div>
                    <% } %>
                </div>
            </div>
            <% if (ouverte) { %>
            <div class="box">
                <div class="box-body">
                    <p><b>Places choisies :</b> <span id="cinListePlaces">aucune</span><br>
                        <b>Total :</b> <span id="cinTotal">0</span> Ar</p>
                    <form action="<%= lien %>?but=cinema/reservation/apres-reservation.jsp" method="post" id="cinFormResa">
                        <input type="hidden" name="iddiffusion" value="<%= html(idDiffusion) %>">
                        <input type="hidden" name="places" id="cinPlaces">
                        <%
                            pi.getFormu().makeHtmlInsertTabIndex();
                            out.println(pi.getFormu().getHtmlInsert());
                        %>
                    </form>
                </div>
            </div>
            <% } %>
        </div>
        <div class="col-md-8">
            <div class="box">
                <div class="box-header with-border"><h3 class="box-title">Cliquez sur les places libres</h3></div>
                <div class="box-body">
                    <%@ include file="../inc/plan-salle.jspf" %>
                </div>
            </div>
        </div>
    </div>
</div>
<% if (ouverte) { %>
<script>
    (function () {
        var choisies = {};
        var plan = document.getElementById('cinPlan');
        function maj() {
            var ids = Object.keys(choisies), total = 0, numeros = [];
            ids.forEach(function (id) { total += choisies[id].prix; numeros.push(choisies[id].numero); });
            document.getElementById('cinTotal').textContent = total.toLocaleString('fr-FR');
            document.getElementById('cinListePlaces').textContent = numeros.length ? numeros.join(', ') : 'aucune';
            document.getElementById('cinPlaces').value = ids.join(',');
        }
        plan.addEventListener('click', function (e) {
            var p = e.target;
            if (!p.classList.contains('cin-place') || !p.hasAttribute('data-id')) return;
            if (p.getAttribute('data-statut') !== '<%= CinPlaceDiffusion.LIBRE %>') return;
            var id = p.getAttribute('data-id');
            if (choisies[id]) { delete choisies[id]; p.classList.remove('cin-choisie'); }
            else { choisies[id] = {prix: parseFloat(p.getAttribute('data-prix')) || 0, numero: p.getAttribute('data-numero')}; p.classList.add('cin-choisie'); }
            maj();
        });
        document.getElementById('cinFormResa').addEventListener('submit', function (e) {
            var client = this.elements['idclient'];
            if (!client || !client.value) { e.preventDefault(); alert('Choisissez le client.'); return; }
            if (!document.getElementById('cinPlaces').value) { e.preventDefault(); alert('Choisissez au moins une place sur le plan.'); }
        });
    })();
</script>
<% } %>
<%
        }
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
