<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="cinema.paiement.CinFacture"%>
<%@page import="cinema.paiement.CinFactureDetail"%>
<%@page import="cinema.paiement.CinPaiement"%>
<%@page import="cinema.paiement.CinPaiementDetailLib"%>
<%@page import="cinema.reservation.CinTicket"%>
<%@page import="cinema.reservation.CinTicketDetailLib"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="utilitaire.UtilDB"%>
<%--
    Facture imprimable + un ticket d'entree par place. Page autonome (ouverte dans un nouvel onglet, sans le menu).
    "Exporter en PDF" = impression du navigateur -> "Enregistrer au format PDF".
--%>
<%!
    static String html(String s) {
        if (s == null) return "";
        // les textes de la base contiennent deja des entites HTML (ex. &eacute;) : on garde les entites valides, on neutralise le reste
        return s.replaceAll("&(?!#?[a-zA-Z0-9]+;)", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    if (session.getAttribute("u") == null) {
        response.sendError(HttpServletResponse.SC_FORBIDDEN);
        return;
    }
    String id = request.getParameter("id");
    String numero, daty, client, tel, film, salle, cinema, seance, heure, idTicket, idPaiement;
    double montant;
    CinFactureDetail[] lignes;
    CinPaiementDetailLib[] paiements;
    CinTicketDetailLib[] places;
    Connection c = null;
    try {
        c = new UtilDB().GetConn();
        String sql = "select f.numero, to_char(f.daty, 'DD/MM/YYYY'), f.idclientlib, f.telephone, f.idfilmlib, f.idsallelib,"
                + " to_char(f.daty_diffusion, 'DD/MM/YYYY'), f.heure, f.idticket, f.idpaiement, f.montant, ci.nom"
                + " from CIN_FACTURE_LIB f join CIN_DIFFUSION d on d.id = f.iddiffusion join CIN_SALLE s on s.id = d.idsalle"
                + " join CIN_CINEMA ci on ci.id = s.idcinema where f.id = ?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND);
                    return;
                }
                numero = rs.getString(1); daty = rs.getString(2); client = rs.getString(3); tel = rs.getString(4);
                film = rs.getString(5); salle = rs.getString(6); seance = rs.getString(7); heure = rs.getString(8);
                idTicket = rs.getString(9); idPaiement = rs.getString(10); montant = rs.getDouble(11); cinema = rs.getString(12);
            }
        }
        lignes = CinFacture.getDetails(id, c);
        paiements = CinPaiement.getDetails(idPaiement, c);
        places = CinTicket.getDetails(idTicket, c);
    } finally {
        if (c != null) c.close();
    }
    java.text.DecimalFormat fmt = new java.text.DecimalFormat("#,##0");
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Facture <%= html(numero) %></title>
    <style>
        body { font-family: Arial, Helvetica, sans-serif; color: #1C1F21; margin: 0; background: #f2f3f5; }
        .page { width: 190mm; margin: 12px auto; background: #fff; padding: 14mm; box-sizing: border-box; }
        .barre { width: 190mm; margin: 12px auto 0; display: flex; gap: 8px; justify-content: flex-end; }
        .barre button { padding: 8px 16px; border: 0; border-radius: 6px; background: #2B68D9; color: #fff; font-size: 14px; cursor: pointer; }
        .barre button.secondaire { background: #6c757d; }
        h1 { margin: 0; font-size: 24px; }
        .entete { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #1C1F21; padding-bottom: 10px; }
        .bloc { margin-top: 14px; display: flex; justify-content: space-between; gap: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 16px; font-size: 13px; }
        th, td { border: 1px solid #C3C5C6; padding: 6px 8px; text-align: left; }
        th { background: #eef1f4; }
        .droite { text-align: right; }
        .total td { font-weight: 700; font-size: 15px; }
        .tickets { display: grid; grid-template-columns: 1fr 1fr; gap: 8mm; margin-top: 10mm; }
        .ticket { border: 2px dashed #1C1F21; border-radius: 10px; padding: 8px 12px; font-size: 13px; page-break-inside: avoid; }
        .ticket .place { font-size: 26px; font-weight: 700; }
        .muted { color: #666; }
        @media print {
            body { background: #fff; }
            .barre { display: none; }
            .page { margin: 0; width: auto; padding: 0; }
        }
    </style>
</head>
<body>
<div class="barre">
    <button class="secondaire" onclick="window.close()">Fermer</button>
    <button onclick="window.print()">Exporter en PDF / imprimer</button>
</div>
<div class="page">
    <div class="entete">
        <div><h1><%= html(cinema) %></h1><div class="muted">Facture de billetterie</div></div>
        <div class="droite"><h1>Facture <%= html(numero) %></h1><div>du <%= daty %></div></div>
    </div>
    <div class="bloc">
        <div><b>Client</b><br><%= html(client) %><br><span class="muted"><%= html(tel) %></span></div>
        <div class="droite"><b>S&eacute;ance</b><br><%= html(film) %><br><%= html(salle) %> &middot; <%= seance %> &agrave; <%= heure %></div>
    </div>
    <table>
        <thead><tr><th>D&eacute;signation</th><th class="droite">Prix (Ar)</th></tr></thead>
        <tbody>
        <% for (CinFactureDetail l : lignes) { %>
        <tr><td><%= html(l.getDesignation()) %></td><td class="droite"><%= fmt.format(l.getPrix()) %></td></tr>
        <% } %>
        <tr class="total"><td class="droite">Total pay&eacute;</td><td class="droite"><%= fmt.format(montant) %> Ar</td></tr>
        </tbody>
    </table>
    <table>
        <thead><tr><th>Mode de paiement</th><th>Caisse</th><th class="droite">Montant (Ar)</th></tr></thead>
        <tbody>
        <% for (CinPaiementDetailLib p : paiements) { %>
        <tr><td><%= html(p.getIdmodepaiementlib()) %></td><td><%= html(p.getIdcaisselib()) %></td><td class="droite"><%= fmt.format(p.getMontant()) %></td></tr>
        <% } %>
        </tbody>
    </table>
    <p class="muted" style="margin-top: 8px;">Ticket <%= html(idTicket) %> &middot; paiement <%= html(idPaiement) %></p>

    <div class="tickets">
        <% for (CinTicketDetailLib pl : places) { %>
        <div class="ticket">
            <div class="muted"><%= html(cinema) %> &middot; billet d'entr&eacute;e</div>
            <div><b><%= html(film) %></b></div>
            <div><%= html(salle) %> &middot; <%= seance %> &agrave; <%= heure %></div>
            <div style="display: flex; justify-content: space-between; align-items: flex-end;">
                <span class="place">Place <%= pl.getNumero() %></span>
                <span><%= html(pl.getIdclasselib()) %> &middot; <%= fmt.format(pl.getPrix()) %> Ar</span>
            </div>
            <div class="muted"><%= html(client) %> &middot; <%= html(numero) %></div>
        </div>
        <% } %>
    </div>
</div>
</body>
</html>
