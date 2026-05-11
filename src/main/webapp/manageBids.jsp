<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         import="java.sql.*,com.cs336.pkg.*,java.util.*,java.math.*" %>

<%
    String role = (String) session.getAttribute("role");
    Integer sellerId = (Integer) session.getAttribute("userId");
    if (sellerId == null || role == null || !"seller".equals(role)) {
        response.sendRedirect("home.jsp");
        return;
    }

    String auctionIdStr = request.getParameter("auction_id");
    if (auctionIdStr == null) {
        out.println("No auction selected.");
        return;
    }
    int auctionId = Integer.parseInt(auctionIdStr);

    ApplicationDB db = null;
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    String auctionTitle = null;
    String auctionStatus = null;
    double minimumPrice = 0.0;
    Timestamp endTime = null;
    String infoMessage = null;
    String notifError = null; // to show notification problems

    try {
        db = new ApplicationDB();
        con = db.getConnection();

        // 1) Load auction basic info
        ps = con.prepareStatement(
            "SELECT title, status, minimum_price, end_datetime " +
            "FROM Auction WHERE auction_id = ?"
        );
        ps.setInt(1, auctionId);
        rs = ps.executeQuery();
        if (!rs.next()) {
            rs.close();
            ps.close();
            con.close();
            out.println("Auction not found.");
            return;
        }
        auctionTitle  = rs.getString("title");
        auctionStatus = rs.getString("status");
        minimumPrice  = rs.getDouble("minimum_price");
        endTime       = rs.getTimestamp("end_datetime");
        rs.close();
        ps.close();

        // --- list of ALL bidders on this auction (for notifications) ---
        List<Integer> bidderIds = new ArrayList<Integer>();
        PreparedStatement psAllBidders = con.prepareStatement(
            "SELECT DISTINCT PL.buyer_id " +
            "FROM Bid B " +
            "JOIN placed_on PO ON B.bid_id = PO.bid_id " +
            "JOIN places PL    ON B.bid_id = PL.bid_id " +
            "WHERE PO.auction_id = ?"
        );
        psAllBidders.setInt(1, auctionId);
        ResultSet rsAllBidders = psAllBidders.executeQuery();
        while (rsAllBidders.next()) {
            bidderIds.add(rsAllBidders.getInt("buyer_id"));
        }
        rsAllBidders.close();
        psAllBidders.close();

        // 2) If time passed AND still active, resolve winner / reserve logic
        Timestamp nowTs = new Timestamp(new java.util.Date().getTime());
        if ("active".equalsIgnoreCase(auctionStatus) &&
            endTime != null && nowTs.after(endTime)) {

            // Find highest active bid + buyer
            PreparedStatement psHigh = con.prepareStatement(
                "SELECT B.bid_id, B.amount, PL.buyer_id " +
                "FROM Bid B " +
                "JOIN placed_on PO ON B.bid_id = PO.bid_id " +
                "JOIN places PL    ON B.bid_id = PL.bid_id " +
                "WHERE PO.auction_id = ? AND B.status = 'active' " +
                "ORDER BY B.amount DESC, B.bid_time ASC LIMIT 1"
            );
            psHigh.setInt(1, auctionId);
            ResultSet rsHigh = psHigh.executeQuery();

            boolean hasActiveBid = rsHigh.next();
            Integer winningBidId = null;
            Double  winningAmt   = null;
            Integer winningBuyer = null;

            if (hasActiveBid) {
                winningBidId = rsHigh.getInt("bid_id");
                winningAmt   = rsHigh.getDouble("amount");
                winningBuyer = rsHigh.getInt("buyer_id");
            }

            rsHigh.close();
            psHigh.close();

            PreparedStatement psNotif = null;
            try {
                psNotif = con.prepareStatement(
                    "INSERT INTO Notification (buyer_id, auction_id, message, created_at) " +
                    "VALUES (?, ?, ?, NOW())"
                );
            } catch (Exception ne) {
                // if table missing or columns mismatch
                notifError = "Notification insert prep failed: " + ne.getMessage();
            }

            if (!hasActiveBid) {
                // No active bids -> closed_no_winner
                PreparedStatement psClose = con.prepareStatement(
                    "UPDATE Auction SET status = 'closed_no_winner', sale_price = NULL WHERE auction_id = ?"
                );
                psClose.setInt(1, auctionId);
                psClose.executeUpdate();
                psClose.close();

                // Mark any still-active bids as outbid
                PreparedStatement psExp = con.prepareStatement(
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
                psExp.setInt(1, auctionId);
                psExp.executeUpdate();
                psExp.close();

                auctionStatus = "closed_no_winner";
                infoMessage = "Auction closed: no active bids at end time. No winner.";

                // Notify all bidders (if we can)
                if (psNotif != null) {
                    String msg = "Auction '" + auctionTitle + "' ended. " +
                                 "No winner was selected (no active bids at closing time).";
                    for (Integer bId : bidderIds) {
                        if (bId == null) continue;
                        try {
                            psNotif.setInt(1, bId);
                            psNotif.setInt(2, auctionId);
                            psNotif.setString(3, msg);
                            psNotif.executeUpdate();
                        } catch (Exception ne2) {
                            notifError = "Notification insert (no winner) failed: " + ne2.getMessage();
                        }
                    }
                }

            } else if (winningAmt < minimumPrice) {
                // Reserve not met → closed_no_winner
                PreparedStatement psReserve = con.prepareStatement(
                    "UPDATE Auction SET status = 'closed_no_winner', sale_price = NULL " +
                    "WHERE auction_id = ?"
                );
                psReserve.setInt(1, auctionId);
                psReserve.executeUpdate();
                psReserve.close();

                // All active bids on this auction → outbid (no winner)
                PreparedStatement psOutAll = con.prepareStatement(
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
                psOutAll.setInt(1, auctionId);
                psOutAll.executeUpdate();
                psOutAll.close();

                auctionStatus = "closed_no_winner";
                infoMessage = "Auction closed: highest bid $" +
                              String.format("%.2f", winningAmt) +
                              " did NOT meet reserve $" +
                              String.format("%.2f", minimumPrice) +
                              ". No winner.";

                // Notify all bidders reserve not met
                if (psNotif != null) {
                    String msg = "Auction '" + auctionTitle + "' ended. " +
                                 "Highest bid $" + String.format("%.2f", winningAmt) +
                                 " did not meet the reserve $" + String.format("%.2f", minimumPrice) +
                                 ". No winner was selected.";
                    for (Integer bId : bidderIds) {
                        if (bId == null) continue;
                        try {
                            psNotif.setInt(1, bId);
                            psNotif.setInt(2, auctionId);
                            psNotif.setString(3, msg);
                            psNotif.executeUpdate();
                        } catch (Exception ne3) {
                            notifError = "Notification insert (reserve not met) failed: " + ne3.getMessage();
                        }
                    }
                }

            } else {
                // Reserve met → winner, create transaction, mark sold
                PreparedStatement psTx = con.prepareStatement(
                    "INSERT INTO Transaction_ " +
                    " (transaction_time, sale_price, buyer_id, seller_id, auction_id) " +
                    "VALUES (NOW(), ?, ?, ?, ?)"
                );
                psTx.setBigDecimal(1,
                    new BigDecimal(winningAmt).setScale(2, RoundingMode.HALF_UP));
                psTx.setInt(2, winningBuyer);
                psTx.setInt(3, sellerId);
                psTx.setInt(4, auctionId);
                psTx.executeUpdate();
                psTx.close();

                // Update auction as sold with final price
                PreparedStatement psSold = con.prepareStatement(
                    "UPDATE Auction SET status = 'sold', sale_price = ? " +
                    "WHERE auction_id = ?"
                );
                psSold.setBigDecimal(1,
                    new BigDecimal(winningAmt).setScale(2, RoundingMode.HALF_UP));
                psSold.setInt(2, auctionId);
                psSold.executeUpdate();
                psSold.close();

                // Winning bid → won
                PreparedStatement psWin = con.prepareStatement(
                    "UPDATE Bid SET status = 'won' WHERE bid_id = ?"
                );
                psWin.setInt(1, winningBidId);
                psWin.executeUpdate();
                psWin.close();

                // All other bids on this auction → outbid
                PreparedStatement psOutOthers = con.prepareStatement(
                    "UPDATE Bid SET status = 'outbid' " +
                    "WHERE bid_id IN ( " +
                    "  SELECT b2.bid_id FROM ( " +
                    "    SELECT B.bid_id " +
                    "    FROM Bid B " +
                    "    JOIN placed_on PO ON B.bid_id = PO.bid_id " +
                    "    WHERE PO.auction_id = ? " +
                    "      AND B.bid_id <> ? " +
                    "  ) b2 " +
                    ")"
                );
                psOutOthers.setInt(1, auctionId);
                psOutOthers.setInt(2, winningBidId);
                psOutOthers.executeUpdate();
                psOutOthers.close();

                auctionStatus = "sold";
                infoMessage = "Auction closed automatically: winner selected at $" +
                              String.format("%.2f", winningAmt) + ".";

                // --- Notifications ---
                if (psNotif != null) {
                    // Winner
                    String winMsg = "You won auction '" + auctionTitle +
                                    "' with a final bid of $" +
                                    String.format("%.2f", winningAmt) + ".";
                    try {
                        psNotif.setInt(1, winningBuyer);
                        psNotif.setInt(2, auctionId);
                        psNotif.setString(3, winMsg);
                        psNotif.executeUpdate();
                    } catch (Exception ne4) {
                        notifError = "Notification insert (winner) failed: " + ne4.getMessage();
                    }

                    // Everyone else who bid
                    String loseMsg = "Auction '" + auctionTitle + "' ended. " +
                                     "Winning bid was $" + String.format("%.2f", winningAmt) +
                                     ". You did not win.";
                    for (Integer bId : bidderIds) {
                        if (bId == null || bId.equals(winningBuyer)) continue;
                        try {
                            psNotif.setInt(1, bId);
                            psNotif.setInt(2, auctionId);
                            psNotif.setString(3, loseMsg);
                            psNotif.executeUpdate();
                        } catch (Exception ne5) {
                            notifError = "Notification insert (loser) failed: " + ne5.getMessage();
                        }
                    }
                }
            }

            if (psNotif != null) {
                try { psNotif.close(); } catch (Exception ignore) {}
            }
        }

        // 3) Load bids for display to seller
        PreparedStatement psBids = con.prepareStatement(
            "SELECT B.bid_id, B.amount, B.status, B.autobid_limit, B.bid_time, " +
            "       U.name AS buyer_name, U.email AS buyer_email " +
            "FROM Bid B " +
            "JOIN placed_on PO ON B.bid_id = PO.bid_id " +
            "JOIN places    PL ON B.bid_id = PL.bid_id " +
            "JOIN Buyer     B2 ON PL.buyer_id = B2.user_id " +
            "JOIN User      U  ON B2.user_id  = U.user_id " +
            "WHERE PO.auction_id = ? " +
            "ORDER BY B.amount DESC, B.bid_time ASC"
        );
        psBids.setInt(1, auctionId);
        ResultSet rsBids = psBids.executeQuery();
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Manage Bids – Auction #<%= auctionId %></title>
<style>
body{font-family:Arial;background:#f6f7fb;margin:0;padding:40px 0;}
.card{width:900px;margin:0 auto;background:#fff;padding:24px 28px;border-radius:14px;box-shadow:0 10px 25px rgba(0,0,0,.08);}
.badge{display:inline-block;padding:3px 10px;border-radius:999px;font-size:12px;}
.badge-sold{background:#dcfce7;color:#166534;}
.badge-reserve{background:#fee2e2;color:#b91c1c;}
.badge-active{background:#dbeafe;color:#1d4ed8;}
.badge-nobids{background:#e5e7eb;color:#374151;}
.row{border-bottom:1px solid #e5e7eb;padding:8px 0;font-size:14px;}
.head{font-weight:600;}
.small{font-size:12px;color:#6b7280;}
button{padding:8px 12px;border:none;border-radius:8px;background:#111827;color:#fff;cursor:pointer;}
</style>
</head>
<body>
<div class="card">
    <div style="display:flex;justify-content:space-between;align-items:center;">
        <h2>Auction #<%= auctionId %>: <%= auctionTitle %></h2>
        <form action="sellerHome.jsp" method="get">
            <button type="submit">Back to Seller Panel</button>
        </form>
    </div>

    <% if (notifError != null) { %>
        <p class="small" style="color:#b91c1c;">
            Notification warning: <%= notifError %>
        </p>
    <% } %>

    <p>
        Status:
        <% if ("sold".equalsIgnoreCase(auctionStatus)) { %>
            <span class="badge badge-sold">Sold</span>
        <% } else if ("closed_no_winner".equalsIgnoreCase(auctionStatus)
                   || "reserve_not_met".equalsIgnoreCase(auctionStatus)
                   || "no_bids".equalsIgnoreCase(auctionStatus)) { %>
            <span class="badge badge-reserve">Closed – No Winner</span>
        <% } else { %>
            <span class="badge badge-active"><%= auctionStatus %></span>
        <% } %>
    </p>
    <p class="small">
        Reserve (minimum) price: $<%= String.format("%.2f", minimumPrice) %><br>
        End time: <%= (endTime != null ? endTime.toString() : "Not set") %>
    </p>

    <% if (infoMessage != null) { %>
        <p class="small"><strong>Auto-close:</strong> <%= infoMessage %></p>
    <% } %>

    <h3>Bids</h3>
    <div class="row head">
        <div style="width:10%;display:inline-block;">ID</div>
        <div style="width:20%;display:inline-block;">Buyer</div>
        <div style="width:15%;display:inline-block;">Amount</div>
        <div style="width:20%;display:inline-block;">Autobid</div>
        <div style="width:15%;display:inline-block;">Status</div>
        <div style="width:20%;display:inline-block;">Time</div>
    </div>
    <%
        boolean anyBidRow = false;
        while (rsBids.next()) {
            anyBidRow = true;
    %>
    <div class="row">
        <div style="width:10%;display:inline-block;"><%= rsBids.getInt("bid_id") %></div>
        <div style="width:20%;display:inline-block;">
            <%= rsBids.getString("buyer_name") %><br>
            <span class="small"><%= rsBids.getString("buyer_email") %></span>
        </div>
        <div style="width:15%;display:inline-block;">
            $<%= String.format("%.2f", rsBids.getDouble("amount")) %>
        </div>
        <div style="width:20%;display:inline-block;">
            <%
                double autoLim = rsBids.getDouble("autobid_limit");
                if (rsBids.wasNull()) {
            %>
                <span class="small">None</span>
            <%
                } else {
            %>
                <span class="small">Auto-bid set (hidden max)</span>
            <%
                }
            %>
        </div>
        <div style="width:15%;display:inline-block;"><%= rsBids.getString("status") %></div>
        <div style="width:20%;display:inline-block;">
            <span class="small"><%= rsBids.getTimestamp("bid_time") %></span>
        </div>
    </div>
    <%
        }
        rsBids.close();
        psBids.close();

        if (!anyBidRow) {
    %>
        <p class="small">No bids placed yet.</p>
    <%
        }
    %>
</div>
</body>
</html>

<%
    } catch (Exception e) {
        out.println("Error in manageBids: " + e);
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ignore) {}
        try { if (ps != null) ps.close(); } catch (Exception ignore) {}
        try { if (con != null) con.close(); } catch (Exception ignore) {}
    }
%>
