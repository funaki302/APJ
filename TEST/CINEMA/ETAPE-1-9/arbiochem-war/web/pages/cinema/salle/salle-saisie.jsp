<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.salle.CinSalle"%>
<%@page import="cinema.salle.CinCinema"%>
<%@page import="affichage.PageInsert"%>
<%@page import="affichage.Liste"%>
<%@page import="user.UserEJB"%>
<%-- Saisie d'une salle : les places (rangees x colonnes) sont generees automatiquement en classe Standard --%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        String mapping = "cinema.salle.CinSalle",
               nomtable = "CIN_SALLE",
               apres = "cinema/salle/salle-fiche.jsp",
               titre = "Saisie d'une salle";

        PageInsert pi = new PageInsert(new CinSalle(), request, u);
        pi.setLien((String) session.getValue("lien"));

        Liste[] liste = new Liste[2];
        liste[0] = new Liste("idcinema", new CinCinema(), "nom", "id");
        liste[0].setApresW(" and etat = 1");
        liste[1] = new Liste("etat", new String[]{"Active", "Inactive"}, new String[]{"1", "0"});
        pi.getFormu().changerEnChamp(liste);

        pi.getFormu().getChamp("idcinema").setLibelle("Cin&eacute;ma");
        pi.getFormu().getChamp("nom").setLibelle("Nom de la salle");
        pi.getFormu().getChamp("nb_rangees").setLibelle("Nombre de rang&eacute;es (1 &agrave; 26 : A &agrave; Z)");
        pi.getFormu().getChamp("nb_rangees").setType("number");
        pi.getFormu().getChamp("nb_rangees").setAutre("min='1' max='26'");
        pi.getFormu().getChamp("nb_colonnes").setLibelle("Places par rang&eacute;e (1 &agrave; 40)");
        pi.getFormu().getChamp("nb_colonnes").setType("number");
        pi.getFormu().getChamp("nb_colonnes").setAutre("min='1' max='40'");
        pi.getFormu().getChamp("etat").setLibelle("&Eacute;tat");
        pi.getFormu().getChamp("capacite").setVisible(false);
        pi.getFormu().getChamp("date_creation").setVisible(false);
        pi.preparerDataFormu();
%>
<div class="content-wrapper">
    <h1><%= titre %></h1>
    <p class="text-muted">Les places sont cr&eacute;&eacute;es automatiquement (A1, A2&hellip;) dans la classe la moins ch&egrave;re.
        Vous pourrez ensuite changer la classe de chaque place sur le plan de la salle.
        <b id="cinCapacite"></b></p>
    <form action="<%= pi.getLien() %>?but=apresTarif.jsp" method="post" name="<%= nomtable %>" id="<%= nomtable %>">
        <%
            pi.getFormu().makeHtmlInsertTabIndex();
            out.println(pi.getFormu().getHtmlInsert());
        %>
        <input name="acte" type="hidden" value="insert">
        <input name="bute" type="hidden" value="<%= apres %>">
        <input name="classe" type="hidden" value="<%= mapping %>">
        <input name="nomtable" type="hidden" value="<%= nomtable %>">
    </form>
</div>
<script>
    (function () {
        var r = document.querySelector('[name="nb_rangees"]'), c = document.querySelector('[name="nb_colonnes"]');
        function maj() {
            var nr = parseInt(r.value, 10), nc = parseInt(c.value, 10);
            document.getElementById('cinCapacite').textContent = (nr > 0 && nc > 0) ? 'Capacité : ' + nr + ' × ' + nc + ' = ' + (nr * nc) + ' places.' : '';
        }
        if (r && c) { r.addEventListener('input', maj); c.addEventListener('input', maj); maj(); }
    })();
</script>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
