<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>

<%
    // Access control: only logged-in admins can see this
    Boolean isAdmin = (Boolean) session.getAttribute("isAdmin");
    if (isAdmin == null || !isAdmin) {
        response.sendRedirect("adminlogin.jsp");
        return;
    }

    // Handle logout
    if ("logout".equals(request.getParameter("action"))) {
        session.invalidate();
        response.sendRedirect("adminlogin.jsp");
        return;
    }

    String adminEmail = (String) session.getAttribute("adminEmail");
    if (adminEmail == null) {
        adminEmail = "Admin";
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Admin Dashboard</title>
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
            width: 750px;
            background: #ffffff;
            border-radius: 14px;
            box-shadow: 0 18px 45px rgba(15, 23, 42, 0.12);
            padding: 24px 26px 30px;
        }

        .topbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 18px;
            font-size: 0.9rem;
            color: #4b5563;
        }

        .brand {
            display: flex;
            flex-direction: column;
        }

        .brand-title {
            font-size: 1.1rem;
            font-weight: 700;
            color: #111827;
        }

        .brand-sub {
            font-size: 0.8rem;
            color: #6b7280;
        }

        .user-pill {
            background: #f3f4f6;
            border-radius: 999px;
            padding: 6px 12px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .user-pill b {
            font-size: 0.85rem;
            color: #111827;
        }

        .logout-btn {
            font-size: 0.8rem;
            color: #dc2626;
            text-decoration: none;
            font-weight: 500;
        }

        .logout-btn:hover {
            text-decoration: underline;
        }

        h2 {
            text-align: left;
            margin: 6px 0 4px;
            font-size: 1.4rem;
            color: #111827;
        }

        .subtitle {
            margin: 0 0 18px;
            font-size: 0.9rem;
            color: #6b7280;
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 12px 14px;
            margin-top: 10px;
        }

        a.button {
            display: block;
            padding: 11px 12px;
            background: #111827;
            color: #ffffff;
            text-decoration: none;
            border-radius: 10px;
            text-align: left;
            font-size: 0.9rem;
            font-weight: 500;
            border: 1px solid transparent;
            transition: transform 0.14s ease, box-shadow 0.14s ease, background 0.14s ease, border-color 0.14s ease;
        }

        a.button:hover {
            background: #020617;
            transform: translateY(-1px);
            box-shadow: 0 10px 20px rgba(15, 23, 42, 0.18);
            border-color: #0f172a;
        }

        .section-label {
            font-size: 0.75rem;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            color: #9ca3af;
            margin-top: 16px;
            margin-bottom: 4px;
        }

        @media (max-width: 800px) {
            .box {
                width: 92%;
                padding: 20px 18px 24px;
            }
            .grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>

<div class="box">
    <div class="topbar">
        <div class="brand">
            <span class="brand-title">BuyMe Admin</span>
            <span class="brand-sub">Dashboard & Reports</span>
        </div>
        <div class="user-pill">
            <span>Logged in as:</span>
            <b><%= adminEmail %></b>
            <span>•</span>
            <a class="logout-btn" href="adminHome.jsp?action=logout">Logout</a>
        </div>
    </div>

    <h2>Admin Dashboard</h2>
    <p class="subtitle">Use the tools below to manage representatives and view key marketplace statistics.</p>

    <div class="section-label">Management</div>
    <div class="grid">
        <a class="button" href="adminCreateRep.jsp">
            Create Customer Representative
        </a>
    </div>

    <div class="section-label">Reports</div>
    <div class="grid">
        <a class="button" href="adminReportTotalEarnings.jsp">
            Total Earnings Report
        </a>
        <a class="button" href="adminReportEarningsPerItem.jsp">
            Earnings per Item
        </a>
        <a class="button" href="adminReportEarningsPerItemType.jsp">
            Earnings per Item Type
        </a>
        <a class="button" href="adminReportEarningsPerUser.jsp">
            Earnings per End User (Seller)
        </a>
        <a class="button" href="adminReportBestItems.jsp">
            Best-selling Items
        </a>
        <a class="button" href="adminReportBestBuyers.jsp">
            Best Buyers
        </a>
    </div>
</div>

</body>
</html>
