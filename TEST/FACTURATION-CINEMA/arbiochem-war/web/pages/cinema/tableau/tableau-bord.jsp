<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.utils.CinTableauBord"%>
<%@page import="java.sql.Date"%>
<%@page import="java.util.Calendar"%>
<%--
    Tableau de bord du cinema sur une periode (par defaut le mois en cours) :
    chiffres cles, recettes par film, remplissage des seances, derniers mouvements de caisse.
    Barres horizontales a une seule mesure (une couleur) ; remplissage = payees + reservees (deux couleurs + legende).
    Chaque graphique a son tableau de valeurs ; survol = infobulle.
--%>
<%!
    static String html(String s) {
        if (s == null) return "";
        return s.replaceAll("&(?!#?[a-zA-Z0-9]+;)", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    try {
        String lien = (String) session.getValue("lien");
        Calendar cal = Calendar.getInstance();
        cal.set(Calendar.DAY_OF_MONTH, 1);
        Date debut = new Date(cal.getTimeInMillis());
        cal.set(Calendar.DAY_OF_MONTH, cal.getActualMaximum(Calendar.DAY_OF_MONTH));
        Date fin = new Date(cal.getTimeInMillis());
        String pDebut = request.getParameter("debut"), pFin = request.getParameter("fin");
        if (pDebut != null && pDebut.matches("\\d{4}-\\d{2}-\\d{2}")) debut = Date.valueOf(pDebut);
        if (pFin != null && pFin.matches("\\d{4}-\\d{2}-\\d{2}")) fin = Date.valueOf(pFin);
        if (fin.before(debut)) { Date x = debut; debut = fin; fin = x; }

        CinTableauBord tb = CinTableauBord.calculer(debut, fin, null);
        java.text.DecimalFormat fmt = new java.text.DecimalFormat("#,##0");
        double maxFilm = 1;
        for (CinTableauBord.Ligne l : tb.recettesParFilm) maxFilm = Math.max(maxFilm, l.valeur1);
%>
<style>
    .cin-tb {
        --surface-1: #fcfcfb;
        --text-primary: #0b0b0b;
        --text-secondary: #52514e;
        --grille: #e4e3df;
        --series-1: #2a78d6;
        --series-2: #eb6834;
    }
    .cin-tb .cin-filtre { display: flex; flex-wrap: wrap; gap: 10px; align-items: flex-end; margin-bottom: 14px; }
    .cin-tb .cin-filtre label { display: block; font-size: 12px; color: var(--text-secondary); margin-bottom: 2px; }
    .cin-tb .cin-kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)); gap: 10px; margin-bottom: 14px; }
    .cin-tb .cin-kpi { background: var(--surface-1); border: 1px solid #C3C5C6; border-radius: 12px; padding: 12px 14px; }
    .cin-tb .cin-kpi .lib { font-size: 12px; color: var(--text-secondary); }
    .cin-tb .cin-kpi .val { font-size: 24px; font-weight: 600; color: var(--text-primary); line-height: 1.25; }
    .cin-tb .cin-kpi .sous { font-size: 12px; color: var(--text-secondary); }
    .cin-tb .cin-kpi.negatif .val { color: #b42318; }
    .cin-tb .cin-barres { display: flex; flex-direction: column; gap: 8px; }
    .cin-tb .cin-barre { display: grid; grid-template-columns: minmax(110px, 30%) 1fr auto; gap: 10px; align-items: center; font-size: 13px; }
    .cin-tb .cin-barre .nom { color: var(--text-primary); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .cin-tb .cin-barre .piste { display: flex; gap: 2px; height: 16px; background: transparent; border-left: 1px solid var(--grille); }
    .cin-tb .cin-barre .seg { height: 100%; border-radius: 0 4px 4px 0; min-width: 2px; }
    .cin-tb .cin-barre .seg.s1 { background: var(--series-1); }
    .cin-tb .cin-barre .seg.s2 { background: var(--series-2); }
    .cin-tb .cin-barre .seg.s1.avec-suite { border-radius: 0; }
    .cin-tb .cin-barre .valeur { color: var(--text-secondary); white-space: nowrap; font-variant-numeric: tabular-nums; }
    .cin-tb .cin-barre:hover .nom { color: #2B68D9; }
    .cin-tb .cin-legende { display: flex; gap: 16px; font-size: 12px; color: var(--text-secondary); margin-bottom: 8px; }
    .cin-tb .cin-legende span { display: inline-block; width: 12px; height: 12px; border-radius: 3px; margin-right: 5px; vertical-align: middle; }
    .cin-tb details { margin-top: 10px; font-size: 13px; }
    .cin-tb details summary { cursor: pointer; color: #2B68D9; }
    .cin-tb .num { text-align: right; font-variant-numeric: tabular-nums; }
</style>
<div class="content-wrapper cin-tb">
    <h1>Tableau de bord du cin&eacute;ma</h1>
    <form class="cin-filtre" method="get" action="<%= lien %>">
        <input type="hidden" name="but" value="cinema/tableau/tableau-bord.jsp">
        <div><label for="cinDebut">Du</label><input type="date" class="form-control" id="cinDebut" name="debut" value="<%= debut %>"></div>
        <div><label for="cinFin">Au</label><input type="date" class="form-control" id="cinFin" name="fin" value="<%= fin %>"></div>
        <button type="submit" class="btn btn-primary">Afficher</button>
        <span class="text-muted" style="margin-left: 6px;">P&eacute;riode : factures, achats vis&eacute;s et s&eacute;ances du <%= cinema.diffusion.CinDiffusion.formatDate(debut) %>
            au <%= cinema.diffusion.CinDiffusion.formatDate(fin) %></span>
    </form>

    <div class="cin-kpis">
        <div class="cin-kpi"><div class="lib">Recettes (tickets factur&eacute;s)</div><div class="val"><%= fmt.format(tb.recettes) %> Ar</div>
            <div class="sous"><%= tb.nbPaiements %> facture(s)</div></div>
        <div class="cin-kpi"><div class="lib">Places vendues</div><div class="val"><%= tb.placesVendues %></div>
            <div class="sous">places vendues sur la p&eacute;riode</div></div>
        <div class="cin-kpi"><div class="lib">R&eacute;servations en attente</div><div class="val"><%= tb.reservationsEnAttente %></div>
            <div class="sous"><%= fmt.format(tb.montantEnAttente) %> Ar &agrave; encaisser (aujourd'hui)</div></div>
        <div class="cin-kpi"><div class="lib">Achats vis&eacute;s</div><div class="val"><%= fmt.format(tb.achats) %> Ar</div>
            <div class="sous"><%= tb.nbAchats %> achat(s)</div></div>
        <div class="cin-kpi <%= tb.getResultat() < 0 ? "negatif" : "" %>"><div class="lib">R&eacute;sultat de la p&eacute;riode</div>
            <div class="val"><%= fmt.format(tb.getResultat()) %> Ar</div><div class="sous">recettes &minus; achats</div></div>
        <div class="cin-kpi <%= tb.soldeCaisseCinema < 0 ? "negatif" : "" %>"><div class="lib">Solde de la Caisse Cin&eacute;ma</div>
            <div class="val"><%= fmt.format(tb.soldeCaisseCinema) %> Ar</div><div class="sous">entr&eacute;es &minus; sorties, depuis le d&eacute;but</div></div>
    </div>

    <div class="row">
        <div class="col-md-6">
            <div class="box">
                <div class="box-header with-border"><h3 class="box-title">Recettes par film</h3></div>
                <div class="box-body">
                    <% if (tb.recettesParFilm.isEmpty()) { %>
                    <p class="text-muted">Aucune facture sur la p&eacute;riode.</p>
                    <% } else { %>
                    <div class="cin-barres">
                        <% for (CinTableauBord.Ligne l : tb.recettesParFilm) { %>
                        <div class="cin-barre" title="<%= html(l.libelle) %> : <%= fmt.format(l.valeur1) %> Ar, <%= (int) l.valeur2 %> place(s)">
                            <span class="nom"><a href="<%= lien %>?but=cinema/film/film-fiche.jsp&id=<%= l.id %>"><%= html(l.libelle) %></a></span>
                            <span class="piste"><span class="seg s1" style="width: <%= String.format(java.util.Locale.US, "%.2f", 100.0 * l.valeur1 / maxFilm) %>%;"></span></span>
                            <span class="valeur"><%= fmt.format(l.valeur1) %> Ar</span>
                        </div>
                        <% } %>
                    </div>
                    <details>
                        <summary>Voir le tableau</summary>
                        <table class="table table-condensed">
                            <thead><tr><th>Film</th><th class="num">Places vendues</th><th class="num">Recettes (Ar)</th></tr></thead>
                            <tbody>
                            <% for (CinTableauBord.Ligne l : tb.recettesParFilm) { %>
                            <tr><td><%= html(l.libelle) %></td><td class="num"><%= (int) l.valeur2 %></td><td class="num"><%= fmt.format(l.valeur1) %></td></tr>
                            <% } %>
                            </tbody>
                        </table>
                    </details>
                    <% } %>
                </div>
            </div>
        </div>
        <div class="col-md-6">
            <div class="box">
                <div class="box-header with-border"><h3 class="box-title">Remplissage des s&eacute;ances</h3></div>
                <div class="box-body">
                    <% if (tb.remplissage.isEmpty()) { %>
                    <p class="text-muted">Aucune s&eacute;ance programm&eacute;e sur la p&eacute;riode.</p>
                    <% } else { %>
                    <div class="cin-legende"><div><span style="background: var(--series-1);"></span>Places vendues</div>
                        <div><span style="background: var(--series-2);"></span>Places r&eacute;serv&eacute;es</div></div>
                    <div class="cin-barres">
                        <% for (CinTableauBord.Ligne l : tb.remplissage) {
                               double total = Math.max(1, l.total);
                               int pct = (int) Math.round(100.0 * (l.valeur1 + l.valeur2) / total); %>
                        <div class="cin-barre" title="<%= html(l.libelle) %> (<%= html(l.detail) %>) : <%= (int) l.valeur1 %> vendue(s), <%= (int) l.valeur2 %> r&eacute;serv&eacute;e(s) sur <%= (int) l.total %> places">
                            <span class="nom"><a href="<%= lien %>?but=cinema/diffusion/diffusion-fiche.jsp&id=<%= l.id %>"><%= html(l.libelle) %></a><br>
                                <small class="text-muted"><%= html(l.detail) %></small></span>
                            <span class="piste">
                                <% if (l.valeur1 > 0) { %><span class="seg s1 <%= l.valeur2 > 0 ? "avec-suite" : "" %>" style="width: <%= String.format(java.util.Locale.US, "%.2f", 100.0 * l.valeur1 / total) %>%;"></span><% } %>
                                <% if (l.valeur2 > 0) { %><span class="seg s2" style="width: <%= String.format(java.util.Locale.US, "%.2f", 100.0 * l.valeur2 / total) %>%;"></span><% } %>
                            </span>
                            <span class="valeur"><%= pct %> %</span>
                        </div>
                        <% } %>
                    </div>
                    <details>
                        <summary>Voir le tableau</summary>
                        <table class="table table-condensed">
                            <thead><tr><th>S&eacute;ance</th><th class="num">Vendues</th><th class="num">R&eacute;serv&eacute;es</th><th class="num">Places</th><th class="num">Remplissage</th></tr></thead>
                            <tbody>
                            <% for (CinTableauBord.Ligne l : tb.remplissage) { %>
                            <tr><td><%= html(l.libelle) %> &mdash; <%= html(l.detail) %></td><td class="num"><%= (int) l.valeur1 %></td>
                                <td class="num"><%= (int) l.valeur2 %></td><td class="num"><%= (int) l.total %></td>
                                <td class="num"><%= Math.round(100.0 * (l.valeur1 + l.valeur2) / Math.max(1, l.total)) %> %</td></tr>
                            <% } %>
                            </tbody>
                        </table>
                    </details>
                    <% } %>
                </div>
            </div>
        </div>
    </div>

    <div class="box">
        <div class="box-header with-border"><h3 class="box-title">Derniers mouvements de caisse du cin&eacute;ma</h3></div>
        <div class="box-body">
            <table class="table table-bordered table-condensed">
                <thead><tr><th>Date</th><th>D&eacute;signation</th><th>Caisse</th><th class="num">Entr&eacute;e (Ar)</th><th class="num">Sortie (Ar)</th></tr></thead>
                <tbody>
                <% if (tb.mouvements.isEmpty()) { %><tr><td colspan="5" class="text-muted">Aucun mouvement.</td></tr><% } %>
                <% for (CinTableauBord.Ligne l : tb.mouvements) { %>
                <tr><td><%= l.detail %></td>
                    <td><a href="<%= lien %>?but=caisse/mvt/mvtCaisse-fiche.jsp&id=<%= l.id %>"><%= html(l.libelle) %></a></td>
                    <td><%= html(l.detail2) %></td>
                    <td class="num"><%= l.valeur1 > 0 ? fmt.format(l.valeur1) : "" %></td>
                    <td class="num"><%= l.valeur2 > 0 ? fmt.format(l.valeur2) : "" %></td></tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>
</div>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
