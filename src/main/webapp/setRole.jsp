<%@ page import="java.sql.*, com.cs336.pkg.*" %>

<%
    Integer userId = (Integer) session.getAttribute("userId");
    String role = request.getParameter("role");

    if (userId == null || role == null) {
        response.sendRedirect("home.jsp");
        return;
    }

    ApplicationDB db = new ApplicationDB();
    Connection con = db.getConnection();
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        if (role.equals("buyer")) {

            ps = con.prepareStatement("SELECT * FROM Buyer WHERE user_id=?");
            ps.setInt(1, userId);
            rs = ps.executeQuery();

            if (!rs.next()) {
                PreparedStatement insert = con.prepareStatement("INSERT INTO Buyer VALUES (?)");
                insert.setInt(1, userId);
                insert.executeUpdate();
                insert.close();
            }

            session.setAttribute("role", "buyer");
            response.sendRedirect("buyerHome.jsp");
            return;
        }

        if (role.equals("seller")) {

            ps = con.prepareStatement("SELECT * FROM Seller WHERE user_id=?");
            ps.setInt(1, userId);
            rs = ps.executeQuery();

            if (!rs.next()) {
                PreparedStatement insert = con.prepareStatement("INSERT INTO Seller VALUES (?)");
                insert.setInt(1, userId);
                insert.executeUpdate();
                insert.close();
            }

            session.setAttribute("role", "seller");
            response.sendRedirect("sellerHome.jsp");
            return;
        }

    } catch (Exception e) {
        out.println("Error: " + e.getMessage());
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ignore) {}
        try { if (ps != null) ps.close(); } catch (Exception ignore) {}
        db.closeConnection(con);
    }
%>
