<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.film.CinActeur"%>
<%@page import="affichage.PageConsulte"%>
<%@page import="user.UserEJB"%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        PageConsulte pc = new PageConsulte(new CinActeur(), request, u);
        pc.setTitre("Fiche de l'acteur");
        String id = pc.getBase().getTuppleID();
        pc.getChampByName("id").setLibelle("ID");
        pc.getChampByName("nom").setLibelle("Nom");
        pc.getChampByName("nom_acteur").setLibelle("Nom de sc&egrave;ne");
        pc.getChampByName("date_naissance").setLibelle("Date de naissance");
        String lien = (String) session.getValue("lien");
%>
<div class="content-wrapper">
    <h1 class="box-title"><a href="<%= lien %>?but=cinema/film/acteur-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a><%= pc.getTitre() %></h1>
    <div class="row">
        <div class="col-md-6">
            <div class="box-fiche">
                <div class="box">
                    <div class="box-body">
                        <% out.println(pc.getHtml()); %>
                        <br/>
                        <div class="box-footer">
                            <a class="btn btn-secondary pull-right" href="<%= lien %>?but=cinema/film/acteur-modif.jsp&id=<%= id %>" style="margin-right: 10px">Modifier</a>
                            <a class="btn btn-danger pull-left" href="<%= lien %>?but=apresTarif.jsp&id=<%= id %>&acte=delete&bute=cinema/film/acteur-liste.jsp&classe=cinema.film.CinActeur"
                               onclick="return confirm('Supprimer cet acteur ?');">Supprimer</a>
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
