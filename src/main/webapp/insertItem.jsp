<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         import="java.sql.*,com.cs336.pkg.*,java.math.BigDecimal" %>

<%
    String role = (String) session.getAttribute("role");
    Integer sellerId = (Integer) session.getAttribute("userId");
    if (sellerId == null || role == null || !"seller".equals(role)) {
        response.sendRedirect("home.jsp");
        return;
    }

    request.setCharacterEncoding("UTF-8");

    // ----- ITEM FIELDS -----
    String name        = request.getParameter("name");
    String description = request.getParameter("description");
    String type        = request.getParameter("type");   // dress / shoes / belt

    String size     = request.getParameter("size");
    String color    = request.getParameter("color");
    String material = request.getParameter("material");
    String widthStr = request.getParameter("width");
    String lengthStr= request.getParameter("length");

    // ----- AUCTION FIELDS -----
    String title         = request.getParameter("title");
    String initialStr    = request.getParameter("initial_price");
    String minimumStr    = request.getParameter("minimum_price");
    String incrementStr  = request.getParameter("bid_increment");
    String durationStr   = request.getParameter("duration_minutes");
    String showName      = request.getParameter("show_name");

    double initialPrice  = Double.parseDouble(initialStr);
    double minimumPrice  = Double.parseDouble(minimumStr);
    double bidIncrement  = Double.parseDouble(incrementStr);

    int durationMinutes = 60;
    try {
        durationMinutes = Integer.parseInt(durationStr);
        if (durationMinutes <= 0) durationMinutes = 60;
    } catch (Exception ignore) {}

    ApplicationDB db = null;
    Connection con = null;

    try {
        db = new ApplicationDB();
        con = db.getConnection();
        con.setAutoCommit(false);

        /* ---------------------------------------------------
           1) Insert into Item
           --------------------------------------------------- */
        PreparedStatement psItem = con.prepareStatement(
            "INSERT INTO Item (description, name) VALUES (?, ?)",
            Statement.RETURN_GENERATED_KEYS
        );
        psItem.setString(1, description);
        psItem.setString(2, name);
        psItem.executeUpdate();

        ResultSet rsItem = psItem.getGeneratedKeys();
        rsItem.next();
        int itemId = rsItem.getInt(1);
        rsItem.close();
        psItem.close();

        /* ---------------------------------------------------
           2) Insert into subtype table Dress / Shoes / Belt
           --------------------------------------------------- */
        if ("dress".equalsIgnoreCase(type)) {
            PreparedStatement psDress = con.prepareStatement(
                "INSERT INTO Dress (dress_id, size, color, material) VALUES (?, ?, ?, ?)"
            );
            psDress.setInt(1, itemId);
            psDress.setString(2, size);
            psDress.setString(3, color);
            psDress.setString(4, material);
            psDress.executeUpdate();
            psDress.close();

        } else if ("shoes".equalsIgnoreCase(type)) {
            PreparedStatement psShoes = con.prepareStatement(
                "INSERT INTO Shoes (shoe_id, size, width, material, color) VALUES (?, ?, ?, ?, ?)"
            );
            psShoes.setInt(1, itemId);
            psShoes.setString(2, size);
            psShoes.setString(3, widthStr);
            psShoes.setString(4, material);
            psShoes.setString(5, color);
            psShoes.executeUpdate();
            psShoes.close();

        } else if ("belt".equalsIgnoreCase(type)) {
            PreparedStatement psBelt = con.prepareStatement(
                "INSERT INTO Belt (belt_id, length, width, material, color) VALUES (?, ?, ?, ?, ?)"
            );
            psBelt.setInt(1, itemId);

            if (lengthStr != null && !lengthStr.isEmpty())
                psBelt.setInt(2, Integer.parseInt(lengthStr));
            else
                psBelt.setNull(2, java.sql.Types.INTEGER);

            if (widthStr != null && !widthStr.isEmpty())
                psBelt.setInt(3, Integer.parseInt(widthStr));
            else
                psBelt.setNull(3, java.sql.Types.INTEGER);

            psBelt.setString(4, material);
            psBelt.setString(5, color);
            psBelt.executeUpdate();
            psBelt.close();
        }

        /* ---------------------------------------------------
           3) Compute start & end times using duration (minutes)
           --------------------------------------------------- */
        java.util.Date nowDate = new java.util.Date();
        java.sql.Timestamp startTs = new java.sql.Timestamp(nowDate.getTime());
        long endMillis = nowDate.getTime() + durationMinutes * 60L * 1000L;
        java.sql.Timestamp endTs = new java.sql.Timestamp(endMillis);

        /* ---------------------------------------------------
           4) Insert Auction
           --------------------------------------------------- */
        PreparedStatement psAuc = con.prepareStatement(
            "INSERT INTO Auction " +
            " (title, status, initial_price, minimum_price, " +
            "  start_date, end_datetime, bid_increment) " +
            "VALUES (?, 'active', ?, ?, ?, ?, ?)",
            Statement.RETURN_GENERATED_KEYS
        );
        psAuc.setString(1, title);
        psAuc.setBigDecimal(2, new BigDecimal(initialPrice).setScale(2, BigDecimal.ROUND_HALF_UP));
        psAuc.setBigDecimal(3, new BigDecimal(minimumPrice).setScale(2, BigDecimal.ROUND_HALF_UP));
        psAuc.setTimestamp(4, startTs);
        psAuc.setTimestamp(5, endTs);
        psAuc.setBigDecimal(6, new BigDecimal(bidIncrement).setScale(2, BigDecimal.ROUND_HALF_UP));
        psAuc.executeUpdate();

        ResultSet rsAuc = psAuc.getGeneratedKeys();
        rsAuc.next();
        int auctionId = rsAuc.getInt(1);
        rsAuc.close();
        psAuc.close();

        /* ---------------------------------------------------
           5) Link Item ↔ Auction (is_in)
           --------------------------------------------------- */
        PreparedStatement psIsIn = con.prepareStatement(
            "INSERT INTO is_in (item_id, auction_id) VALUES (?, ?)"
        );
        psIsIn.setInt(1, itemId);
        psIsIn.setInt(2, auctionId);
        psIsIn.executeUpdate();
        psIsIn.close();

        /* ---------------------------------------------------
           6) Link Seller ↔ Auction with show_name flag (posts)
           --------------------------------------------------- */
        PreparedStatement psPosts = con.prepareStatement(
            "INSERT INTO posts (seller_id, show_name, auction_id) VALUES (?, ?, ?)"
        );
        psPosts.setInt(1, sellerId);
        psPosts.setString(2, ("YES".equalsIgnoreCase(showName) ? "YES" : "NO"));
        psPosts.setInt(3, auctionId);
        psPosts.executeUpdate();
        psPosts.close();

        /* ---------------------------------------------------
           7) ALERT MATCHING – notify buyers whose alerts match
           --------------------------------------------------- */

        // Normalize type to match Alert.item_type values
        String alertType = null;
        if ("dress".equalsIgnoreCase(type))      alertType = "Dress";
        else if ("shoes".equalsIgnoreCase(type)) alertType = "Shoes";
        else if ("belt".equalsIgnoreCase(type))  alertType = "Belt";

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

        // 1: item_type
        if (alertType != null)
            psAlert.setString(1, alertType);
        else
            psAlert.setNull(1, java.sql.Types.VARCHAR);

        // 2: size
        if (size != null && !size.isEmpty())
            psAlert.setString(2, size);
        else
            psAlert.setNull(2, java.sql.Types.VARCHAR);

        // 3: color
        if (color != null && !color.isEmpty())
            psAlert.setString(3, color);
        else
            psAlert.setNull(3, java.sql.Types.VARCHAR);

        // 4–5: price bounds
        psAlert.setBigDecimal(4, new BigDecimal(initialStr));
        psAlert.setBigDecimal(5, new BigDecimal(initialStr));

        // 6–8: keyword matching against title, item name, description
        String t  = (title       != null ? title       : "");
        String nm = (name        != null ? name        : "");
        String ds = (description != null ? description : "");
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

        /* ---------------------------------------------------
           commit everything
           --------------------------------------------------- */
        con.commit();
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Auction Created</title>
<meta http-equiv="refresh" content="2;URL=sellerHome.jsp" />
<style>
body{font-family:Arial;background:#f6f7fb;display:flex;justify-content:center;align-items:center;height:100vh;}
.box{background:#fff;padding:20px;border-radius:12px;box-shadow:0 0 12px rgba(0,0,0,.1);text-align:center;}
button{padding:8px 14px;border:none;border-radius:8px;background:#111827;color:#fff;cursor:pointer;}
</style>
</head>
<body>
<div class="box">
    <h2>✅ Auction Created</h2>
    <p>Your auction "<strong><%= title %></strong>" has been posted.</p>
    <p>It will run for <strong><%= durationMinutes %></strong> minutes.</p>
    <form action="sellerHome.jsp">
        <button type="submit">Back to Seller Panel</button>
    </form>
</div>
</body>
</html>

<%
    } catch (Exception e) {
        if (con != null) try { con.rollback(); } catch (Exception ignore) {}
%>
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>Error</title></head>
<body>
<p>Error creating auction: <%= e %></p>
<a href="sellerHome.jsp">Back to Seller Panel</a>
</body>
</html>
<%
    } finally {
        if (con != null) try { con.setAutoCommit(true); con.close(); } catch (Exception ignore) {}
    }
%>
