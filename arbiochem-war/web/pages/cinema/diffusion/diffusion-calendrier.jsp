<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.diffusion.CinDiffusion"%>
<%@page import="cinema.diffusion.CinDiffusionLib"%>
<%@page import="java.sql.Date"%>
<%@page import="java.util.Calendar"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.List"%>
<%@page import="java.util.LinkedHashMap"%>
<%@page import="java.util.Map"%>
<%--
    Calendrier des diffusions sur une semaine (lundi -> dimanche).
    Parametre semaine=AAAA-MM-JJ (n'importe quel jour de la semaine voulue) ; par defaut la semaine en cours.
    Une couleur par salle ; les seances annulees sont barrees.
--%>
<%!
    static String html(String s) {
        if (s == null) return "";
        // les textes de la base contiennent deja des entites HTML (ex. &eacute;) : on garde les entites valides, on neutralise le reste
        return s.replaceAll("&(?!#?[a-zA-Z0-9]+;)", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
    static final String[] COULEURS = {"#2B68D9", "#E67E22", "#16A085", "#8E44AD", "#C0392B", "#2C3E50", "#D35400", "#27AE60"};
%>
<%
    try {
        String lien = (String) session.getValue("lien");
        Calendar cal = Calendar.getInstance();
        String param = request.getParameter("semaine");
        if (param != null && param.matches("\\d{4}-\\d{2}-\\d{2}")) cal.setTime(Date.valueOf(param));
        cal.set(Calendar.HOUR_OF_DAY, 0);
        cal.set(Calendar.MINUTE, 0);
        cal.set(Calendar.SECOND, 0);
        cal.set(Calendar.MILLISECOND, 0);
        int decalage = (cal.get(Calendar.DAY_OF_WEEK) + 5) % 7; // lundi = 0
        cal.add(Calendar.DAY_OF_MONTH, -decalage);
        Date lundi = new Date(cal.getTimeInMillis());
        List<Date> jours = new ArrayList<Date>();
        for (int i = 0; i < 7; i++) {
            jours.add(new Date(cal.getTimeInMillis()));
            cal.add(Calendar.DAY_OF_MONTH, 1);
        }
        Date lundiSuivant = new Date(cal.getTimeInMillis());
        cal.add(Calendar.DAY_OF_MONTH, -14);
        Date lundiPrecedent = new Date(cal.getTimeInMillis());

        CinDiffusionLib[] diffusions = CinDiffusion.getDiffusionsEntre(lundi, lundiSuivant, null, null);
        Map<String, String> couleurSalle = new LinkedHashMap<String, String>();
        Map<String, String> nomSalle = new LinkedHashMap<String, String>();
        for (CinDiffusionLib d : diffusions) {
            if (!couleurSalle.containsKey(d.getIdsalle())) {
                couleurSalle.put(d.getIdsalle(), COULEURS[couleurSalle.size() % COULEURS.length]);
                nomSalle.put(d.getIdsalle(), d.getIdsallelib());
            }
        }
        String[] nomsJours = {"Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"};
        String aujourdhui = new Date(System.currentTimeMillis()).toString();
%>
<style>
    .cin-cal { display: grid; grid-template-columns: repeat(7, minmax(130px, 1fr)); gap: 8px; overflow-x: auto; }
    .cin-cal-jour { background: #fff; border: 1px solid #C3C5C6; border-radius: 10px; min-height: 220px; padding: 8px; }
    .cin-cal-jour.cin-aujourdhui { border: 2px solid #2B68D9; }
    .cin-cal-jour h5 { margin: 0 0 8px; font-weight: 600; }
    .cin-cal-seance { display: block; border-left: 4px solid; background: #f6f7f9; border-radius: 6px; padding: 4px 6px; margin-bottom: 6px;
                      font-size: 12px; color: #1C1F21; text-decoration: none; }
    .cin-cal-seance:hover { background: #e8effb; text-decoration: none; }
    .cin-cal-seance b { display: block; }
    .cin-cal-annulee { text-decoration: line-through; opacity: .5; }
    .cin-cal-legende { display: flex; flex-wrap: wrap; gap: 14px; margin: 10px 0; font-size: 13px; }
    .cin-cal-legende span { display: inline-block; width: 12px; height: 12px; border-radius: 3px; margin-right: 5px; vertical-align: middle; }
</style>
<div class="content-wrapper">
    <h1>Calendrier des diffusions</h1>
    <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
        <a class="btn btn-secondary btn-sm" href="<%= lien %>?but=cinema/diffusion/diffusion-calendrier.jsp&semaine=<%= lundiPrecedent %>">&larr; Semaine pr&eacute;c&eacute;dente</a>
        <b>Semaine du <%= CinDiffusion.formatDate(lundi) %> au <%= CinDiffusion.formatDate(jours.get(6)) %></b>
        <a class="btn btn-secondary btn-sm" href="<%= lien %>?but=cinema/diffusion/diffusion-calendrier.jsp&semaine=<%= lundiSuivant %>">Semaine suivante &rarr;</a>
        <a class="btn btn-link btn-sm" href="<%= lien %>?but=cinema/diffusion/diffusion-calendrier.jsp">Aujourd'hui</a>
        <a class="btn btn-primary btn-sm" style="margin-left: auto;" href="<%= lien %>?but=cinema/diffusion/diffusion-saisie.jsp">
            <i class="material-symbols-rounded" style="font-size: 16px; vertical-align: middle;">add</i> Programmer une diffusion</a>
    </div>
    <div class="cin-cal-legende">
        <% if (nomSalle.isEmpty()) { %><span class="text-muted" style="width: auto; height: auto;">Aucune diffusion cette semaine.</span><% } %>
        <% for (Map.Entry<String, String> s : nomSalle.entrySet()) { %>
        <div><span style="background: <%= couleurSalle.get(s.getKey()) %>;"></span><%= html(s.getValue()) %></div>
        <% } %>
    </div>
    <div class="cin-cal">
        <% for (int i = 0; i < 7; i++) {
               Date jour = jours.get(i); %>
        <div class="cin-cal-jour <%= jour.toString().equals(aujourdhui) ? "cin-aujourdhui" : "" %>">
            <h5><%= nomsJours[i] %> <span class="text-muted" style="font-weight: 400;"><%= CinDiffusion.formatDate(jour).substring(0, 5) %></span></h5>
            <% for (CinDiffusionLib d : diffusions) {
                   if (!d.getDaty().toString().equals(jour.toString())) continue; %>
            <a class="cin-cal-seance <%= d.getEtat() == CinDiffusion.ANNULEE ? "cin-cal-annulee" : "" %>" style="border-left-color: <%= couleurSalle.get(d.getIdsalle()) %>;"
               href="<%= lien %>?but=cinema/diffusion/diffusion-fiche.jsp&id=<%= d.getId() %>" title="<%= html(d.getIdfilmlib()) %> - <%= d.getEtatlib() %>">
                <b><%= d.getHeure() %> &ndash; <%= d.getHeure_fin() %></b><%= html(d.getIdfilmlib()) %><br>
                <span class="text-muted"><%= html(d.getIdsallelib()) %></span>
            </a>
            <% } %>
        </div>
        <% } %>
    </div>
</div>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
