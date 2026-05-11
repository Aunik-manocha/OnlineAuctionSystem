<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         import="java.sql.*,com.cs336.pkg.*" %>

<%
    // --- session / role check ---
    String role = (String) session.getAttribute("role");
    Integer buyerId = (Integer) session.getAttribute("userId");
    if (buyerId == null || role == null || !"buyer".equals(role)) {
        response.sendRedirect("home.jsp");
        return;
    }

    String auctionIdStr = request.getParameter("auction_id");
    if (auctionIdStr == null) {
        out.println("No auction selected.");
        return;
    }
    int auctionId = Integer.parseInt(auctionIdStr);

    ApplicationDB db = new ApplicationDB();
    Connection con = db.getConnection();

    // --- load auction info ---
    String title = null, status = null;
    double initial = 0, increment = 0, minimumPrice = 0;
    Timestamp endTime = null;
    Double highestBid = null;

    PreparedStatement ps = con.prepareStatement(
        "SELECT A.title, A.status, A.initial_price, A.bid_increment, " +
        "       A.minimum_price, A.end_datetime, " +
        "       (SELECT MAX(B.amount) " +
        "          FROM Bid B " +
        "          JOIN placed_on PO2 ON B.bid_id = PO2.bid_id " +
        "         WHERE PO2.auction_id = A.auction_id " +
        "           AND B.status='active') AS highest_bid " +
        "FROM Auction A WHERE A.auction_id = ?"
    );
    ps.setInt(1, auctionId);
    ResultSet rs = ps.executeQuery();
    if (!rs.next()) {
        out.println("Auction not found.");
        rs.close(); ps.close(); con.close();
        return;
    }
    title        = rs.getString("title");
    status       = rs.getString("status");
    initial      = rs.getDouble("initial_price");
    increment    = rs.getDouble("bid_increment");
    minimumPrice = rs.getDouble("minimum_price");
    endTime      = rs.getTimestamp("end_datetime");
    double hbTmp = rs.getDouble("highest_bid");
    if (!rs.wasNull()) highestBid = hbTmp;

    rs.close();
    ps.close();

    // if auction already closed by status, don't allow bids
    if (!"active".equalsIgnoreCase(status)) {
        con.close();
        out.println("This auction is closed for bidding.");
        return;
    }

    double base    = (highestBid != null ? highestBid : initial);
    double minNext = base + increment;

    String method   = request.getMethod();
    String error    = null;
    boolean success = false;

    if ("POST".equalsIgnoreCase(method)) {

        // Does this buyer already have an active bid on this auction?
        boolean hasActiveBid = false;
        PreparedStatement psCheck = con.prepareStatement(
            "SELECT COUNT(*) AS cnt " +
            "FROM Bid B " +
            "JOIN placed_on PO ON B.bid_id = PO.bid_id " +
            "JOIN places    PL ON B.bid_id = PL.bid_id " +
            "WHERE PL.buyer_id = ? AND PO.auction_id = ? AND B.status='active'"
        );
        psCheck.setInt(1, buyerId);
        psCheck.setInt(2, auctionId);
        ResultSet rsCheck = psCheck.executeQuery();
        if (rsCheck.next() && rsCheck.getInt("cnt") > 0) {
            hasActiveBid = true;
        }
        rsCheck.close();
        psCheck.close();

        if (hasActiveBid) {
            error = "You already have an active bid on this auction. "
                  + "Withdraw it in My Bids before bidding again.";
        } else {
            String amountStr = request.getParameter("amount");
            String autoStr   = request.getParameter("autobid_limit");

            try {
                double amount = Double.parseDouble(amountStr);
                Double autoLimit = null;
                if (autoStr != null && !autoStr.trim().isEmpty()) {
                    autoLimit = Double.parseDouble(autoStr);
                }

                if (amount < minNext) {
                    error = "Your bid must be at least $"
                          + String.format("%.2f", minNext);
                } else {
                    double diff  = amount - base;
                    double steps = diff / increment;
                    double rounded = Math.round(steps);

                    if (Math.abs(steps - rounded) > 1e-6) {
                        error = "Your bid must increase by exact increments of $"
                              + String.format("%.2f", increment)
                              + " over $"
                              + String.format("%.2f", base);
                    } else {
                        // --- Insert the buyer's bid (active) ---
                        PreparedStatement psBid = con.prepareStatement(
                            "INSERT INTO Bid (amount, autobid_limit, status, bid_time) " +
                            "VALUES (?, ?, 'active', NOW())",
                            Statement.RETURN_GENERATED_KEYS
                        );
                        psBid.setDouble(1, amount);
                        if (autoLimit == null) {
                            psBid.setNull(2, java.sql.Types.DECIMAL);
                        } else {
                            psBid.setDouble(2, autoLimit);
                        }
                        psBid.executeUpdate();

                        ResultSet rsBid = psBid.getGeneratedKeys();
                        rsBid.next();
                        int newBidId = rsBid.getInt(1);
                        rsBid.close();
                        psBid.close();

                        // link bid to buyer and auction
                        PreparedStatement psPlaces = con.prepareStatement(
                            "INSERT INTO places (bid_id, buyer_id) VALUES (?, ?)"
                        );
                        psPlaces.setInt(1, newBidId);
                        psPlaces.setInt(2, buyerId);
                        psPlaces.executeUpdate();
                        psPlaces.close();

                        PreparedStatement psPO = con.prepareStatement(
                            "INSERT INTO placed_on (bid_id, auction_id) VALUES (?, ?)"
                        );
                        psPO.setInt(1, newBidId);
                        psPO.setInt(2, auctionId);
                        psPO.executeUpdate();
                        psPO.close();

                        // ==========================
                        //  SIMPLE AUTO-BID LOGIC
                        // ==========================
                        // If some *other* buyer already had an active bid with an
                        // autobid_limit high enough to beat this new amount,
                        // automatically place a counter-bid for them.

                        int winningBidId   = newBidId;
                        int winningBuyerId = buyerId;
                        double winningAmt  = amount;

                        PreparedStatement psAuto = con.prepareStatement(
                            "SELECT B.bid_id, B.amount, B.autobid_limit, PL.buyer_id " +
                            "FROM Bid B " +
                            "JOIN placed_on PO ON B.bid_id = PO.bid_id " +
                            "JOIN places PL ON B.bid_id = PL.bid_id " +
                            "WHERE PO.auction_id = ? " +
                            "  AND B.status = 'active' " +
                            "  AND PL.buyer_id <> ? " +
                            "  AND B.autobid_limit IS NOT NULL " +
                            "ORDER BY B.autobid_limit DESC, B.bid_time ASC " +
                            "LIMIT 1"
                        );
                        psAuto.setInt(1, auctionId);
                        psAuto.setInt(2, buyerId);
                        ResultSet rsAuto = psAuto.executeQuery();

                        boolean autoWinnerLimitExceeded = false;
                        Integer autoWinnerBuyerId = null;

                        if (rsAuto.next()) {
                            int autoBidId   = rsAuto.getInt("bid_id");
                            double autoAmt  = rsAuto.getDouble("amount");
                            double autoLim  = rsAuto.getDouble("autobid_limit");
                            int autoBuyerId = rsAuto.getInt("buyer_id");

                            double minToBeat = amount + increment;

                            if (autoLim >= minToBeat) {
                                // auto-bidder can beat new bid by one increment (or up to limit)
                                double autoNewAmount = Math.min(autoLim, minToBeat);

                                // mark old auto bid and new bidder's bid as outbid
                                PreparedStatement psUpd = con.prepareStatement(
                                    "UPDATE Bid SET status='outbid' WHERE bid_id IN (?,?)"
                                );
                                psUpd.setInt(1, autoBidId);
                                psUpd.setInt(2, newBidId);
                                psUpd.executeUpdate();
                                psUpd.close();

                                // insert new auto bid
                                PreparedStatement psAutoIns = con.prepareStatement(
                                    "INSERT INTO Bid (amount, autobid_limit, status, bid_time) " +
                                    "VALUES (?, ?, 'active', NOW())",
                                    Statement.RETURN_GENERATED_KEYS
                                );
                                psAutoIns.setDouble(1, autoNewAmount);
                                psAutoIns.setDouble(2, autoLim);
                                psAutoIns.executeUpdate();
                                ResultSet rsAutoNew = psAutoIns.getGeneratedKeys();
                                rsAutoNew.next();
                                int autoNewBidId = rsAutoNew.getInt(1);
                                rsAutoNew.close();
                                psAutoIns.close();

                                // link new auto bid
                                PreparedStatement psAutoPlaces = con.prepareStatement(
                                    "INSERT INTO places (bid_id, buyer_id) VALUES (?, ?)"
                                );
                                psAutoPlaces.setInt(1, autoNewBidId);
                                psAutoPlaces.setInt(2, autoBuyerId);
                                psAutoPlaces.executeUpdate();
                                psAutoPlaces.close();

                                PreparedStatement psAutoPO = con.prepareStatement(
                                    "INSERT INTO placed_on (bid_id, auction_id) VALUES (?, ?)"
                                );
                                psAutoPO.setInt(1, autoNewBidId);
                                psAutoPO.setInt(2, auctionId);
                                psAutoPO.executeUpdate();
                                psAutoPO.close();

                                winningBidId   = autoNewBidId;
                                winningBuyerId = autoBuyerId;
                                winningAmt     = autoNewAmount;

                            } else {
                                // auto bidder cannot beat new bid -> they are outbid,
                                // and their upper limit has been exceeded.
                                PreparedStatement psUpd = con.prepareStatement(
                                    "UPDATE Bid SET status='outbid' WHERE bid_id = ?"
                                );
                                psUpd.setInt(1, autoBidId);
                                psUpd.executeUpdate();
                                psUpd.close();

                                winningBidId   = newBidId;
                                winningBuyerId = buyerId;
                                winningAmt     = amount;

                                autoWinnerLimitExceeded = true;
                                autoWinnerBuyerId = autoBuyerId;
                            }
                        } else {
                            // no previous auto-bidder, new bid is leading
                            winningBidId   = newBidId;
                            winningBuyerId = buyerId;
                            winningAmt     = amount;
                        }
                        rsAuto.close();
                        psAuto.close();

                        // Ensure *only* the highest bid is 'active'
                        PreparedStatement psOutOthers = con.prepareStatement(
                            "UPDATE Bid SET status='outbid' " +
                            "WHERE bid_id IN ( " +
                            "  SELECT b2.bid_id FROM ( " +
                            "    SELECT B.bid_id " +
                            "    FROM Bid B " +
                            "    JOIN placed_on PO ON B.bid_id = PO.bid_id " +
                            "    WHERE PO.auction_id = ? AND B.status='active' " +
                            "  ) b2 " +
                            ") AND bid_id <> ?"
                        );
                        psOutOthers.setInt(1, auctionId);
                        psOutOthers.setInt(2, winningBidId);
                        psOutOthers.executeUpdate();
                        psOutOthers.close();

                        // ==========================
                        //  NOTIFICATIONS
                        // ==========================
                        // 1) Notify ALL other bidders that a higher bid exists
                        // 2) If someone's auto-limit was exceeded, special message

                        // find current highest bid to know final winningAmt / buyer
                        PreparedStatement psWin = con.prepareStatement(
                            "SELECT B.bid_id, B.amount, PL.buyer_id " +
                            "FROM Bid B " +
                            "JOIN placed_on PO ON B.bid_id = PO.bid_id " +
                            "JOIN places PL ON B.bid_id = PL.bid_id " +
                            "WHERE PO.auction_id = ? AND B.bid_id = ?"
                        );
                        psWin.setInt(1, auctionId);
                        psWin.setInt(2, winningBidId);
                        ResultSet rsWin = psWin.executeQuery();
                        if (rsWin.next()) {
                            winningAmt     = rsWin.getDouble("amount");
                            winningBuyerId = rsWin.getInt("buyer_id");
                        }
                        rsWin.close();
                        psWin.close();

                        // notify other bidders
                        PreparedStatement psNoti = con.prepareStatement(
                            "SELECT DISTINCT PL.buyer_id, B.autobid_limit " +
                            "FROM Bid B " +
                            "JOIN placed_on PO ON B.bid_id = PO.bid_id " +
                            "JOIN places PL ON B.bid_id = PL.bid_id " +
                            "WHERE PO.auction_id = ?"
                        );
                        psNoti.setInt(1, auctionId);
                        ResultSet rsNoti = psNoti.executeQuery();
                        while (rsNoti.next()) {
                            int otherBuyer = rsNoti.getInt("buyer_id");
                            Double otherLimit = rsNoti.getObject("autobid_limit") == null
                                                ? null
                                                : rsNoti.getDouble("autobid_limit");

                            if (otherBuyer == winningBuyerId) continue; // don't notify winner here

                            String msg;
                            if (autoWinnerLimitExceeded && autoWinnerBuyerId != null
                                && otherBuyer == autoWinnerBuyerId) {
                                msg = "Your auto-bid limit on \"" + title +
                                      "\" has been exceeded by another buyer.";
                            } else {
                                msg = "A higher bid has been placed on \"" + title + "\".";
                            }

                            PreparedStatement psInsN = con.prepareStatement(
                                "INSERT INTO Notification (buyer_id, message) VALUES (?, ?)"
                            );
                            psInsN.setInt(1, otherBuyer);
                            psInsN.setString(2, msg);
                            psInsN.executeUpdate();
                            psInsN.close();
                        }
                        rsNoti.close();
                        psNoti.close();

                        success = true;
                    }
                }

            } catch (NumberFormatException e) {
                error = "Please enter valid numeric values.";
            }
        }
    }
%>

<% if (success) { %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Bid Placed</title>
    <meta http-equiv="refresh" content="2;URL=buyerHome.jsp" />
    <style>
        body{font-family:Arial;background:#f6f7fb;display:flex;justify-content:center;align-items:center;height:100vh;}
        .box{background:#fff;padding:20px;border-radius:12px;box-shadow:0 0 12px rgba(0,0,0,.1);text-align:center;}
        button{padding:8px 14px;border:none;border-radius:8px;background:#111827;color:#fff;cursor:pointer;}
    </style>
</head>
<body>
<div class="box">
    <h2>✅ Bid Placed</h2>
    <p>Your bid on "<strong><%= title %></strong>" has been recorded.</p>
    <form action="buyerHome.jsp">
        <button type="submit">Back to Auctions</button>
    </form>
</div>
</body>
</html>
<%
    con.close();
    return;
} %>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Place Bid</title>
<style>
body{font-family:Arial;background:#f6f7fb;display:flex;justify-content:center;align-items:center;height:100vh;}
.card{background:#fff;width:500px;padding:20px;border-radius:12px;box-shadow:0 0 12px rgba(0,0,0,0.1);}
input{width:100%;padding:10px;margin:8px 0;}
button{padding:10px 14px;border:none;border-radius:10px;font-weight:600;cursor:pointer;background:#111827;color:#fff;}
.error{color:#b91c1c;font-size:13px;}
.info{font-size:13px;color:#4b5563;}
</style>
</head>
<body>
<div class="card">
    <h2>Place Bid on "<%= title %>"</h2>
    <p><strong>Current Highest Bid:</strong>
        <%= (highestBid == null ? "No bids yet"
                                : "$" + String.format("%.2f", highestBid)) %></p>
    <p><strong>Minimum Allowed Bid:</strong> $<%= String.format("%.2f", minNext) %></p>
    <p><strong>Bid Increment:</strong> $<%= String.format("%.2f", increment) %></p>
    <p class="info">Reserve price is hidden but enforced when the auction closes.</p>

    <% if (error != null) { %>
        <p class="error"><%= error %></p>
    <% } %>

    <form method="post">
        <input type="hidden" name="auction_id" value="<%= auctionId %>">

        <label>Your Bid Amount</label>
        <input type="number"
               name="amount"
               step="<%= String.format("%.2f", increment) %>"
               min="<%= String.format("%.2f", minNext) %>"
               required>

        <label>Autobid Limit (optional)</label>
        <input type="number"
               name="autobid_limit"
               step="<%= String.format("%.2f", increment) %>"
               min="<%= String.format("%.2f", minNext) %>">

        <button type="submit">Submit Bid</button>
    </form>
</div>
</body>
</html>

<%
    con.close();
%>
