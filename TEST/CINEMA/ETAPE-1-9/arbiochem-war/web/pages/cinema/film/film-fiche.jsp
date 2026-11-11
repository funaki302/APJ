<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.film.CinFilmLib"%>
<%@page import="affichage.PageConsulte"%>
<%@page import="user.UserEJB"%>
<%-- Fiche d'un film (maquette film_fiche) : photo en grand + ajout / changement / suppression de la photo --%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        PageConsulte pc = new PageConsulte(new CinFilmLib(), request, u);
        pc.setTitre("Fiche du film");
        CinFilmLib film = (CinFilmLib) pc.getBase();
        String id = film.getTuppleID();
        pc.getChampByName("id").setLibelle("ID");
        pc.getChampByName("titre").setLibelle("Titre");
        pc.getChampByName("idcategorielib").setLibelle("Cat&eacute;gorie");
        pc.getChampByName("idacteurlib").setLibelle("Acteur principal");
        pc.getChampByName("dureelib").setLibelle("Dur&eacute;e");
        pc.getChampByName("pa").setLibelle("Prix d'achat (Ar)");
        pc.getChampByName("description").setLibelle("Description");
        pc.getChampByName("date_creation").setLibelle("Date de cr&eacute;ation");
        pc.getChampByName("etatlib").setLibelle("&Eacute;tat");
        pc.getChampByName("idcategorie").setVisible(false);
        pc.getChampByName("idacteur").setVisible(false);
        pc.getChampByName("duree").setVisible(false);
        pc.getChampByName("etat").setVisible(false);
        pc.getChampByName("a_photo").setVisible(false);
        String lien = (String) session.getValue("lien");
        String urlServlet = request.getContextPath() + "/cinema/film-photo";
        boolean aPhoto = film.getA_photo() == 1;
%>
<style>
    .cin-affiche { position: relative; }
    .cin-affiche img { width: 100%; max-height: 340px; object-fit: contain; background: #E9ECEF; border-radius: 12px; }
    .cin-affiche .cin-etat { position: absolute; top: 10px; right: 10px; background: #fff; border: 1px solid #C3C5C6; border-radius: 10px; padding: 2px 10px; font-size: 12px; }
</style>
<div class="content-wrapper">
    <h1 class="box-title"><a href="<%= lien %>?but=cinema/film/film-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a><%= pc.getTitre() %></h1>
    <div class="row">
        <div class="col-md-5">
            <div class="box">
                <div class="box-body">
                    <div class="cin-affiche">
                        <img src="<%= urlServlet %>?id=<%= id %>&v=<%= System.currentTimeMillis() %>" alt="Photo du film">
                        <span class="cin-etat"><%= film.getEtatlib() %></span>
                    </div>
                    <form action="<%= urlServlet %>" method="post" enctype="multipart/form-data" style="margin-top: 12px;">
                        <input type="hidden" name="idfilm" value="<%= id %>">
                        <label><%= aPhoto ? "Changer la photo" : "Ajouter une photo" %> (JPG, PNG ou WEBP, 2 Mo maximum)</label>
                        <input type="file" name="photo" accept="image/jpeg,image/png,image/webp" required class="form-control">
                        <button type="submit" class="btn btn-primary btn-sm" style="margin-top: 8px;">Enregistrer la photo</button>
                    </form>
                    <% if (aPhoto) { %>
                    <form action="<%= urlServlet %>" method="post" enctype="multipart/form-data" style="margin-top: 6px;"
                          onsubmit="return confirm('Supprimer la photo de ce film ?');">
                        <input type="hidden" name="idfilm" value="<%= id %>">
                        <input type="hidden" name="action" value="supprimer">
                        <button type="submit" class="btn btn-link btn-sm" style="padding-left: 0; color: #c0392b;">Supprimer la photo</button>
                    </form>
                    <% } %>
                </div>
            </div>
        </div>
        <div class="col-md-7">
            <div class="box-fiche">
                <div class="box">
                    <div class="box-body">
                        <% out.println(pc.getHtml()); %>
                        <br/>
                        <div class="box-footer">
                            <a class="btn btn-secondary pull-right" href="<%= lien %>?but=cinema/film/film-modif.jsp&id=<%= id %>" style="margin-right: 10px">Modifier</a>
                            <a class="btn btn-danger pull-left" href="<%= lien %>?but=apresTarif.jsp&id=<%= id %>&acte=delete&bute=cinema/film/film-liste.jsp&classe=cinema.film.CinFilm"
                               onclick="return confirm('Supprimer ce film (et sa photo) ?');">Supprimer</a>
                        </div>
                        <br/>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
