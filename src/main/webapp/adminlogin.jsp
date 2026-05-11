<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" import="com.cs336.pkg.*" %>
<%@ page import="java.sql.*" %>

<%
    String email = request.getParameter("email");
    String password = request.getParameter("password");
    String error = null;

    if (email != null && password != null) {
        ApplicationDB db = null;
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            db = new ApplicationDB();
            con = db.getConnection();

            ps = con.prepareStatement("SELECT admin_id, name FROM Admin WHERE email = ? AND password = ?");
            ps.setString(1, email);
            ps.setString(2, password);
            rs = ps.executeQuery();

            if (rs.next()) {
                session.setAttribute("isAdmin", true);
                session.setAttribute("adminId", rs.getInt("admin_id"));
                session.setAttribute("adminName", rs.getString("name"));
                session.setAttribute("adminEmail", email);

                response.sendRedirect("adminHome.jsp");
                return;
            } else {
                error = "Invalid admin email or password.";
            }

        } catch (Exception e) {
            error = "Database error: " + e.getMessage();
        } finally {
            try { if (rs != null) rs.close(); } catch (Exception ignore) {}
            try { if (ps != null) ps.close(); } catch (Exception ignore) {}
            try { if (con != null && db != null) db.closeConnection(con); } catch (Exception ignore) {}
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Admin Login</title>
    <style>
        body { font-family: Arial; background:#f2f2f2; }
        .box {
            margin: 100px auto; width: 350px; padding: 20px;
            background: white; border-radius: 8px; box-shadow: 0 0 10px rgba(0,0,0,.2);
        }
        input { width: 95%; padding: 10px; margin-top:10px; }
        button { width: 100%; padding: 10px; margin-top: 15px; background:black; color:white; cursor:pointer; }
        button:hover { opacity:0.8; }
        h2{text-align:center;}
        .msg { text-align:center; margin-top:10px; }

        .back-btn {
            width: 100%;
            padding: 10px;
            margin-top: 10px;
            background: #ddd;
            color: #333;
            border: none;
            cursor: pointer;
            border-radius: 4px;
        }
        .back-btn:hover {
            background: #ccc;
        }
    </style>
</head>

<body>
<div class="box">
    <h2>Admin Login</h2>

    <form method="post" action="adminlogin.jsp">
        <input type="text" name="email" placeholder="Admin Email" required
               value="<%= (email != null ? email : "") %>">
        <input type="password" name="password" placeholder="Password" required>
        <button type="submit">Login</button>
    </form>

    <!-- BACK BUTTON -->
    <button class="back-btn" onclick="history.back()">⬅ Back</button>

    <% if (error != null) { %>
        <div class="msg" style="color:red;"><%= error %></div>
    <% } %>
</div>
</body>
</html>
