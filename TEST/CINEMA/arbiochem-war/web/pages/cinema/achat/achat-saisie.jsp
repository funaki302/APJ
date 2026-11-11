<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.achat.CinAchat"%>
<%@page import="cinema.achat.CinAchatFille"%>
<%@page import="cinema.film.CinFilm"%>
<%@page import="affichage.PageInsertMultiple"%>
<%@page import="affichage.Liste"%>
<%@page import="bean.ClassMAPTable"%>
<%@page import="bean.TypeObjet"%>
<%@page import="user.UserEJB"%>
<%--
    Saisie d'un achat de films et / ou de materiel (mere + lignes) -> apresMultiple.jsp.
    L'argent ne sort de la caisse qu'au visa (fiche de l'achat). Les lignes laissees vides sont ignorees.
--%>
<%
    try {
        UserEJB u = (UserEJB) session.getValue("u");
        int nombreLigne = 8;
        PageInsertMultiple pi = new PageInsertMultiple(new CinAchat(), new CinAchatFille(), request, nombreLigne, u);
        pi.setLien((String) session.getValue("lien"));

        Liste[] liste = new Liste[2];
        liste[0] = new Liste("idcaisse", new caisse.Caisse(), "val", "id");
        liste[0].setApresW(" and actif = 1");
        liste[0].setDefaultSelected(CinAchat.CAISSE_CINEMA);
        TypeObjet mode = new TypeObjet();
        mode.setNomTable("MODEPAIEMENT");
        liste[1] = new Liste("idmodepaiement", mode, "val", "id");
        liste[1].setDefaultSelected(CinAchat.MODE_ESPECE);
        pi.getFormu().changerEnChamp(liste);

        pi.getFormu().getChamp("daty").setLibelle("Date");
        pi.getFormu().getChamp("fournisseur").setLibelle("Fournisseur");
        pi.getFormu().getChamp("idcaisse").setLibelle("Caisse qui paie");
        pi.getFormu().getChamp("idmodepaiement").setLibelle("Mode de paiement");
        pi.getFormu().getChamp("remarque").setLibelle("Remarque");
        pi.getFormu().getChamp("montant").setVisible(false);
        pi.getFormu().getChamp("idmvtcaisse").setVisible(false);
        pi.getFormu().getChamp("etat").setVisible(false);

        // lignes : liste des films actifs avec un choix vide (ligne de materiel)
        CinFilm[] actifs = CinFilm.getFilmsActifs(null);
        ClassMAPTable[] films = new ClassMAPTable[actifs.length + 1];
        CinFilm aucun = new CinFilm();
        aucun.setId("");
        aucun.setTitre(" - ");
        films[0] = aucun;
        System.arraycopy(actifs, 0, films, 1, actifs.length);
        Liste[] listef = new Liste[2];
        listef[0] = new Liste("type", new String[]{"Mat&eacute;riel", "Film"}, new String[]{CinAchatFille.TYPE_MATERIEL, CinAchatFille.TYPE_FILM});
        listef[1] = new Liste("idfilm", films, "titre", "id");
        pi.getFormufle().changerEnChamp(listef);
        pi.getFormufle().getChamp("type_0").setLibelle("Type");
        pi.getFormufle().getChamp("idfilm_0").setLibelle("Film (si type Film)");
        pi.getFormufle().getChamp("designation_0").setLibelle("D&eacute;signation (mat&eacute;riel)");
        pi.getFormufle().getChamp("qte_0").setLibelle("Quantit&eacute;");
        pi.getFormufle().getChamp("pu_0").setLibelle("Prix unitaire (Ar)");
        affichage.Champ.setDefaut(pi.getFormufle().getChampFille("qte"), "1");
        affichage.Champ.setVisible(pi.getFormufle().getChampFille("id"), false);
        affichage.Champ.setVisible(pi.getFormufle().getChampFille("idachat"), false);
        affichage.Champ.setVisible(pi.getFormufle().getChampFille("etat"), false);
        pi.getFormufle().setColOrdre(new String[]{"id", "type", "idfilm", "designation", "qte", "pu"});

        pi.preparerDataFormu();
        pi.getFormu().makeHtmlInsertTabIndex();
        pi.getFormufle().makeHtmlInsertTableauIndex();
%>
<div class="content-wrapper">
    <h1>Saisie d'un achat (films / mat&eacute;riel)</h1>
    <form id="formAchat" class="container" action="<%= pi.getLien() %>?but=apresMultiple.jsp" method="post">
        <div class="alert alert-info">Une ligne par film ou par mat&eacute;riel achet&eacute;. L'argent sort de la caisse au moment du <b>visa</b>
            de l'achat (sur sa fiche). Pour un film, il doit d'abord exister dans <a href="module.jsp?but=cinema/film/film-saisie.jsp">Films &gt; Saisie</a> ;
            au visa, son prix d'achat prend le prix de la ligne.</div>
        <% out.println(pi.getFormu().getHtmlInsert()); %>
        <h4 style="margin-top: 16px;">Total de l'achat : <b id="cinTotalAchat">0</b> Ar</h4>
        <div id="butfillejsp">
            <% out.println(pi.getFormufle().getHtmlTableauInsert()); %>
        </div>
        <input name="acte" type="hidden" value="insert">
        <input name="bute" type="hidden" value="cinema/achat/achat-fiche.jsp">
        <input name="classe" type="hidden" value="cinema.achat.CinAchat">
        <input name="classefille" type="hidden" value="cinema.achat.CinAchatFille">
        <input name="nomtable" type="hidden" value="CIN_ACHAT_FILLE">
        <input name="nombreLigne" type="hidden" value="<%= nombreLigne %>">
        <input name="colonneMere" type="hidden" value="idachat">
    </form>
</div>
<script>
    (function () {
        var form = document.getElementById('formAchat');
        function total() {
            var t = 0;
            for (var i = 0; i < <%= nombreLigne %>; i++) {
                var q = form.querySelector('[name="qte_' + i + '"]'), p = form.querySelector('[name="pu_' + i + '"]');
                var film = form.querySelector('[name="idfilm_' + i + '"]'), des = form.querySelector('[name="designation_' + i + '"]');
                var remplie = (film && film.value) || (des && des.value.trim());
                if (remplie && q && p) t += (parseFloat(q.value) || 0) * (parseFloat(p.value) || 0);
            }
            document.getElementById('cinTotalAchat').textContent = t.toLocaleString('fr-FR');
        }
        form.addEventListener('input', total);
        form.addEventListener('change', function (e) {
            // choisir un film met la ligne en type Film
            var m = e.target.name && e.target.name.match(/^idfilm_(\d+)$/);
            if (m && e.target.value) {
                var type = form.querySelector('[name="type_' + m[1] + '"]');
                if (type) type.value = '<%= CinAchatFille.TYPE_FILM %>';
            }
            total();
        });
        total();
    })();
</script>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
