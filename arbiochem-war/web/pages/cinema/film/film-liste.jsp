<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.film.CinFilmLib"%>
<%@page import="cinema.film.CinCategorieFilm"%>
<%@page import="cinema.film.CinActeur"%>
<%@page import="affichage.PageRecherche"%>
<%@page import="affichage.Liste"%>
<%@page import="bean.ClassMAPTable"%>
<%-- Liste des films en cartes (maquette film_liste) : la recherche et la pagination restent celles d'APJ --%>
<%!
    // les textes viennent de la base : on les echappe avant de les afficher
    static String html(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    try {
        CinFilmLib t = new CinFilmLib();
        String listeCrt[] = {"titre", "idcategorie", "idacteur", "duree", "etat"};
        String listeInt[] = {"duree"};
        String libEntete[] = {"id", "titre", "idacteurlib", "dureelib", "idcategorielib", "pa", "etatlib"};

        PageRecherche pr = new PageRecherche(t, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
        pr.setTitre("Liste des films");
        pr.setUtilisateur((user.UserEJB) session.getValue("u"));
        pr.setLien((String) session.getValue("lien"));
        pr.setApres("cinema/film/film-liste.jsp");

        Liste[] liste = new Liste[3];
        liste[0] = new Liste("idcategorie", new CinCategorieFilm(), "val", "id");
        liste[1] = new Liste("idacteur", new CinActeur(), "nom", "id");
        liste[2] = new Liste("etat", new String[]{"Tous", "Actif", "Inactif"}, new String[]{"", "1", "0"});
        pr.getFormu().changerEnChamp(liste);
        pr.getFormu().getChamp("titre").setLibelle("Titre");
        pr.getFormu().getChamp("idcategorie").setLibelle("Cat&eacute;gorie");
        pr.getFormu().getChamp("idacteur").setLibelle("Acteur");
        pr.getFormu().getChamp("duree1").setLibelle("Dur&eacute;e min (minutes)");
        pr.getFormu().getChamp("duree2").setLibelle("Dur&eacute;e max (minutes)");
        pr.getFormu().getChamp("etat").setLibelle("&Eacute;tat");
        pr.getFormu().setAnotherButton(
            "<a class=\"btn btn-primary pull-right btn-small\" href=\"module.jsp?but=cinema/film/film-saisie.jsp&currentMenu=MENDYNCINEMA0301\">"
            + "<i class=\"material-symbols-rounded\">add</i>Saisie d'un film</a>");

        pr.creerObjetPage(libEntete, null);
        ClassMAPTable[] films = pr.getListe();
        String lien = pr.getLien();
        String urlPhoto = request.getContextPath() + "/cinema/film-photo?id=";
%>
<style>
    .cin-films { display: flex; flex-direction: column; gap: 10px; }
    .cin-film { display: flex; align-items: center; gap: 16px; padding: 10px; border: 1px solid #C3C5C6; border-radius: 12px; background: #fff; }
    .cin-film img { width: 120px; height: 80px; object-fit: cover; border-radius: 8px; background: #E9ECEF; flex-shrink: 0; }
    .cin-film-infos { flex: 1; min-width: 0; }
    .cin-film-infos h4 { margin: 0 0 4px; font-weight: 600; }
    .cin-film-infos p { margin: 0; color: #666; font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .cin-film-duree { font-weight: 600; white-space: nowrap; }
    .cin-film-inactif { opacity: .55; }
    .cin-badge { display: inline-block; font-size: 11px; padding: 1px 8px; border-radius: 10px; background: #eef1f4; color: #555; margin-left: 6px; }
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
        <div class="cin-films">
            <% if (films == null || films.length == 0) { %>
            <p class="text-muted">Aucun film.</p>
            <% } else {
                   for (ClassMAPTable o : films) {
                       CinFilmLib f = (CinFilmLib) o; %>
            <div class="cin-film <%= f.getEtat() == 1 ? "" : "cin-film-inactif" %>">
                <img src="<%= urlPhoto + f.getId() %>" alt="" loading="lazy">
                <div class="cin-film-infos">
                    <h4><%= html(f.getTitre()) %> <span class="text-muted" style="font-weight: 400;">(<%= html(f.getIdacteurlib()) %>)</span>
                        <span class="cin-badge"><%= html(f.getIdcategorielib()) %></span>
                        <% if (f.getEtat() != 1) { %><span class="cin-badge">Inactif</span><% } %></h4>
                    <p><%= f.getDescription() == null ? "" : html(f.getDescription()) %></p>
                </div>
                <span class="cin-film-duree"><%= html(f.getDureelib()) %></span>
                <a class="btn btn-secondary btn-sm" href="<%= lien %>?but=cinema/film/film-fiche.jsp&id=<%= f.getId() %>">D&eacute;tail</a>
            </div>
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
