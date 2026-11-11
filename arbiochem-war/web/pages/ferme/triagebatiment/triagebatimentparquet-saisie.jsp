<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="affichage.PageInsertMultiple"%>
<%@ page import="user.UserEJB" %>
<%@ page import="bean.CGenUtil" %>
<%@ page import="ferme.triageBatiment.TriageBatimentParquet" %>
<%@ page import="ferme.triageBatiment.TriageBatimentParquetDetail" %>
<%@ page import="ferme.receptionaeroport.ReceptionPoussinAeroport" %>
<%@ page import="affichage.Champ" %>
<%@ page import="affichage.Liste" %>
<%@ page import="bean.TypeObjet" %>
<%@ page import="ferme.configuration.ParquetBatiment" %>
<%@ page import="ferme.configuration.Batiment" %>
<%@ page import="ferme.configuration.QualitePoussin" %>

<% try{
    UserEJB u = (user.UserEJB) session.getValue("u");
    if(u == null){
        throw new Exception("La session utilisateur a expir&eacute;. Reconnectez-vous avant de saisir le triage.");
    }
    String classeMere = "ferme.triageBatiment.TriageBatimentParquet";
    String classeFille = "ferme.triageBatiment.TriageBatimentParquetDetail";
    String nomTableFille = "TRIAGEBATIMENTPARQUETDETAIL";
    String colonneMere = "idmere";
    String apres = "ferme/triagebatiment/triagebatimentparquet-fiche.jsp";

    String idRfa = request.getParameter("idRfa");
    ReceptionPoussinAeroport receptionPrefill = null;
    if(idRfa != null && !idRfa.trim().isEmpty()){
        String idRfaSql = idRfa.trim().replace("'", "''");
        ReceptionPoussinAeroport[] receptions = (ReceptionPoussinAeroport[]) CGenUtil.rechercher(
                new ReceptionPoussinAeroport(), null, null, " AND ID = '" + idRfaSql + "'");
        if(receptions != null && receptions.length == 1){
            receptionPrefill = receptions[0];
            idRfa = receptionPrefill.getId();
        }
    }

    TriageBatimentParquet mere = new TriageBatimentParquet();
    mere.setNomTable("TRIAGEBATIMENTPARQUET");
    TriageBatimentParquetDetail fille = new TriageBatimentParquetDetail();
    fille.setNomTable("TRIAGEBATIMENTPARQUETDETAIL");
    int taille = 10;
    PageInsertMultiple pi = new PageInsertMultiple(mere, fille, request, taille, u);
    pi.setLien((String) session.getValue("lien"));
    pi.setTitre("Saisie triage batiment par parquet");

    String[] champsPrincipauxRequis = {"daty", "idRfa", "idlot", "qterecus", "morts", "perdus", "etat", "dispomale", "dispofemelle"};
    for(String nomChamp : champsPrincipauxRequis){
        if(pi.getFormu().getChamp(nomChamp) == null){
            throw new Exception("Colonne " + nomChamp.toUpperCase() + " absente des colonnes disponibles de TRIAGEBATIMENTPARQUET. V&eacute;rifiez le sch&eacute;ma et la configuration LISTECOLONNETABLE; appliquez les colonnes correspondantes de alter.sql.");
        }
    }

    pi.getFormu().getChamp("daty").setLibelle("Date");
    pi.getFormu().getChamp("idRfa").setLibelle("R&eacute;ception a&eacute;roport");
    pi.getFormu().getChamp("idRfa").setPageAppelCompleteAWhere(
            "ferme.receptionaeroport.ReceptionPoussinAeroport", "id",
            "RECEPTIONPOUSSINAEROPORT", "qteRecus;morts;idLot",
            "qteAeroportAutocomplete;mortsAeroportAutocomplete;idlot", "");
    pi.getFormu().getChamp("idRfa").setAutre("required");
    pi.getFormu().getChamp("idlot").setLibelle("Lot");
    pi.getFormu().getChamp("qterecus").setLibelle("Quantit&eacute; th&eacute;orique vivante (a&eacute;roport)");
    pi.getFormu().getChamp("morts").setLibelle("Morts au triage");
    pi.getFormu().getChamp("perdus").setLibelle("Pertes suppl&eacute;mentaires au triage");
    pi.getFormu().getChamp("etat").setVisible(false);
    pi.getFormu().getChamp("dispomale").setVisible(false);
    pi.getFormu().getChamp("dispofemelle").setVisible(false);
    pi.getFormu().getChamp("idlot").setAutre("readonly");
    pi.getFormu().getChamp("qterecus").setType("number");
    pi.getFormu().getChamp("qterecus").setAutre("readonly min=\"0\" step=\"any\"");
    pi.getFormu().getChamp("morts").setType("number");
    pi.getFormu().getChamp("morts").setAutre("min=\"0\" step=\"1\" required");
    pi.getFormu().getChamp("morts").setDefaut("0");
    pi.getFormu().getChamp("perdus").setType("number");
    pi.getFormu().getChamp("perdus").setAutre("min=\"0\" step=\"1\" required");
    pi.getFormu().getChamp("perdus").setDefaut("0");
    if(receptionPrefill != null){
        pi.getFormu().getChamp("idRfa").setDefaut(receptionPrefill.getId());
        pi.getFormu().getChamp("idlot").setDefaut(receptionPrefill.getIdLot());
        pi.getFormu().getChamp("qterecus").setDefaut(Double.toString(
                receptionPrefill.getQteRecus() - receptionPrefill.getMorts()));
    }

    Liste[] liste = new Liste[4];
    TypeObjet sexe = new TypeObjet();
    sexe.setNomTable("SEXE");
    liste[0] = new Liste("idsexe", sexe, "val", "id");
    liste[0].ajouterVide();
    ParquetBatiment parquet = new ParquetBatiment();
    liste[2] = new Liste("idparquet", parquet, "val", "id");
    liste[1] = new Liste("idbatiment", new Batiment(), "nomBatiment", "id");
    liste[1].setDeroulanteDependante(liste[2],"idbatiment","onchange");
    QualitePoussin qualitePoussin = new QualitePoussin();
    liste[3] = new Liste("idqualite", qualitePoussin, "val", "id");
    pi.getFormufle().changerEnChamp(liste);
    pi.getFormufle().getChamp("idbatiment_0").setLibelle("B&acirc;timent");
    pi.getFormufle().getChamp("idparquet_0").setLibelle("Parquet");
    pi.getFormufle().getChamp("idsexe_0").setLibelle("Sexe");
    pi.getFormufle().getChamp("idqualite_0").setLibelle("Qualit&eacute;");
    pi.getFormufle().getChamp("qte_0").setLibelle("Quantit&eacute;");
    Champ premiereSante = pi.getFormufle().getChamp("sante_0");
    if(premiereSante == null){
        throw new Exception("Le champ SANTE est absent du modele detail. Recompilez et redeployez ensemble les modules EJB et WAR.");
    }
    premiereSante.setLibelle("Sant&eacute; (1 &agrave; 10)");
    for(int i = 0; i < taille; i++){
        Champ champSante = pi.getFormufle().getChamp("sante_" + i);
        if(champSante == null){
            throw new Exception("Le champ SANTE de la ligne " + (i + 1) + " est absent. Recompilez et redeployez les modules EJB et WAR.");
        }
        champSante.setType("number");
        champSante.setAutre("min=\"1\" max=\"10\" step=\"1\" required");
        champSante.setDefaut("10");
    }
    affichage.ListeChamp champIdMere = pi.getFormufle().getChampMulitple("idmere");
    if(champIdMere != null){
        champIdMere.setVisible(false);
    }

    String[] colOrdre = {"idbatiment","idparquet","idsexe","idqualite","qte","sante"};
    pi.getFormufle().setColOrdre(colOrdre);

    String acte = request.getParameter("acte");
    if(acte != null && acte.equalsIgnoreCase("update")){
        pi.setTitre("Modification triage batiment par parquet");
    }

    pi.preparerDataFormu();
    pi.getFormu().makeHtmlInsertTabIndex();
    pi.getFormufle().makeHtmlInsertTableauIndex();
%>

<div class="content-wrapper">
    <h1><%=pi.getTitre()%></h1>
    <form id="formId" class='container' action="<%=pi.getLien()%>?but=apresMultiple.jsp" method="post" >
        <%
            out.println(pi.getFormu().getHtmlInsert());
            out.println("<input type=\"hidden\" id=\"qteAeroportAutocomplete\" value=\""
                    + (receptionPrefill == null ? "" : receptionPrefill.getQteRecus()) + "\">");
            out.println("<input type=\"hidden\" id=\"mortsAeroportAutocomplete\" value=\""
                    + (receptionPrefill == null ? "" : receptionPrefill.getMorts()) + "\">");
            out.println("<div class=\"form-group\"><label for=\"qteVivanteRestante\">"
                    + "Quantit&eacute; vivante restante</label><input class=\"form-control\" "
                    + "type=\"number\" id=\"qteVivanteRestante\" readonly value=\"0\"></div>");
            out.println(pi.getFormufle().getHtmlTableauInsert());
        %>
        <input name="acte" type="hidden" id="nature" value="insert">
        <input name="bute" type="hidden" id="bute" value="<%=apres%>">
        <input name="classe" type="hidden" id="classe" value="<%=classeMere%>">
        <input name="classefille" type="hidden" id="classefille" value="<%=classeFille%>">
        <input name="nomtable" type="hidden" id="nomtable" value="<%=nomTableFille%>">
        <input name="nombreLigne" type="hidden" id="nombreLigne" value="<%=taille%>">
        <input name="colonneMere" type="hidden" id="colonneMere" value="<%=colonneMere%>">
    </form>
</div>
<script>
(function () {
    var qteTheorique = document.getElementById("qterecus");
    var mortsTri = document.getElementById("morts");
    var pertesTri = document.getElementById("perdus");
    var qteAeroport = document.getElementById("qteAeroportAutocomplete");
    var mortsAeroport = document.getElementById("mortsAeroportAutocomplete");
    var qteRestante = document.getElementById("qteVivanteRestante");
    var derniereQteAeroport = null;
    var derniersMortsAeroport = null;

    function valeurNumerique(champ) {
        var valeur = champ ? parseFloat(champ.value) : 0;
        return isFinite(valeur) ? valeur : 0;
    }

    function actualiser() {
        if (qteAeroport && mortsAeroport && qteTheorique) {
            var qteBrute = valeurNumerique(qteAeroport);
            var mortsReception = valeurNumerique(mortsAeroport);
            if (qteBrute !== derniereQteAeroport || mortsReception !== derniersMortsAeroport) {
                qteTheorique.value = Math.max(0, qteBrute - mortsReception);
                derniereQteAeroport = qteBrute;
                derniersMortsAeroport = mortsReception;
            }
        }
        var restante = valeurNumerique(qteTheorique)
                - valeurNumerique(mortsTri) - valeurNumerique(pertesTri);
        qteRestante.value = Math.max(0, restante);
        qteRestante.setCustomValidity(restante < 0
                ? "Les morts et les pertes depassent la quantite theorique vivante."
                : "");
    }

    [mortsTri, pertesTri].forEach(function (champ) {
        if (champ) {
            champ.addEventListener("input", actualiser);
            champ.addEventListener("change", actualiser);
        }
    });
    window.setInterval(actualiser, 250);
    actualiser();
}());
</script>

<% } catch (Exception e) {
  e.printStackTrace();
%>
<script language="JavaScript"> alert('<%=e.getMessage()%>');
    history.back();
</script>
<% }%>
