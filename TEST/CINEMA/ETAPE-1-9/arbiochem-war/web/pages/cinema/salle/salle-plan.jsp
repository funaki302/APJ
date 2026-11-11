<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.salle.CinSalle"%>
<%@page import="cinema.salle.CinClassePlace"%>
<%@page import="cinema.salle.CinPlaceLib"%>
<%@page import="cinema.utils.CinUtils"%>
<%@page import="java.sql.Connection"%>
<%@page import="utilitaire.UtilDB"%>
<%--
    Modification du plan d'une salle : choisir un pinceau (une classe ou Hors service) puis cliquer
    sur une place, une lettre de rangee (toute la rangee) ou un numero de colonne (toute la colonne).
    Les changements sont envoyes a apres-salle-plan.jsp -> CinSalle.modifierPlaces.
--%>
<%
    try {
        String lien = (String) session.getValue("lien");
        String id = request.getParameter("id");
        String nomSalle;
        int planColonnes;
        CinPlaceLib[] planPlaces;
        CinClassePlace[] planClasses;
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            nomSalle = CinUtils.valeur(c, "select nom from CIN_SALLE where id = ?", id);
            if (nomSalle == null) throw new Exception("Salle introuvable");
            planColonnes = CinUtils.entier(c, "select nb_colonnes from CIN_SALLE where id = ?", id);
            planPlaces = CinSalle.getPlaces(id, c);
            planClasses = CinClassePlace.getClassesActives(c);
        } finally {
            if (c != null) c.close();
        }
        boolean planEditable = true;
%>
<style>
    .cin-pinceaux { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 8px; }
    .cin-pinceau { border: 2px solid transparent; border-radius: 8px; padding: 6px 12px; background: #f4f5f6; cursor: pointer; font-size: 13px; }
    .cin-pinceau.actif { border-color: #2B68D9; background: #e8effb; }
    .cin-pinceau span { display: inline-block; width: 14px; height: 14px; border-radius: 3px; border: 1px solid rgba(0,0,0,.25); vertical-align: middle; margin-right: 6px; }
</style>
<div class="content-wrapper">
    <h1 class="box-title"><a href="<%= lien %>?but=cinema/salle/salle-fiche.jsp&id=<%= id %>"><i class="fa fa-arrow-circle-left"></i></a>
        Plan de la salle <%= nomSalle %></h1>
    <div class="box">
        <div class="box-body">
            <p class="text-muted">1. Choisissez un pinceau. 2. Cliquez sur une place, sur une lettre (toute la rang&eacute;e) ou sur un num&eacute;ro (toute la colonne).
                3. Enregistrez. Les places modifi&eacute;es sont entour&eacute;es en bleu.</p>
            <div class="cin-pinceaux" id="cinPinceaux">
                <% for (CinClassePlace cl : planClasses) { %>
                <div class="cin-pinceau" data-valeur="<%= cl.getId() %>" data-couleur="<%= cl.getCouleur() %>">
                    <span style="background: <%= cl.getCouleur() %>;"></span><%= cl.getVal() %></div>
                <% } %>
                <div class="cin-pinceau" data-valeur="<%= CinSalle.HORS_SERVICE %>">
                    <span class="cin-place cin-hs" style="width: 14px; height: 14px;"></span>Hors service</div>
            </div>
            <%@ include file="../inc/plan-salle.jspf" %>
            <form action="<%= lien %>?but=cinema/salle/apres-salle-plan.jsp" method="post" id="cinFormPlan">
                <input type="hidden" name="idsalle" value="<%= id %>">
                <input type="hidden" name="modifs" id="cinModifs">
                <span id="cinNbModifs" class="text-muted">Aucune modification.</span>
                <button type="submit" class="btn btn-primary pull-right">Enregistrer le plan</button>
                <a class="btn btn-secondary pull-right" style="margin-right: 10px" href="<%= lien %>?but=cinema/salle/salle-plan.jsp&id=<%= id %>">Annuler les changements</a>
            </form>
        </div>
    </div>
</div>
<script>
    (function () {
        var HS = '<%= CinSalle.HORS_SERVICE %>';
        var pinceau = null, modifs = {};
        var pinceaux = document.querySelectorAll('#cinPinceaux .cin-pinceau');
        function choisir(p) {
            for (var i = 0; i < pinceaux.length; i++) pinceaux[i].classList.remove('actif');
            p.classList.add('actif');
            pinceau = p;
        }
        for (var i = 0; i < pinceaux.length; i++) pinceaux[i].addEventListener('click', function () { choisir(this); });
        if (pinceaux.length) choisir(pinceaux[0]);

        function peindre(place) {
            if (!pinceau) return;
            var valeur = pinceau.getAttribute('data-valeur');
            if (valeur === HS) {
                place.classList.add('cin-hs');
            } else {
                place.classList.remove('cin-hs');
                place.style.background = pinceau.getAttribute('data-couleur');
            }
            var inchangee = (valeur === HS) ? place.getAttribute('data-etat') === '0'
                    : (place.getAttribute('data-etat') === '1' && place.getAttribute('data-classe') === valeur);
            if (inchangee) { delete modifs[place.getAttribute('data-id')]; place.classList.remove('cin-modifiee'); }
            else { modifs[place.getAttribute('data-id')] = valeur; place.classList.add('cin-modifiee'); }
            var n = Object.keys(modifs).length;
            document.getElementById('cinNbModifs').textContent = n ? n + ' place(s) modifiée(s), non enregistrée(s).' : 'Aucune modification.';
        }
        var plan = document.getElementById('cinPlan');
        plan.addEventListener('click', function (e) {
            var cible = e.target;
            if (cible.classList.contains('cin-place') && cible.hasAttribute('data-id')) { peindre(cible); return; }
            if (cible.classList.contains('cin-entete')) {
                var attr = cible.hasAttribute('data-rangee') ? 'data-rangee' : 'data-colonne';
                var places = plan.querySelectorAll('.cin-place[data-id][' + attr + '="' + cible.getAttribute(attr) + '"]');
                for (var j = 0; j < places.length; j++) peindre(places[j]);
            }
        });
        document.getElementById('cinFormPlan').addEventListener('submit', function (e) {
            var liste = [];
            for (var idPlace in modifs) liste.push(idPlace + ':' + modifs[idPlace]);
            if (!liste.length) { e.preventDefault(); alert('Aucune modification à enregistrer.'); return; }
            document.getElementById('cinModifs').value = liste.join(';');
        });
    })();
</script>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
