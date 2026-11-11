<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="affichage.PageInsertMultiple"%>
<%@ page import="user.UserEJB" %>
<%@ page import="ferme.suiviJournalier.SuiviJournalier" %>
<%@ page import="ferme.suiviJournalier.SuiviJournalierDetail" %>
<%@ page import="affichage.Champ" %>
<%@ page import="affichage.Liste" %>
<%@ page import="ferme.configuration.Batiment" %>
<%@ page import="ferme.configuration.ParquetBatiment" %>
<%@ page import="utilitaire.Utilitaire" %>

<% try{
    UserEJB u = (user.UserEJB) session.getValue("u");
    String lien = (String) session.getValue("lien");
    String classeMere = "ferme.suiviJournalier.SuiviJournalier";
    String classeFille = "ferme.suiviJournalier.SuiviJournalierDetail";
    String nomTableFille = "SUIVIJOURNALIERDETAIL";
    String colonneMere = "idmere";
    String apres = "ferme/suiviJournalier/suivijournalier-fiche.jsp";
    String pageSaisie = "ferme/suiviJournalier/suivijournalier-saisie.jsp";

    // ---- Lot choisi : on recupere les lignes du triage (batiment / parquet) ----
    String idlot = Utilitaire.champNull(request.getParameter("idlot")).trim();
    String datyParam = Utilitaire.champNull(request.getParameter("daty")).trim();
    java.util.Date dateSuivi = new java.util.Date();
    if (!datyParam.isEmpty()) {
        try { dateSuivi = new java.text.SimpleDateFormat("dd/MM/yyyy").parse(datyParam); } catch (Exception ignore) { }
    }
    if (datyParam.isEmpty()) {
        datyParam = new java.text.SimpleDateFormat("dd/MM/yyyy").format(dateSuivi);
    }

    String erreurLot = null;
    SuiviJournalierDetail[] lignes = SuiviJournalierDetail.genererDepuisTriage(idlot, dateSuivi, null);
    if (!idlot.isEmpty() && lignes.length == 0) {
        erreurLot = "Le LOT choisi n'a pas encore ete trier";
    }

    int taille = lignes.length == 0 ? 1 : lignes.length;
    boolean afficherDetails = lignes.length > 0;

    SuiviJournalier mere = new SuiviJournalier();
    mere.setNomTable("SUIVIJOURNALIER");
    SuiviJournalierDetail fille = new SuiviJournalierDetail();
    fille.setNomTable("SUIVIJOURNALIERDETAIL");
    PageInsertMultiple pi = new PageInsertMultiple(mere, fille, request, taille, u);
    pi.setLien(lien);
    pi.setTitre("Saisie suivi journalier");

    pi.getFormu().getChamp("daty").setLibelle("Date");
    pi.getFormu().getChamp("daty").setDefaut(datyParam);
    pi.getFormu().getChamp("idlot").setLibelle("Lot");
    pi.getFormu().getChamp("etat").setVisible(false);
    pi.getFormu().getChamp("idlot").setPageAppelComplete("ferme.lot.Lot","id","LOT","id","id");
    if (!idlot.isEmpty()) {
        pi.getFormu().getChamp("idlot").setDefaut(idlot);
    }

    Liste[] liste = new Liste[2];
    liste[0] = new Liste("idbatiment", new Batiment(), "nomBatiment", "id");
    liste[1] = new Liste("idparquet", new ParquetBatiment(), "val", "id");
    pi.getFormufle().changerEnChamp(liste);

    pi.getFormufle().getChamp("idbatiment_0").setLibelle("B&acirc;timent");
    pi.getFormufle().getChamp("idparquet_0").setLibelle("Parquet");
    pi.getFormufle().getChamp("agejour_0").setLibelle("&Acirc;ge en jour");
    pi.getFormufle().getChamp("entree_0").setLibelle("Entr&eacute;e");
    pi.getFormufle().getChamp("tri_0").setLibelle("Tri");
    pi.getFormufle().getChamp("mortalite_0").setLibelle("Mortalit&eacute;");
    pi.getFormufle().getChamp("culls_0").setLibelle("Culls");
    pi.getFormufle().getChamp("consignesuraliment_0").setLibelle("Consigne sur aliment (g/poussin)");
    pi.getFormufle().getChamp("eau_0").setLibelle("Eau");
    pi.getFormufle().getChamp("temperaturemin_0").setLibelle("Temp&eacute;rature min");
    pi.getFormufle().getChamp("temperaturemax_0").setLibelle("Temp&eacute;rature max");
    Champ.setVisible(pi.getFormufle().getChampMulitple("idmere").getListeChamp(),false);

    if (afficherDetails) {
        // batiment / parquet / age viennent du triage : non modifiables ; le reste vaut 0 par defaut
        pi.setDefautFille(lignes);
        for (int i = 0; i < lignes.length; i++) {
            pi.getFormufle().getChamp("idbatiment_" + i).setAutre("style='pointer-events:none;background:#eee'");
            pi.getFormufle().getChamp("idparquet_" + i).setAutre("style='pointer-events:none;background:#eee'");
            pi.getFormufle().getChamp("agejour_" + i).setAutre("readonly");
            String[] aZero = {"entree", "tri", "mortalite", "culls", "consignesuraliment", "eau", "temperaturemin", "temperaturemax"};
            for (String nom : aZero) {
                pi.getFormufle().getChamp(nom + "_" + i).setDefaut("0");
            }
        }
    }

    String[] colOrdre = {"idbatiment","idparquet","agejour","entree","tri","mortalite","culls","consignesuraliment","eau","temperaturemin","temperaturemax"};
    pi.getFormufle().setColOrdre(colOrdre);

    pi.preparerDataFormu();
    pi.getFormu().makeHtmlInsertTabIndex();
    pi.getFormufle().makeHtmlInsertTableauIndex();
%>

<div class="content-wrapper">
    <h1><%=pi.getTitre()%></h1>
    <form id="formId" class='container' action="<%=pi.getLien()%>?but=apresMultiple.jsp" method="post" >
        <%
            out.println(pi.getFormu().getHtmlInsert());
        %>
        <div style="margin:10px 0">
            <button type="button" class="btn btn-info" onclick="chargerLot()">Charger les parquets du lot</button>
        </div>
        <% if (erreurLot != null) { %>
            <div class="alert alert-danger"><%= erreurLot %></div>
        <% } else if (afficherDetails) {
            out.println(pi.getFormufle().getHtmlTableauInsert());
        } else { %>
            <div class="alert alert-info">Choisissez un lot puis cliquez sur &laquo; Charger les parquets du lot &raquo;.</div>
        <% } %>
        <input name="acte" type="hidden" id="nature" value="insert">
        <input name="bute" type="hidden" id="bute" value="<%=apres%>">
        <input name="classe" type="hidden" id="classe" value="<%=classeMere%>">
        <input name="classefille" type="hidden" id="classefille" value="<%=classeFille%>">
        <input name="nomtable" type="hidden" id="nomtable" value=<%=nomTableFille%>>
        <input name="nombreLigne" type="hidden" id="nombreLigne" value="<%=taille%>">
        <input name="colonneMere" type="hidden" id="colonneMere" value="<%=colonneMere%>">
    </form>
</div>

<script>
function chargerLot() {
    var lot = document.getElementsByName('idlot')[0].value;
    var daty = document.getElementsByName('daty')[0].value;
    if (!lot) { alert('Choisissez un lot'); return; }
    window.location = '<%=lien%>?but=<%=pageSaisie%>&idlot=' + encodeURIComponent(lot) + '&daty=' + encodeURIComponent(daty);
}
</script>

<% } catch (Exception e) {
  e.printStackTrace();
%>
<script language="JavaScript"> alert('<%=e.getMessage()%>');
    history.back();
</script>
<% }%>
