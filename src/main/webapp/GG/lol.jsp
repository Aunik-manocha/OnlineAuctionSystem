<%@ page import="java.sql.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%
    // --- SIMPLE LOGIN LOGIC (runs only when form submits) ---
    String email = request.getParameter("email");
    String password = request.getParameter("password");
    String error = null;

    if (email != null && password != null) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/cs336?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC",
                "cs336", "cs336pwd");

            PreparedStatement ps = conn.prepareStatement(
                "SELECT name FROM User WHERE email=? AND password=?");
            ps.setString(1, email);
            ps.setString(2, password);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                // success → remember user and go to home
                session.setAttribute("email", email);
                session.setAttribute("name", rs.getString("name"));
                rs.close(); ps.close(); conn.close();
                response.sendRedirect("home.jsp");
                return;
            } else {
                error = "Invalid email or password.";
            }

            rs.close(); ps.close(); conn.close();
        } catch (Exception e) {
            error = "Database error: " + e.getMessage();
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
  <title>Seller Club – Login</title>
  <meta charset="UTF-8">
  <style>
    body { font-family: system-ui, Arial; display:flex; align-items:center; justify-content:center; min-height:100vh; background:#f6f7fb; }
    .card { background:#fff; padding:28px; border-radius:14px; box-shadow:0 10px 25px rgba(0,0,0,.08); width:360px; }
    h1 { margin:0 0 12px; font-size:22px; }
    label { display:block; margin:10px 0 6px; font-size:14px; }
    input { width:100%; padding:10px 12px; border:1px solid #ddd; border-radius:10px; font-size:14px; }
    button { margin-top:16px; width:100%; padding:10px 12px; border:0; border-radius:10px; font-weight:600; cursor:pointer; background:#111827; color:#fff; }
    .error { color:#b91c1c; margin-top:10px; font-size:13px; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Welcome to the Seller Club</h1>

    <form method="post">
      <label for="email">Email</label>
      <input id="email" name="email" type="email" value="<%= (email!=null?email:"") %>" required />

      <label for="password">Password</label>
      <input id="password" name="password" type="password" required />

      <button type="submit">Proceed</button>

      <% if (error != null) { %>
        <div class="error"><%= error %></div>
      <% } %>
    </form>
  </div>
</body>
</html>





