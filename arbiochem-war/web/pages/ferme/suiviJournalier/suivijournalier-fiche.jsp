<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="user.UserEJB" %>
<%@ page import="affichage.PageConsulte" %>
<%@ page import="ferme.suiviJournalier.SuiviJournalieLib" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Map" %>
<%@ page import="utilitaire.ConstanteEtat" %>

<%!
    // Evite le NullPointerException si un champ n'existe pas dans la classe SuiviJournalieLib
    static void libelle(affichage.PageConsulte pc, String nom, String lib) {
        affichage.Champ c = pc.getChampByName(nom);
        if (c == null) { System.out.println("[suivijournalier-fiche] champ introuvable : " + nom); return; }
        c.setLibelle(lib);
    }
    static void masquer(affichage.PageConsulte pc, String nom) {
        affichage.Champ c = pc.getChampByName(nom);
        if (c == null) { System.out.println("[suivijournalier-fiche] champ introuvable : " + nom); return; }
        c.setVisible(false);
    }
%>
<% try{ 
    UserEJB u = (user.UserEJB)session.getValue("u");
    String lien = (String) session.getValue("lien");

    SuiviJournalieLib o = new SuiviJournalieLib();
    o.setNomTable("SUIVIJOURNALIER_LIB");
    PageConsulte pc = new PageConsulte(o, request, u);
    pc.setTitre("Fiche du suivi journalier");
    // L'id vient de l'URL : getTuppleID() renvoyait null (liens Valider/Modifier et onglet Details en id=null)
    String id = request.getParameter("id");
    if (id == null || id.trim().isEmpty()) {
        id = pc.getBase().getTuppleID();
    }

    libelle(pc, "id", "Id");
    libelle(pc, "idlot", "ID Lot");
    libelle(pc, "idLotLib", "Nom du lot");
    libelle(pc, "IdSoucheLib", "Souche");
    if (pc.getChampByName("idlot") != null) pc.getChampByName("idlot").setLien(lien+"?but=ferme/lot/lot-fiche.jsp","id=");
    libelle(pc, "daty", "Date");
    libelle(pc, "etatLib", "&Eacute;tat");
    masquer(pc, "etat");



    String[] ordre = {"id", "idlot", "idLotLib", "IdSoucheLib","daty", "etatLib"};
    pc.setOrdre(ordre);

    String pageActuel = "ferme/suiviJournalier/suivijournalier-fiche.jsp";
    String pageRetour = "ferme/suiviJournalier/suivijournalier-liste.jsp";
    String pageModif = "ferme/suiviJournalier/suivijournalier-saisie.jsp&acte=update";
    String pageApresDelete = "ferme/suiviJournalier/suivijournalier-liste.jsp";
    String classe = "ferme.suiviJournalier.SuiviJournalier";

    Map<String, String> map = new HashMap<>();
    map.put("inc/suivijournlier-det", "");
    String tab = request.getParameter("tab");
    if (tab == null) {
        tab = "inc/suivijournlier-det";
    }
    map.put(tab, "active");
    tab = tab + ".jsp";
    o = (SuiviJournalieLib) pc.getBase();
%>

<div class="content-wrapper">

<h1 class="box-title"><a href=<%= lien + "?but=" + pageRetour%>> <i class="fa fa-angle-left"></i></a><%=pc.getTitre()%></h1>

<div class="row m-0">
    <div class="col-md-3"></div>
    <div class="col-md-6">
        <div class="box-fiche">
            <div class="box">
                <div class="box-body">
                    <%
                        out.println(pc.getHtml());
                    %>
                    <br/>
                    <div class="box-footer">
                        <% if(o.getEtat() < ConstanteEtat.getEtatValider()) { %>
                            <a class="btn btn-primary pull-right" href="<%= lien + "?but=apresTarif.jsp&id=" + id+"&acte=valider&bute="+pageActuel+"&classe="+classe %>">Valider</a>
                            <a class="btn btn-secondary pull-right" href="<%= lien + "?but="+ pageModif +"&id=" + id %>" style="margin-right: 10px">Modifier</a>
                            <a class="btn btn-danger pull-left" href="<%= lien + "?but=apresTarif.jsp&id=" + id+"&acte=delete&bute="+pageApresDelete+"&classe="+classe %>">Supprimer</a>
                        <% } %>
                    </div>
                    <br/>
                </div>
            </div>
        </div>
    </div>
</div>
<div class="row m-0">
    <div class="col-md-12 nopadding">
        <div class="nav-tabs-custom">
            <ul class="nav nav-tabs">
                <!-- Exemple d'onglet -->
                <li class="<%=map.get("inc/suivijournlier-det")%>"><a href="<%= lien %>?but=<%= pageActuel %>&id=<%= id %>&tab=inc/suivijournlier-det">D&eacute;tails</a></li>
            </ul>
            <div class="tab-content">
                    <jsp:include page="<%= tab %>" >
                        <jsp:param name="id" value="<%= id %>" />
                    </jsp:include>
            </div>
        </div>
        
        </div>
    </div>
</div>

<% } catch (Exception e) {
  e.printStackTrace();
%>
<script language="JavaScript"> alert('<%=String.valueOf(e.getMessage()).replace("'", " ")%>');
    history.back();
</script>
<% }%>

