<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.salle.CinCinema"%>
<%@page import="affichage.PageUpdate"%>
<%@page import="affichage.Liste"%>
<%
    try {
        String mapping = "cinema.salle.CinCinema",
               nomtable = "CIN_CINEMA",
               apres = "cinema/salle/cinema-fiche.jsp";

        PageUpdate pu = new PageUpdate(new CinCinema(), request, (user.UserEJB) session.getValue("u"));
        pu.setLien((String) session.getValue("lien"));
        pu.setTitre("Modification du cin&eacute;ma");

        Liste[] liste = new Liste[1];
        liste[0] = new Liste("etat", new String[]{"Actif", "Inactif"}, new String[]{"1", "0"});
        pu.getFormu().changerEnChamp(liste);

        pu.getFormu().getChamp("id").setAutre("readonly");
        pu.getFormu().getChamp("nom").setLibelle("Nom");
        pu.getFormu().getChamp("localisation").setLibelle("Localisation");
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
