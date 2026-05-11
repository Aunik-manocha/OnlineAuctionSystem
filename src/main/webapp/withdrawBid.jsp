<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         import="java.sql.*,com.cs336.pkg.*" %>

<%
    String role = (String) session.getAttribute("role");
    Integer buyerId = (Integer) session.getAttribute("userId");
    if (buyerId == null || role == null || !"buyer".equals(role)) {
        response.sendRedirect("home.jsp");
        return;
    }

    String bidIdStr = request.getParameter("bid_id");
    if (bidIdStr == null) {
        response.sendRedirect("buyerBids.jsp");
        return;
    }
    int bidId = Integer.parseInt(bidIdStr);

    ApplicationDB db = new ApplicationDB();
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        con = db.getConnection();

        // make sure this bid belongs to this buyer
        ps = con.prepareStatement(
            "SELECT PL.buyer_id " +
            "FROM places PL " +
            "WHERE PL.bid_id = ?"
        );
        ps.setInt(1, bidId);
        rs = ps.executeQuery();
        if (!rs.next() || rs.getInt("buyer_id") != buyerId) {
            // not your bid
            rs.close(); ps.close(); con.close();
            response.sendRedirect("buyerBids.jsp");
            return;
        }
        rs.close();
        ps.close();

        // set status to withdrawn only if still active
        ps = con.prepareStatement(
            "UPDATE Bid SET status='withdrawn' " +
            "WHERE bid_id = ? AND status='active'"
        );
        ps.setInt(1, bidId);
        ps.executeUpdate();
        ps.close();

    } catch (Exception e) {
        // for now just print stack trace
        e.printStackTrace();
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ignore) {}
        try { if (ps != null) ps.close(); } catch (Exception ignore) {}
        try { if (con != null) con.close(); } catch (Exception ignore) {}
    }

    // back to My Bids
    response.sendRedirect("buyerBids.jsp");
%>
