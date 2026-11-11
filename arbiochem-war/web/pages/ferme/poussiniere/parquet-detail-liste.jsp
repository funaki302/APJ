<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="affichage.PageRecherche"%>
<%@ page import="ferme.triageBatiment.TriageBatimentParquetDetailValorise" %>

<% try{
    TriageBatimentParquetDetailValorise o = new TriageBatimentParquetDetailValorise();
    o.setNomTable("TRIAGEBATPARQUETDETAIL_VALO");

    String[] listeCrt = {"idparquet","idParquetLib","idmere","idlot","idbl","daty"};
    String[] listeInt = {"daty"};
    String[] libEntete = {
        "idparquet",
        "idParquetLib",
        "qteTheorique",
        "qteReelle",
        "valeurTheoriqueUnitaire",
        "valeurUnitaireReelle",
        "valeurTotaleTheorique",
        "valeurTotaleReelle"
    };

    PageRecherche pr = new PageRecherche(o, request, listeCrt, listeInt, 4, libEntete, libEntete.length);
    pr.setTitre("Liste des parquets valorises");
    pr.setUtilisateur((user.UserEJB) session.getValue("u"));
    pr.setLien((String) session.getValue("lien"));
    pr.setApres("ferme/poussiniere/parquet-detail-liste.jsp");

    pr.getFormu().getChamp("idparquet").setLibelle("Id parquet");
    pr.getFormu().getChamp("idParquetLib").setLibelle("Nom du parquet");
    pr.getFormu().getChamp("idmere").setLibelle("Triage");
    pr.getFormu().getChamp("idlot").setLibelle("Lot");
    pr.getFormu().getChamp("idbl").setLibelle("Bon de livraison");
    pr.getFormu().getChamp("daty1").setLibelle("Date min");
    pr.getFormu().getChamp("daty2").setLibelle("Date max");

    String[] colSomme = {"qteTheorique","qteReelle","valeurTotaleTheorique","valeurTotaleReelle"};
    pr.creerObjetPage(libEntete, colSomme);

    String[] enteteRecap = {"","Nombre","Qt&eacute; th&eacute;orique","Qt&eacute; r&eacute;elle","Valeur th&eacute;orique","Valeur r&eacute;elle"};
    pr.getTableauRecap().setLibeEntete(enteteRecap);

    String[] lienTableau = {pr.getLien() + "?but=ferme/configuration/parquet-fiche.jsp"};
    String[] colonneLien = {"idparquet"};
    String[] attributLien = {"idparquet"};
    pr.getTableau().setLien(lienTableau);
    pr.getTableau().setColonneLien(colonneLien);
    pr.getTableau().setAttLien(attributLien);

    String[] libEnteteAffiche = {
        "Id parquet",
        "Nom",
        "Qt&eacute; th&eacute;orique",
        "Qt&eacute; r&eacute;elle",
        "Valeur th&eacute;orique unitaire",
        "Valeur unitaire r&eacute;elle",
        "Valeur totale th&eacute;orique",
        "Valeur totale r&eacute;elle"
    };
    pr.getTableau().setLibelleAffiche(libEnteteAffiche);
%>

<div class="content-wrapper">
    <section class="content-header">
        <h1><%= pr.getTitre() %></h1>
    </section>
    <section class="content">
        <form action="<%=pr.getLien()%>?but=<%= pr.getApres() %>" method="post">
            <%
                out.println(pr.getFormu().getHtmlEnsemble());
            %>
        </form>
        <%
            out.println(pr.getTableauRecap().getHtml());
        %>
        <br>
        <%
            out.println(pr.getTableau().getHtml());
            out.println(pr.getBasPage());
        %>
    </section>
</div>

<% } catch (Exception e) {
    e.printStackTrace();
%>
<script language="JavaScript"> alert('<%=e.getMessage()%>');
    history.back();
</script>
<% } %>
