<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.sql.*, com.cs336.pkg.ApplicationDB" %>
<%@ page session="true" %>

<%
    // Security: only allow logged-in customer reps
    Boolean isRep = (Boolean) session.getAttribute("isCustomerRep");
    if (isRep == null || !isRep) {
        response.sendRedirect("login.jsp");
        return;
    }

    String message = null;
    String messageColor = "green";

    ApplicationDB db = null;
    Connection conn = null;

    try {
        db = new ApplicationDB();
        conn = db.getConnection();

        if (conn == null) {
            message = "Error: Could not connect to database.";
            messageColor = "red";
        } else {
            // Handle delete
            String deleteIdStr = request.getParameter("delete");
            if (deleteIdStr != null && !deleteIdStr.isEmpty()) {
                int id = Integer.parseInt(deleteIdStr);

                PreparedStatement psDel = conn.prepareStatement(
                    "DELETE FROM User WHERE user_id = ?"
                );
                psDel.setInt(1, id);
                int rows = psDel.executeUpdate();
                psDel.close();

                if (rows > 0) {
                    message = "User with ID " + id + " was deleted.";
                    messageColor = "green";
                } else {
                    message = "No user deleted. (ID " + id + " not found.)";
                    messageColor = "red";
                }
            }

            // Handle edit (update name + password)
            String editIdStr = request.getParameter("edit");
            if (editIdStr != null && !editIdStr.isEmpty()) {
                int id = Integer.parseInt(editIdStr);
                String newName = request.getParameter("name");
                String newPass = request.getParameter("pass");

                PreparedStatement psUpd = conn.prepareStatement(
                    "UPDATE User SET name = ?, password = ? WHERE user_id = ?"
                );
                psUpd.setString(1, newName);
                psUpd.setString(2, newPass);
                psUpd.setInt(3, id);
                int rows = psUpd.executeUpdate();
                psUpd.close();

                if (rows > 0) {
                    message = "User with ID " + id + " was updated.";
                    messageColor = "green";
                } else {
                    message = "No user updated. (ID " + id + " not found.)";
                    messageColor = "red";
                }
            }
        }

    } catch (Exception e) {
        message = "Error: " + e.getMessage();
        messageColor = "red";
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Edit / Delete Users</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background:#f3f4f6;
            margin:0;
            padding:40px 0;
            display:flex;
            justify-content:center;
        }
        .shell {
            width: 900px;
            background:white;
            padding:24px 28px;
            border-radius:12px;
            box-shadow:0 10px 25px rgba(0,0,0,0.08);
        }
        h2 {
            margin:0 0 10px;
            text-align:left;
        }
        .top-row {
            display:flex;
            justify-content:space-between;
            align-items:center;
        }
        .back-link {
            font-size:13px;
            text-decoration:none;
            color:#2563eb;
        }
        .back-link:hover {
            text-decoration:underline;
        }
        .subtitle {
            font-size:13px;
            color:#6b7280;
            margin-bottom:14px;
        }
        table {
            width:100%;
            border-collapse:collapse;
            margin-top:10px;
            font-size:14px;
        }
        th, td {
            padding:8px 10px;
            border-bottom:1px solid #e5e7eb;
            text-align:left;
        }
        th {
            background:#f9fafb;
            font-weight:600;
            font-size:12px;
            text-transform:uppercase;
            letter-spacing:0.05em;
            color:#4b5563;
        }
        input[type="text"], input[type="password"] {
            width:100%;
            padding:6px 8px;
            border-radius:6px;
            border:1px solid #d1d5db;
            font-size:13px;
        }
        .btn {
            padding:6px 10px;
            border:none;
            border-radius:6px;
            font-size:12px;
            cursor:pointer;
            font-weight:600;
        }
        .btn-save {
            background:#16a34a;
            color:white;
            margin-right:4px;
        }
        .btn-save:hover {
            background:#15803d;
        }
        .btn-delete {
            background:#b91c1c;
            color:white;
        }
        .btn-delete:hover {
            background:#7f1d1d;
        }
        .msg {
            margin-top:8px;
            font-size:13px;
        }
        .no-data {
            text-align:center;
            padding:12px 0;
            color:#6b7280;
        }
    </style>

    <script>
        function confirmDelete(userId) {
            return confirm("Are you sure you want to delete user with ID " + userId + "?");
        }
    </script>
</head>
<body>

<div class="shell">
    <div class="top-row">
        <h2>Edit / Delete Users</h2>
        <a class="back-link" href="CustomerRepHome.jsp">&laquo; Back to Customer Rep Home</a>
    </div>
    <div class="subtitle">
        Update user names/passwords or remove accounts. Customer Rep accounts are hidden.
    </div>

    <% if (message != null) { %>
        <div class="msg" style="color:<%= messageColor %>;">
            <%= message %>
        </div>
    <% } %>

    <table>
        <tr>
            <th>User ID</th>
            <th>Email</th>
            <th>Name</th>
            <th>Password</th>
            <th style="text-align:center;">Actions</th>
        </tr>

        <%
            if (conn != null) {
                try {
                    // 🔹 Show all users EXCEPT those who are CustomerReps
                    PreparedStatement psList = conn.prepareStatement(
                        "SELECT u.user_id, u.email, u.name, u.password " +
                        "FROM User u " +
                        "LEFT JOIN CustomerRep cr ON cr.user_id = u.user_id " +
                        "WHERE cr.user_id IS NULL " +
                        "ORDER BY u.user_id ASC"
                    );
                    ResultSet rs = psList.executeQuery();

                    boolean anyRows = false;
                    while (rs.next()) {
                        anyRows = true;
                        int uid = rs.getInt("user_id");
                        String email = rs.getString("email");
                        String name = rs.getString("name");
                        String pass = rs.getString("password");
        %>
        <tr>
            <form method="post">
                <td><%= uid %></td>
                <td><%= email %></td>
                <td>
                    <input type="text" name="name" value="<%= name %>" required />
                </td>
                <td>
                    <input type="text" name="pass" value="<%= pass %>" required />
                </td>
                <td style="text-align:center; white-space:nowrap;">
                    <button class="btn btn-save" name="edit" value="<%= uid %>">Save</button>
                    <button class="btn btn-delete" name="delete" value="<%= uid %>"
                            onclick="return confirmDelete(<%= uid %>);">
                        Delete
                    </button>
                </td>
            </form>
        </tr>
        <%
                    }

                    if (!anyRows) {
        %>
        <tr>
            <td colspan="5" class="no-data">No users (who are not customer reps) found.</td>
        </tr>
        <%
                    }

                    rs.close();
                    psList.close();
                } catch (SQLException exList) {
        %>
        <tr>
            <td colspan="5" style="color:#b91c1c;">
                Error loading users: <%= exList.getMessage() %>
            </td>
        </tr>
        <%
                    exList.printStackTrace();
                }
            } else {
        %>
        <tr>
            <td colspan="5" style="color:#b91c1c;">
                Database connection is not available.
            </td>
        </tr>
        <%
            }
        %>
    </table>
</div>

<%
    // Close connection in the end
    if (conn != null && db != null) {
        try { db.closeConnection(conn); } catch (Exception ignore) {}
    }
%>

</body>
</html>
