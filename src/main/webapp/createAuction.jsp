<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>

<%
    String role       = (String) session.getAttribute("role");
    Integer sellerId  = (Integer) session.getAttribute("userId");
    String sellerName = (String) session.getAttribute("name");

    if (sellerId == null || role == null || !"seller".equals(role)) {
        response.sendRedirect("home.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Create Auction – Post Item</title>
    <style>
        body {
            background:#f6f7fb;
            font-family:Arial, sans-serif;
            margin:0;
            padding:40px 0;
        }
        .card {
            background:#fff;
            width:700px;
            margin:0 auto;
            padding:24px 28px;
            border-radius:14px;
            box-shadow:0 10px 25px rgba(0,0,0,.08);
        }
        h1 { margin-top:0; }
        section { margin-bottom:18px; }
        label {
            display:block;
            margin:8px 0 4px;
            font-size:14px;
        }
        input, select {
            width:100%;
            padding:8px 10px;
            border-radius:8px;
            border:1px solid #d1d5db;
            font-size:14px;
            box-sizing:border-box;
        }
        hr {
            border:none;
            border-top:1px solid #e5e7eb;
            margin:18px 0;
        }
        button {
            padding:10px 14px;
            border:none;
            border-radius:10px;
            font-weight:600;
            cursor:pointer;
            background:#111827;
            color:#fff;
        }
        .secondary {
            background:#4b5563;
        }
        .small {
            font-size:13px;
            color:#6b7280;
        }
    </style>
</head>

<body>
<div class="card">
    <h1>Create New Auction</h1>
    <p class="small">
        Seller:
        <strong><%= (sellerName != null ? sellerName : "Seller") %></strong>
    </p>

    <!-- This form goes to insertItem.jsp which will insert the item + auction -->
    <form method="post" action="insertItem.jsp">
        <!-- ITEM INFO -->
        <section>
            <h2>Item Details</h2>

            <label>Item Name</label>
            <input type="text" name="name" required>

            <label>Description</label>
            <input type="text" name="description" required>

            <label>Type</label>
            <select name="type">
                <option value="dress">Dress</option>
                <option value="shoes">Shoes</option>
                <option value="belt">Belt</option>
            </select>

            <label>Size</label>
            <input name="size" placeholder="e.g., S / 8">

            <label>Color</label>
            <input name="color" placeholder="e.g., Blue">

            <label>Material</label>
            <input name="material" placeholder="e.g., Cotton, Leather">

            <label>Width (for shoes / belt)</label>
            <input name="width" placeholder="e.g., Wide, 2.5 in">

            <label>Length (for belt)</label>
            <input name="length" placeholder="e.g., 34 in">
        </section>

        <hr>

        <!-- AUCTION INFO -->
        <section>
            <h2>Auction Details</h2>

            <label>Title</label>
            <input name="title" required>

            <label>Initial Price ($)</label>
            <input name="initial_price" type="number" step="0.01" min="0" required>

            <label>Hidden Minimum Price / Reserve ($)</label>
            <input name="minimum_price" type="number" step="0.01" min="0" required>

            <label>Bid Increment ($)</label>
            <input name="bid_increment" type="number" step="0.01" min="0.01" required>

            <label>Auction Duration (minutes)</label>
            <input name="duration_minutes" type="number" min="1" value="60" required>
            <p class="small">
                The auction will automatically close after this many minutes
                and determine a winner based on the highest bid and the reserve
                price.
            </p>

            <h3>Show Your Name to Buyers?</h3>
            <label><input type="radio" name="show_name" value="YES" checked> Yes</label>
            <label><input type="radio" name="show_name" value="NO"> No (show as “Hidden”)</label>
        </section>

        <button type="submit">Create Auction</button>
    </form>

    <form action="sellerHome.jsp" method="get" style="margin-top:12px;">
        <button type="submit" class="secondary">Back to Seller Panel</button>
    </form>
</div>
</body>
</html>
