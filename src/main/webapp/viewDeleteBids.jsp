<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.sql.*, com.cs336.pkg.ApplicationDB, java.util.*" %>
<%@ page session="true" %>

<%
    // Only allow logged-in Customer Rep
    Boolean isRep = (Boolean) session.getAttribute("isCustomerRep");
    if (isRep == null || !isRep) {
        response.sendRedirect("login.jsp");
        return;
    }

    String message = null;
    String messageColor = "green";

    // Filters
    String statusFilter  = request.getParameter("status");
    String buyerFilter   = request.getParameter("buyer_id");
    String auctionFilter = request.getParameter("auction_id");
    String minAmt        = request.getParameter("min_amount");
    String maxAmt        = request.getParameter("max_amount");
    String titleFilter   = request.getParameter("title");
    String fromDate      = request.getParameter("fromDate");
    String toDate        = request.getParameter("toDate");

    ApplicationDB db = null;
    Connection conn = null;

    try {
        db = new ApplicationDB();
        conn = db.getConnection();

        // Handle delete
        String deleteIdStr = request.getParameter("delete");
        if (deleteIdStr != null && !deleteIdStr.isEmpty()) {
            int bidId = Integer.parseInt(deleteIdStr);
            PreparedStatement psDel = conn.prepareStatement(
                "DELETE FROM Bid WHERE bid_id = ?"
            );
            psDel.setInt(1, bidId);
            int rows = psDel.executeUpdate();
            psDel.close();

            if (rows > 0) {
                message = "Bid #" + bidId + " deleted successfully.";
            } else {
                message = "Bid not found.";
                messageColor = "red";
            }
        }

    } catch (Exception e) {
        message = "Error: " + e.getMessage();
        messageColor = "red";
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>View / Delete Bids</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background:#f3f4f6;
            margin:0;
            padding:40px 0;
            display:flex;
            justify-content:center;
        }
        .shell {
            width: 1100px;
            background:white;
            padding:24px 28px;
            border-radius:12px;
            box-shadow:0 10px 25px rgba(0,0,0,0.08);
        }
        h2 { margin:0 0 10px; }
        .back-link {
            float:right;
            text-decoration:none;
            color:#2563eb;
            font-size:13px;
        }
        .back-link:hover {
            text-decoration:underline;
        }
        .filter-box {
            background:#f9fafb;
            padding:12px;
            border-radius:8px;
            margin-bottom:15px;
            font-size:13px;
        }
        .filter-box form {
            display:flex;
            flex-wrap:wrap;
            gap:10px;
            align-items:flex-end;
        }
        .filter-group {
            display:flex;
            flex-direction:column;
        }
        label {
            display:block;
            margin-bottom:3px;
            font-size:12px;
            color:#374151;
        }
        input, select {
            padding:6px 8px;
            border:1px solid #d1d5db;
            border-radius:6px;
            font-size:13px;
        }
        button {
            padding:7px 12px;
            border:none;
            border-radius:6px;
            cursor:pointer;
            font-size:13px;
        }
        .btn-apply { background:#111827; color:white; }
        .btn-apply:hover { background:#020617; }
        .btn-delete {
            background:#b91c1c;
            color:white;
        }
        .btn-delete:hover {
            background:#7f1d1d;
        }
        .btn-view {
            background:#2563eb;
            color:white;
            margin-top:4px;
        }
        .btn-view:hover {
            background:#1e40af;
        }
        table {
            width:100%;
            border-collapse:collapse;
            margin-top:10px;
            font-size:13px;
        }
        th, td {
            padding:8px 10px;
            border-bottom:1px solid #e5e7eb;
            text-align:left;
        }
        th {
            background:#f3f4f6;
            font-size:11px;
            text-transform:uppercase;
            letter-spacing:0.04em;
            color:#4b5563;
        }
        .msg { margin-top:10px; font-size:13px; }
        .status-pill {
            display:inline-block;
            padding:2px 8px;
            border-radius:999px;
            font-size:11px;
            font-weight:600;
        }
        .status-active  { background:#dbeafe; color:#1d4ed8; }
        .status-accepted{ background:#dcfce7; color:#166534; }
        .status-won     { background:#fef3c7; color:#92400e; }
        .status-outbid  { background:#fee2e2; color:#b91c1c; }
        details {
            font-size:12px;
        }
        details summary {
            cursor:pointer;
            color:#2563eb;
        }
    </style>

    <script>
        function confirmDelete(id) {
            return confirm("Delete bid #" + id + " ?");
        }
    </script>
</head>
<body>

<div class="shell">

    <a href="CustomerRepHome.jsp" class="back-link">&laquo; Back to Customer Rep Home</a>
    <h2>View / Delete Bids</h2>

    <% if (message != null) { %>
        <div class="msg" style="color:<%= messageColor %>;"><%= message %></div>
    <% } %>

    <!-- FILTERS -->
    <div class="filter-box">
        <form method="get">
            <div class="filter-group">
                <label>Status</label>
                <select name="status">
                    <option value="">All</option>
                    <option value="active"   <%= "active".equals(statusFilter)?"selected":"" %>>Active</option>
                    <option value="accepted" <%= "accepted".equals(statusFilter)?"selected":"" %>>Accepted</option>
                    <option value="won"      <%= "won".equals(statusFilter)?"selected":"" %>>Won</option>
                    <option value="outbid"   <%= "outbid".equals(statusFilter)?"selected":"" %>>Outbid</option>
                </select>
            </div>

            <div class="filter-group">
                <label>Buyer ID</label>
                <input type="number" name="buyer_id" value="<%= buyerFilter==null? "" : buyerFilter %>">
            </div>

            <div class="filter-group">
                <label>Auction ID</label>
                <input type="number" name="auction_id" value="<%= auctionFilter==null? "" : auctionFilter %>">
            </div>

            <div class="filter-group">
                <label>Auction title contains</label>
                <input type="text" name="title" value="<%= titleFilter==null? "" : titleFilter %>">
            </div>

            <div class="filter-group">
                <label>Min Amount</label>
                <input type="number" step="0.01" name="min_amount" value="<%= minAmt==null? "" : minAmt %>">
            </div>

            <div class="filter-group">
                <label>Max Amount</label>
                <input type="number" step="0.01" name="max_amount" value="<%= maxAmt==null? "" : maxAmt %>">
            </div>

            <div class="filter-group">
                <label>From date (bid time)</label>
                <input type="date" name="fromDate" value="<%= fromDate==null? "" : fromDate %>">
            </div>

            <div class="filter-group">
                <label>To date (bid time)</label>
                <input type="date" name="toDate" value="<%= toDate==null? "" : toDate %>">
            </div>

            <div class="filter-group">
                <label>&nbsp;</label>
                <button class="btn-apply" type="submit">Apply</button>
            </div>
        </form>
    </div>

    <!-- TABLE -->
    <table>
        <tr>
            <th>Bid ID</th>
            <th>Status</th>
            <th>Amount</th>
            <th>Buyer</th>
            <th>Auction</th>
            <th>Bid Time</th>
            <th>Actions</th>
        </tr>

        <%
            if (conn != null) {
                try {
                    StringBuilder sql = new StringBuilder(
                        "SELECT " +
                        "  B.bid_id, B.amount, B.status, B.bid_time, " +
                        "  PL.buyer_id, UB.name AS buyer_name, " +
                        "  PO.auction_id, A.title AS auction_title, A.status AS auction_status, " +
                        "  A.initial_price, A.bid_increment, A.end_datetime, " +
                        "  S.user_id AS seller_id, US.name AS seller_name, " +
                        "  I.item_id, I.name AS item_name, I.type AS item_type " +
                        "FROM Bid B " +
                        "JOIN places   PL ON B.bid_id = PL.bid_id " +
                        "JOIN Buyer    BYR ON PL.buyer_id = BYR.user_id " +
                        "JOIN User     UB  ON BYR.user_id = UB.user_id " +
                        "JOIN placed_on PO ON B.bid_id = PO.bid_id " +
                        "JOIN Auction  A  ON PO.auction_id = A.auction_id " +
                        "JOIN posts    P  ON A.auction_id = P.auction_id " +
                        "JOIN Seller   S  ON P.seller_id = S.user_id " +
                        "JOIN User     US ON S.user_id = US.user_id " +
                        "LEFT JOIN is_in II ON A.auction_id = II.auction_id " +
                        "LEFT JOIN Item  I  ON II.item_id = I.item_id " +
                        "WHERE 1=1 "
                    );

                    List<Object> params = new ArrayList<>();

                    if (statusFilter != null && !statusFilter.isEmpty()) {
                        sql.append(" AND B.status = ? ");
                        params.add(statusFilter);
                    }
                    if (buyerFilter != null && !buyerFilter.isEmpty()) {
                        sql.append(" AND PL.buyer_id = ? ");
                        params.add(Integer.parseInt(buyerFilter));
                    }
                    if (auctionFilter != null && !auctionFilter.isEmpty()) {
                        sql.append(" AND PO.auction_id = ? ");
                        params.add(Integer.parseInt(auctionFilter));
                    }
                    if (titleFilter != null && !titleFilter.isEmpty()) {
                        sql.append(" AND A.title LIKE ? ");
                        params.add("%" + titleFilter + "%");
                    }
                    if (minAmt != null && !minAmt.isEmpty()) {
                        sql.append(" AND B.amount >= ? ");
                        params.add(Double.parseDouble(minAmt));
                    }
                    if (maxAmt != null && !maxAmt.isEmpty()) {
                        sql.append(" AND B.amount <= ? ");
                        params.add(Double.parseDouble(maxAmt));
                    }
                    if (fromDate != null && !fromDate.isEmpty()) {
                        sql.append(" AND DATE(B.bid_time) >= ? ");
                        params.add(java.sql.Date.valueOf(fromDate));
                    }
                    if (toDate != null && !toDate.isEmpty()) {
                        sql.append(" AND DATE(B.bid_time) <= ? ");
                        params.add(java.sql.Date.valueOf(toDate));
                    }

                    sql.append(" ORDER BY B.bid_time DESC");

                    PreparedStatement ps = conn.prepareStatement(sql.toString());
                    int idx = 1;
                    for (Object p : params) {
                        if (p instanceof String) {
                            ps.setString(idx++, (String)p);
                        } else if (p instanceof Integer) {
                            ps.setInt(idx++, (Integer)p);
                        } else if (p instanceof Double) {
                            ps.setDouble(idx++, (Double)p);
                        } else if (p instanceof java.sql.Date) {
                            ps.setDate(idx++, (java.sql.Date)p);
                        }
                    }

                    ResultSet rs = ps.executeQuery();
                    boolean hasRows = false;

                    while (rs.next()) {
                        hasRows = true;

                        int bidId      = rs.getInt("bid_id");
                        String bStatus = rs.getString("status");
                        String statusClass = "status-active";
                        if ("accepted".equalsIgnoreCase(bStatus)) statusClass = "status-accepted";
                        else if ("won".equalsIgnoreCase(bStatus)) statusClass = "status-won";
                        else if ("outbid".equalsIgnoreCase(bStatus)) statusClass = "status-outbid";
        %>

        <tr>
            <td><%= bidId %></td>
            <td>
                <span class="status-pill <%= statusClass %>"><%= bStatus %></span>
            </td>
            <td>$<%= String.format("%.2f", rs.getDouble("amount")) %></td>
            <td>
                <%= rs.getInt("buyer_id") %><br>
                <small><%= rs.getString("buyer_name") %></small>
            </td>
            <td>
                ID: <%= rs.getInt("auction_id") %><br>
                <small><%= rs.getString("auction_title") %></small>
                <br>
                <details>
                    <summary>Details</summary>
                    <div>
                        Seller: <%= rs.getInt("seller_id") %> – <%= rs.getString("seller_name") %><br>
                        <% Integer itemId = (rs.getObject("item_id") == null ? null : rs.getInt("item_id")); %>
                        <% if (itemId == null) { %>
                            Item: <em>None linked</em><br>
                        <% } else { %>
                            Item: #<%= itemId %> – <%= rs.getString("item_name") %>
                            (<%= rs.getString("item_type") %>)<br>
                        <% } %>
                        Initial price: $<%= String.format("%.2f", rs.getDouble("initial_price")) %><br>
                        Bid increment: $<%= String.format("%.2f", rs.getDouble("bid_increment")) %><br>
                        Ends at: <%= rs.getTimestamp("end_datetime") %>
                    </div>
                </details>

                <!-- Link to auctions page focused on this auction -->
                <form method="get" action="viewDeleteAuctions.jsp" style="margin-top:4px;">
                    <input type="hidden" name="auction_id" value="<%= rs.getInt("auction_id") %>">
                    <button type="submit" class="btn-view">View Auction</button>
                </form>
            </td>
            <td><%= rs.getTimestamp("bid_time") %></td>
            <td>
                <form method="post" style="margin:0;">
                    <button class="btn-delete"
                            name="delete"
                            value="<%= bidId %>"
                            onclick="return confirmDelete(<%= bidId %>);">
                        Delete
                    </button>
                </form>
            </td>
        </tr>

        <%
                    }

                    if (!hasRows) {
        %>
        <tr>
            <td colspan="7" style="text-align:center; padding:12px;">
                No bids match the filters.
            </td>
        </tr>
        <%
                    }

                    rs.close();
                    ps.close();

                } catch (SQLException listErr) {
        %>
        <tr>
            <td colspan="7" style="color:red;">
                Error loading bids: <%= listErr.getMessage() %>
            </td>
        </tr>
        <%
                }
            }

            // Close connection
            try { if (conn != null && db != null) db.closeConnection(conn); } catch (Exception ignore) {}
        %>

    </table>

</div>

</body>
</html>
