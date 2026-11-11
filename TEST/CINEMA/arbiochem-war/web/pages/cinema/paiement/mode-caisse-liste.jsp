<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.paiement.CinModeCaisseLib"%>
<%@page import="affichage.PageRecherche"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.HashMap"%>
<%-- Caisse proposee pour chaque mode de paiement au paiement d'un ticket (seuls les modes actifs sont proposes) --%>
<%
    try {
        CinModeCaisseLib t = new CinModeCaisseLib();
        String listeCrt[] = {"idmodepaiementlib", "idcaisselib"};
        String listeInt[] = {};
        String libEntete[] = {"id", "idmodepaiementlib", "idcaisselib", "actiflib"};
        String libEnteteAffiche[] = {"ID", "Mode de paiement", "Caisse propos&eacute;e", "Propos&eacute; au paiement"};

        PageRecherche pr = new PageRecherche(t, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
        pr.setTitre("Caisses par mode de paiement");
        pr.setUtilisateur((user.UserEJB) session.getValue("u"));
        pr.setLien((String) session.getValue("lien"));
        pr.setApres("cinema/paiement/mode-caisse-liste.jsp");
        pr.getFormu().getChamp("idmodepaiementlib").setLibelle("Mode");
        pr.getFormu().getChamp("idcaisselib").setLibelle("Caisse");

        pr.creerObjetPage(libEntete, null);

        pr.getTableau().setLien(new String[]{pr.getLien() + "?but=cinema/paiement/mode-caisse-modif.jsp"});
        pr.getTableau().setColonneLien(new String[]{"id"});
        pr.getTableau().setLibelleAffiche(libEnteteAffiche);
        pr.getFormu().setAnotherButton(
            "<a class=\"btn btn-primary pull-right btn-small\" href=\"module.jsp?but=cinema/paiement/mode-caisse-saisie.jsp&currentMenu=MENDYNCINEMA0106\">"
            + "<i class=\"material-symbols-rounded\">add</i>Ajouter un mode</a>");
%>
<div class="content-wrapper">
    <section class="content-header">
        <h1><%= pr.getTitre() %></h1>
        <p class="text-muted">Au paiement d'un ticket, chaque ligne propose la caisse de son mode (modifiable). Cliquez sur un ID pour modifier.</p>
    </section>
    <section class="content">
        <form action="<%= pr.getLien() %>?but=<%= pr.getApres() %>" method="post">
            <% out.println(pr.getFormu().getHtmlEnsemble()); %>
        </form>
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
