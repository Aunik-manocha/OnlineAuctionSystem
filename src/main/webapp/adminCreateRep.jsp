<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" session="true"
         import="java.sql.*, com.cs336.pkg.ApplicationDB" %>
<!DOCTYPE html>
<html>
<head>
    <title>Create Customer Representative</title>
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
            width: 780px;
            background: #ffffff;
            border-radius: 14px;
            box-shadow: 0 18px 45px rgba(15, 23, 42, 0.12);
            padding: 24px 26px 26px;
        }

        .header-row {
            display: flex;
            justify-content: space-between;
            align-items: baseline;
            gap: 12px;
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

        form {
            margin-top: 12px;
        }

        label {
            display: block;
            margin-top: 10px;
            font-size: 0.9rem;
            color: #374151;
        }

        input {
            width: 100%;
            padding: 9px 10px;
            margin-top: 4px;
            border-radius: 10px;
            border: 1px solid #d1d5db;
            font-size: 0.9rem;
            outline: none;
            transition: border-color 0.15s ease, box-shadow 0.15s ease;
        }

        input:focus {
            border-color: #4f46e5;
            box-shadow: 0 0 0 1px rgba(79, 70, 229, 0.25);
        }

        .form-grid {
            display: grid;
            grid-template-columns: 1.3fr 1fr;
            gap: 18px;
            margin-top: 6px;
            align-items: flex-start;
        }

        button {
            margin-top: 18px;
            width: 100%;
            padding: 10px;
            background: #111827;
            color: #ffffff;
            border: none;
            cursor: pointer;
            border-radius: 10px;
            font-weight: 600;
            font-size: 0.95rem;
            transition: transform 0.14s ease, box-shadow 0.14s ease, background 0.14s ease;
        }

        button:hover {
            background: #020617;
            transform: translateY(-1px);
            box-shadow: 0 10px 20px rgba(15, 23, 42, 0.18);
        }

        .msg {
            margin-top: 10px;
            font-size: 0.9rem;
        }

        .msg-wrapper {
            margin-top: 8px;
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

        .table-wrapper {
            margin-top: 24px;
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
            font-size: 0.88rem;
        }

        th, td {
            padding: 8px 6px;
            border-bottom: 1px solid #e5e7eb;
            text-align: left;
        }

        th {
            font-weight: 600;
            color: #4b5563;
            font-size: 0.8rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        .delete-btn {
            background: #dc2626;
            color: #ffffff;
            border: none;
            border-radius: 999px;
            padding: 5px 11px;
            font-size: 0.75rem;
            cursor: pointer;
            transition: background 0.15s ease, transform 0.1s ease;
        }

        .delete-btn:hover {
            background: #b91c1c;
            transform: translateY(-1px);
        }

        .no-data {
            text-align: center;
            font-size: 0.85rem;
            color: #6b7280;
            padding: 10px 0;
        }

        @media (max-width: 900px) {
            .box {
                width: 94%;
                padding: 20px 18px 22px;
            }

            .form-grid {
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

    String message = null;
    String messageColor = "#16a34a"; // green-ish

    String action = request.getParameter("action");
    String email = request.getParameter("email");
    String name = request.getParameter("name");
    String password = request.getParameter("password");

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        ApplicationDB db = new ApplicationDB();
        Connection con = null;

        try {
            con = db.getConnection();

            if (con == null) {
                message = "Error: could not connect to database.";
                messageColor = "#dc2626";
            } else {
                if ("create".equals(action)) {
                    // Server-side validation: all fields required
                    if (email == null || email.trim().isEmpty() ||
                        name == null || name.trim().isEmpty() ||
                        password == null || password.trim().isEmpty()) {

                        message = "All fields are required.";
                        messageColor = "#dc2626";
                    } else {
                        // 1) Get next user_id (since User.user_id is NOT AUTO_INCREMENT)
                        String sqlNextId = "SELECT COALESCE(MAX(user_id), 0) + 1 AS new_id FROM User";
                        PreparedStatement psNext = con.prepareStatement(sqlNextId);
                        ResultSet rsNext = psNext.executeQuery();

                        int newUserId = -1;
                        if (rsNext.next()) {
                            newUserId = rsNext.getInt("new_id");
                        }
                        rsNext.close();
                        psNext.close();

                        // 2) Insert into User
                        String sqlUser = "INSERT INTO User (user_id, email, name, password) VALUES (?, ?, ?, ?)";
                        PreparedStatement psUser = con.prepareStatement(sqlUser);
                        psUser.setInt(1, newUserId);
                        psUser.setString(2, email.trim());
                        psUser.setString(3, name.trim());
                        psUser.setString(4, password); // (plaintext per your current design)
                        psUser.executeUpdate();
                        psUser.close();

                        // 3) Insert into CustomerRep
                        String sqlRep = "INSERT INTO CustomerRep (user_id) VALUES (?)";
                        PreparedStatement psRep = con.prepareStatement(sqlRep);
                        psRep.setInt(1, newUserId);
                        psRep.executeUpdate();
                        psRep.close();

                        message = "Customer Representative created successfully (user_id = " + newUserId + ").";
                        messageColor = "#16a34a";

                        // Clear fields after success
                        email = "";
                        name = "";
                        password = "";
                    }
                } else if ("delete".equals(action)) {
                    String idStr = request.getParameter("user_id");
                    if (idStr != null && !idStr.trim().isEmpty()) {
                        int deleteId = Integer.parseInt(idStr.trim());

                        // Delete from CustomerRep first (FK constraint safe)
                        PreparedStatement psRepDel = con.prepareStatement(
                            "DELETE FROM CustomerRep WHERE user_id = ?"
                        );
                        psRepDel.setInt(1, deleteId);
                        psRepDel.executeUpdate();
                        psRepDel.close();

                        // Then delete from User (if you want to remove the entire user)
                        PreparedStatement psUserDel = con.prepareStatement(
                            "DELETE FROM User WHERE user_id = ?"
                        );
                        psUserDel.setInt(1, deleteId);
                        psUserDel.executeUpdate();
                        psUserDel.close();

                        message = "Customer Representative with user_id " + deleteId + " was deleted.";
                        messageColor = "#16a34a";
                    } else {
                        message = "Invalid representative selected for deletion.";
                        messageColor = "#dc2626";
                    }
                }
            }
        } catch (SQLException e) {
            message = "Database error: " + e.getMessage();
            messageColor = "#dc2626";
            e.printStackTrace();
        } finally {
            if (con != null) {
                try { con.close(); } catch (SQLException e) { e.printStackTrace(); }
            }
        }
    }
%>

<div class="box">
    <a class="back" href="adminHome.jsp">&laquo; Back to Admin Dashboard</a>

    <div class="header-row">
        <div>
            <h2>Create Customer Representative</h2>
            <p class="subtitle">
                Every field is required. New reps will log in with the email and password you set.
            </p>
        </div>
    </div>

    <div class="form-grid">
        <div>
            <form method="post" action="adminCreateRep.jsp">
                <input type="hidden" name="action" value="create" />

                <label>Email</label>
                <input type="email" name="email" required
                       value="<%= (email != null ? email : "") %>">

                <label>Name</label>
                <input type="text" name="name" required
                       value="<%= (name != null ? name : "") %>">

                <label>Password</label>
                <input type="password" name="password" required>

                <button type="submit">Create Customer Rep</button>
            </form>

            <div class="msg-wrapper">
                <% if (message != null) { %>
                    <div class="msg" style="color:<%= messageColor %>;">
                        <%= message %>
                    </div>
                <% } %>
            </div>
        </div>

        <div class="table-wrapper">
            <div class="table-title">Existing Customer Representatives</div>
            <table>
                <tr>
                    <th>User ID</th>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Actions</th>
                </tr>

                <%
                    ApplicationDB dbList = new ApplicationDB();
                    Connection conList = null;

                    try {
                        conList = dbList.getConnection();
                        if (conList != null) {
                            String sqlList = "SELECT u.user_id, u.name, u.email " +
                                             "FROM User u JOIN CustomerRep cr ON u.user_id = cr.user_id " +
                                             "ORDER BY u.user_id ASC";
                            PreparedStatement psList = conList.prepareStatement(sqlList);
                            ResultSet rsList = psList.executeQuery();

                            boolean hasRows = false;
                            while (rsList.next()) {
                                hasRows = true;
                %>
                <tr>
                    <td><%= rsList.getInt("user_id") %></td>
                    <td><%= rsList.getString("name") %></td>
                    <td><%= rsList.getString("email") %></td>
                    <td>
                        <form method="post" action="adminCreateRep.jsp"
                              style="display:inline;"
                              onsubmit="return confirm('Are you sure you want to delete this representative?');">
                            <input type="hidden" name="action" value="delete" />
                            <input type="hidden" name="user_id" value="<%= rsList.getInt("user_id") %>" />
                            <button type="submit" class="delete-btn">Delete</button>
                        </form>
                    </td>
                </tr>
                <%
                            }
                            if (!hasRows) {
                %>
                <tr>
                    <td colspan="4" class="no-data">No customer representatives found.</td>
                </tr>
                <%
                            }

                            rsList.close();
                            psList.close();
                        } else {
                %>
                <tr>
                    <td colspan="4" class="no-data" style="color:#dc2626;">
                        Could not connect to database to load representatives.
                    </td>
                </tr>
                <%
                        }
                    } catch (SQLException e) {
                %>
                <tr>
                    <td colspan="4" class="no-data" style="color:#dc2626;">
                        Error loading reps: <%= e.getMessage() %>
                    </td>
                </tr>
                <%
                        e.printStackTrace();
                    } finally {
                        if (conList != null) {
                            try { conList.close(); } catch (SQLException e) { e.printStackTrace(); }
                        }
                    }
                %>
            </table>
        </div>
    </div>
</div>

</body>
</html>
