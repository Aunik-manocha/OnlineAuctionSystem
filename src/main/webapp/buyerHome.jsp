<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         import="java.sql.*,com.cs336.pkg.*,java.math.BigDecimal,java.util.*" %>

<%
    String role = (String) session.getAttribute("role");
    Integer buyerId = (Integer) session.getAttribute("userId");

    if (buyerId == null || role == null || !"buyer".equals(role)) {
        response.sendRedirect("home.jsp");
        return;
    }

    // Read filters
    String searchTitle = request.getParameter("search_title");
    if (searchTitle == null) searchTitle = "";

    // Item type filter – values: ALL / Dress / Shoes / Belt
    String typeFilter = request.getParameter("type_filter");
    if (typeFilter == null) typeFilter = "ALL";

    String sortFilter = request.getParameter("sort_filter");
    if (sortFilter == null) sortFilter = "newest";

    // Show all vs only auctions I’ve bid on
    String mineFilter = request.getParameter("mine_filter");
    if (mineFilter == null) mineFilter = "ALL";

    // Active-only toggle: YES / NO
    String activeOnly = request.getParameter("active_only");
    if (activeOnly == null) activeOnly = "NO";
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>BuyMe – Buyer Panel</title>

    <style>
        body {
            font-family: system-ui, Arial;
            background:#f6f7fb;
            margin:0;
            padding:40px 0;
        }
        .shell {
            width:1100px;
            margin:0 auto;
            display:flex;
            gap:16px;
        }
        .card {
            flex:3;
            background:#fff;
            padding:24px 28px;
            border-radius:14px;
            box-shadow:0 10px 25px rgba(0,0,0,.08);
        }
        .side {
            flex:1.5;
            display:flex;
            flex-direction:column;
            gap:12px;
        }
        .side-card {
            background:#fff;
            padding:18px 20px;
            border-radius:14px;
            box-shadow:0 10px 25px rgba(0,0,0,.06);
            font-size:14px;
        }
        .auction-box {
            border:1px solid #e5e7eb;
            padding:14px 16px;
            border-radius:12px;
            margin:12px 0;
            background:#f9fafb;
        }
        .type-badge{
            display:inline-block;
            background:#dbeafe;
            color:#1d4ed8;
            padding:2px 8px;
            border-radius:6px;
            font-size:12px;
            margin-right:6px;
        }
        .status-badge{
            display:inline-block;
            padding:2px 8px;
            border-radius:999px;
            font-size:11px;
            font-weight:600;
        }
        .status-active { background:#dcfce7; color:#166534; }
        .status-sold   { background:#dbeafe; color:#1d4ed8; }
        .status-closed { background:#fee2e2; color:#b91c1c; }

        button {
            padding:10px 14px;
            border:none;
            border-radius:10px;
            font-weight:600;
            cursor:pointer;
            background:#111827;
            color:#fff;
        }
        .danger-btn { background:#b91c1c; }
        .small { font-size:13px; color:#6b7280; }
        .pill {
            display:inline-block;
            padding:3px 10px;
            border-radius:999px;
            font-size:12px;
            background:#dbeafe;
            color:#1d4ed8;
            margin-bottom:6px;
            border:none;
        }
        .pill-mine {
            background:#fef3c7;
            color:#92400e;
        }
        .notif-item{
            font-size:13px;
            border-bottom:1px solid #e5e7eb;
            padding:6px 0;
        }
        .notif-time{
            font-size:11px;
            color:#9ca3af;
        }
        .search-row {
            display:flex;
            gap:10px;
            margin-bottom:16px;
            align-items:center;
            flex-wrap:wrap;
        }
        input[type=text], select {
            padding:8px 10px;
            border:1px solid #d1d5db;
            border-radius:8px;
            font-size:14px;
            background:#fff;
        }
        .item-details-box{
            margin-top:6px;
            padding:8px 10px;
            background:#ffffff;
            border-radius:8px;
            border:1px solid #e5e7eb;
            font-size:13px;
        }
        .item-details-box strong{
            font-weight:600;
        }
        details{
            margin-top:8px;
            font-size:13px;
        }
        details summary{
            cursor:pointer;
            font-weight:600;
        }
        table.bid-table{
            width:100%;
            border-collapse:collapse;
            margin-top:4px;
            font-size:12px;
        }
        table.bid-table th, table.bid-table td{
            border-bottom:1px solid #e5e7eb;
            padding:4px 6px;
            text-align:left;
        }
        table.bid-table th{
            background:#f3f4f6;
        }

        .active-toggle {
            display:inline-flex;
            align-items:center;
            padding:6px 10px;
            border-radius:999px;
            border:1px solid #d1d5db;
            background:<%= "YES".equals(activeOnly) ? "#111827" : "#ffffff" %>;
            color:<%= "YES".equals(activeOnly) ? "#ffffff" : "#374151" %>;
            font-size:12px;
            cursor:pointer;
            gap:6px;
        }
        .active-toggle input {
            accent-color:#111827;
        }

        .alert-chip{
            font-size:12px;
            padding:4px 6px;
            border-radius:8px;
            background:#f3f4ff;
            margin-bottom:4px;
        }
        .alert-chip span{
            font-weight:600;
        }
    </style>
</head>

<body>
<div class="shell">

    <!-- MAIN BUYER PANEL -->
    <div class="card">

        <div style="display:flex;justify-content:space-between;align-items:center;">
            <h1>Buyer Panel</h1>
            <form action="logout.jsp" method="post" style="margin:0;">
                <button type="submit" class="danger-btn">Logout</button>
            </form>
        </div>

        <!-- TABS -->
        <div style="margin:10px 0 20px;">
            <form action="buyerHome.jsp" method="get" style="display:inline;">
                <button type="submit">Browse Auctions</button>
            </form>
            <form action="buyerBids.jsp" method="get" style="display:inline; margin-left:6px;">
                <button type="submit">My Bids</button>
            </form>
            <form action="buyerPurchases.jsp" method="get" style="display:inline; margin-left:6px;">
                <button type="submit">My Purchases</button>
            </form>
        </div>

        <!-- SEARCH / FILTER BAR -->
        <form method="get">
            <div class="search-row">
                <label>Search:</label>
                <input type="text" name="search_title" placeholder="Title contains..." value="<%= searchTitle %>">

                <label>Type:</label>
                <select name="type_filter">
                    <option value="ALL"   <%= typeFilter.equals("ALL")?"selected":"" %>>All</option>
                    <option value="Dress" <%= typeFilter.equals("Dress")?"selected":"" %>>Dress</option>
                    <option value="Shoes" <%= typeFilter.equals("Shoes")?"selected":"" %>>Shoes</option>
                    <option value="Belt"  <%= typeFilter.equals("Belt")?"selected":"" %>>Belt</option>
                </select>

                <label>Show:</label>
                <select name="mine_filter">
                    <option value="ALL"  <%= mineFilter.equals("ALL")?"selected":"" %>>All auctions</option>
                    <option value="MINE" <%= mineFilter.equals("MINE")?"selected":"" %>>Auctions I'm bidding on</option>
                </select>

                <label>Sort by:</label>
                <select name="sort_filter">
                    <option value="newest" <%= sortFilter.equals("newest")?"selected":"" %>>Newest first</option>
                    <option value="oldest" <%= sortFilter.equals("oldest")?"selected":"" %>>Oldest first</option>
                    <option value="low"    <%= sortFilter.equals("low")?"selected":"" %>>Lowest price</option>
                    <option value="high"   <%= sortFilter.equals("high")?"selected":"" %>>Highest price</option>
                </select>

                <!-- Active-only "button" -->
                <label class="active-toggle">
                    <input type="checkbox" name="active_only" value="YES"
                           <%= "YES".equals(activeOnly) ? "checked" : "" %> />
                    Active only
                </label>

                <button type="submit">Apply</button>
            </div>
        </form>

        <h3>Auctions</h3>

        <%
            Connection con = null;
            PreparedStatement ps = null, psNotif = null, psHist = null, psAlert = null;
            ResultSet rs = null, rsNotif = null, rsHist = null, rsAlert = null;

            int activeBidCount=0, purchaseCount=0, outbidCount=0, limitHitCount=0;
            List<Map<String,String>> notifications = new ArrayList<>();
            List<Map<String,Object>> alerts = new ArrayList<>();

            try {
                ApplicationDB db = new ApplicationDB();
                con = db.getConnection();

                /* ---------- Counters for sidebar ---------- */

                PreparedStatement p1 = con.prepareStatement(
                    "SELECT COUNT(*) FROM Bid B " +
                    "JOIN places PL ON B.bid_id=PL.bid_id " +
                    "WHERE PL.buyer_id=? AND B.status='active'");
                p1.setInt(1,buyerId);
                ResultSet r1 = p1.executeQuery();
                if(r1.next()) activeBidCount=r1.getInt(1);
                r1.close(); p1.close();

                PreparedStatement p2 = con.prepareStatement(
                    "SELECT COUNT(*) FROM Transaction_ WHERE buyer_id=?");
                p2.setInt(1,buyerId);
                ResultSet r2 = p2.executeQuery();
                if(r2.next()) purchaseCount=r2.getInt(1);
                r2.close(); p2.close();

                PreparedStatement p3 = con.prepareStatement(
                    "SELECT COUNT(*) FROM Bid B " +
                    "JOIN places PL ON B.bid_id=PL.bid_id " +
                    "WHERE PL.buyer_id=? AND B.status='outbid'");
                p3.setInt(1,buyerId);
                ResultSet r3 = p3.executeQuery();
                if(r3.next()) outbidCount=r3.getInt(1);
                r3.close(); p3.close();

                PreparedStatement p4 = con.prepareStatement(
                    "SELECT COUNT(*) FROM Bid B " +
                    "JOIN places PL ON B.bid_id=PL.bid_id " +
                    "WHERE PL.buyer_id=? AND B.status='outbid' " +
                    "AND B.autobid_limit IS NOT NULL");
                p4.setInt(1,buyerId);
                ResultSet r4 = p4.executeQuery();
                if(r4.next()) limitHitCount=r4.getInt(1);
                r4.close(); p4.close();

                /* ---------- Build auction query with Item + subtypes ---------- */

                StringBuilder sql = new StringBuilder();
                sql.append(
                    "SELECT A.auction_id, A.status, A.title, A.initial_price, A.bid_increment, " +
                    "A.created_at, A.end_datetime, " +
                    "U.name AS seller_name, P.show_name, " +
                    "I.name AS item_name, I.description, " +
                    "DR.dress_id, SH.shoe_id, BT.belt_id, " +
                    "COALESCE(DR.size, SH.size, NULL) AS size, " +
                    "COALESCE(DR.color, SH.color, BT.color) AS color, " +
                    "COALESCE(DR.material, SH.material, BT.material) AS material, " +
                    "BT.length AS belt_length, COALESCE(SH.width, BT.width) AS width, " +
                    "CASE " +
                    "  WHEN DR.dress_id IS NOT NULL THEN 'Dress' " +
                    "  WHEN SH.shoe_id IS NOT NULL THEN 'Shoes' " +
                    "  WHEN BT.belt_id IS NOT NULL THEN 'Belt' " +
                    "  ELSE 'Item' " +
                    "END AS item_type, " +
                    "(SELECT MAX(B.amount) " +
                    "   FROM Bid B JOIN placed_on PO ON B.bid_id=PO.bid_id " +
                    "  WHERE PO.auction_id = A.auction_id AND B.status='active') AS highest_bid, " +
                    "(SELECT COUNT(*) " +
                    "   FROM Bid B2 " +
                    "   JOIN placed_on PO2 ON B2.bid_id=PO2.bid_id " +
                    "   JOIN places PL2 ON B2.bid_id=PL2.bid_id " +
                    "  WHERE PO2.auction_id=A.auction_id " +
                    "    AND PL2.buyer_id=? ) AS my_bid_cnt " +
                    "FROM Auction A " +
                    "JOIN posts P   ON A.auction_id=P.auction_id " +
                    "JOIN Seller S  ON P.seller_id=S.user_id " +
                    "JOIN User   U  ON S.user_id=U.user_id " +
                    "JOIN is_in II  ON A.auction_id=II.auction_id " +
                    "JOIN Item  I   ON II.item_id=I.item_id " +
                    "LEFT JOIN Dress DR ON DR.dress_id = I.item_id " +
                    "LEFT JOIN Shoes SH ON SH.shoe_id = I.item_id " +
                    "LEFT JOIN Belt  BT ON BT.belt_id = I.item_id " +
                    "WHERE A.status <> 'not_available' "
                );

                List<Object> params = new ArrayList<>();
                params.add(buyerId); // for my_bid_cnt subquery

                if (!searchTitle.isEmpty()) {
                    sql.append(" AND A.title LIKE ? ");
                    params.add("%"+searchTitle+"%");
                }

                // Type filter via subtype presence
                if ("Dress".equals(typeFilter)) {
                    sql.append(" AND DR.dress_id IS NOT NULL ");
                } else if ("Shoes".equals(typeFilter)) {
                    sql.append(" AND SH.shoe_id IS NOT NULL ");
                } else if ("Belt".equals(typeFilter)) {
                    sql.append(" AND BT.belt_id IS NOT NULL ");
                }

                // Only auctions I'm bidding on?
                if ("MINE".equals(mineFilter)) {
                    sql.append(
                        " AND EXISTS ( " +
                        "   SELECT 1 FROM Bid Bm " +
                        "   JOIN placed_on POm ON Bm.bid_id = POm.bid_id " +
                        "   JOIN places PLm    ON Bm.bid_id = PLm.bid_id " +
                        "   WHERE POm.auction_id = A.auction_id " +
                        "     AND PLm.buyer_id = ? " +
                        " ) "
                    );
                    params.add(buyerId);
                }

                // Active-only toggle
                if ("YES".equals(activeOnly)) {
                    sql.append(" AND A.status = 'active' ");
                }

                // Sorting
                if ("oldest".equals(sortFilter)) {
                    sql.append(" ORDER BY A.created_at ASC");
                } else if ("low".equals(sortFilter)) {
                    sql.append(" ORDER BY A.initial_price ASC");
                } else if ("high".equals(sortFilter)) {
                    sql.append(" ORDER BY A.initial_price DESC");
                } else {
                    sql.append(" ORDER BY A.created_at DESC");
                }

                ps = con.prepareStatement(sql.toString());
                int idx = 1;
                for(Object o : params) {
                    if (o instanceof Integer) {
                        ps.setInt(idx++, (Integer)o);
                    } else {
                        ps.setString(idx++, (String)o);
                    }
                }

                rs = ps.executeQuery();
                boolean any = false;

                while (rs.next()) {
                    any = true;

                    int    auctionId     = rs.getInt("auction_id");
                    String auctionStatus = rs.getString("status");
                    String title        = rs.getString("title");
                    double initial      = rs.getDouble("initial_price");
                    double increment    = rs.getDouble("bid_increment");
                    java.sql.Timestamp endTs = rs.getTimestamp("end_datetime");

                    String itemName    = rs.getString("item_name");
                    String itemDesc    = rs.getString("description");
                    String itemType    = rs.getString("item_type");
                    String size        = rs.getString("size");
                    String color       = rs.getString("color");
                    String material    = rs.getString("material");
                    String beltLen     = rs.getString("belt_length");
                    String width       = rs.getString("width");

                    BigDecimal highestBD = rs.getBigDecimal("highest_bid");
                    Double highestBidObj = (highestBD != null ? highestBD.doubleValue() : null);

                    double base    = (highestBidObj != null ? highestBidObj : initial);
                    double minNext = base + increment;

                    String sellerName  = rs.getString("seller_name");
                    boolean showSeller = "YES".equals(rs.getString("show_name"));

                    int myBidCnt = rs.getInt("my_bid_cnt");

                    // time remaining
                    boolean endedByTime = false;
                    String timeLeft = "";
                    if (endTs != null) {
                        long diff = endTs.getTime() - new java.util.Date().getTime();
                        if (diff <= 0) {
                            endedByTime = true;
                            timeLeft = "Ended";
                        } else {
                            long mins = diff / 60000;
                            long h = mins / 60;
                            long m = mins % 60;
                            timeLeft = (h > 0)
                                ? ("Ends in " + h + "h " + m + "m")
                                : ("Ends in " + m + "m");
                        }
                    }
        %>

        <div class="auction-box">
            <div style="display:flex;justify-content:space-between;align-items:center;">
                <div>
                    <span class="type-badge"><%= itemType %></span>
                    <%
                        String statusLabel = auctionStatus;
                        String statusClass = "status-closed";
                        if ("active".equalsIgnoreCase(auctionStatus)) {
                            statusLabel = "Active";
                            statusClass = "status-active";
                        } else if ("sold".equalsIgnoreCase(auctionStatus)) {
                            statusLabel = "Sold";
                            statusClass = "status-sold";
                        } else if ("closed_no_winner".equalsIgnoreCase(auctionStatus) ||
                                   "reserve_not_met".equalsIgnoreCase(auctionStatus) ||
                                   "no_bids".equalsIgnoreCase(auctionStatus)) {
                            statusLabel = "Closed";
                            statusClass = "status-closed";
                        }
                    %>
                    <span class="status-badge <%= statusClass %>"><%= statusLabel %></span>
                </div>

                <% if (myBidCnt > 0) { %>
                    <span class="pill pill-mine">You have bid on this</span>
                <% } %>
            </div>

            <div class="item-details-box">
                <div><strong>Item:</strong> <%= itemName %></div>
                <% if (itemDesc != null && !itemDesc.isEmpty()) { %>
                    <div><%= itemDesc %></div>
                <% } %>
                <% if ((size != null && !size.isEmpty()) ||
                       (color != null && !color.isEmpty()) ||
                       (material != null && !material.isEmpty()) ||
                       (beltLen != null && !beltLen.isEmpty()) ||
                       (width != null && !width.isEmpty())) { %>
                    <div style="margin-top:4px;">
                        <% if (size != null && !size.isEmpty()) { %>
                            <strong>Size:</strong> <%= size %> &nbsp;
                        <% } %>
                        <% if (color != null && !color.isEmpty()) { %>
                            <strong>Color:</strong> <%= color %> &nbsp;
                        <% } %>
                        <% if (material != null && !material.isEmpty()) { %>
                            <strong>Material:</strong> <%= material %> &nbsp;
                        <% } %>
                        <% if (beltLen != null && !beltLen.isEmpty()) { %>
                            <strong>Length:</strong> <%= beltLen %> &nbsp;
                        <% } %>
                        <% if (width != null && !width.isEmpty()) { %>
                            <strong>Width:</strong> <%= width %>
                        <% } %>
                    </div>
                <% } %>
            </div>

            <div style="margin-top:8px;">
                <div><strong>ID:</strong> <%= auctionId %></div>
                <div><strong>Title:</strong> <%= title %></div>
                <div><strong>Seller:</strong> <%= showSeller ? sellerName : "Hidden" %></div>
                <div><strong>Initial Price:</strong> $<%= String.format("%.2f", initial) %></div>
                <div><strong>Current Highest:</strong>
                    <%= (highestBidObj == null)
                            ? "No bids yet"
                            : "$" + String.format("%.2f", highestBidObj) %>
                </div>
                <div><strong>Minimum Next Bid:</strong>
                    $<%= String.format("%.2f", minNext) %>
                </div>
                <div><strong>Time Remaining:</strong> <%= timeLeft %></div>
            </div>

            <%-- Only allow new bids while status is active and time not ended --%>
            <% if ("active".equalsIgnoreCase(auctionStatus) && !endedByTime) { %>
            <form action="placeBid.jsp" method="get" style="margin-top:8px;">
                <input type="hidden" name="auction_id" value="<%= auctionId %>">
                <button type="submit">Place Bid</button>
            </form>
            <% } %>

            <%-- BID HISTORY --%>
            <%
                try {
                    psHist = con.prepareStatement(
                        "SELECT B.amount, B.status, B.bid_time, U.name AS buyer_name " +
                        "FROM Bid B " +
                        "JOIN placed_on PO ON B.bid_id = PO.bid_id " +
                        "JOIN places PL    ON B.bid_id = PL.bid_id " +
                        "JOIN Buyer BYR    ON PL.buyer_id = BYR.user_id " +
                        "JOIN User  U      ON BYR.user_id = U.user_id " +
                        "WHERE PO.auction_id = ? " +
                        "ORDER BY B.bid_time ASC"
                    );
                    psHist.setInt(1, auctionId);
                    rsHist = psHist.executeQuery();

                    List<Map<String,String>> histRows = new ArrayList<>();
                    while (rsHist.next()) {
                        Map<String,String> row = new HashMap<>();
                        row.put("buyer", rsHist.getString("buyer_name"));
                        row.put("amount", String.format("%.2f", rsHist.getDouble("amount")));
                        row.put("status", rsHist.getString("status"));
                        row.put("time",   rsHist.getTimestamp("bid_time").toString());
                        histRows.add(row);
                    }
                    rsHist.close(); rsHist = null;
                    psHist.close(); psHist = null;

                    int bidCount = histRows.size();
            %>
            <details>
                <summary>Bid history (<%= bidCount %> bid<%= bidCount==1?"":"s" %>)</summary>
                <% if (bidCount == 0) { %>
                    <div class="small" style="margin-top:4px;">No bids yet.</div>
                <% } else { %>
                    <table class="bid-table">
                        <tr>
                            <th>Buyer</th>
                            <th>Amount</th>
                            <th>Status</th>
                            <th>Time</th>
                        </tr>
                        <% for (Map<String,String> row : histRows) { %>
                            <tr>
                                <td><%= row.get("buyer") %></td>
                                <td>$<%= row.get("amount") %></td>
                                <td><%= row.get("status") %></td>
                                <td><%= row.get("time") %></td>
                            </tr>
                        <% } %>
                    </table>
                <% } %>
            </details>
            <%
                } catch(Exception eHist){
            %>
                <div class="small" style="color:#b91c1c;margin-top:6px;">
                    Error loading bid history: <%= eHist.getMessage() %>
                </div>
            <%
                } finally {
                    try { if (rsHist != null) { rsHist.close(); rsHist = null; } } catch(Exception ignore){}
                    try { if (psHist != null) { psHist.close(); psHist = null; } } catch(Exception ignore){}
                }
            %>
        </div>

        <%
                } // end while

                if (!any) {
        %>
            <p class="small">No auctions match your filters.</p>
        <%
                }

                /* ---------- Notification list ---------- */
                psNotif = con.prepareStatement(
                    "SELECT message, created_at " +
                    "FROM Notification " +
                    "WHERE buyer_id=? " +
                    "ORDER BY created_at DESC " +
                    "LIMIT 10");
                psNotif.setInt(1, buyerId);
                rsNotif = psNotif.executeQuery();
                while (rsNotif.next()) {
                    Map<String,String> n = new HashMap<String,String>();
                    n.put("msg", rsNotif.getString("message"));
                    n.put("time", rsNotif.getString("created_at"));
                    notifications.add(n);
                }

                /* ---------- Alerts list ---------- */
                psAlert = con.prepareStatement(
                    "SELECT alert_id, keywords, item_type, size, color, min_price, max_price, created_at " +
                    "FROM Alert WHERE buyer_id=? ORDER BY created_at DESC"
                );
                psAlert.setInt(1, buyerId);
                rsAlert = psAlert.executeQuery();
                while (rsAlert.next()) {
                    Map<String,Object> a = new HashMap<String,Object>();
                    a.put("id", rsAlert.getInt("alert_id"));
                    a.put("keywords", rsAlert.getString("keywords"));
                    a.put("item_type", rsAlert.getString("item_type"));
                    a.put("size", rsAlert.getString("size"));
                    a.put("color", rsAlert.getString("color"));
                    a.put("min_price", rsAlert.getObject("min_price")); // may be null
                    a.put("max_price", rsAlert.getObject("max_price"));
                    a.put("created_at", rsAlert.getString("created_at"));
                    alerts.add(a);
                }

            } catch(Exception e){
        %>
            <p style="color:#b91c1c;">Error loading auctions: <%= e %></p>
        <%
            } finally {
                try { if (rs!=null) rs.close(); } catch(Exception ig){}
                try { if (ps!=null) ps.close(); } catch(Exception ig){}
                try { if (rsHist!=null) rsHist.close(); } catch(Exception ig){}
                try { if (psHist!=null) psHist.close(); } catch(Exception ig){}
                try { if (rsNotif!=null) rsNotif.close(); } catch(Exception ig){}
                try { if (psNotif!=null) psNotif.close(); } catch(Exception ig){}
                try { if (rsAlert!=null) rsAlert.close(); } catch(Exception ig){}
                try { if (psAlert!=null) psAlert.close(); } catch(Exception ig){}
                try { if (con!=null) con.close(); } catch(Exception ig){}
            }
        %>

    </div>

    <!-- RIGHT SIDEBAR -->
    <div class="side">

        <div class="side-card">
            <!-- Help + FAQ button -->
            <div style="display:flex;justify-content:space-between;align-items:center;">
                <h3 style="margin:0;">Help</h3>
                <form action="fqahome.jsp" method="get" style="margin:0;">
                    <button type="submit" style="padding:6px 10px;font-size:12px;">FAQ</button>
                </form>
            </div>

            <ul>
                <li>Use the search bar and filters to find items.</li>
                <li>Click <strong>Place Bid</strong> to bid on an auction.</li>
                <li>Your bid must follow the seller's <strong>bid increment</strong>.</li>
                <li>You can withdraw an active bid from <strong>My Bids</strong> before acceptance.</li>
                <li>Watch <strong>Time Remaining</strong> — auctions auto-close.</li>
            </ul>
        </div>

        <div class="side-card">
            <h3>Notifications</h3>

            <p><%= activeBidCount %> active bid(s)</p>
            <p><%= purchaseCount %> completed purchase(s)</p>

            <hr>

            <p><%= outbidCount %> auction(s) where <strong>you have been outbid</strong></p>
            <p><%= limitHitCount %> auto-bid(s) where <strong>your max was exceeded</strong></p>

            <hr>

            <%
                if (notifications.isEmpty()) {
            %>
                <p class="small">No notification messages yet.</p>
            <%
                } else {
            %>
                <p class="small">Recent activity:</p>
            <%
                    for (Map<String,String> n : notifications) {
            %>
                <div class="notif-item">
                    <div><%= n.get("msg") %></div>
                    <div class="notif-time"><%= n.get("time") %></div>
                </div>
            <%
                    }
                }
            %>
        </div>

        <div class="side-card">
            <div style="display:flex;justify-content:space-between;align-items:center;">
                <h3 style="margin:0;">Alerts</h3>
                <form action="createAlert.jsp" method="get" style="margin:0;">
                    <button type="submit" style="padding:6px 10px;font-size:12px;">Create</button>
                </form>
            </div>

            <hr style="margin:8px 0;">

            <%
                if (alerts.isEmpty()) {
            %>
                <p class="small">You don’t have any alerts yet.</p>
            <%
                } else {
                    for (Map<String,Object> a : alerts) {
                        Integer aId      = (Integer)a.get("id");
                        String  aKeywords= (String)a.get("keywords");
                        String  aType    = (String)a.get("item_type");
                        String  aSize    = (String)a.get("size");
                        String  aColor   = (String)a.get("color");
                        Object  minObj   = a.get("min_price");
                        Object  maxObj   = a.get("max_price");
            %>
                <div class="alert-chip">
                    <div style="display:flex;justify-content:space-between;align-items:flex-start;gap:6px;">
                        <div>
                            <span>#<%= aId %></span>
                            <% if (aKeywords != null && !aKeywords.isEmpty()) { %>
                                – "<%= aKeywords %>"
                            <% } %>
                            <br>
                            <% if (aType != null && !aType.isEmpty()) { %>
                                Type: <%= aType %>&nbsp;
                            <% } %>
                            <% if (aSize != null && !aSize.isEmpty()) { %>
                                Size: <%= aSize %>&nbsp;
                            <% } %>
                            <% if (aColor != null && !aColor.isEmpty()) { %>
                                Color: <%= aColor %>&nbsp;
                            <% } %>
                            <% if (minObj != null || maxObj != null) { %>
                                <br>
                                Price:
                                <% if (minObj != null) { %>
                                    from $<%= String.format("%.2f", ((java.math.BigDecimal)minObj).doubleValue()) %>
                                <% } %>
                                <% if (maxObj != null) { %>
                                    to $<%= String.format("%.2f", ((java.math.BigDecimal)maxObj).doubleValue()) %>
                                <% } %>
                            <% } %>
                        </div>

                        <!-- delete button -->
                        <form action="deleteAlert.jsp" method="post" style="margin:0;">
                            <input type="hidden" name="alert_id" value="<%= aId %>"/>
                            <button type="submit"
                                    style="border:none;background:#fee2e2;color:#b91c1c;border-radius:999px;
                                           font-size:11px;padding:2px 8px;cursor:pointer;">
                                delete
                            </button>
                        </form>
                    </div>
                </div>
            <%
                    }
                }
            %>
        </div>


    </div>
</div>
</body>
</html>
