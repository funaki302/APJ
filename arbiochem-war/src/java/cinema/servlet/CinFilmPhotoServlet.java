package cinema.servlet;

import cinema.film.CinFilmPhoto;
import java.io.IOException;
import java.io.PrintWriter;
import java.net.URLEncoder;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;

/**
 * Photo (affiche) d'un film, stockee en base (CIN_FILM_PHOTO).
 * GET  /cinema/film-photo?id=CINFIL... : renvoie l'image (ou une image "pas de photo").
 * POST /cinema/film-photo (multipart) : idfilm + photo (fichier), ou idfilm + action=supprimer ; puis retour a la fiche du film.
 * Reserve aux utilisateurs connectes (session "u").
 */
@WebServlet("/cinema/film-photo")
public class CinFilmPhotoServlet extends HttpServlet {

    private static final String SANS_PHOTO =
            "<svg xmlns='http://www.w3.org/2000/svg' width='300' height='200' viewBox='0 0 300 200'>"
            + "<rect width='300' height='200' fill='#E9ECEF'/>"
            + "<rect x='115' y='70' width='70' height='50' rx='6' fill='none' stroke='#9B9EA0' stroke-width='6'/>"
            + "<path d='M185 85 l25 -15 v50 l-25 -15z' fill='#9B9EA0'/>"
            + "<text x='150' y='160' font-family='sans-serif' font-size='16' fill='#9B9EA0' text-anchor='middle'>Pas de photo</text></svg>";

    private static boolean connecte(HttpServletRequest request) {
        return request.getSession(false) != null && request.getSession(false).getAttribute("u") != null;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        if (!connecte(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        try {
            CinFilmPhoto photo = CinFilmPhoto.lire(request.getParameter("id"), null);
            response.setHeader("Cache-Control", "private, max-age=60");
            if (photo == null) {
                response.setContentType("image/svg+xml;charset=UTF-8");
                response.getWriter().write(SANS_PHOTO);
                return;
            }
            response.setContentType(photo.getTypeMime());
            response.setContentLength(photo.getContenu().length);
            response.getOutputStream().write(photo.getContenu());
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        if (!connecte(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        request.setCharacterEncoding("UTF-8");
        String idFilm = null;
        try {
            if (!ServletFileUpload.isMultipartContent(request)) throw new Exception("Formulaire invalide");
            ServletFileUpload upload = new ServletFileUpload(new DiskFileItemFactory());
            // marge au-dessus de 2 Mo pour les champs du formulaire ; la taille de l'image est controlee par CinFilmPhoto
            upload.setSizeMax(CinFilmPhoto.TAILLE_MAX + 64 * 1024);
            List<FileItem> items;
            try {
                items = upload.parseRequest(request);
            } catch (org.apache.commons.fileupload.FileUploadBase.SizeLimitExceededException e) {
                throw new Exception("L'image d&eacute;passe 2 Mo");
            }
            FileItem fichier = null;
            String action = null;
            for (FileItem item : items) {
                if (item.isFormField()) {
                    if ("idfilm".equals(item.getFieldName())) idFilm = item.getString("UTF-8").trim();
                    if ("action".equals(item.getFieldName())) action = item.getString("UTF-8");
                } else if ("photo".equals(item.getFieldName())) {
                    fichier = item;
                }
            }
            if ("supprimer".equals(action)) {
                CinFilmPhoto.supprimer(idFilm);
            } else {
                if (fichier == null || fichier.getSize() == 0) throw new Exception("Choisissez une image");
                CinFilmPhoto.enregistrer(idFilm, fichier.get(), fichier.getName());
            }
            response.sendRedirect(request.getContextPath() + "/pages/module.jsp?but=cinema/film/film-fiche.jsp&id="
                    + URLEncoder.encode(idFilm, "UTF-8"));
        } catch (Exception e) {
            e.printStackTrace();
            response.setContentType("text/html;charset=UTF-8");
            PrintWriter out = response.getWriter();
            String message = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
            out.write("<script>alert('" + message.replace("&eacute;", "é").replace("&ecirc;", "ê").replace("&agrave;", "à")
                    + "'); history.back();</script>");
        }
    }
}
