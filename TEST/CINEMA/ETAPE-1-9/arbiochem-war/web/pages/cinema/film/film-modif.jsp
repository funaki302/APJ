<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.film.CinFilm"%>
<%@page import="cinema.film.CinCategorieFilm"%>
<%@page import="cinema.film.CinActeur"%>
<%@page import="affichage.PageUpdate"%>
<%@page import="affichage.Liste"%>
<%-- Modification d'un film. La photo se change sur la fiche. --%>
<%
    try {
        String mapping = "cinema.film.CinFilm",
               nomtable = "CIN_FILM",
               apres = "cinema/film/film-fiche.jsp";

        PageUpdate pu = new PageUpdate(new CinFilm(), request, (user.UserEJB) session.getValue("u"));
        pu.setLien((String) session.getValue("lien"));
        pu.setTitre("Modification du film");

        Liste[] liste = new Liste[4];
        liste[0] = new Liste("idcategorie", new CinCategorieFilm(), "val", "id");
        liste[0].setApresW(" and etat = 1");
        // acteur principal facultatif : choix vide en tete de liste
        CinActeur[] tousActeurs = CinActeur.getActeurs(null);
        bean.ClassMAPTable[] acteurs = new bean.ClassMAPTable[tousActeurs.length + 1];
        CinActeur aucunActeur = new CinActeur();
        aucunActeur.setId("");
        aucunActeur.setNom(" - ");
        acteurs[0] = aucunActeur;
        System.arraycopy(tousActeurs, 0, acteurs, 1, tousActeurs.length);
        liste[1] = new Liste("idacteur", acteurs, "nom", "id");
        liste[2] = new Liste("etat", new String[]{"Actif", "Inactif"}, new String[]{"1", "0"});
        liste[3] = new Liste("classification", new String[]{" - ", "Tous publics", "-12", "-16", "-18"}, new String[]{"", "Tous publics", "-12", "-16", "-18"});
        pu.getFormu().changerEnChamp(liste);

        pu.getFormu().getChamp("id").setAutre("readonly");
        pu.getFormu().getChamp("titre").setLibelle("Titre");
        pu.getFormu().getChamp("idcategorie").setLibelle("Cat&eacute;gorie");
        pu.getFormu().getChamp("realisateur").setLibelle("R&eacute;alisateur");
        pu.getFormu().getChamp("idacteur").setLibelle("Acteur principal (facultatif)");
        pu.getFormu().getChamp("classification").setLibelle("Classification");
        pu.getFormu().getChamp("duree").setLibelle("Dur&eacute;e (minutes)");
        pu.getFormu().getChamp("duree").setType("number");
        pu.getFormu().getChamp("duree").setAutre("min='1' max='600'");
        pu.getFormu().getChamp("pa").setLibelle("Prix d'achat (Ar)");
        pu.getFormu().getChamp("pa").setType("number");
        pu.getFormu().getChamp("pa").setAutre("min='0'");
        pu.getFormu().getChamp("description").setLibelle("Description");
        pu.getFormu().getChamp("description").setType("textarea");
        pu.getFormu().getChamp("date_creation").setLibelle("Date de cr&eacute;ation");
        pu.getFormu().getChamp("date_creation").setAutre("readonly");
        pu.getFormu().getChamp("etat").setLibelle("&Eacute;tat");
        String lien = (String) session.getValue("lien");
        String id = pu.getBase().getTuppleID();
        pu.preparerDataFormu();
%>
<div class="content-wrapper">
    <div class="row">
        <div class="col-md-3"></div>
        <div class="col-md-6">
            <div class="box-fiche">
                <div class="box">
                    <div class="box-title with-border">
                        <h1 class="box-title"><a href="<%= lien %>?but=<%= apres %>&id=<%= id %>"><i class="fa fa-arrow-circle-left"></i></a><%= pu.getTitre() %></h1>
                    </div>
                    <form action="<%= lien %>?but=apresTarif.jsp&id=<%= id %>" method="post">
                        <% out.println(pu.getFormu().getHtmlInsert()); %>
                        <div class="row">
                            <div class="col-md-11">
                                <button class="btn btn-primary pull-right" name="Submit2" type="submit">Valider</button>
                            </div>
                            <br><br>
                        </div>
                        <input name="acte" type="hidden" value="update">
                        <input name="bute" type="hidden" value="<%= apres %>">
                        <input name="classe" type="hidden" value="<%= mapping %>">
                        <input name="rajoutLien" type="hidden" value="id-<%= id %>">
                        <input name="nomtable" type="hidden" value="<%= nomtable %>">
                    </form>
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
