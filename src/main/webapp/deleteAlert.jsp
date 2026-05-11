<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         import="java.sql.*,com.cs336.pkg.*" %>

<%
    // Make sure only logged-in buyers can delete their own alerts
    String role = (String) session.getAttribute("role");
    Integer buyerId = (Integer) session.getAttribute("userId");

    if (buyerId == null || role == null || !"buyer".equals(role)) {
        response.sendRedirect("home.jsp");
        return;
    }

    String alertIdStr = request.getParameter("alert_id");

    if (alertIdStr != null && !alertIdStr.isEmpty()) {
        try {
            int alertId = Integer.parseInt(alertIdStr);

            ApplicationDB db = new ApplicationDB();
            Connection con = db.getConnection();

            PreparedStatement ps = con.prepareStatement(
                "DELETE FROM Alert WHERE alert_id = ? AND buyer_id = ?"
            );
            ps.setInt(1, alertId);
            ps.setInt(2, buyerId);
            ps.executeUpdate();

            ps.close();
            con.close();
        } catch (Exception e) {
            // Optional: log or show an error if you want
            // e.printStackTrace();
        }
    }

    // Go back to buyer dashboard
    response.sendRedirect("buyerHome.jsp");
%>
