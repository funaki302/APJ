<%@page import="bean.CGenUtil"%>
<%@page import="affichage.PageUpdateMultiple"%>
<%@page import="ferme.receptionaeroport.*"%>
<%@page import="user.UserEJB"%>
<%@page import="affichage.PageInsertMultiple"%>
<%@page import="affichage.Liste"%>
<%@page import="bean.TypeObjet"%>
<%@page import="affichage.PageInsert"%>
<%@page import="utilitaire.Utilitaire"%>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="magasin.Magasin" %>
<%@ page import="java.util.Date" %>
<%@ page import="ferme.configuration.QualitePoussin" %>
<%
    try{
    UserEJB u = null;
    u = (UserEJB) session.getValue("u");
    ReceptionPoussinAeroport mere = new ReceptionPoussinAeroport();
    ReceptionPoussinAeroportDetail fille = new ReceptionPoussinAeroportDetail();
    int nombreLigne = 10;
    PageInsertMultiple pi = new PageInsertMultiple(mere, fille, request, nombreLigne, u);
    pi.setLien((String) session.getValue("lien"));
    pi.getFormu().getChamp("idLot").setVisible(false);
    pi.getFormu().getChamp("idBl").setLibelle("Bon de livraison");
    pi.getFormu().getChamp("idBl").setPageAppelComplete("faturefournisseur.As_BonDeLivraison_Lib", "id", "AS_BONDELIVRAISON_LIB");
    pi.getFormu().getChamp("idBl").setAutre("required");
    pi.getFormu().getChamp("perdus").setLibelle("Poussins perdus (calcul automatique)");
    pi.getFormu().getChamp("perdus").setVisible(false);
    pi.getFormu().getChamp("morts").setLibelle("Poussins morts");
    pi.getFormu().getChamp("morts").setType("number");
    pi.getFormu().getChamp("morts").setAutre("min=\"0\" step=\"1\" required");
    pi.getFormu().getChamp("morts").setDefaut("0");
    pi.getFormu().getChamp("daty").setLibelle("Date");
    pi.getFormu().getChamp("heureDepart").setLibelle("Heure de d&eacute;part");
    pi.getFormu().getChamp("heureDepart").setType("time");
    pi.getFormu().getChamp("heureArrive").setLibelle("Heure d'arriv&eacute;e");
    pi.getFormu().getChamp("heureArrive").setType("time");
    pi.getFormu().getChamp("etat").setVisible(false);
    pi.getFormu().getChamp("nbrCartonMale").setLibelle("Nombre de cartons m&acirc;les");
    pi.getFormu().getChamp("nbrCartonFemelle").setLibelle("Nombre de cartons femelles");
    pi.getFormu().getChamp("qteRecus").setLibelle("Quantit&eacute; totale re&ccedil;ue (vivants + morts)");


    pi.getFormufle().getChamp("idSexe_0").setLibelle("Sexe");
    pi.getFormufle().getChamp("qte_0").setLibelle("Quantit&eacute;");
    affichage.Champ.setVisible(pi.getFormufle().getChampFille("id"), false);
    affichage.Champ.setVisible(pi.getFormufle().getChampFille("idMere"), false);

    affichage.Liste[] listef = new Liste[2];
    TypeObjet sexe=new TypeObjet();
    sexe.setNomTable("SEXE");
    Object[] sexesTrouves = CGenUtil.rechercher(sexe, null, null, "");
    int nombreSexes = sexesTrouves == null ? 0 : sexesTrouves.length;
    bean.ClassMAPTable[] sexes = new bean.ClassMAPTable[nombreSexes + 1];
    for(int i = 0; i < nombreSexes; i++){
        sexes[i] = (bean.ClassMAPTable) sexesTrouves[i];
    }
    TypeObjet sexeNonPrecise = new TypeObjet();
    sexeNonPrecise.setId("");
    sexeNonPrecise.setVal(" - ");
    sexes[nombreSexes] = sexeNonPrecise;
    listef[0]=new Liste("idSexe",sexes,"val","id");
    QualitePoussin qp=new QualitePoussin();
    listef[1]=new Liste("idQualitePoussin",qp,"val","id");
    pi.getFormufle().changerEnChamp(listef);
    pi.getFormufle().getChamp("idSexe_0").setLibelle("Sexe");
    pi.getFormufle().getChamp("idQualitePoussin_0").setLibelle("Qualit&eacute; poussin");

    String classeMere = "ferme.receptionaeroport.ReceptionPoussinAeroport";
    String classeFille = "ferme.receptionaeroport.ReceptionPoussinAeroportDetail";
    String butApresPost = "ferme/receptionaeroport/receptionaeroport-fiche.jsp";
    String colonneMere = "idMere";

    String[] colOrdre = {"id", "idQualitePoussin","idsexe","qte"};
    pi.getFormufle().setColOrdre(colOrdre);


    pi.preparerDataFormu();
    pi.getFormu().makeHtmlInsertTabIndex();
    pi.getFormufle().makeHtmlInsertTableauIndex();

%>
<div class="content-wrapper">
    <!-- A modifier -->
    <%
        if (request.getParameter("acte")!=null && request.getParameter("acte")!=""){
            out.println("<h1>Modification du reception de poussin &agrave; l'aeroport</h1>");
        }else{
            out.println("<h1>Saisie d'un reception de poussin &agrave; l'aeroport</h1>");
        }
    %>
    <form id="formId" class='container' action="<%=pi.getLien()%>?but=apresMultiple.jsp" method="post" >
        <div class="alert alert-info">Le lot sera cr&eacute;&eacute; automatiquement depuis le produit du bon de livraison. Saisissez les poussins morts s&eacute;par&eacute;ment; la somme des quantit&eacute;s vivantes par qualit&eacute;/sexe et des morts doit correspondre au total re&ccedil;u. Les pertes par rapport au bon de livraison sont calcul&eacute;es &agrave; l'enregistrement.</div>
        <%
            out.println(pi.getFormu().getHtmlInsert());
        %>
        <div id="butfillejsp">
            <%
                out.println(pi.getFormufle().getHtmlTableauInsert());
            %>
        </div>
        <input name="acte" type="hidden" id="nature" value="insert">
        <input name="bute" type="hidden" id="bute" value="<%= butApresPost %>">
        <input name="classe" type="hidden" id="classe" value="<%= classeMere %>">
        <input name="classefille" type="hidden" id="classefille" value="<%= classeFille %>">
        <input name="nombreLigne" type="hidden" id="nombreLigne" value="<%= nombreLigne %>">
        <input name="colonneMere" type="hidden" id="colonneMere" value="<%= colonneMere %>">
    </form>
</div>
<%
	} catch (Exception e) {
		e.printStackTrace();
%>
    <script language="JavaScript">
        alert('<%=e.getMessage()%>');
        history.back();
    </script>
<% }%>
