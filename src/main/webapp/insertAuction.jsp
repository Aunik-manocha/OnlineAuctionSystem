<%@ page import="java.sql.*, com.cs336.pkg.*" %>

<%
    int itemId   = Integer.parseInt(request.getParameter("itemId"));
    int sellerId = (Integer) session.getAttribute("userId");

    String title    = request.getParameter("title");
    String initial  = request.getParameter("initial_price");
    String minimum  = request.getParameter("minimum_price");
    String increment= request.getParameter("bid_increment");
    String showName = request.getParameter("show_name");

    ApplicationDB db = new ApplicationDB();
    Connection con   = db.getConnection();

    // ---- insert auction ----
    PreparedStatement ps = con.prepareStatement(
        "INSERT INTO Auction (title, status, initial_price, minimum_price, start_date, end_datetime, bid_increment) " +
        "VALUES (?, 'active', ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY), ?)",
        Statement.RETURN_GENERATED_KEYS
    );
    ps.setString(1, title);
    ps.setString(2, initial);
    ps.setString(3, minimum);
    ps.setString(4, increment);
    ps.executeUpdate();

    ResultSet rs = ps.getGeneratedKeys();
    rs.next();
    int auctionId = rs.getInt(1);

    // ---- link Auction → Item ----
    PreparedStatement join = con.prepareStatement("INSERT INTO is_in VALUES (?, ?)");
    join.setInt(1, auctionId);
    join.setInt(2, itemId);
    join.executeUpdate();

    // ---- link Seller → Auction ----
    PreparedStatement ps3 = con.prepareStatement(
        "INSERT INTO posts (seller_id, auction_id, show_name) VALUES (?, ?, ?)"
    );
    ps3.setInt(1, sellerId);
    ps3.setInt(2, auctionId);
    ps3.setString(3, showName);
    ps3.executeUpdate();

    /* ---------------------------------------------------
       ALERT MATCHING for auctions created this way too
       --------------------------------------------------- */

    // 1) get item details (type/size/color) from DB
    String itemName = null;
    String itemDesc = null;
    String alertType = null;
    String sizeVal = null;
    String colorVal = null;

    PreparedStatement psItem = con.prepareStatement(
        "SELECT I.name, I.description, " +
        "       DR.dress_id, SH.shoe_id, BT.belt_id, " +
        "       COALESCE(DR.size, SH.size, NULL) AS size, " +
        "       COALESCE(DR.color, SH.color, BT.color) AS color " +
        "FROM Item I " +
        "LEFT JOIN Dress DR ON DR.dress_id = I.item_id " +
        "LEFT JOIN Shoes SH ON SH.shoe_id = I.item_id " +
        "LEFT JOIN Belt  BT ON BT.belt_id  = I.item_id " +
        "WHERE I.item_id = ?"
    );
    psItem.setInt(1, itemId);
    ResultSet rsItem = psItem.executeQuery();
    if (rsItem.next()) {
        itemName = rsItem.getString("name");
        itemDesc = rsItem.getString("description");
        sizeVal  = rsItem.getString("size");
        colorVal = rsItem.getString("color");

        if (rsItem.getObject("dress_id") != null)      alertType = "Dress";
        else if (rsItem.getObject("shoe_id") != null)  alertType = "Shoes";
        else if (rsItem.getObject("belt_id") != null)  alertType = "Belt";
    }
    rsItem.close();
    psItem.close();

    // 2) run same Alert matching
    double startPrice = 0.0;
    try { startPrice = Double.parseDouble(initial); } catch(Exception ignore){}

    String sqlAlert =
        "SELECT alert_id, buyer_id, keywords " +
        "FROM Alert " +
        "WHERE (item_type IS NULL OR item_type = ?) " +
        "  AND (size IS NULL OR size = ?) " +
        "  AND (color IS NULL OR color = ?) " +
        "  AND (min_price IS NULL OR min_price <= ?) " +
        "  AND (max_price IS NULL OR max_price >= ?) " +
        "  AND (keywords IS NULL " +
        "       OR ? LIKE CONCAT('%', keywords, '%') " +
        "       OR ? LIKE CONCAT('%', keywords, '%') " +
        "       OR ? LIKE CONCAT('%', keywords, '%'))";

    PreparedStatement psAlert = con.prepareStatement(sqlAlert);

    if (alertType != null)
        psAlert.setString(1, alertType);
    else
        psAlert.setNull(1, java.sql.Types.VARCHAR);

    if (sizeVal != null && !sizeVal.isEmpty())
        psAlert.setString(2, sizeVal);
    else
        psAlert.setNull(2, java.sql.Types.VARCHAR);

    if (colorVal != null && !colorVal.isEmpty())
        psAlert.setString(3, colorVal);
    else
        psAlert.setNull(3, java.sql.Types.VARCHAR);

    psAlert.setDouble(4, startPrice);
    psAlert.setDouble(5, startPrice);

    String t  = (title    != null ? title    : "");
    String nm = (itemName != null ? itemName : "");
    String ds = (itemDesc != null ? itemDesc : "");
    psAlert.setString(6, t);
    psAlert.setString(7, nm);
    psAlert.setString(8, ds);

    ResultSet rsAlert = psAlert.executeQuery();
    while (rsAlert.next()) {
        int alertBuyer = rsAlert.getInt("buyer_id");
        String kw      = rsAlert.getString("keywords");

        String msg = "New auction \"" + title + "\" (ID " + auctionId +
                     ") matches your alert";
        if (kw != null && !kw.isEmpty()) {
            msg += " for \"" + kw + "\"";
        }
        msg += ".";

        PreparedStatement psNotif = con.prepareStatement(
            "INSERT INTO Notification (buyer_id, message, is_read) VALUES (?, ?, 0)"
        );
        psNotif.setInt(1, alertBuyer);
        psNotif.setString(2, msg);
        psNotif.executeUpdate();
        psNotif.close();
    }
    rsAlert.close();
    psAlert.close();

    // ---- clean up originals ----
    rs.close();
    ps.close();
    join.close();
    ps3.close();
    con.close();
%>

<!DOCTYPE html>
<html>
<head>
<title>Auction Created</title>
<meta http-equiv="refresh" content="2;URL=sellerHome.jsp" />
<style>
body { 
    font-family:Arial; 
    background:#f6f7fb; 
    display:flex; 
    justify-content:center; 
    align-items:center; 
    height:100vh; 
}
.box {
    background:#fff; 
    padding:25px; 
    border-radius:12px; 
    box-shadow:0 0 12px rgba(0,0,0,.1);
    text-align:center;
}
</style>
</head>

<body>
<div class="box">
    <h2>🎉 Auction Created Successfully!</h2>
    <p>Your auction "<strong><%= title %></strong>" has been posted.</p>
    <p>You will be redirected in 2 seconds...</p>

    <form action="sellerHome.jsp">
        <button style="padding:10px 15px; border:none; background:#111827; color:#fff; border-radius:8px; cursor:pointer;">
            Go Now
        </button>
    </form>
</div>
</body>
</html>
