<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.diffusion.CinDiffusion"%>
<%@page import="cinema.film.CinFilm"%>
<%@page import="cinema.salle.CinSalle"%>
<%@page import="affichage.PageUpdate"%>
<%@page import="affichage.Liste"%>
<%-- Modification ou annulation (etat Annulee) d'une diffusion pas encore commencee --%>
<%
    try {
        String mapping = "cinema.diffusion.CinDiffusion",
               nomtable = "CIN_DIFFUSION",
               apres = "cinema/diffusion/diffusion-fiche.jsp";

        PageUpdate pu = new PageUpdate(new CinDiffusion(), request, (user.UserEJB) session.getValue("u"));
        pu.setLien((String) session.getValue("lien"));
        pu.setTitre("Modification de la diffusion");

        Liste[] liste = new Liste[3];
        liste[0] = new Liste("idfilm", new CinFilm(), "titre", "id");
        liste[0].setApresW(" and etat = 1");
        liste[1] = new Liste("idsalle", new CinSalle(), "nom", "id");
        liste[1].setApresW(" and etat = 1");
        liste[2] = new Liste("etat", new String[]{"Programm&eacute;e", "Annul&eacute;e"}, new String[]{"1", "0"});
        pu.getFormu().changerEnChamp(liste);

        pu.getFormu().getChamp("id").setAutre("readonly");
        pu.getFormu().getChamp("idfilm").setLibelle("Film");
        pu.getFormu().getChamp("idsalle").setLibelle("Salle");
        pu.getFormu().getChamp("daty").setLibelle("Date de la s&eacute;ance");
        pu.getFormu().getChamp("heure").setLibelle("Heure de d&eacute;but");
        pu.getFormu().getChamp("heure").setType("time");
        pu.getFormu().getChamp("date_creation").setLibelle("Programm&eacute;e le");
        pu.getFormu().getChamp("date_creation").setAutre("readonly");
        pu.getFormu().getChamp("etat").setLibelle("&Eacute;tat (Annul&eacute;e = s&eacute;ance annul&eacute;e)");
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
