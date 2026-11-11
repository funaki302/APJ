<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.paiement.CinModeCaisse"%>
<%@page import="affichage.PageInsert"%>
<%@page import="affichage.Liste"%>
<%@page import="bean.TypeObjet"%>
<%@page import="user.UserEJB"%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        PageInsert pi = new PageInsert(new CinModeCaisse(), request, u);
        pi.setLien((String) session.getValue("lien"));
        TypeObjet mode = new TypeObjet();
        mode.setNomTable("MODEPAIEMENT");
        Liste[] liste = new Liste[3];
        liste[0] = new Liste("idmodepaiement", mode, "val", "id");
        liste[1] = new Liste("idcaisse", new caisse.Caisse(), "val", "id");
        liste[1].setApresW(" and actif = 1");
        liste[2] = new Liste("actif", new String[]{"Oui", "Non"}, new String[]{"1", "0"});
        pi.getFormu().changerEnChamp(liste);
        pi.getFormu().getChamp("idmodepaiement").setLibelle("Mode de paiement");
        pi.getFormu().getChamp("idcaisse").setLibelle("Caisse propos&eacute;e");
        pi.getFormu().getChamp("actif").setLibelle("Propos&eacute; au paiement des tickets");
        pi.preparerDataFormu();
%>
<div class="content-wrapper">
    <h1>Ajouter un mode de paiement pour le cin&eacute;ma</h1>
    <form action="<%= pi.getLien() %>?but=apresTarif.jsp" method="post">
        <%
            pi.getFormu().makeHtmlInsertTabIndex();
            out.println(pi.getFormu().getHtmlInsert());
        %>
        <input name="acte" type="hidden" value="insert">
        <input name="bute" type="hidden" value="cinema/paiement/mode-caisse-liste.jsp">
        <input name="classe" type="hidden" value="cinema.paiement.CinModeCaisse">
        <input name="nomtable" type="hidden" value="CIN_MODE_CAISSE">
    </form>
</div>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
