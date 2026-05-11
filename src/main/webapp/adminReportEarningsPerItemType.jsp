<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" session="true"
         import="java.sql.*, java.text.DecimalFormat, java.time.LocalDate, com.cs336.pkg.ApplicationDB" %>
<!DOCTYPE html>
<html>
<head>
    <title>Earnings per Item Type</title>
    <style>
        * {
            box-sizing: border-box;
        }

        body {
            font-family: Arial, sans-serif;
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #eef2ff, #f9fafb);
        }

        .box {
            width: 850px;
            background: #ffffff;
            border-radius: 14px;
            box-shadow: 0 18px 45px rgba(15, 23, 42, 0.12);
            padding: 22px 26px 26px;
        }

        .back {
            display: inline-block;
            margin-bottom: 8px;
            font-size: 0.85rem;
            text-decoration: none;
            color: #4b5563;
        }

        .back:hover {
            text-decoration: underline;
        }

        h2 {
            text-align: left;
            margin: 0 0 4px;
            font-size: 1.4rem;
            color: #111827;
        }

        .subtitle {
            margin: 0 0 14px;
            font-size: 0.9rem;
            color: #6b7280;
        }

        .filters {
            margin-top: 10px;
            padding: 10px 12px;
            border-radius: 10px;
            background: #f3f4f6;
            display: flex;
            align-items: flex-end;
            gap: 12px;
            flex-wrap: wrap;
        }

        .filter-group {
            display: flex;
            flex-direction: column;
            font-size: 0.85rem;
            color: #374151;
        }

        label {
            margin-bottom: 3px;
        }

        input[type="date"] {
            padding: 6px 8px;
            border-radius: 8px;
            border: 1px solid #d1d5db;
            font-size: 0.85rem;
        }

        button.filter-btn {
            padding: 8px 12px;
            border-radius: 999px;
            border: none;
            background: #111827;
            color: #ffffff;
            font-size: 0.85rem;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.12s ease, box-shadow 0.12s ease, background 0.12s ease;
        }

        button.filter-btn:hover {
            background: #020617;
            transform: translateY(-1px);
            box-shadow: 0 8px 18px rgba(15, 23, 42, 0.2);
        }

        .range-note {
            margin-top: 10px;
            font-size: 0.85rem;
            color: #6b7280;
        }

        table {
            margin-top: 16px;
            border-collapse: collapse;
            width: 100%;
            font-size: 0.85rem;
        }

        th, td {
            border-bottom: 1px solid #e5e7eb;
            padding: 8px 10px;
            text-align: center;
        }

        th {
            background:#f9fafb;
            font-weight: 600;
            color:#4b5563;
            font-size: 0.78rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        .msg {
            text-align:center;
            margin-top:14px;
            font-size: 0.9rem;
        }

        .error {
            color:#dc2626;
        }

        .no-data {
            text-align:center;
            color:#6b7280;
        }
    </style>
</head>
<body>

<%
    // Only allow admin
    Boolean isAdmin = (Boolean) session.getAttribute("isAdmin");
    if (isAdmin == null || !isAdmin) {
        response.sendRedirect("adminlogin.jsp");
        return;
    }

    // Date filters
    String fromDateStr = request.getParameter("fromDate");
    String toDateStr   = request.getParameter("toDate");

    // Default: current month (1st -> today)
    if (fromDateStr == null || fromDateStr.isEmpty() ||
        toDateStr == null || toDateStr.isEmpty()) {

        LocalDate today = LocalDate.now();
        LocalDate firstOfMonth = today.withDayOfMonth(1);

        fromDateStr = firstOfMonth.toString(); // YYYY-MM-DD
        toDateStr   = today.toString();
    }

    ApplicationDB db = new ApplicationDB();
    Connection con = null;
    String errorMsg = null;

    java.util.List<String>  types         = new java.util.ArrayList<>();
    java.util.List<Integer> numItems      = new java.util.ArrayList<>();
    java.util.List<Integer> numSales      = new java.util.ArrayList<>();
    java.util.List<Double>  totalEarnings = new java.util.ArrayList<>();

    try {
        con = db.getConnection();

        if (con == null) {
            errorMsg = "Could not connect to the database.";
        } else {
            /*
                Earnings per item type within a date range.

                We derive item_type the SAME way as buyerHome.jsp:
                - Join Dress / Shoes / Belt subtype tables on i.item_id
                - Use CASE to map presence to 'Dress', 'Shoes', 'Belt', else 'Item'

                For each item_type:
                  total_earnings = SUM(t.sale_price)
                  num_items      = COUNT(DISTINCT i.item_id)
                  num_sales      = COUNT(t.transaction_id)
            */

            String sql =
                "SELECT " +
                "   CASE " +
                "     WHEN DR.dress_id IS NOT NULL THEN 'Dress' " +
                "     WHEN SH.shoe_id IS NOT NULL THEN 'Shoes' " +
                "     WHEN BT.belt_id  IS NOT NULL THEN 'Belt' " +
                "     ELSE 'Item' " +
                "   END AS item_type, " +
                "   COUNT(DISTINCT i.item_id) AS num_items, " +
                "   COUNT(t.transaction_id)   AS num_sales, " +
                "   COALESCE(SUM(t.sale_price), 0) AS total_earnings " +
                "FROM Item i " +
                "JOIN is_in ii      ON ii.item_id = i.item_id " +
                "JOIN Auction a     ON a.auction_id = ii.auction_id " +
                "JOIN Transaction_ t ON t.auction_id = a.auction_id " +
                "LEFT JOIN Dress DR ON DR.dress_id = i.item_id " +
                "LEFT JOIN Shoes SH ON SH.shoe_id = i.item_id " +
                "LEFT JOIN Belt  BT ON BT.belt_id  = i.item_id " +
                "WHERE DATE(t.transaction_time) BETWEEN ? AND ? " +
                "GROUP BY item_type " +
                "ORDER BY total_earnings DESC, item_type ASC";

            PreparedStatement ps = con.prepareStatement(sql);
            ps.setDate(1, java.sql.Date.valueOf(fromDateStr));
            ps.setDate(2, java.sql.Date.valueOf(toDateStr));

            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                types.add(rs.getString("item_type"));
                numItems.add(rs.getInt("num_items"));
                numSales.add(rs.getInt("num_sales"));
                totalEarnings.add(rs.getDouble("total_earnings"));
            }

            rs.close();
            ps.close();
        }
    } catch (SQLException e) {
        errorMsg = "SQL Error: " + e.getMessage();
        e.printStackTrace();
    } finally {
        if (con != null) {
            try { con.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    }

    DecimalFormat df = new DecimalFormat("#,##0.00");
%>

<div class="box">
    <a class="back" href="adminHome.jsp">&laquo; Back to Admin Dashboard</a>

    <h2>Earnings per Item Type</h2>
    <p class="subtitle">
        View total earnings and sales counts grouped by item type for a selected date range.
    </p>

    <!-- Date filter -->
    <form method="get" action="adminReportEarningsPerItemType.jsp">
        <div class="filters">
            <div class="filter-group">
                <label>From date</label>
                <input type="date" name="fromDate"
                       value="<%= fromDateStr %>">
            </div>
            <div class="filter-group">
                <label>To date</label>
                <input type="date" name="toDate"
                       value="<%= toDateStr %>">
            </div>
            <div class="filter-group">
                <label>&nbsp;</label>
                <button type="submit" class="filter-btn">Apply Filter</button>
            </div>
        </div>
    </form>

    <div class="range-note">
        Showing earnings per item type from <b><%= fromDateStr %></b> to <b><%= toDateStr %></b>.
        If you leave dates blank, it defaults to the current month.
    </div>

    <%
        if (errorMsg != null) {
    %>
        <p class="msg error"><%= errorMsg %></p>
    <%
        } else if (types.isEmpty()) {
    %>
        <p class="msg no-data">No earnings found for any item type in this date range.</p>
    <%
        } else {
    %>
        <table>
            <tr>
                <th>Item Type</th>
                <th>Number of Items</th>
                <th>Number of Sales</th>
                <th>Total Earnings ($)</th>
            </tr>
            <%
                for (int i = 0; i < types.size(); i++) {
            %>
            <tr>
                <td><%= types.get(i) %></td>
                <td><%= numItems.get(i) %></td>
                <td><%= numSales.get(i) %></td>
                <td><%= df.format(totalEarnings.get(i)) %></td>
            </tr>
            <%
                }
            %>
        </table>
    <%
        }
    %>
</div>

</body>
</html>
