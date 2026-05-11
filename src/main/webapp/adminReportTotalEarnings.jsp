<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" session="true"
         import="java.sql.*, java.text.DecimalFormat, java.time.LocalDate, com.cs336.pkg.ApplicationDB" %>
<!DOCTYPE html>
<html>
<head>
    <title>Total Earnings Report</title>
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
            width: 900px;
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

        .summary-grid {
            margin-top: 16px;
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 12px;
        }

        .summary-card {
            border-radius: 12px;
            padding: 12px 14px;
            background: #0f172a;
            color: #f9fafb;
        }

        .summary-card.light {
            background: #f3f4f6;
            color: #111827;
        }

        .summary-label {
            font-size: 0.75rem;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            opacity: 0.8;
        }

        .summary-value {
            margin-top: 4px;
            font-size: 1.1rem;
            font-weight: 700;
        }

        .summary-note {
            margin-top: 3px;
            font-size: 0.78rem;
            opacity: 0.8;
        }

        .table-wrapper {
            margin-top: 22px;
        }

        .table-title {
            font-size: 0.95rem;
            font-weight: 600;
            color: #111827;
            margin-bottom: 6px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.85rem;
        }

        th, td {
            border-bottom: 1px solid #e5e7eb;
            padding: 7px 6px;
            text-align: left;
        }

        th {
            background: #f9fafb;
            font-weight: 600;
            color: #4b5563;
            font-size: 0.78rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        .no-data {
            text-align: center;
            padding: 10px 0;
            color: #6b7280;
        }

        .msg {
            margin-top: 10px;
            font-size: 0.9rem;
        }

        .error {
            color: #dc2626;
        }

        @media (max-width: 950px) {
            .box {
                width: 94%;
                padding: 20px 18px 22px;
            }

            .summary-grid {
                grid-template-columns: 1fr;
            }
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

    // Get date params (YYYY-MM-DD from <input type="date">)
    String fromDateStr = request.getParameter("fromDate");
    String toDateStr   = request.getParameter("toDate");

    // Default to current month: first day -> today
    if (fromDateStr == null || fromDateStr.isEmpty() ||
        toDateStr == null || toDateStr.isEmpty()) {

        LocalDate today = LocalDate.now();
        LocalDate firstOfMonth = today.withDayOfMonth(1);

        fromDateStr = firstOfMonth.toString(); // e.g., 2025-12-01
        toDateStr   = today.toString();        // e.g., 2025-12-05
    }

    ApplicationDB db = new ApplicationDB();
    Connection con = null;
    Double totalEarnings = 0.0;
    Integer numTransactions = 0;
    String errorMsg = null;

    ResultSet rsDetails = null;
    PreparedStatement psDetails = null;

    DecimalFormat moneyFormat = new DecimalFormat("#,##0.00");

    try {
        con = db.getConnection();

        if (con == null) {
            errorMsg = "Could not connect to the database.";
        } else {
            // ===== SUMMARY: total earnings + number of transactions in date range =====
            String summarySql =
                "SELECT COALESCE(SUM(t.sale_price), 0) AS total_earnings, " +
                "       COUNT(*) AS num_txns " +
                "FROM Transaction_ t " +
                "WHERE DATE(t.transaction_time) BETWEEN ? AND ?";

            PreparedStatement psSummary = con.prepareStatement(summarySql);
            psSummary.setDate(1, java.sql.Date.valueOf(fromDateStr));
            psSummary.setDate(2, java.sql.Date.valueOf(toDateStr));

            ResultSet rsSummary = psSummary.executeQuery();
            if (rsSummary.next()) {
                totalEarnings   = rsSummary.getDouble("total_earnings");
                numTransactions = rsSummary.getInt("num_txns");
            }
            rsSummary.close();
            psSummary.close();

            // ===== DETAILS: all transactions in range =====
            String detailSql =
                "SELECT t.transaction_id, t.sale_price, t.transaction_time, " +
                "       t.buyer_id, t.seller_id, t.auction_id " +
                "FROM Transaction_ t " +
                "WHERE DATE(t.transaction_time) BETWEEN ? AND ? " +
                "ORDER BY t.transaction_time DESC";

            psDetails = con.prepareStatement(detailSql);
            psDetails.setDate(1, java.sql.Date.valueOf(fromDateStr));
            psDetails.setDate(2, java.sql.Date.valueOf(toDateStr));

            rsDetails = psDetails.executeQuery();
        }
    } catch (SQLException e) {
        errorMsg = "SQL Error: " + e.getMessage();
        e.printStackTrace();
    }
%>

<div class="box">
    <a class="back" href="adminHome.jsp">&laquo; Back to Admin Dashboard</a>

    <h2>Total Earnings Report</h2>
    <p class="subtitle">
        Filter by date range to see total earnings, number of transactions, and detailed transaction records.
    </p>

    <!-- Filter form -->
    <form method="get" action="adminReportTotalEarnings.jsp">
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

    <%
        if (errorMsg != null) {
    %>
        <div class="msg error"><%= errorMsg %></div>
    <%
        } else {
    %>

        <!-- Summary cards -->
        <div class="summary-grid">
            <div class="summary-card">
                <div class="summary-label">Total Earnings</div>
                <div class="summary-value">$ <%= moneyFormat.format(totalEarnings) %></div>
                <div class="summary-note">
                    Sum of <code>sale_price</code> in <code>Transaction_</code> for the selected range.
                </div>
            </div>

            <div class="summary-card light">
                <div class="summary-label">Number of Transactions</div>
                <div class="summary-value"><%= numTransactions %></div>
                <div class="summary-note">
                    Count of transactions between <%= fromDateStr %> and <%= toDateStr %>.
                </div>
            </div>

            <div class="summary-card light">
                <div class="summary-label">Date Range</div>
                <div class="summary-value">
                    <%= fromDateStr %> &rarr; <%= toDateStr %>
                </div>
                <div class="summary-note">
                    Defaults to the current month if no dates are selected.
                </div>
            </div>
        </div>

        <!-- Detail table -->
        <div class="table-wrapper">
            <div class="table-title">
                Transactions for <%= fromDateStr %> to <%= toDateStr %>
            </div>
            <table>
                <tr>
                    <th>Transaction ID</th>
                    <th>Auction ID</th>
                    <th>Buyer ID</th>
                    <th>Seller ID</th>
                    <th>Sale Price</th>
                    <th>Transaction Time</th>
                </tr>

                <%
                    boolean hasRows = false;
                    if (rsDetails != null) {
                        while (rsDetails.next()) {
                            hasRows = true;
                %>
                <tr>
                    <td><%= rsDetails.getInt("transaction_id") %></td>
                    <td><%= rsDetails.getInt("auction_id") %></td>
                    <td><%= rsDetails.getInt("buyer_id") %></td>
                    <td><%= rsDetails.getInt("seller_id") %></td>
                    <td>$ <%= moneyFormat.format(rsDetails.getDouble("sale_price")) %></td>
                    <td><%= rsDetails.getTimestamp("transaction_time") %></td>
                </tr>
                <%
                        }
                    }

                    if (!hasRows) {
                %>
                <tr>
                    <td colspan="6" class="no-data">
                        No transactions found for the selected date range.
                    </td>
                </tr>
                <%
                    }

                    // Close details resources
                    if (rsDetails != null) try { rsDetails.close(); } catch (SQLException ignore) {}
                    if (psDetails != null) try { psDetails.close(); } catch (SQLException ignore) {}
                %>
            </table>
        </div>
    <%
        } // end error vs success
    %>

    <%
        // Close connection
        if (con != null) {
            try { con.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    %>
</div>

</body>
</html>
