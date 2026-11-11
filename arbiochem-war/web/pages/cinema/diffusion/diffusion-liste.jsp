<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.diffusion.CinDiffusion"%>
<%@page import="cinema.diffusion.CinDiffusionLib"%>
<%@page import="cinema.film.CinFilm"%>
<%@page import="cinema.salle.CinSalle"%>
<%@page import="affichage.PageRecherche"%>
<%@page import="affichage.Liste"%>
<%@page import="bean.ClassMAPTable"%>
<%-- Liste des diffusions en cartes (maquette « diffusion ») : recherche et pagination APJ --%>
<%!
    static String html(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    try {
        CinDiffusionLib t = new CinDiffusionLib();
        String listeCrt[] = {"daty", "idfilm", "idsalle", "etat"};
        String listeInt[] = {"daty"};
        String libEntete[] = {"id", "idfilmlib", "idsallelib", "daty", "heure", "heure_fin", "etatlib"};

        PageRecherche pr = new PageRecherche(t, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
        pr.setTitre("Liste des diffusions");
        pr.setUtilisateur((user.UserEJB) session.getValue("u"));
        pr.setLien((String) session.getValue("lien"));
        pr.setApres("cinema/diffusion/diffusion-liste.jsp");

        Liste[] liste = new Liste[3];
        liste[0] = new Liste("idfilm", new CinFilm(), "titre", "id");
        liste[1] = new Liste("idsalle", new CinSalle(), "nom", "id");
        liste[2] = new Liste("etat", new String[]{"Tous", "Programm&eacute;e", "Annul&eacute;e"}, new String[]{"", "1", "0"});
        pr.getFormu().changerEnChamp(liste);
        pr.getFormu().getChamp("daty1").setLibelle("Date min");
        pr.getFormu().getChamp("daty2").setLibelle("Date max");
        pr.getFormu().getChamp("idfilm").setLibelle("Film");
        pr.getFormu().getChamp("idsalle").setLibelle("Salle");
        pr.getFormu().getChamp("etat").setLibelle("&Eacute;tat");
        pr.getFormu().setAnotherButton(
            "<a class=\"btn btn-primary pull-right btn-small\" href=\"module.jsp?but=cinema/diffusion/diffusion-saisie.jsp&currentMenu=MENDYNCINEMA0501\">"
            + "<i class=\"material-symbols-rounded\">add</i>Programmer une diffusion</a>"
            + "<a class=\"btn btn-secondary pull-right btn-small\" style=\"margin-right: 8px\" href=\"module.jsp?but=cinema/diffusion/diffusion-calendrier.jsp&currentMenu=MENDYNCINEMA0503\">"
            + "<i class=\"material-symbols-rounded\">calendar_month</i>Calendrier</a>");

        pr.creerObjetPage(libEntete, null);
        ClassMAPTable[] diffusions = pr.getListe();
        String lien = pr.getLien();
        String urlPhoto = request.getContextPath() + "/cinema/film-photo?id=";
%>
<style>
    .cin-seances { display: flex; flex-direction: column; gap: 10px; }
    .cin-seance { display: flex; align-items: center; gap: 16px; padding: 10px; border: 1px solid #C3C5C6; border-radius: 12px; background: #fff;
                  color: inherit; text-decoration: none; }
    .cin-seance:hover { border-color: #2B68D9; text-decoration: none; }
    .cin-seance img { width: 90px; height: 60px; object-fit: cover; border-radius: 8px; background: #E9ECEF; flex-shrink: 0; }
    .cin-seance-infos { flex: 1; min-width: 0; }
    .cin-seance-infos h4 { margin: 0 0 2px; font-weight: 600; }
    .cin-seance-infos p { margin: 0; color: #666; font-size: 13px; }
    .cin-seance-heure { font-weight: 600; white-space: nowrap; text-align: right; }
    .cin-seance-annulee { opacity: .5; }
    .cin-seance-annulee h4 { text-decoration: line-through; }
    .cin-badge { display: inline-block; font-size: 11px; padding: 1px 8px; border-radius: 10px; background: #eef1f4; color: #555; margin-left: 6px; font-weight: 400; }
</style>
<div class="content-wrapper">
    <section class="content-header">
        <h1><%= pr.getTitre() %></h1>
    </section>
    <section class="content">
        <form action="<%= lien %>?but=<%= pr.getApres() %>" method="post">
            <% out.println(pr.getFormu().getHtmlEnsemble()); %>
        </form>
        <% out.println(pr.getTableauRecap().getHtml()); %>
        <br>
        <div class="cin-seances">
            <% if (diffusions == null || diffusions.length == 0) { %>
            <p class="text-muted">Aucune diffusion.</p>
            <% } else {
                   for (ClassMAPTable o : diffusions) {
                       CinDiffusionLib d = (CinDiffusionLib) o; %>
            <a class="cin-seance <%= d.getEtat() == CinDiffusion.ANNULEE ? "cin-seance-annulee" : "" %>"
               href="<%= lien %>?but=cinema/diffusion/diffusion-fiche.jsp&id=<%= d.getId() %>">
                <img src="<%= urlPhoto + d.getIdfilm() %>" alt="" loading="lazy">
                <div class="cin-seance-infos">
                    <h4><%= html(d.getIdfilmlib()) %> <span class="cin-badge"><%= d.getEtatlib() %></span></h4>
                    <p><%= html(d.getIdsallelib()) %> &middot; <%= CinDiffusion.formatDate(d.getDaty()) %></p>
                </div>
                <div class="cin-seance-heure"><%= d.getHeure() %> &ndash; <%= d.getHeure_fin() %><br>
                    <span class="text-muted" style="font-weight: 400;">(<%= html(d.getDureelib()) %>)</span></div>
                <i class="material-symbols-rounded">arrow_forward</i>
            </a>
            <%     }
               } %>
        </div>
        <br>
        <% out.println(pr.getBasPage()); %>
    </section>
</div>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
