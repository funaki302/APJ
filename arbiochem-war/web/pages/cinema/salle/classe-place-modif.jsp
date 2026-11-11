<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.salle.CinClassePlace"%>
<%@page import="affichage.PageUpdate"%>
<%@page import="affichage.Liste"%>
<%
    try {
        String mapping = "cinema.salle.CinClassePlace",
               nomtable = "CIN_CLASSE_PLACE",
               apres = "cinema/salle/classe-place-fiche.jsp";

        PageUpdate pu = new PageUpdate(new CinClassePlace(), request, (user.UserEJB) session.getValue("u"));
        pu.setLien((String) session.getValue("lien"));
        pu.setTitre("Modification de la classe de place");

        Liste[] liste = new Liste[1];
        liste[0] = new Liste("etat", new String[]{"Actif", "Inactif"}, new String[]{"1", "0"});
        pu.getFormu().changerEnChamp(liste);

        pu.getFormu().getChamp("id").setAutre("readonly");
        pu.getFormu().getChamp("val").setLibelle("Libell&eacute;");
        pu.getFormu().getChamp("desce").setLibelle("Description");
        pu.getFormu().getChamp("prix").setLibelle("Prix d'une place (Ar)");
        pu.getFormu().getChamp("couleur").setLibelle("Couleur sur le plan de salle");
        pu.getFormu().getChamp("couleur").setType("color");
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
