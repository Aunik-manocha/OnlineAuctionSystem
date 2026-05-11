<%@ page import="java.sql.*, com.cs336.pkg.*" %>

<%
String auctionIdStr = request.getParameter("auction_id");

if (auctionIdStr == null) {
    out.println("Auction ID missing.");
    return;
}

int auctionId = Integer.parseInt(auctionIdStr);

ApplicationDB db = new ApplicationDB();
Connection con = db.getConnection();

PreparedStatement ps = con.prepareStatement(
    "SELECT * FROM Auction WHERE auction_id=?"
);
ps.setInt(1, auctionId);
ResultSet rs = ps.executeQuery();

if (!rs.next()) {
    out.println("Auction not found.");
    return;
}

String title = rs.getString("title");
String status = rs.getString("status");
String initial = rs.getString("initial_price");
String minimum = rs.getString("minimum_price");
String increment = rs.getString("bid_increment");
String date = rs.getString("created_at");

rs.close();
ps.close();
con.close();
%>

<!DOCTYPE html>
<html>
<head>
<title>Edit Auction</title>
<style>
body{font-family:Arial;background:#f6f7fb;display:flex;justify-content:center;align-items:center;height:100vh;}
.card{background:#fff;width:500px;padding:20px;border-radius:12px;box-shadow:0 0 12px rgba(0,0,0,.1);}
input,select{width:100%;padding:10px;margin:8px 0;}
button{padding:10px;background:#111827;color:#fff;border:none;border-radius:8px;cursor:pointer;}
</style>
</head>

<body>
<div class="card">
<h2>Edit Auction #<%= auctionId %></h2>
<p><strong>Posted:</strong> <%= date %></p>

<form method="post" action="updateAuction.jsp">

    <input type="hidden" name="auction_id" value="<%= auctionId %>">

    <label>Title</label>
    <input name="title" value="<%= title %>" required>

    <label>Initial Price</label>
    <input name="initial_price" type="number" step="0.01" value="<%= initial %>" required>

    <label>Minimum Price</label>
    <input name="minimum_price" type="number" step="0.01" value="<%= minimum %>" required>

    <label>Bid Increment</label>
    <input name="bid_increment" type="number" step="0.01" value="<%= increment %>" required>

    <label>Status</label>
    <select name="status">
        <option value="active" <%="active".equals(status)?"selected":""%>>Active</option>
        <option value="sold" <%="sold".equals(status)?"selected":""%>>Sold</option>
        <option value="not_available" <%="not_available".equals(status)?"selected":""%>>Not Available</option>
    </select>

    <button type="submit">Save Changes</button>
</form>
</div>
</body>
</html>
