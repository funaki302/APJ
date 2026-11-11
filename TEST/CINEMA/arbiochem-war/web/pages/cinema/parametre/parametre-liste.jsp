<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.utils.CinParametre"%>
<%@page import="affichage.PageRecherche"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.HashMap"%>
<%-- Parametres du cinema : codes fixes (pas de saisie ni de suppression), seule la valeur se modifie --%>
<%
    try {
        CinParametre t = new CinParametre();
        String listeCrt[] = {"code"};
        String listeInt[] = {};
        String libEntete[] = {"id", "code", "valeur", "desce"};
        String libEnteteAffiche[] = {"ID", "Code", "Valeur", "Description"};

        PageRecherche pr = new PageRecherche(t, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
        pr.setTitre("Param&egrave;tres du cin&eacute;ma");
        pr.setUtilisateur((user.UserEJB) session.getValue("u"));
        pr.setLien((String) session.getValue("lien"));
        pr.setApres("cinema/parametre/parametre-liste.jsp");
        pr.getFormu().getChamp("code").setLibelle("Code");

        pr.creerObjetPage(libEntete, null);

        Map<String, String> lienTab = new HashMap();
        lienTab.put("modifier", pr.getLien() + "?but=cinema/parametre/parametre-modif.jsp");
        pr.getTableau().setLienClicDroite(lienTab);
        pr.getTableau().setLien(new String[]{pr.getLien() + "?but=cinema/parametre/parametre-fiche.jsp"});
        pr.getTableau().setColonneLien(new String[]{"id"});
        pr.getTableau().setLibelleAffiche(libEnteteAffiche);
%>
<div class="content-wrapper">
    <section class="content-header">
        <h1><%= pr.getTitre() %></h1>
    </section>
    <section class="content">
        <form action="<%= pr.getLien() %>?but=<%= pr.getApres() %>" method="post">
            <% out.println(pr.getFormu().getHtmlEnsemble()); %>
        </form>
        <% out.println(pr.getTableauRecap().getHtml()); %>
        <br>
        <%
            out.println(pr.getTableau().getHtml());
            out.println(pr.getBasPage());
        %>
    </section>
</div>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
