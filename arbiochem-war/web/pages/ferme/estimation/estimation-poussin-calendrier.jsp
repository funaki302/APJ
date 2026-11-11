<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.YearMonth" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Collections" %>
<%@ page import="java.util.Comparator" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.TreeMap" %>
<%@ page import="bean.CGenUtil" %>
<%@ page import="bean.TypeObjet" %>
<%@ page import="ferme.lot.Lot" %>
<%@ page import="ferme.estimation.EstimationPoussinCalendrier" %>
<%@ page import="ferme.estimation.PoussinExistant" %>

<%!
    // ---------- utilitaires de la page ----------
    private static int entier(String s, int defaut, int min, int max) {
        try {
            int v = Integer.parseInt(s.trim());
            return v < min ? min : (v > max ? max : v);
        } catch (Exception e) {
            return defaut;
        }
    }

    private static String h(String s) {   // echappement HTML
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    private static String nb(double v) {
        return v > 0 ? String.format("%,.0f", v) : "-";
    }
%>

<style>
    .cal-poussin .table-container { max-width: 100%; max-height: 75vh; overflow: auto; border: 1px solid #ccc; padding: 0; }
    .cal-poussin table { border-collapse: collapse; width: 100%; table-layout: auto; min-width: fit-content; }
    .cal-poussin th, .cal-poussin td { border: 1px solid #999; padding: 6px; text-align: right; font-size: 12px; }
    .cal-poussin th { background-color: #f2f2f2; text-align: center; position: sticky; top: 0; z-index: 2; }
    .cal-poussin .jour-cell { text-align: center; background: #fff; }
    .cal-poussin .jour { text-align: left; position: sticky; left: 0; background: #fff; z-index: 3; min-width: 90px; white-space: nowrap; }
    .cal-poussin .dimanche { background-color: #fdd; }
    .cal-poussin .produit { background-color: #e8f5e9; font-weight: bold; }
    .cal-poussin .montant { text-align: right; }
    .cal-poussin .total { font-weight: bold; }
    .cal-poussin .filtres .form-input { margin-bottom: 8px; }
    .cal-poussin .detail td, .cal-poussin .detail th { position: static; }
</style>

<%
    try {
        String lien = (String) session.getValue("lien");
        String bute = "ferme/estimation/estimation-poussin-calendrier.jsp";

        String[] mois = {"Janvier", "F&eacute;vrier", "Mars", "Avril", "Mai", "Juin", "Juillet",
                         "Ao&ucirc;t", "Septembre", "Octobre", "Novembre", "D&eacute;cembre"};
        String[] jourAbbr = {"Lun.", "Mar.", "Mer.", "Jeu.", "Ven.", "Sam.", "Dim."};

        // ---------- filtres ----------
        YearMonth maintenant = YearMonth.now();
        YearMonth finDefaut = maintenant.plusMonths(5);
        int moisDebut  = entier(request.getParameter("moisDebut"),  maintenant.getMonthValue(), 1, 12);
        int anneeDebut = entier(request.getParameter("anneeDebut"), maintenant.getYear(), 2000, 2100);
        int moisFin    = entier(request.getParameter("moisFin"),    finDefaut.getMonthValue(), 1, 12);
        int anneeFin   = entier(request.getParameter("anneeFin"),   finDefaut.getYear(), 2000, 2100);
        YearMonth debut = YearMonth.of(anneeDebut, moisDebut);
        YearMonth fin   = YearMonth.of(anneeFin, moisFin);
        if (fin.isBefore(debut)) { YearMonth t = debut; debut = fin; fin = t; }
        if (debut.plusMonths(35).isBefore(fin)) { fin = debut.plusMonths(35); }   // 36 mois maximum

        String idLot = request.getParameter("idlot");
        if (idLot == null || !idLot.matches("[A-Za-z0-9._/-]+")) idLot = "";
        String souche = request.getParameter("souche");
        if (souche == null) souche = "";
        souche = souche.trim();
        boolean enOeufs = "oeufs".equals(request.getParameter("indicateur"));
        boolean avecDetail = "1".equals(request.getParameter("detail"));
        String libIndicateur = enOeufs ? "&oelig;ufs" : "poussins";

        // ---------- donnees ----------
        LocalDate d1 = debut.atDay(1);
        LocalDate d2 = fin.atEndOfMonth();
        StringBuilder aWhere = new StringBuilder();
        aWhere.append(" AND DATE_ECLOSION >= TO_DATE('").append(d1).append("','YYYY-MM-DD')");
        aWhere.append(" AND DATE_ECLOSION < TO_DATE('").append(d2.plusDays(1)).append("','YYYY-MM-DD')");
        if (!idLot.isEmpty()) aWhere.append(" AND IDLOT = '").append(idLot).append("'");
        if (!souche.isEmpty()) aWhere.append(" AND SOUCHE = '").append(souche.replace("'", "''")).append("'");

        EstimationPoussinCalendrier[] lignes = (EstimationPoussinCalendrier[]) CGenUtil.rechercher(
                new EstimationPoussinCalendrier(), null, null, aWhere.toString());
        if (lignes == null) lignes = new EstimationPoussinCalendrier[0];

        // total par jour d'eclosion  [0]=poussins [1]=oeufs ; detail par lot pour l'infobulle
        Map<LocalDate, double[]> parJour = new HashMap<LocalDate, double[]>();
        Map<LocalDate, Map<String, Double>> parJourLot = new HashMap<LocalDate, Map<String, Double>>();
        for (EstimationPoussinCalendrier l : lignes) {
            if (l.getDate_eclosion() == null) continue;
            LocalDate jr = l.getDate_eclosion().toLocalDate();
            double[] t = parJour.get(jr);
            if (t == null) { t = new double[2]; parJour.put(jr, t); }
            t[0] += l.getNb_poussins_estimes();
            t[1] += l.getNb_oeufs_estimes();
            Map<String, Double> pl = parJourLot.get(jr);
            if (pl == null) { pl = new TreeMap<String, Double>(); parJourLot.put(jr, pl); }
            String cle = l.getNomlot() == null ? l.getIdlot() : l.getNomlot();
            Double ancien = pl.get(cle);
            pl.put(cle, (ancien == null ? 0 : ancien) + (enOeufs ? l.getNb_oeufs_estimes() : l.getNb_poussins_estimes()));
        }

        List<YearMonth> colonnes = new ArrayList<YearMonth>();
        for (YearMonth m = debut; !m.isAfter(fin); m = m.plusMonths(1)) colonnes.add(m);

        // poussins EXISTANTS (stock a ce jour, meme filtres lot / souche, independants de la periode)
        StringBuilder aWhereEx = new StringBuilder();
        if (!idLot.isEmpty()) aWhereEx.append(" AND IDLOT = '").append(idLot).append("'");
        if (!souche.isEmpty()) aWhereEx.append(" AND SOUCHE = '").append(souche.replace("'", "''")).append("'");
        PoussinExistant[] existants = (PoussinExistant[]) CGenUtil.rechercher(new PoussinExistant(), null, null, aWhereEx.toString());
        if (existants == null) existants = new PoussinExistant[0];
        double totalExistants = 0;
        for (PoussinExistant ex : existants) totalExistants += ex.getQte_existants();

        // listes des filtres
        Lot[] lots = (Lot[]) CGenUtil.rechercher(new Lot(), null, null, "");
        TypeObjet sch = new TypeObjet();
        sch.setNomTable("SOUCHE");
        Object[] souches = CGenUtil.rechercher(sch, null, null, "");
        double totalGeneral = 0;
%>
<div class="content-wrapper cal-poussin">
    <section class="content-header">
        <h1>Calendrier d'estimation des poussins &agrave; venir</h1>
    </section>
    <div class="alert alert-info" style="margin-top:10px">
        Toutes les valeurs sont des <b>estimations</b> calcul&eacute;es &agrave; partir des femelles vivantes du triage
        et des param&egrave;tres de la souche (&acirc;ge d'entr&eacute;e en ponte, fr&eacute;quence et potentiel de ponte,
        dur&eacute;e d'incubation, pourcentage d'&oelig;ufs non &eacute;clos). La date affich&eacute;e est la date d'&eacute;closion.
    </div>

    <form class="filtres" action="<%=lien%>" method="get" style="display:flex;flex-wrap:wrap;gap:10px;align-items:flex-end;">
        <input type="hidden" name="but" value="<%=bute%>">
        <div class="form-input">
            <label class="input-label">Mois &amp; ann&eacute;e d&eacute;but</label>
            <span style="display:flex;gap:2px">
                <select class="form-control" name="moisDebut">
                    <% for (int i = 0; i < mois.length; i++) { %>
                    <option value="<%=i + 1%>" <%= (i + 1) == debut.getMonthValue() ? "selected" : "" %>><%=mois[i]%></option>
                    <% } %>
                </select>
                <input class="form-control" type="number" name="anneeDebut" value="<%=debut.getYear()%>" style="width:90px">
            </span>
        </div>
        <div class="form-input">
            <label class="input-label">Mois &amp; ann&eacute;e fin</label>
            <span style="display:flex;gap:2px">
                <select class="form-control" name="moisFin">
                    <% for (int i = 0; i < mois.length; i++) { %>
                    <option value="<%=i + 1%>" <%= (i + 1) == fin.getMonthValue() ? "selected" : "" %>><%=mois[i]%></option>
                    <% } %>
                </select>
                <input class="form-control" type="number" name="anneeFin" value="<%=fin.getYear()%>" style="width:90px">
            </span>
        </div>
        <div class="form-input">
            <label class="input-label">Lot</label>
            <select class="form-control" name="idlot">
                <option value="">Tous les lots</option>
                <% if (lots != null) for (Lot lt : lots) { %>
                <option value="<%=h(lt.getId())%>" <%= lt.getId().equals(idLot) ? "selected" : "" %>><%=h(lt.getNomlot())%></option>
                <% } %>
            </select>
        </div>
        <div class="form-input">
            <label class="input-label">Souche</label>
            <select class="form-control" name="souche">
                <option value="">Toutes les souches</option>
                <% if (souches != null) for (Object o : souches) { TypeObjet so = (TypeObjet) o; %>
                <option value="<%=h(so.getVal())%>" <%= so.getVal() != null && so.getVal().equals(souche) ? "selected" : "" %>><%=h(so.getVal())%></option>
                <% } %>
            </select>
        </div>
        <div class="form-input">
            <label class="input-label">Indicateur</label>
            <select class="form-control" name="indicateur">
                <option value="poussins" <%= enOeufs ? "" : "selected" %>>Poussins estim&eacute;s</option>
                <option value="oeufs" <%= enOeufs ? "selected" : "" %>>&OElig;ufs estim&eacute;s</option>
            </select>
        </div>
        <div class="form-input">
            <label class="input-label">D&eacute;tail</label>
            <select class="form-control" name="detail">
                <option value="0" <%= avecDetail ? "" : "selected" %>>Non</option>
                <option value="1" <%= avecDetail ? "selected" : "" %>>Par lot / parquet</option>
            </select>
        </div>
        <div class="form-input">
            <button class="btn btn-primary btn-small" style="height:32px" type="submit">Afficher</button>
        </div>
    </form>

    <div class="table-container" style="margin-top:10px">
        <table>
            <thead>
            <tr>
                <th class="jour-cell jour">Jour</th>
                <% for (YearMonth m : colonnes) { %>
                <th class="jour-cell" style="width:50px;">DATE</th>
                <th class="jour-cell"><%= mois[m.getMonthValue() - 1].toUpperCase() %> <%= m.getYear() %></th>
                <% } %>
            </tr>
            </thead>
            <tbody>
            <% for (int jour = 1; jour <= 31; jour++) { %>
            <tr>
                <td class="jour-cell jour"><%=jour%></td>
                <% for (YearMonth m : colonnes) {
                    if (jour > m.lengthOfMonth()) { %>
                <td class="jour-cell">-</td><td class="jour-cell montant">-</td>
                <%  continue; }
                    LocalDate dt = m.atDay(jour);
                    boolean dimanche = dt.getDayOfWeek().getValue() == 7;
                    double[] t = parJour.get(dt);
                    double val = t == null ? 0 : (enOeufs ? t[1] : t[0]);
                    String info = "";
                    if (val > 0 && parJourLot.get(dt) != null) {
                        StringBuilder sb = new StringBuilder();
                        for (Map.Entry<String, Double> e : parJourLot.get(dt).entrySet()) {
                            sb.append(e.getKey()).append(" : ").append(String.format("%,.0f", e.getValue())).append("&#10;");
                        }
                        info = sb.toString();
                    }
                %>
                <td class="jour-cell <%= dimanche ? "dimanche" : "" %>"><%= jourAbbr[dt.getDayOfWeek().getValue() - 1] %></td>
                <td class="jour-cell montant <%= val > 0 ? "produit" : (dimanche ? "dimanche" : "") %>" <%= val > 0 ? "title=\"" + info + "\"" : "" %>><%= nb(val) %></td>
                <% } %>
            </tr>
            <% } %>
            </tbody>
            <tfoot>
            <tr>
                <td class="jour-cell jour total">TOTAL <%= libIndicateur.toUpperCase() %></td>
                <% for (YearMonth m : colonnes) {
                    double somme = 0;
                    for (int jour = 1; jour <= m.lengthOfMonth(); jour++) {
                        double[] t = parJour.get(m.atDay(jour));
                        if (t != null) somme += enOeufs ? t[1] : t[0];
                    }
                    totalGeneral += somme;
                %>
                <td class="jour-cell montant total" colspan="2"><%= nb(somme) %></td>
                <% } %>
            </tr>
            <tr>
                <td class="jour-cell jour total">MOYENNE / JOUR D'&Eacute;CLOSION</td>
                <% for (YearMonth m : colonnes) {
                    double somme = 0; int nbJours = 0;
                    for (int jour = 1; jour <= m.lengthOfMonth(); jour++) {
                        double[] t = parJour.get(m.atDay(jour));
                        double v = t == null ? 0 : (enOeufs ? t[1] : t[0]);
                        if (v > 0) { somme += v; nbJours++; }
                    }
                %>
                <td class="jour-cell montant total" colspan="2"><%= nbJours > 0 ? nb(somme / nbJours) : "-" %></td>
                <% } %>
            </tr>
            </tfoot>
        </table>
    </div>
    <p style="margin-top:8px">
        <b>Poussins existants (lots re&ccedil;us) :</b> <%= nb(totalExistants) %>
        &nbsp;|&nbsp; <b>Total de la p&eacute;riode (<%= libIndicateur %>) :</b> <%= nb(totalGeneral) %>
        <% if (!enOeufs) { %>&nbsp;|&nbsp; <b>Existants + estim&eacute;s :</b> <%= nb(totalExistants + totalGeneral) %><% } %>
    </p>
    <% if (lignes.length == 0) { %>
    <div class="alert alert-warning">
        Aucune estimation sur cette p&eacute;riode. V&eacute;rifiez qu'un triage de femelles existe pour le lot et que
        les param&egrave;tres de la souche (&acirc;ge d'entr&eacute;e en ponte, incubation, potentiel et fr&eacute;quence de ponte) sont renseign&eacute;s.
    </div>
    <% } %>

    <% if (avecDetail && lignes.length > 0) {
        List<EstimationPoussinCalendrier> tri = new ArrayList<EstimationPoussinCalendrier>();
        Collections.addAll(tri, lignes);
        Collections.sort(tri, new Comparator<EstimationPoussinCalendrier>() {
            public int compare(EstimationPoussinCalendrier a, EstimationPoussinCalendrier b) {
                int c = a.getDate_eclosion().compareTo(b.getDate_eclosion());
                if (c != 0) return c;
                String la = a.getNomlot() == null ? "" : a.getNomlot();
                String lb = b.getNomlot() == null ? "" : b.getNomlot();
                return la.compareTo(lb);
            }
        });
    %>
    <h3>D&eacute;tail par lot et par parquet</h3>
    <div class="table-container detail">
        <table class="detail">
            <thead>
            <tr><th>Date d'&eacute;closion</th><th>Origine</th><th>Lot</th><th>Souche</th><th>Parquet</th><th>Femelles</th><th>&OElig;ufs estim&eacute;s</th><th>Poussins estim&eacute;s</th></tr>
            </thead>
            <tbody>
            <% for (EstimationPoussinCalendrier l : tri) { %>
            <tr>
                <td class="jour-cell"><%= l.getDate_eclosion().toLocalDate() %></td>
                <td style="text-align:left"><%= l.getGeneration() == 2 ? "Poussins estim&eacute;s" : "Poussins re&ccedil;us" %></td>
                <td style="text-align:left"><%= h(l.getNomlot()) %></td>
                <td style="text-align:left"><%= h(l.getSouche()) %></td>
                <td style="text-align:left"><%= h(l.getParquet()) %></td>
                <td><%= nb(l.getNb_femelles()) %></td>
                <td><%= nb(l.getNb_oeufs_estimes()) %></td>
                <td><%= nb(l.getNb_poussins_estimes()) %></td>
            </tr>
            <% } %>
            </tbody>
        </table>
    </div>
    <% } %>
</div>
<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">
    alert('<%= String.valueOf(e.getMessage()).replace("'", " ").replace("\n", " ") %>');
    history.back();
</script>
<% } %>
