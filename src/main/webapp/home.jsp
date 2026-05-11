<%@ page contentType="text/html; charset=UTF-8" %>
<%
    String email = (String) session.getAttribute("email");
    String name  = (String) session.getAttribute("name");

    if (email == null) { 
        response.sendRedirect("index.jsp"); 
        return; 
    }
%>

<!DOCTYPE html>
<html>
<head>
  <title>BuyMe – Home</title>
  <meta charset="UTF-8">
  <style>
    body { font-family: system-ui, Arial; display:flex; align-items:center; justify-content:center; min-height:100vh; background:#f6f7fb; }
    .card { background:#fff; padding:28px; border-radius:14px; box-shadow:0 10px 25px rgba(0,0,0,.08); width:420px; text-align:center; }
    h1 { margin:0 0 10px; font-size:24px; }
    p { color:#444; }
    button { padding:12px 14px; border:0; border-radius:10px; font-weight:600; cursor:pointer; background:#111827; color:#fff; width:80%; margin-top:10px; }
  </style>
</head>

<body>
  <div class="card">
    <h1>You are logged in!</h1>
    <p>Welcome <strong><%= (name!=null && !name.isEmpty()) ? name : email %></strong></p>

    <h3>Select Your Role</h3>
    <p>You can choose a role every time you log in.</p>

    <!-- BUYER BUTTON -->
    <form action="setRole.jsp" method="post">
      <input type="hidden" name="role" value="buyer">
      <button type="submit">Continue as Buyer / Bidder</button>
    </form>

    <!-- SELLER BUTTON -->
    <form action="setRole.jsp" method="post">
      <input type="hidden" name="role" value="seller">
      <button type="submit">Continue as Seller</button>
    </form>

    <!-- LOGOUT -->
    <form method="post" action="logout.jsp">
      <button type="submit" style="background:#b91c1c; margin-top:20px;">Logout</button>
    </form>
  </div>
</body>
</html>
