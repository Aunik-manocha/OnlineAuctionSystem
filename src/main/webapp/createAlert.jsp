<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         import="java.sql.*,com.cs336.pkg.*" %>

<%
    String role = (String) session.getAttribute("role");
    Integer buyerId = (Integer) session.getAttribute("userId");

    if (buyerId == null || role == null || !"buyer".equals(role)) {
        response.sendRedirect("home.jsp");
        return;
    }

    request.setCharacterEncoding("UTF-8");

    String errorMsg = null;

    // If form submitted, insert the alert
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String keywords = request.getParameter("keywords");
        String itemType = request.getParameter("item_type"); // Dress / Shoes / Belt / ANY
        String size     = request.getParameter("size");
        String color    = request.getParameter("color");
        String minStr   = request.getParameter("min_price");
        String maxStr   = request.getParameter("max_price");

        // Normalize itemType: store NULL when "ANY" is selected
        if ("ANY".equals(itemType)) {
            itemType = null;
        }

        Connection con = null;
        PreparedStatement ps = null;
        try {
            ApplicationDB db = new ApplicationDB();
            con = db.getConnection();

            String sql =
                "INSERT INTO Alert (buyer_id, keywords, item_type, size, color, min_price, max_price) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)";

            ps = con.prepareStatement(sql);
            ps.setInt(1, buyerId);
            ps.setString(2, (keywords != null && !keywords.trim().isEmpty()) ? keywords.trim() : null);

            if (itemType != null && !itemType.trim().isEmpty())
                ps.setString(3, itemType);
            else
                ps.setNull(3, java.sql.Types.VARCHAR);

            if (size != null && !size.trim().isEmpty())
                ps.setString(4, size.trim());
            else
                ps.setNull(4, java.sql.Types.VARCHAR);

            if (color != null && !color.trim().isEmpty())
                ps.setString(5, color.trim());
            else
                ps.setNull(5, java.sql.Types.VARCHAR);

            if (minStr != null && !minStr.trim().isEmpty())
                ps.setBigDecimal(6, new java.math.BigDecimal(minStr.trim()));
            else
                ps.setNull(6, java.sql.Types.DECIMAL);

            if (maxStr != null && !maxStr.trim().isEmpty())
                ps.setBigDecimal(7, new java.math.BigDecimal(maxStr.trim()));
            else
                ps.setNull(7, java.sql.Types.DECIMAL);

            ps.executeUpdate();

            // go back to buyer home after creating the alert
            response.sendRedirect("buyerHome.jsp");
            return;

        } catch (Exception e) {
            errorMsg = "Error creating alert: " + e.getMessage();
        } finally {
            try { if (ps != null) ps.close(); } catch(Exception ignore){}
            try { if (con != null) con.close(); } catch(Exception ignore){}
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Create Alert</title>
    <style>
        body {
            font-family: system-ui, Arial;
            background:#f6f7fb;
            margin:0;
            padding:40px 0;
        }
        .shell {
            width:700px;
            margin:0 auto;
        }
        .card {
            background:#fff;
            padding:24px 28px;
            border-radius:14px;
            box-shadow:0 10px 25px rgba(0,0,0,.08);
        }
        h1 {
            margin-top:0;
        }
        label {
            display:block;
            margin:10px 0 4px;
            font-size:14px;
        }
        input[type=text],
        input[type=number],
        select {
            width:100%;
            padding:8px 10px;
            border-radius:8px;
            border:1px solid #d1d5db;
            font-size:14px;
            box-sizing:border-box;
        }
        .row {
            display:flex;
            gap:12px;
        }
        .row > div {
            flex:1;
        }
        button {
            padding:10px 16px;
            border:none;
            border-radius:10px;
            font-weight:600;
            cursor:pointer;
            background:#111827;
            color:#fff;
            margin-top:16px;
        }
        .secondary {
            background:#4b5563;
        }
        .small {
            font-size:13px;
            color:#6b7280;
        }
        .error {
            color:#b91c1c;
            margin-top:8px;
            font-size:13px;
        }
    </style>
</head>

<body>
<div class="shell">
    <div class="card">
        <h1>Create Alert</h1>
        <p class="small">
            Set an alert for items you care about. When a matching auction is created,
            you’ll get a notification on your buyer dashboard.
        </p>

        <% if (errorMsg != null) { %>
            <div class="error"><%= errorMsg %></div>
        <% } %>

        <form method="post" action="createAlert.jsp">
            <label>Keywords (title / description)</label>
            <input type="text" name="keywords" placeholder="e.g., blue dress, leather belt">

            <div class="row">
                <div>
                    <label>Item Type</label>
                    <select name="item_type">
                        <option value="ANY">Any type</option>
                        <option value="Dress">Dress</option>
                        <option value="Shoes">Shoes</option>
                        <option value="Belt">Belt</option>
                    </select>
                </div>
                <div>
                    <label>Size</label>
                    <input type="text" name="size" placeholder="e.g., S, 8, 32">
                </div>
            </div>

            <label>Color</label>
            <input type="text" name="color" placeholder="e.g., blue, black">

            <div class="row">
                <div>
                    <label>Min Price ($)</label>
                    <input type="number" name="min_price" step="0.01" min="0">
                </div>
                <div>
                    <label>Max Price ($)</label>
                    <input type="number" name="max_price" step="0.01" min="0">
                </div>
            </div>

            <button type="submit">Save Alert</button>
        </form>

        <form action="buyerHome.jsp" method="get">
            <button type="submit" class="secondary">Back to Buyer Panel</button>
        </form>
    </div>
</div>
</body>
</html>
