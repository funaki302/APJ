<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.salle.CinClassePlaceLib"%>
<%@page import="affichage.PageConsulte"%>
<%@page import="user.UserEJB"%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        PageConsulte pc = new PageConsulte(new CinClassePlaceLib(), request, u);
        pc.setTitre("Fiche de la classe de place");
        String id = pc.getBase().getTuppleID();
        pc.getChampByName("id").setLibelle("ID");
        pc.getChampByName("val").setLibelle("Classe");
        pc.getChampByName("desce").setLibelle("Description");
        pc.getChampByName("prix").setLibelle("Prix d'une place (Ar)");
        pc.getChampByName("couleur").setLibelle("Couleur");
        pc.getChampByName("date_creation").setLibelle("Date de cr&eacute;ation");
        pc.getChampByName("etatlib").setLibelle("&Eacute;tat");
        pc.getChampByName("etat").setVisible(false);
        String lien = (String) session.getValue("lien");
%>
<div class="content-wrapper">
    <h1 class="box-title"><a href="<%= lien %>?but=cinema/salle/classe-place-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a><%= pc.getTitre() %></h1>
    <div class="row">
        <div class="col-md-6">
            <div class="box-fiche">
                <div class="box">
                    <div class="box-body">
                        <% out.println(pc.getHtml()); %>
                        <br/>
                        <div class="box-footer">
                            <a class="btn btn-secondary pull-right" href="<%= lien %>?but=cinema/salle/classe-place-modif.jsp&id=<%= id %>" style="margin-right: 10px">Modifier</a>
                            <a class="btn btn-danger pull-left" href="<%= lien %>?but=apresTarif.jsp&id=<%= id %>&acte=delete&bute=cinema/salle/classe-place-liste.jsp&classe=cinema.salle.CinClassePlace"
                               onclick="return confirm('Supprimer cette classe de place ?');">Supprimer</a>
                        </div>
                        <br/>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<%@ include file="../inc/couleur-apercu.jspf" %>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
