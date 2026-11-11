<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.diffusion.CinDiffusion"%>
<%@page import="cinema.diffusion.CinDiffusionLib"%>
<%@page import="cinema.salle.CinSalle"%>
<%@page import="cinema.salle.CinClassePlace"%>
<%@page import="cinema.salle.CinPlaceLib"%>
<%@page import="cinema.utils.CinUtils"%>
<%@page import="affichage.PageConsulte"%>
<%@page import="user.UserEJB"%>
<%-- Fiche d'une diffusion : infos, affiche du film, plan de la salle. La reservation arrive a l'etape 6. --%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        PageConsulte pc = new PageConsulte(new CinDiffusionLib(), request, u);
        pc.setTitre("Fiche de la diffusion");
        CinDiffusionLib d = (CinDiffusionLib) pc.getBase();
        String id = d.getTuppleID();
        pc.getChampByName("id").setLibelle("ID");
        pc.getChampByName("idfilmlib").setLibelle("Film");
        pc.getChampByName("dureelib").setLibelle("Dur&eacute;e");
        pc.getChampByName("idsallelib").setLibelle("Salle");
        pc.getChampByName("idcinemalib").setLibelle("Cin&eacute;ma");
        pc.getChampByName("daty").setLibelle("Date");
        pc.getChampByName("heure").setLibelle("D&eacute;but");
        pc.getChampByName("heure_fin").setLibelle("Fin");
        pc.getChampByName("nb_places").setLibelle("Places en service");
        pc.getChampByName("date_creation").setLibelle("Programm&eacute;e le");
        pc.getChampByName("etatlib").setLibelle("&Eacute;tat");
        pc.getChampByName("idfilm").setVisible(false);
        pc.getChampByName("idsalle").setVisible(false);
        pc.getChampByName("idcinema").setVisible(false);
        pc.getChampByName("duree").setVisible(false);
        pc.getChampByName("etat").setVisible(false);
        String lien = (String) session.getValue("lien");
        boolean commencee;
        java.sql.Connection c = null;
        try {
            c = new utilitaire.UtilDB().GetConn();
            commencee = CinDiffusion.dejaCommencee(id, c);
        } finally {
            if (c != null) c.close();
        }
        boolean annulee = d.getEtat() == CinDiffusion.ANNULEE;

        CinPlaceLib[] planPlaces = CinSalle.getPlaces(d.getIdsalle(), null);
        int planColonnes = 0;
        for (CinPlaceLib p : planPlaces) planColonnes = Math.max(planColonnes, p.getColonne());
        CinClassePlace[] planClasses = CinClassePlace.getClassesActives(null);
        boolean planEditable = false;
%>
<div class="content-wrapper">
    <h1 class="box-title"><a href="<%= lien %>?but=cinema/diffusion/diffusion-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a><%= pc.getTitre() %></h1>
    <div class="row">
        <div class="col-md-4">
            <div class="box">
                <div class="box-body">
                    <img src="<%= request.getContextPath() %>/cinema/film-photo?id=<%= d.getIdfilm() %>" alt=""
                         style="width: 100%; max-height: 220px; object-fit: contain; background: #E9ECEF; border-radius: 12px; margin-bottom: 10px;">
                    <% out.println(pc.getHtml()); %>
                    <div class="box-footer">
                        <% if (!commencee && !annulee) { %>
                        <a class="btn btn-secondary pull-right" href="<%= lien %>?but=cinema/diffusion/diffusion-modif.jsp&id=<%= id %>" style="margin-right: 10px">Modifier / annuler</a>
                        <a class="btn btn-danger pull-left" href="<%= lien %>?but=apresTarif.jsp&id=<%= id %>&acte=delete&bute=cinema/diffusion/diffusion-liste.jsp&classe=cinema.diffusion.CinDiffusion"
                           onclick="return confirm('Supprimer cette diffusion ?');">Supprimer</a>
                        <% } else { %>
                        <span class="text-muted">S&eacute;ance <%= d.getEtatlib() %> : plus modifiable.</span>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-8">
            <div class="box">
                <div class="box-header with-border">
                    <h3 class="box-title">Places de la salle <%= d.getIdsallelib() %></h3>
                    <span class="btn btn-primary btn-sm pull-right disabled" title="Disponible &agrave; l'&eacute;tape 6">R&eacute;server (bient&ocirc;t)</span>
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
