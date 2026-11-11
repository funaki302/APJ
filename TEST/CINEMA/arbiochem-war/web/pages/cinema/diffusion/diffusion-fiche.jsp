<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.diffusion.CinDiffusion"%>
<%@page import="cinema.diffusion.CinDiffusionLib"%>
<%@page import="cinema.salle.CinSalle"%>
<%@page import="cinema.salle.CinClassePlace"%>
<%@page import="cinema.reservation.CinTicket"%>
<%@page import="cinema.reservation.CinPlaceDiffusion"%>
<%@page import="cinema.utils.CinUtils"%>
<%@page import="affichage.PageConsulte"%>
<%@page import="user.UserEJB"%>
<%-- Fiche d'une diffusion : infos, affiche du film, plan de la salle avec l'occupation des places, bouton Reserver. --%>
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
        boolean commencee, ouverte;
        int nbActifs;
        java.sql.Connection c = null;
        try {
            c = new utilitaire.UtilDB().GetConn();
            commencee = CinDiffusion.dejaCommencee(id, c);
            ouverte = CinTicket.reservationOuverte(id, c);
            nbActifs = CinDiffusion.nbTicketsActifs(id, c);
        } finally {
            if (c != null) c.close();
        }
        boolean annulee = d.getEtat() == CinDiffusion.ANNULEE;

        CinPlaceDiffusion[] planPlaces = CinTicket.getPlacesDiffusion(id, null);
        int planColonnes = 0;
        for (CinPlaceDiffusion p : planPlaces) planColonnes = Math.max(planColonnes, p.getColonne());
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
                        <% if (!commencee && !annulee && nbActifs > 0) { %>
                        <span class="text-muted"><%= nbActifs %> r&eacute;servation(s) active(s) : s&eacute;ance non modifiable.</span>
                        <% } else if (!commencee && !annulee) { %>
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
                    <% if (ouverte) { %>
                    <a class="btn btn-primary btn-sm pull-right" href="<%= lien %>?but=cinema/reservation/reservation-saisie.jsp&iddiffusion=<%= id %>">R&eacute;server des places</a>
                    <% } else { %>
                    <span class="btn btn-primary btn-sm pull-right disabled" title="S&eacute;ance annul&eacute;e, commenc&eacute;e ou r&eacute;servations closes">R&eacute;servations closes</span>
                    <% } %>
                    <a class="btn btn-secondary btn-sm pull-right" style="margin-right: 6px;" href="<%= lien %>?but=cinema/reservation/reservation-liste.jsp&iddiffusion=<%= id %>">R&eacute;servations</a>
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
