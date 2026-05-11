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
    String sellerFilter  = request.getParameter("seller_id");
    String auctionFilter = request.getParameter("auction_id");
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
            int auctionId = Integer.parseInt(deleteIdStr);

            // If you have FK constraints with ON DELETE CASCADE, this alone may be enough.
            // Otherwise, you might need to delete from related tables first.
            PreparedStatement psDel = conn.prepareStatement(
                "DELETE FROM Auction WHERE auction_id = ?"
            );
            psDel.setInt(1, auctionId);
            int rows = psDel.executeUpdate();
            psDel.close();

            if (rows > 0) {
                message = "Auction #" + auctionId + " deleted successfully.";
            } else {
                message = "Auction not found.";
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
    <title>View / Delete Auctions</title>
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
        label {
            display:block;
            margin-bottom:3px;
            font-size:12px;
            color:#374151;
        }
        .filter-group {
            display:flex;
            flex-direction:column;
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
        .status-active { background:#dcfce7; color:#166534; }
        .status-sold   { background:#dbeafe; color:#1d4ed8; }
        .status-other  { background:#fee2e2; color:#b91c1c; }
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
            return confirm("Delete auction #" + id + " ? This may remove related data depending on constraints.");
        }
    </script>
</head>
<body>

<div class="shell">

    <a href="CustomerRepHome.jsp" class="back-link">&laquo; Back to Customer Rep Home</a>
    <h2>View / Delete Auctions</h2>

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
                    <option value="active"          <%= "active".equals(statusFilter)?"selected":"" %>>Active</option>
                    <option value="sold"            <%= "sold".equals(statusFilter)?"selected":"" %>>Sold</option>
                    <option value="closed_no_winner"<%= "closed_no_winner".equals(statusFilter)?"selected":"" %>>Closed (no winner)</option>
                    <option value="reserve_not_met" <%= "reserve_not_met".equals(statusFilter)?"selected":"" %>>Reserve not met</option>
                    <option value="no_bids"         <%= "no_bids".equals(statusFilter)?"selected":"" %>>No bids</option>
                </select>
            </div>

            <div class="filter-group">
                <label>Seller ID</label>
                <input type="number" name="seller_id" value="<%= sellerFilter==null? "": sellerFilter %>">
            </div>

            <div class="filter-group">
                <label>Auction ID</label>
                <input type="number" name="auction_id" value="<%= auctionFilter==null? "": auctionFilter %>">
            </div>

            <div class="filter-group">
                <label>Title contains</label>
                <input type="text" name="title" value="<%= titleFilter==null? "": titleFilter %>">
            </div>

            <div class="filter-group">
                <label>From date (created)</label>
                <input type="date" name="fromDate" value="<%= fromDate==null? "": fromDate %>">
            </div>

            <div class="filter-group">
                <label>To date (created)</label>
                <input type="date" name="toDate" value="<%= toDate==null? "": toDate %>">
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
            <th>Auction ID</th>
            <th>Title</th>
            <th>Status</th>
            <th>Seller</th>
            <th>Item</th>
            <th>Initial / Highest / Final ($)</th>
            <th>Buyer (if sold)</th>
            <th>Created / Ends</th>
            <th>Action</th>
        </tr>

        <%
            if (conn != null) {
                try {
                    StringBuilder sql = new StringBuilder(
                        "SELECT " +
                        "  A.auction_id, A.title, A.status, A.created_at, A.end_datetime, " +
                        "  A.initial_price, A.bid_increment, " +
                        "  S.user_id AS seller_id, U.name AS seller_name, " +
                        "  I.item_id, I.name AS item_name, I.type AS item_type, " +
                        "  (SELECT MAX(B.amount) " +
                        "     FROM Bid B " +
                        "     JOIN placed_on PO ON B.bid_id = PO.bid_id " +
                        "    WHERE PO.auction_id = A.auction_id AND B.status = 'active') AS highest_bid, " +
                        "  (SELECT T.buyer_id " +
                        "     FROM Transaction_ T " +
                        "    WHERE T.auction_id = A.auction_id " +
                        "    ORDER BY T.transaction_time DESC LIMIT 1) AS buyer_id, " +
                        "  (SELECT T.sale_price " +
                        "     FROM Transaction_ T " +
                        "    WHERE T.auction_id = A.auction_id " +
                        "    ORDER BY T.transaction_time DESC LIMIT 1) AS final_price " +
                        "FROM Auction A " +
                        "JOIN posts   P ON A.auction_id = P.auction_id " +
                        "JOIN Seller  S ON P.seller_id = S.user_id " +
                        "JOIN User    U ON S.user_id = U.user_id " +
                        "LEFT JOIN is_in II ON A.auction_id = II.auction_id " +
                        "LEFT JOIN Item  I  ON II.item_id = I.item_id " +
                        "WHERE 1=1 "
                    );

                    List<Object> params = new ArrayList<>();

                    if (statusFilter != null && !statusFilter.isEmpty()) {
                        sql.append(" AND A.status = ? ");
                        params.add(statusFilter);
                    }

                    if (sellerFilter != null && !sellerFilter.isEmpty()) {
                        sql.append(" AND S.user_id = ? ");
                        params.add(Integer.parseInt(sellerFilter));
                    }

                    if (auctionFilter != null && !auctionFilter.isEmpty()) {
                        sql.append(" AND A.auction_id = ? ");
                        params.add(Integer.parseInt(auctionFilter));
                    }

                    if (titleFilter != null && !titleFilter.isEmpty()) {
                        sql.append(" AND A.title LIKE ? ");
                        params.add("%" + titleFilter + "%");
                    }

                    if (fromDate != null && !fromDate.isEmpty()) {
                        sql.append(" AND DATE(A.created_at) >= ? ");
                        params.add(java.sql.Date.valueOf(fromDate));
                    }

                    if (toDate != null && !toDate.isEmpty()) {
                        sql.append(" AND DATE(A.created_at) <= ? ");
                        params.add(java.sql.Date.valueOf(toDate));
                    }

                    sql.append(" ORDER BY A.auction_id DESC");

                    PreparedStatement ps = conn.prepareStatement(sql.toString());

                    int idx = 1;
                    for (Object p : params) {
                        if (p instanceof String) {
                            ps.setString(idx++, (String)p);
                        } else if (p instanceof Integer) {
                            ps.setInt(idx++, (Integer)p);
                        } else if (p instanceof java.sql.Date) {
                            ps.setDate(idx++, (java.sql.Date)p);
                        }
                    }

                    ResultSet rs = ps.executeQuery();
                    boolean hasRows = false;

                    while (rs.next()) {
                        hasRows = true;

                        int auctionId = rs.getInt("auction_id");
                        String status = rs.getString("status");
                        String statusClass = "status-other";
                        if ("active".equalsIgnoreCase(status)) {
                            statusClass = "status-active";
                        } else if ("sold".equalsIgnoreCase(status)) {
                            statusClass = "status-sold";
                        }

        %>
        <tr>
            <td><%= auctionId %></td>
            <td><%= rs.getString("title") %></td>
            <td>
                <span class="status-pill <%= statusClass %>">
                    <%= status %>
                </span>
            </td>
            <td>
                <%= rs.getInt("seller_id") %><br>
                <small><%= rs.getString("seller_name") %></small>
            </td>
            <td>
                <% Integer itemId = rs.getInt("item_id"); %>
                <% if (rs.wasNull()) { %>
                    <em>No item linked</em>
                <% } else { %>
                    ID: <%= itemId %><br>
                    <small><%= rs.getString("item_name") %> (<%= rs.getString("item_type") %>)</small>
                <% } %>
            </td>
            <td>
                Initial: $<%= String.format("%.2f", rs.getDouble("initial_price")) %><br>
                <% Double highest = (rs.getObject("highest_bid") == null ? null : rs.getDouble("highest_bid")); %>
                Highest: <%= highest == null ? "-" : "$" + String.format("%.2f", highest) %><br>
                <% Double finalP = (rs.getObject("final_price") == null ? null : rs.getDouble("final_price")); %>
                Final:   <%= finalP == null ? "-" : "$" + String.format("%.2f", finalP) %>
            </td>
            <td>
                <% Integer buyerId = (rs.getObject("buyer_id") == null ? null : rs.getInt("buyer_id")); %>
                <%= buyerId == null ? "<em>None</em>" : buyerId.toString() %>
            </td>
            <td>
                <small>
                    Created: <%= rs.getTimestamp("created_at") %><br>
                    Ends:    <%= rs.getTimestamp("end_datetime") %>
                </small>
            </td>
            <td>
                <form method="post" style="margin:0;">
                    <button class="btn-delete"
                            name="delete"
                            value="<%= auctionId %>"
                            onclick="return confirmDelete(<%= auctionId %>);">
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
            <td colspan="9" style="text-align:center; padding:12px;">
                No auctions match the filters.
            </td>
        </tr>
        <%
                    }

                    rs.close();
                    ps.close();

                } catch (SQLException eList) {
        %>
        <tr><td colspan="9" style="color:red;">Error loading auctions: <%= eList.getMessage() %></td></tr>
        <%
                } finally {
                    try { if (conn != null && db != null) db.closeConnection(conn); } catch (Exception ignore) {}
                }
            }
        %>

    </table>

</div>

</body>
</html>
