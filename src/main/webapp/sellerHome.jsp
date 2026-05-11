<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         import="java.sql.*,com.cs336.pkg.*" %>

<%
    String role = (String) session.getAttribute("role");
    Integer sellerId = (Integer) session.getAttribute("userId");
    String sellerName = (String) session.getAttribute("name");

    if (sellerId == null || role == null || !"seller".equals(role)) {
        response.sendRedirect("home.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Seller Panel</title>
<style>
body{
    font-family:Arial, sans-serif;
    background:#f6f7fb;
    margin:0;
    padding:40px 0;
}
.card{
    background:#fff;
    width:1000px;
    margin:0 auto;
    padding:24px 28px;
    border-radius:14px;
    box-shadow:0 10px 25px rgba(0,0,0,.08);
}
h1{margin-top:0;}
.topbar{
    display:flex;
    justify-content:space-between;
    align-items:center;
    margin-bottom:16px;
}
.btn{
    padding:8px 14px;
    border:none;
    border-radius:10px;
    background:#111827;
    color:#fff;
    font-weight:600;
    cursor:pointer;
}
.btn.secondary{ background:#4b5563; }
.btn.red{ background:#b91c1c; }
.auction-box{
    border:1px solid #e5e7eb;
    padding:12px;
    border-radius:10px;
    margin:8px 0;
    background:#f9fafb;
}
.small{font-size:13px;color:#6b7280;}
.actions form{display:inline-block;margin-right:6px;}
.badge{
    display:inline-block;
    padding:2px 8px;
    border-radius:999px;
    font-size:12px;
    color:#fff;
}
.badge.active{background:#16a34a;}
.badge.sold{background:#2563eb;}
.badge.closed{background:#6b7280;}
.badge.other{background:#92400e;}
</style>
</head>
<body>
<div class="card">
    <div class="topbar">
        <div>
            <h1>Seller Panel</h1>
            <div class="small">Welcome, <strong><%= (sellerName != null ? sellerName : "Seller") %></strong></div>
        </div>
        <form action="logout.jsp" method="post">
            <button type="submit" class="btn red">Logout</button>
        </form>
    </div>

    <div style="margin-bottom:16px;">
        <form action="postItem.jsp" method="get" style="display:inline-block;margin-right:8px;">
            <button type="submit" class="btn">Create New Auction</button>
        </form>
        <form action="sellerSales.jsp" method="get" style="display:inline-block;">
            <button type="submit" class="btn secondary">View Sales History</button>
        </form>
    </div>

    <h2>Your Auctions</h2>

<%
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        ApplicationDB db = new ApplicationDB();
        con = db.getConnection();

        String q =
          "SELECT A.auction_id, A.title, A.status, " +
          "       A.initial_price, A.minimum_price, A.bid_increment, " +
          "       A.start_date, A.end_datetime, A.sale_price " +
          "FROM Auction A " +
          "JOIN posts P ON A.auction_id = P.auction_id " +
          "WHERE P.seller_id = ? " +
          "ORDER BY A.start_date DESC";

        ps = con.prepareStatement(q);
        ps.setInt(1, sellerId);
        rs = ps.executeQuery();

        boolean hasAny = false;
        while (rs.next()) {
            hasAny = true;
            int auctionId   = rs.getInt("auction_id");
            String title    = rs.getString("title");
            String status   = rs.getString("status");
            double initial  = rs.getDouble("initial_price");
            double minimum  = rs.getDouble("minimum_price");
            double inc      = rs.getDouble("bid_increment");
            String start    = rs.getString("start_date");
            String end      = rs.getString("end_datetime");
            double sale     = rs.getDouble("sale_price");
            boolean hasSale = !rs.wasNull();

            String badgeClass;
            if ("active".equalsIgnoreCase(status)) badgeClass = "active";
            else if ("sold".equalsIgnoreCase(status)) badgeClass = "sold";
            else if ("closed_no_winner".equalsIgnoreCase(status)) badgeClass = "closed";
            else badgeClass = "other";
%>
    <div class="auction-box">
        <div>
            <strong>#<%= auctionId %> – <%= title %></strong>
            <span class="badge <%= badgeClass %>"><%= status %></span>
        </div>
        <div class="small">
            Initial: $<%= String.format("%.2f", initial) %> |
            Reserve: $<%= String.format("%.2f", minimum) %> |
            Increment: $<%= String.format("%.2f", inc) %>
        </div>
        <div class="small">
            Start: <%= (start != null ? start : "N/A") %> |
            End: <%= (end != null ? end : "N/A") %>
            <% if (hasSale) { %> |
                Sale price: $<%= String.format("%.2f", sale) %>
            <% } %>
        </div>

        <div class="actions" style="margin-top:8px;">
            <!-- Manage bids (accept, auto-close etc.) -->
            <form action="manageBids.jsp" method="get">
                <input type="hidden" name="auction_id" value="<%= auctionId %>">
                <button type="submit" class="btn secondary">Manage Bids</button>
            </form>

            <!-- EDIT AUCTION BUTTON (what you wanted back) -->
            <form action="editAuction.jsp" method="get">
                <input type="hidden" name="auction_id" value="<%= auctionId %>">
                <button type="submit" class="btn">Edit Auction</button>
            </form>
        </div>
    </div>
<%
        }

        if (!hasAny) {
%>
    <p class="small">You haven’t created any auctions yet.</p>
<%
        }

    } catch (Exception e) {
%>
    <p style="color:#b91c1c;">Error loading your auctions: <%= e %></p>
<%
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ignore) {}
        try { if (ps != null) ps.close(); } catch (Exception ignore) {}
        try { if (con != null) con.close(); } catch (Exception ignore) {}
    }
%>

</div>
</body>
</html>
