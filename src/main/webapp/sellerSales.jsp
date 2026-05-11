<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         import="java.sql.*,com.cs336.pkg.*" %>

<%
    String role = (String) session.getAttribute("role");
    Integer sellerId = (Integer) session.getAttribute("userId");
    if (sellerId == null || role == null || !"seller".equals(role)) {
        response.sendRedirect("home.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Sales History</title>
<style>
body{font-family:Arial;background:#f6f7fb;margin:0;padding:40px 0;}
.card{width:800px;margin:0 auto;background:#fff;padding:24px 28px;border-radius:14px;box-shadow:0 10px 25px rgba(0,0,0,.08);}
.sale-box{border:1px solid #e5e7eb;padding:12px;border-radius:10px;margin:8px 0;background:#f9fafb;}
.small{font-size:13px;color:#6b7280;}
button{padding:8px 12px;border:none;border-radius:8px;background:#111827;color:#fff;cursor:pointer;}
</style>
</head>
<body>
<div class="card">
    <h1>Sales History</h1>
    <form action="sellerHome.jsp" method="get" style="margin-bottom:12px;">
        <button type="submit">Back to Seller Panel</button>
    </form>

<%
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        ApplicationDB db = new ApplicationDB();
        con = db.getConnection();

        String q =
          "SELECT T.transaction_id, T.transaction_time, T.sale_price, " +
          "       A.auction_id, A.title AS auction_title, " +
          "       I.name AS item_name, " +
          "       UB.name AS buyer_name, UB.email AS buyer_email " +
          "FROM Transaction_ T " +
          "JOIN Auction  A  ON T.auction_id = A.auction_id " +
          "JOIN is_in   II  ON A.auction_id = II.auction_id " +
          "JOIN Item    I   ON II.item_id   = I.item_id " +
          "JOIN Buyer   B   ON T.buyer_id   = B.user_id " +
          "JOIN User    UB  ON B.user_id    = UB.user_id " +
          "WHERE T.seller_id = ? " +
          "ORDER BY T.transaction_time DESC";

        ps = con.prepareStatement(q);
        ps.setInt(1, sellerId);
        rs = ps.executeQuery();

        boolean hasAny = false;
        while (rs.next()) {
            hasAny = true;
            int txId      = rs.getInt("transaction_id");
            String txTime = rs.getString("transaction_time");
            double price  = rs.getDouble("sale_price");
%>
    <div class="sale-box">
        <div><strong>Transaction #</strong><%= txId %></div>
        <div><strong>Auction:</strong> #<%= rs.getInt("auction_id") %> – <%= rs.getString("auction_title") %></div>
        <div><strong>Item:</strong> <%= rs.getString("item_name") %></div>
        <div><strong>Buyer:</strong> <%= rs.getString("buyer_name") %> (<%= rs.getString("buyer_email") %>)</div>
        <div><strong>Sale Price:</strong> $<%= String.format("%.2f", price) %></div>
        <div class="small"><strong>Time:</strong> <%= txTime %></div>
    </div>
<%
        }

        if (!hasAny) {
%>
    <p class="small">You haven’t sold anything yet.</p>
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
