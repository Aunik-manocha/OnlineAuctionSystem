<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         import="java.sql.*,com.cs336.pkg.*" %>

<%
    request.setCharacterEncoding("UTF-8");

    // (Optional safety) make sure only sellers can hit this
    String role = (String) session.getAttribute("role");
    Integer sellerId = (Integer) session.getAttribute("userId");
    if (sellerId == null || role == null || !"seller".equals(role)) {
        response.sendRedirect("home.jsp");
        return;
    }

    // Get form values
    int auctionId      = Integer.parseInt(request.getParameter("auction_id"));
    String title       = request.getParameter("title");
    String initialStr  = request.getParameter("initial_price");
    String minimumStr  = request.getParameter("minimum_price");
    String incrementStr= request.getParameter("bid_increment");
    String status      = request.getParameter("status");

    Connection con = null;
    PreparedStatement ps = null;

    try {
        ApplicationDB db = new ApplicationDB();
        con = db.getConnection();

        // 1) Update the auction itself
        ps = con.prepareStatement(
            "UPDATE Auction " +
            "SET title = ?, initial_price = ?, minimum_price = ?, " +
            "    bid_increment = ?, status = ? " +
            "WHERE auction_id = ?"
        );
        ps.setString(1, title);
        ps.setBigDecimal(2, new java.math.BigDecimal(initialStr));
        ps.setBigDecimal(3, new java.math.BigDecimal(minimumStr));
        ps.setBigDecimal(4, new java.math.BigDecimal(incrementStr));
        ps.setString(5, status);
        ps.setInt(6, auctionId);
        ps.executeUpdate();
        ps.close();

        // 2) If seller marks auction sold / not_available,
        //    close all remaining ACTIVE bids on this auction.
        if ("sold".equalsIgnoreCase(status) || "not_available".equalsIgnoreCase(status)) {
            PreparedStatement psCloseBids = con.prepareStatement(
                "UPDATE Bid SET status = 'outbid' " +
                "WHERE bid_id IN ( " +
                "  SELECT b2.bid_id FROM ( " +
                "    SELECT B.bid_id " +
                "    FROM Bid B " +
                "    JOIN placed_on PO ON B.bid_id = PO.bid_id " +
                "    WHERE PO.auction_id = ? AND B.status = 'active' " +
                "  ) b2 " +
                ")"
            );
            psCloseBids.setInt(1, auctionId);
            psCloseBids.executeUpdate();
            psCloseBids.close();
        }

    } catch (Exception e) {
        // If something breaks, show it plainly for now
        out.println("Error updating auction: " + e);
        if (con != null) {
            try { con.close(); } catch (Exception ignore) {}
        }
        return;
    } finally {
        try { if (ps  != null) ps.close(); } catch (Exception ignore) {}
        try { if (con != null) con.close(); } catch (Exception ignore) {}
    }
%>

<!DOCTYPE html>
<html>
<head>
<title>Updated</title>
<meta http-equiv="refresh" content="1;URL=sellerHome.jsp" />
<style>
body{font-family:Arial;background:#f6f7fb;display:flex;justify-content:center;align-items:center;height:100vh;}
.box{background:#fff;padding:20px;border-radius:12px;box-shadow:0 0 12px rgba(0,0,0,.1);text-align:center;}
</style>
</head>

<body>
<div class="box">
    <h2>✔ Auction Updated</h2>
    <p>Returning to your seller dashboard...</p>
</div>
</body>
</html>
