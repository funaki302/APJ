<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.paiement.CinModeCaisse"%>
<%@page import="affichage.PageUpdate"%>
<%@page import="affichage.Liste"%>
<%@page import="bean.TypeObjet"%>
<%
    try {
        PageUpdate pu = new PageUpdate(new CinModeCaisse(), request, (user.UserEJB) session.getValue("u"));
        pu.setLien((String) session.getValue("lien"));
        pu.setTitre("Caisse propos&eacute;e pour un mode de paiement");
        TypeObjet mode = new TypeObjet();
        mode.setNomTable("MODEPAIEMENT");
        Liste[] liste = new Liste[3];
        liste[0] = new Liste("idmodepaiement", mode, "val", "id");
        liste[1] = new Liste("idcaisse", new caisse.Caisse(), "val", "id");
        liste[1].setApresW(" and actif = 1");
        liste[2] = new Liste("actif", new String[]{"Oui", "Non"}, new String[]{"1", "0"});
        pu.getFormu().changerEnChamp(liste);
        pu.getFormu().getChamp("id").setAutre("readonly");
        pu.getFormu().getChamp("idmodepaiement").setLibelle("Mode de paiement");
        pu.getFormu().getChamp("idcaisse").setLibelle("Caisse propos&eacute;e");
        pu.getFormu().getChamp("actif").setLibelle("Propos&eacute; au paiement des tickets");
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
                        <h1 class="box-title"><a href="<%= lien %>?but=cinema/paiement/mode-caisse-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a><%= pu.getTitre() %></h1>
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
                        <input name="bute" type="hidden" value="cinema/paiement/mode-caisse-liste.jsp">
                        <input name="classe" type="hidden" value="cinema.paiement.CinModeCaisse">
                        <input name="rajoutLien" type="hidden" value="id-<%= id %>">
                        <input name="nomtable" type="hidden" value="CIN_MODE_CAISSE">
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
