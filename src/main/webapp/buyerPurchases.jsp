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
<title>My Purchases</title>
<style>
body{font-family:Arial;background:#f6f7fb;margin:0;padding:40px 0;}
.card{width:800px;margin:0 auto;background:#fff;padding:24px 28px;border-radius:14px;box-shadow:0 10px 25px rgba(0,0,0,.08);}
.purchase-box{border:1px solid #e5e7eb;padding:12px;border-radius:10px;margin:8px 0;background:#f9fafb;}
.small{font-size:13px;color:#6b7280;}
button{padding:8px 12px;border:none;border-radius:8px;background:#111827;color:#fff;cursor:pointer;}
</style>
</head>
<body>
<div class="card">
    <h1>My Purchases</h1>
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
          "SELECT T.transaction_id, T.transaction_time, T.sale_price, " +
          "       A.auction_id, A.title AS auction_title, " +
          "       I.name AS item_name, " +
          "       U.name AS seller_name, U.email AS seller_email " +
          "FROM Transaction_ T " +
          "JOIN Auction  A  ON T.auction_id = A.auction_id " +
          "JOIN is_in   II  ON A.auction_id = II.auction_id " +
          "JOIN Item    I   ON II.item_id   = I.item_id " +
          "JOIN Seller  S   ON T.seller_id  = S.user_id " +
          "JOIN User    U   ON S.user_id    = U.user_id " +
          "WHERE T.buyer_id = ? " +
          "ORDER BY T.transaction_time DESC";

        ps = con.prepareStatement(q);
        ps.setInt(1, buyerId);
        rs = ps.executeQuery();

        boolean hasAny = false;
        while (rs.next()) {
            hasAny = true;
            int txId      = rs.getInt("transaction_id");
            String txTime = rs.getString("transaction_time");
            double price  = rs.getDouble("sale_price");
%>
    <div class="purchase-box">
        <div><strong>Transaction #</strong><%= txId %></div>
        <div><strong>Auction:</strong> #<%= rs.getInt("auction_id") %> – <%= rs.getString("auction_title") %></div>
        <div><strong>Item:</strong> <%= rs.getString("item_name") %></div>
        <div><strong>Seller:</strong> <%= rs.getString("seller_name") %> (<%= rs.getString("seller_email") %>)</div>
        <div><strong>Sale Price:</strong> $<%= String.format("%.2f", price) %></div>
        <div class="small"><strong>Time:</strong> <%= txTime %></div>
    </div>
<%
        }

        if (!hasAny) {
%>
    <p class="small">You haven’t purchased anything yet.</p>
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
