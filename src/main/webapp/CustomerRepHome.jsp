<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" session="true"
         import="java.sql.*, com.cs336.pkg.*" %>

<%
    // Ensure rep is logged in
    Boolean isRep = (Boolean) session.getAttribute("isCustomerRep");
    String repName = (String) session.getAttribute("name");

    if (isRep == null || !isRep) {
        response.sendRedirect("login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Customer Representative – Home</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            background: #f6f7fb;
            padding-top: 80px;
        }

        /* Top Bar */
        .top-bar {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            background: #ffffff;
            padding: 14px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            z-index: 10;
        }
        .top-bar h2 {
            margin: 0;
            font-size: 20px;
            color: #111827;
        }
        .logout-btn {
            padding: 8px 14px;
            background: #b91c1c;
            border-radius: 8px;
            color: white;
            font-size: 13px;
            border: none;
            cursor: pointer;
            font-weight: bold;
        }
        .logout-btn:hover {
            background: #7f1d1d;
        }

        /* Tools Container */
        .container {
            width: 450px;
            margin: auto;
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0px 0px 12px rgba(0,0,0,0.15);
            text-align: center;
        }

        h2 {
            margin-bottom: 20px;
        }

        a.tool-btn {
            display: block;
            background: #2563eb;
            padding: 12px;
            color: white;
            text-align: center;
            text-decoration: none;
            margin: 10px 0;
            border-radius: 6px;
            font-size: 16px;
            font-weight: 500;
            transition: 0.2s;
        }
        a.tool-btn:hover {
            background: #1e40af;
        }
    </style>
</head>

<body>

    <!-- Top Bar -->
    <div class="top-bar">
        <h2>Welcome, <%= repName %>!</h2>

        <form action="logout.jsp" method="post" style="margin:0;">
            <button class="logout-btn">Logout</button>
        </form>
    </div>

    <!-- Tools Panel -->
    <div class="container">
        <h2>Customer Rep Control Panel</h2>

        <a class="tool-btn" href="editDeleteUser.jsp">Edit / Delete Users</a>
        <a class="tool-btn" href="viewDeleteBids.jsp">View / Delete Bids</a>
        <a class="tool-btn" href="viewDeleteAuctions.jsp">View / Delete Auctions</a>
        <a class="tool-btn" href="viewAnswerQuestions.jsp">View / Answer Questions</a>
    </div>

</body>
</html>
