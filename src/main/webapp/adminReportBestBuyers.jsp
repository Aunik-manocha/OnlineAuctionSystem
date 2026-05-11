<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" session="true"
         import="java.sql.*, java.text.DecimalFormat, java.time.LocalDate, com.cs336.pkg.ApplicationDB" %>
<!DOCTYPE html>
<html>
<head>
    <title>Best Buyers</title>
    <style>
        * { box-sizing: border-box; }

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
            width: 950px;
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

        .back:hover { text-decoration: underline; }

        h2 {
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

        label { margin-bottom: 3px; }

        input[type="date"],
        input[type="text"] {
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

        .error { color:#dc2626; }
        .no-data { color:#6b7280; }
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

    // Filters
    String fromDateStr = request.getParameter("fromDate");
    String toDateStr   = request.getParameter("toDate");
    String searchName  = request.getParameter("searchName");

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

    java.util.List<Integer> userIds      = new java.util.ArrayList<>();
    java.util.List<String>  names        = new java.util.ArrayList<>();
    java.util.List<String>  emails       = new java.util.ArrayList<>();
    java.util.List<Integer> numPurchases = new java.util.ArrayList<>();
    java.util.List<Double>  totalSpent   = new java.util.ArrayList<>();

    try {
        con = db.getConnection();

        if (con == null) {
            errorMsg = "Could not connect to the database.";
        } else {
            /*
               Best buyers within a date range:

               User u
               Buyer b
               Transaction_ t (buyer_id, sale_price, transaction_time)

               For each buyer:
                   total_spent   = SUM(t.sale_price)
                   num_purchases = COUNT(t.transaction_id)

               Filter:
                   DATE(t.transaction_time) BETWEEN from/to
                   AND optional u.name LIKE ? (searchName)
            */

            StringBuilder sql = new StringBuilder(
                "SELECT u.user_id, u.name, u.email, " +
                "       COUNT(t.transaction_id) AS num_purchases, " +
                "       COALESCE(SUM(t.sale_price), 0) AS total_spent " +
                "FROM User u " +
                "JOIN Buyer b ON b.user_id = u.user_id " +
                "JOIN Transaction_ t ON t.buyer_id = b.user_id " +
                "WHERE DATE(t.transaction_time) BETWEEN ? AND ? "
            );

            boolean hasSearch = (searchName != null && !searchName.trim().isEmpty());
            if (hasSearch) {
                sql.append("AND u.name LIKE ? ");
            }

            sql.append(
                "GROUP BY u.user_id, u.name, u.email " +
                "HAVING total_spent > 0 " +
                "ORDER BY total_spent DESC, num_purchases DESC, u.user_id ASC " +
                "LIMIT 10"
            );

            PreparedStatement ps = con.prepareStatement(sql.toString());
            int p = 1;
            ps.setDate(p++, java.sql.Date.valueOf(fromDateStr));
            ps.setDate(p++, java.sql.Date.valueOf(toDateStr));
            if (hasSearch) {
                ps.setString(p++, "%" + searchName.trim() + "%");
            }

            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                userIds.add(rs.getInt("user_id"));
                names.add(rs.getString("name"));
                emails.add(rs.getString("email"));
                numPurchases.add(rs.getInt("num_purchases"));
                totalSpent.add(rs.getDouble("total_spent"));
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

    <h2>Best Buyers</h2>
    <p class="subtitle">
        Top buyers ranked by total amount spent in the selected date range.
    </p>

    <!-- Filters -->
    <form method="get" action="adminReportBestBuyers.jsp">
        <div class="filters">
            <div class="filter-group">
                <label>From date</label>
                <input type="date" name="fromDate" value="<%= fromDateStr %>">
            </div>
            <div class="filter-group">
                <label>To date</label>
                <input type="date" name="toDate" value="<%= toDateStr %>">
            </div>
            <div class="filter-group" style="min-width:180px;">
                <label>Search by buyer name</label>
                <input type="text" name="searchName"
                       placeholder="e.g. Alice"
                       value="<%= (searchName != null ? searchName : "") %>">
            </div>
            <div class="filter-group">
                <label>&nbsp;</label>
                <button type="submit" class="filter-btn">Apply Filter</button>
            </div>
        </div>
    </form>

    <div class="range-note">
        Showing best buyers from <b><%= fromDateStr %></b> to <b><%= toDateStr %></b>
        <% if (searchName != null && !searchName.trim().isEmpty()) { %>
            matching name "<b><%= searchName %></b>".
        <% } else { %>
            (all buyer names).
        <% } %>
    </div>

    <%
        if (errorMsg != null) {
    %>
        <p class="msg error"><%= errorMsg %></p>
    <%
        } else if (userIds.isEmpty()) {
    %>
        <p class="msg no-data">No buyers with completed purchases in this date range.</p>
    <%
        } else {
    %>
        <table>
            <tr>
                <th>Rank</th>
                <th>Buyer User ID</th>
                <th>Name</th>
                <th>Email</th>
                <th>Number of Purchases</th>
                <th>Total Spent ($)</th>
            </tr>
            <%
                for (int i = 0; i < userIds.size(); i++) {
            %>
            <tr>
                <td><%= (i + 1) %></td>
                <td><%= userIds.get(i) %></td>
                <td><%= names.get(i) %></td>
                <td><%= emails.get(i) %></td>
                <td><%= numPurchases.get(i) %></td>
                <td><%= df.format(totalSpent.get(i)) %></td>
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
