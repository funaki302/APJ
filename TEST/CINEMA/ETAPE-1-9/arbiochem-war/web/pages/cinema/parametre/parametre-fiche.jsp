<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.utils.CinParametre"%>
<%@page import="affichage.PageConsulte"%>
<%@page import="user.UserEJB"%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        PageConsulte pc = new PageConsulte(new CinParametre(), request, u);
        pc.setTitre("Param&egrave;tre du cin&eacute;ma");
        String id = pc.getBase().getTuppleID();
        pc.getChampByName("id").setLibelle("ID");
        pc.getChampByName("code").setLibelle("Code");
        pc.getChampByName("valeur").setLibelle("Valeur");
        pc.getChampByName("desce").setLibelle("Description");
        String lien = (String) session.getValue("lien");
%>
<div class="content-wrapper">
    <h1 class="box-title"><a href="<%= lien %>?but=cinema/parametre/parametre-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a><%= pc.getTitre() %></h1>
    <div class="row">
        <div class="col-md-6">
            <div class="box-fiche">
                <div class="box">
                    <div class="box-body">
                        <% out.println(pc.getHtml()); %>
                        <br/>
                        <div class="box-footer">
                            <a class="btn btn-secondary pull-right" href="<%= lien %>?but=cinema/parametre/parametre-modif.jsp&id=<%= id %>" style="margin-right: 10px">Modifier</a>
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
