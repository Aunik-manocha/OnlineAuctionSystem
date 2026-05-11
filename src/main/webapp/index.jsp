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
        PreparedStatement psRep = null;
        ResultSet rs = null;
        ResultSet rsRep = null;

        try {
            db = new ApplicationDB();
            con = db.getConnection();

            // 1) Check User table for valid credentials
            ps = con.prepareStatement("SELECT user_id, name FROM User WHERE email=? AND password=?");
            ps.setString(1, email);
            ps.setString(2, password);
            rs = ps.executeQuery();

            if (rs.next()) {
                int userId = rs.getInt("user_id");
                String name = rs.getString("name");

                // 2) Check if this user is a CustomerRep
                psRep = con.prepareStatement("SELECT 1 FROM CustomerRep WHERE user_id = ?");
                psRep.setInt(1, userId);
                rsRep = psRep.executeQuery();

                // Set common session attributes
                session.setAttribute("userId", userId);
                session.setAttribute("name", name);
                session.setAttribute("email", email);

                if (rsRep.next()) {
                    // User is a customer representative
                    session.setAttribute("isCustomerRep", true);
                    // Optionally also:
                    // session.setAttribute("role", "customerRep");
                    response.sendRedirect("CustomerRepHome.jsp");
                    return;
                } else {
                    // Normal user (buyer/seller flow)
                    response.sendRedirect("home.jsp");
                    return;
                }

            } else {
                error = "Invalid email or password.";
            }

        } catch (Exception e) {
            error = "Database error: " + e.getMessage();
        } finally {
            try { if (rsRep != null) rsRep.close(); } catch (Exception ignore) {}
            try { if (psRep != null) psRep.close(); } catch (Exception ignore) {}
            try { if (rs != null) rs.close(); } catch (Exception ignore) {}
            try { if (ps != null) ps.close(); } catch (Exception ignore) {}
            if (con != null && db != null) db.closeConnection(con);
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>BuyMe – Login</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      background: #f6f7fb;
    }

    /* ADMIN LOGIN BUTTON */
    .admin-btn {
      position: absolute;
      top: 20px;
      right: 20px;
      background: #2563eb;
      color: #fff;
      padding: 8px 14px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
      text-decoration: none;
      box-shadow: 0 4px 10px rgba(0,0,0,0.1);
    }
    .admin-btn:hover {
      background: #1e40af;
    }

    .card {
      background: #fff;
      padding: 28px;
      border-radius: 14px;
      box-shadow: 0 10px 25px rgba(0, 0, 0, .08);
      width: 360px;
    }
    h1 { margin: 0 0 12px; font-size: 22px; text-align:center; }
    label { display: block; margin: 10px 0 6px; font-size: 14px; }
    input {
      width: 100%;
      padding: 10px 12px;
      border: 1px solid #ddd;
      border-radius: 10px;
      font-size: 14px;
    }
    button {
      margin-top: 16px;
      width: 100%;
      padding: 10px 12px;
      border: 0;
      border-radius: 10px;
      font-weight: 600;
      cursor: pointer;
      background: #111827;
      color: #fff;
    }
    .error { color: #b91c1c; margin-top: 10px; font-size: 13px; text-align:center; }
  </style>
</head>

<body>

  <!-- ADMIN LOGIN BUTTON -->
  <a href="adminlogin.jsp" class="admin-btn">ADMIN LOGIN</a>

  <div class="card">
    <h1>Welcome to BuyMe</h1>

    <form method="post">
      <label>Email</label>
      <input name="email" type="email" value="<%= (email != null ? email : "") %>" required />

      <label>Password</label>
      <input name="password" type="password" required />

      <button type="submit">Proceed</button>

      <% if (error != null) { %>
        <div class="error"><%= error %></div>
      <% } %>
    </form>
  </div>
</body>
</html>
