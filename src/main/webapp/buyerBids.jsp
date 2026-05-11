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
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>My Bids</title>
<style>
body{font-family:Arial;background:#f6f7fb;margin:0;padding:40px 0;}
.card{width:900px;margin:0 auto;background:#fff;padding:24px 28px;border-radius:14px;box-shadow:0 10px 25px rgba(0,0,0,.08);}
.bid-box{border:1px solid #e5e7eb;padding:12px;border-radius:10px;margin:8px 0;background:#f9fafb;}
.small{font-size:13px;color:#6b7280;}
.status{font-weight:bold;}
button{padding:8px 12px;border:none;border-radius:8px;background:#111827;color:#fff;cursor:pointer;}
button.danger{background:#b91c1c;}
</style>
</head>
<body>
<div class="card">
    <h1>My Bids</h1>
    <form action="buyerHome.jsp" method="get" style="margin-bottom:12px;">
        <button type="submit">Back to Buyer Panel</button>
    </form>

<%
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        ApplicationDB db = new ApplicationDB();
        con = db.getConnection();

        String q =
          "SELECT B.bid_id, B.amount, B.bid_time, B.status, B.autobid_limit, " +
          "       A.auction_id, A.title, A.status AS auction_status, " +
          "       (SELECT MAX(B2.amount) " +
          "        FROM Bid B2 " +
          "        JOIN placed_on PO2 ON B2.bid_id = PO2.bid_id " +
          "        WHERE PO2.auction_id = A.auction_id AND B2.status='active') AS highest_active " +
          "FROM Bid B " +
          "JOIN placed_on PO ON B.bid_id = PO.bid_id " +
          "JOIN Auction A    ON PO.auction_id = A.auction_id " +
          "JOIN places  PL   ON B.bid_id = PL.bid_id " +
          "WHERE PL.buyer_id = ? " +
          "ORDER BY B.bid_time DESC";

        ps = con.prepareStatement(q);
        ps.setInt(1, buyerId);
        rs = ps.executeQuery();

        boolean hasAny = false;
        while (rs.next()) {
            hasAny = true;
            int bidId         = rs.getInt("bid_id");
            int auctionId     = rs.getInt("auction_id");
            String title      = rs.getString("title");
            String bidStatus  = rs.getString("status");
            String auctionStatus = rs.getString("auction_status");
            double amount     = rs.getDouble("amount");
            double highestAct = rs.getDouble("highest_active");
            boolean hasHighest = !rs.wasNull();
            Double autoLimit   = null;
            double autoTmp     = rs.getDouble("autobid_limit");
            if (!rs.wasNull()) autoLimit = autoTmp;

            String prettyStatus;
            if ("withdrawn".equalsIgnoreCase(bidStatus)) {
                prettyStatus = "Withdrawn";
            } else if ("denied".equalsIgnoreCase(bidStatus)) {
                prettyStatus = "Denied";
            } else if ("outbid".equalsIgnoreCase(bidStatus)) {
                prettyStatus = "Outbid";
            } else if ("active".equalsIgnoreCase(bidStatus) && hasHighest && Math.abs(amount - highestAct) < 1e-6) {
                prettyStatus = "Currently Winning";
            } else if ("active".equalsIgnoreCase(bidStatus)) {
                prettyStatus = "Active (not highest)";
            } else {
                prettyStatus = bidStatus;
            }
%>
    <div class="bid-box">
        <div><strong>Auction #</strong><%= auctionId %> – <%= title %></div>
        <div><strong>Your Bid:</strong> $<%= String.format("%.2f", amount) %></div>
        <div><span class="status"><%= prettyStatus %></span></div>
        <div class="small"><strong>Placed:</strong> <%= rs.getString("bid_time") %></div>
        <% if (autoLimit != null) { %>
            <div class="small"><strong>Your Autobid Limit:</strong> $<%= String.format("%.2f", autoLimit) %></div>
            <% if (hasHighest && highestAct > autoLimit) { %>
                <div class="small" style="color:#b91c1c;">
                    Someone has bid more than your autobid limit.
                </div>
            <% } %>
        <% } %>

        <% if ("active".equalsIgnoreCase(bidStatus) && "active".equalsIgnoreCase(auctionStatus)) { %>
        <form action="withdrawBid.jsp" method="post" style="margin-top:6px;">
            <input type="hidden" name="bid_id" value="<%= bidId %>">
            <button type="submit" class="danger">Withdraw Bid</button>
        </form>
        <% } %>
    </div>
<%
        }

        if (!hasAny) {
%>
    <p class="small">You haven't placed any bids yet.</p>
<%
        }

    } catch (Exception e) {
%>
    <p style="color:#b91c1c;">Error: <%= e %></p>
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
