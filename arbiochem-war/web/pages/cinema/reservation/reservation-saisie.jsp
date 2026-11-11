<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.diffusion.CinDiffusion"%>
<%@page import="cinema.diffusion.CinDiffusionLib"%>
<%@page import="cinema.reservation.CinTicket"%>
<%@page import="cinema.reservation.CinPlaceDiffusion"%>
<%@page import="cinema.salle.CinClassePlace"%>
<%@page import="cinema.utils.CinParametre"%>
<%@page import="cinema.utils.CinUtils"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.Date"%>
<%@page import="utilitaire.UtilDB"%>
<%--
    Reservation (maquette du bas) : seance, client, plan de la salle (places libres cliquables, prises barrees), total, Valider.
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
            CinDiffusionLib d;
            boolean ouverte;
            int delai;
            CinPlaceDiffusion[] planPlaces;
            CinClassePlace[] planClasses;
            String idClient = request.getParameter("idclient"), nomClient = null;
            Connection c = null;
            try {
                c = new UtilDB().GetConn();
                d = CinDiffusion.lireLib(idDiffusion, c);
                if (d == null) throw new Exception("S&eacute;ance introuvable");
                ouverte = CinTicket.reservationOuverte(idDiffusion, c);
                delai = CinParametre.getDelaiExpirationMinutes(c);
                planPlaces = CinTicket.getPlacesDiffusion(idDiffusion, c);
                planClasses = CinClassePlace.getClassesActives(c);
                if (!CinUtils.estVide(idClient)) nomClient = CinUtils.valeur(c, "select nom from CLIENT where id = ?", idClient);
            } finally {
                if (c != null) c.close();
            }
            int planColonnes = 0;
            for (CinPlaceDiffusion p : planPlaces) planColonnes = Math.max(planColonnes, p.getColonne());
            boolean planEditable = ouverte;
%>
<style>
    .cin-resa-entete { display: flex; gap: 14px; align-items: center; }
    .cin-resa-entete img { width: 120px; height: 80px; object-fit: cover; border-radius: 10px; background: #E9ECEF; }
    .cin-client { position: relative; max-width: 460px; }
    .cin-client-resultats { position: absolute; z-index: 20; left: 0; right: 0; background: #fff; border: 1px solid #C3C5C6; border-radius: 8px;
                            max-height: 260px; overflow-y: auto; display: none; }
    .cin-client-resultats div { padding: 6px 10px; cursor: pointer; }
    .cin-client-resultats div:hover { background: #e8effb; }
    .cin-total { font-size: 18px; }
</style>
<div class="content-wrapper">
    <h1 class="box-title"><a href="<%= lien %>?but=cinema/diffusion/diffusion-fiche.jsp&id=<%= idDiffusion %>"><i class="fa fa-arrow-circle-left"></i></a>
        R&eacute;servation</h1>
    <div class="box">
        <div class="box-body">
            <div class="cin-resa-entete">
                <img src="<%= urlPhoto + d.getIdfilm() %>" alt="">
                <div>
                    <h3 style="margin: 0;"><%= html(d.getIdfilmlib()) %></h3>
                    <div><%= html(d.getIdsallelib()) %> &middot; <%= CinDiffusion.formatDate(d.getDaty()) %> &middot;
                        <b><%= d.getHeure() %> &ndash; <%= d.getHeure_fin() %></b> (<%= html(d.getDureelib()) %>)</div>
                    <div class="text-muted">Une r&eacute;servation non pay&eacute;e expire <%= delai %> min avant le d&eacute;but de la s&eacute;ance.</div>
                </div>
            </div>
            <% if (!ouverte) { %>
            <div class="alert alert-warning" style="margin-top: 12px;">Les r&eacute;servations sont closes pour cette s&eacute;ance
                (annul&eacute;e, commenc&eacute;e ou moins de <%= delai %> min avant le d&eacute;but).</div>
            <% } %>
        </div>
    </div>
    <form action="<%= lien %>?but=cinema/reservation/apres-reservation.jsp" method="post" id="cinFormResa">
        <input type="hidden" name="iddiffusion" value="<%= idDiffusion %>">
        <input type="hidden" name="places" id="cinPlaces">
        <div class="box">
            <div class="box-body">
                <label>Client</label>
                <div style="display: flex; gap: 8px; align-items: flex-start; flex-wrap: wrap;">
                    <div class="cin-client">
                        <input type="hidden" name="idclient" id="cinIdClient" value="<%= nomClient == null ? "" : html(idClient) %>">
                        <input type="text" class="form-control" id="cinRechercheClient" autocomplete="off"
                               placeholder="Rechercher un client (nom, t&eacute;l&eacute;phone)" value="<%= html(nomClient) %>">
                        <div class="cin-client-resultats" id="cinResultatsClient"></div>
                    </div>
                    <a class="btn btn-secondary" target="_blank" href="<%= lien %>?but=client/client-saisie.jsp" title="Cr&eacute;er un client (nouvel onglet)">
                        <i class="material-symbols-rounded" style="font-size: 18px; vertical-align: middle;">person_add</i> Nouveau client</a>
                </div>
                <small class="text-muted">Apr&egrave;s avoir cr&eacute;&eacute; un client dans l'autre onglet, recherchez-le ici.</small>
            </div>
        </div>
        <div class="box">
            <div class="box-header with-border"><h3 class="box-title">Choisissez les places (cliquez sur une place libre)</h3></div>
            <div class="box-body">
                <%@ include file="../inc/plan-salle.jspf" %>
                <div style="display: flex; align-items: center; gap: 16px; flex-wrap: wrap; margin-top: 10px;">
                    <span class="cin-total">Places : <b id="cinListePlaces">aucune</b> &middot; Total : <b id="cinTotal">0</b> Ar</span>
                    <input type="text" name="remarque" class="form-control" style="max-width: 320px;" placeholder="Remarque (facultatif)" maxlength="500">
                    <button type="submit" class="btn btn-primary" style="margin-left: auto;" <%= ouverte ? "" : "disabled" %>>Valider la r&eacute;servation</button>
                </div>
            </div>
        </div>
    </form>
</div>
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
            if (!p.classList.contains('cin-place') || !p.hasAttribute('data-id') || !plan.classList.contains('cin-editable')) return;
            if (p.getAttribute('data-statut') !== '<%= CinPlaceDiffusion.LIBRE %>') return;
            var id = p.getAttribute('data-id');
            if (choisies[id]) { delete choisies[id]; p.classList.remove('cin-choisie'); }
            else { choisies[id] = {prix: parseFloat(p.getAttribute('data-prix')) || 0, numero: p.getAttribute('data-numero')}; p.classList.add('cin-choisie'); }
            maj();
        });

        // recherche de client
        var champ = document.getElementById('cinRechercheClient'), boite = document.getElementById('cinResultatsClient'),
            idClient = document.getElementById('cinIdClient'), minuteur = null;
        function texte(t) { var s = document.createElement('span'); s.textContent = t || ''; return s.innerHTML; }
        champ.addEventListener('input', function () {
            idClient.value = '';
            clearTimeout(minuteur);
            var q = champ.value.trim();
            if (!q) { boite.style.display = 'none'; return; }
            minuteur = setTimeout(function () {
                fetch('<%= request.getContextPath() %>/cinema/clients?q=' + encodeURIComponent(q), {credentials: 'same-origin'})
                    .then(function (r) { return r.json(); })
                    .then(function (liste) {
                        boite.innerHTML = liste.length ? '' : '<div class="text-muted">Aucun client</div>';
                        liste.forEach(function (cl) {
                            var ligne = document.createElement('div');
                            ligne.innerHTML = '<b>' + texte(cl.nom) + '</b> <span class="text-muted">' + texte(cl.tel) + ' &middot; ' + texte(cl.id) + '</span>';
                            ligne.addEventListener('click', function () { idClient.value = cl.id; champ.value = cl.nom; boite.style.display = 'none'; });
                            boite.appendChild(ligne);
                        });
                        boite.style.display = 'block';
                    });
            }, 250);
        });
        document.addEventListener('click', function (e) { if (!boite.contains(e.target) && e.target !== champ) boite.style.display = 'none'; });

        document.getElementById('cinFormResa').addEventListener('submit', function (e) {
            if (!idClient.value) { e.preventDefault(); alert('Choisissez le client dans la liste.'); champ.focus(); return; }
            if (!document.getElementById('cinPlaces').value) { e.preventDefault(); alert('Choisissez au moins une place sur le plan.'); }
        });
    })();
</script>
<%
        }
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
