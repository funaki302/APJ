<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    Accueil du module CINEMA (etape 0).
    Chaque carte devient cliquable quand sa page existe : renseigner le lien (colonne 3) a l'etape correspondante.
--%>
<link href="${pageContext.request.contextPath}/assets/css/accueil.css" rel="stylesheet" type="text/css" />
<style>
    .cinema-a-venir { cursor: default; opacity: .55; }
    .cinema-a-venir:hover { background: #FFF; color: inherit; }
    .cinema-a-venir:hover > .card-content > h3 { color: #222; }
    .cinema-a-venir:hover > .card-content > p { color: #666; }
    .cinema-a-venir:hover .icon { transform: none; }
    .cinema-etape { font-size: 12px; color: #9B9EA0; }
</style>
<%
    // { titre, description, lien (null = page pas encore faite), icone, etape }
    String[][] modules = {
        {"Configurations", "Cin&eacute;mas, classes de place (prix, couleur), cat&eacute;gories de film, acteurs et param&egrave;tres.", "cinema/salle/classe-place-liste.jsp", "settings", "1"},
        {"Salles", "Salles du cin&eacute;ma, plan des places et classes (standard, moyen, premium).", "cinema/salle/salle-liste.jsp", "chair", "2"},
        {"Films", "Catalogue des films : cat&eacute;gorie, acteur principal, dur&eacute;e, photo.", "cinema/film/film-liste.jsp", "movie", "3"},
        {"Achats", "Achats de films et de mat&eacute;riel : sortie d'argent de la caisse.", "cinema/achat/achat-liste.jsp", "shopping_bag", "4"},
        {"Diffusions", "S&eacute;ances : tel film, dans telle salle, &agrave; telle heure.", "cinema/diffusion/diffusion-calendrier.jsp", "event", "5"},
        {"R&eacute;servations", "R&eacute;server des places sur le plan de salle d'une diffusion.", "cinema/reservation/reservation-liste.jsp", "confirmation_number", "6"},
        {"Paiements", "Paiement en une fois, plusieurs modes : facture et entr&eacute;e de caisse.", "cinema/paiement/paiement-liste.jsp", "payments", "7"},
        {"Factures", "Factures cin&eacute;ma g&eacute;n&eacute;r&eacute;es automatiquement au paiement.", "cinema/facture/facture-liste.jsp", "receipt_long", "7"},
        {"Clients", "R&eacute;servations et paiements de chaque client.", null, "group", "8"},
        {"Tableau de bord", "Recettes, remplissage des salles, achats et solde de la caisse cin&eacute;ma.", null, "bar_chart", "8"}
    };
%>
<div class="content-wrapper">
    <div class="row m-0">
        <div class="col-md-12 nopadding">
            <h1 class="title-service h142pxBold m-0">Cin&eacute;ma</h1>
            <p class="desc-service h617pxRegular">Achat de films, salles, diffusions, r&eacute;servations et paiements du cin&eacute;ma.</p>
        </div>
        <div class="col-md-12 nopadding card-wrapper">
            <% for (String[] m : modules) {
                   boolean pret = m[2] != null; %>
            <% if (pret) { %>
            <a href="module.jsp?but=<%= m[2] %>" class="card col-md-4">
                <i class="fa-solid fa-arrow-right arrow"></i>
            <% } else { %>
            <div class="card col-md-4 cinema-a-venir">
            <% } %>
                <i class="material-symbols-rounded icon"><%= m[3] %></i>
                <div class="card-content">
                    <h3 class="h617pxSemibold"><%= m[0] %></h3>
                    <p class="Body14pxRegular"><%= m[1] %></p>
                    <% if (!pret) { %><span class="cinema-etape">&Agrave; venir (&eacute;tape <%= m[4] %>)</span><% } %>
                </div>
            <%= pret ? "</a>" : "</div>" %>
            <% } %>
        </div>
    </div>
</div>
