<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.salle.CinSalleLib"%>
<%@page import="cinema.salle.CinSalle"%>
<%@page import="cinema.salle.CinClassePlace"%>
<%@page import="cinema.salle.CinPlaceLib"%>
<%@page import="affichage.PageConsulte"%>
<%@page import="user.UserEJB"%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        PageConsulte pc = new PageConsulte(new CinSalleLib(), request, u);
        pc.setTitre("Fiche de la salle");
        String id = pc.getBase().getTuppleID();
        pc.getChampByName("id").setLibelle("ID");
        pc.getChampByName("nom").setLibelle("Salle");
        pc.getChampByName("idcinemalib").setLibelle("Cin&eacute;ma");
        pc.getChampByName("nb_rangees").setLibelle("Rang&eacute;es");
        pc.getChampByName("nb_colonnes").setLibelle("Places par rang&eacute;e");
        pc.getChampByName("capacite").setLibelle("Capacit&eacute;");
        pc.getChampByName("nb_places_service").setLibelle("Places en service");
        pc.getChampByName("date_creation").setLibelle("Date de cr&eacute;ation");
        pc.getChampByName("etatlib").setLibelle("&Eacute;tat");
        pc.getChampByName("idcinema").setVisible(false);
        pc.getChampByName("etat").setVisible(false);
        String lien = (String) session.getValue("lien");

        CinPlaceLib[] planPlaces = CinSalle.getPlaces(id, null);
        int planColonnes = ((CinSalleLib) pc.getBase()).getNb_colonnes();
        CinClassePlace[] planClasses = CinClassePlace.getClassesActives(null);
        boolean planEditable = false;
%>
<div class="content-wrapper">
    <h1 class="box-title"><a href="<%= lien %>?but=cinema/salle/salle-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a><%= pc.getTitre() %></h1>
    <div class="row">
        <div class="col-md-4">
            <div class="box-fiche">
                <div class="box">
                    <div class="box-body">
                        <% out.println(pc.getHtml()); %>
                        <br/>
                        <div class="box-footer">
                            <a class="btn btn-secondary pull-right" href="<%= lien %>?but=cinema/salle/salle-modif.jsp&id=<%= id %>" style="margin-right: 10px">Modifier</a>
                            <a class="btn btn-danger pull-left" href="<%= lien %>?but=apresTarif.jsp&id=<%= id %>&acte=delete&bute=cinema/salle/salle-liste.jsp&classe=cinema.salle.CinSalle"
                               onclick="return confirm('Supprimer cette salle et toutes ses places ?');">Supprimer</a>
                        </div>
                        <br/>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-8">
            <div class="box">
                <div class="box-header with-border">
                    <h3 class="box-title">Plan de la salle</h3>
                    <a class="btn btn-primary btn-sm pull-right" href="<%= lien %>?but=cinema/salle/salle-plan.jsp&id=<%= id %>">
                        <i class="material-symbols-rounded" style="font-size: 16px; vertical-align: middle;">edit</i> Modifier le plan</a>
                </div>
                <div class="box-body">
                    <%@ include file="../inc/plan-salle.jspf" %>
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
