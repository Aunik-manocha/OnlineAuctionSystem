<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.sql.*, com.cs336.pkg.ApplicationDB, java.util.*" %>
<%@ page session="true" %>

<%
    // Only allow customer reps
    Boolean isRep = (Boolean) session.getAttribute("isCustomerRep");
    if (isRep == null || !isRep) {
        response.sendRedirect("login.jsp");
        return;
    }

    // Representative id: try repUserId, fall back to userId
    Integer repUserId = (Integer) session.getAttribute("repUserId");
    if (repUserId == null) {
        repUserId = (Integer) session.getAttribute("userId");
    }

    String msg = null;
    String msgColor = "green";

    ApplicationDB db = null;
    Connection conn = null;

    try {
        db = new ApplicationDB();
        conn = db.getConnection();

        /* --------- Handle delete question --------- */
        String deleteQ = request.getParameter("delete_question");
        if (deleteQ != null && !deleteQ.isEmpty()) {
            int qid = Integer.parseInt(deleteQ);

            // delete replies first (FK safety)
            PreparedStatement psDelR = conn.prepareStatement(
                "DELETE FROM Replies WHERE question_id = ?"
            );
            psDelR.setInt(1, qid);
            psDelR.executeUpdate();
            psDelR.close();

            PreparedStatement psDelQ = conn.prepareStatement(
                "DELETE FROM Questions WHERE question_id = ?"
            );
            psDelQ.setInt(1, qid);
            int rows = psDelQ.executeUpdate();
            psDelQ.close();

            if (rows > 0) {
                msg = "Question #" + qid + " deleted.";
            } else {
                msg = "Question not found.";
                msgColor = "red";
            }
        }

        /* --------- Handle reply submission --------- */
        String replyQ = request.getParameter("reply_question_id");
        String replyText = request.getParameter("reply_text");

        if (replyQ != null && !replyQ.isEmpty()) {
            if (repUserId == null) {
                msg = "Cannot send reply: representative not recognized in session.";
                msgColor = "red";
            } else if (replyText == null || replyText.trim().isEmpty()) {
                msg = "Reply cannot be empty.";
                msgColor = "red";
            } else {
                int qid = Integer.parseInt(replyQ);

                PreparedStatement psIns = conn.prepareStatement(
                    "INSERT INTO Replies (question_id, rep_id, reply_text) VALUES (?, ?, ?)"
                );
                psIns.setInt(1, qid);
                psIns.setInt(2, repUserId);
                psIns.setString(3, replyText.trim());
                psIns.executeUpdate();
                psIns.close();

                msg = "Reply sent for question #" + qid + ".";
            }
        }

    } catch (Exception e) {
        msg = "Error: " + e.getMessage();
        msgColor = "red";
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>View / Answer Questions</title>
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
            width: 1100px;
            background:white;
            padding:24px 28px;
            border-radius:12px;
            box-shadow:0 10px 25px rgba(0,0,0,0.08);
        }
        h2 { margin:0 0 8px; }
        .back-link {
            float:right;
            text-decoration:none;
            color:#2563eb;
            font-size:13px;
        }
        .back-link:hover { text-decoration:underline; }
        table {
            width:100%;
            border-collapse:collapse;
            margin-top:16px;
            font-size:14px;
        }
        th, td {
            padding:10px;
            border-bottom:1px solid #e5e7eb;
            vertical-align:top;
        }
        th {
            background:#f3f4f6;
            font-size:12px;
            text-transform:uppercase;
        }
        .status-pill {
            display:inline-block;
            padding:3px 9px;
            border-radius:999px;
            font-size:11px;
            font-weight:600;
        }
        .status-none { background:#fee2e2; color:#b91c1c; }
        .status-some { background:#dcfce7; color:#166534; }

        textarea {
            width:100%;
            min-height:70px;
            resize:vertical;
            padding:8px 10px;
            border-radius:8px;
            border:1px solid #d1d5db;
            font-size:13px;
        }
        .btn {
            padding:7px 12px;
            border:none;
            border-radius:8px;
            cursor:pointer;
            font-size:13px;
            font-weight:600;
        }
        .btn-reply { background:#111827; color:white; margin-top:6px; }
        .btn-delete { background:#b91c1c; color:white; margin-top:6px; }
        .btn-delete:hover { background:#7f1d1d; }
        .msg {
            margin-top:10px;
            font-size:13px;
        }
        .reply-list {
            font-size:12px;
            color:#4b5563;
            margin-top:4px;
        }
        .reply-item {
            border-top:1px solid #e5e7eb;
            padding-top:4px;
            margin-top:4px;
        }
        .reply-meta {
            font-size:11px;
            color:#6b7280;
        }
    </style>

    <script>
        function confirmDeleteQ(id) {
            return confirm("Delete question #" + id + " (and all its replies)?");
        }
    </script>
</head>
<body>

<div class="shell">

    <a href="CustomerRepHome.jsp" class="back-link">&laquo; Back to Customer Rep Home</a>
    <h2>View / Answer Questions</h2>

    <% if (msg != null) { %>
        <div class="msg" style="color:<%= msgColor %>;"><%= msg %></div>
    <% } %>

    <table>
        <tr>
            <th>Question ID</th>
            <th>User ID</th>
            <th>Question</th>
            <th>Status / Existing Replies</th>
            <th>Reply / Delete</th>
        </tr>

        <%
            if (conn != null) {
                try {
                    // Get all questions with asker info + reply counts
                    String sqlQ =
                        "SELECT q.question_id, q.user_id, q.question_text, q.created_at, u.name AS asker_name, " +
                        "       COUNT(r.reply_id) AS reply_count " +
                        "FROM Questions q " +
                        "JOIN User u ON q.user_id = u.user_id " +
                        "LEFT JOIN Replies r ON q.question_id = r.question_id " +
                        "GROUP BY q.question_id, q.user_id, q.question_text, q.created_at, u.name " +
                        "ORDER BY q.created_at DESC";

                    PreparedStatement psQ = conn.prepareStatement(sqlQ);
                    ResultSet rsQ = psQ.executeQuery();

                    boolean hasRows = false;

                    while (rsQ.next()) {
                        hasRows = true;
                        int qid = rsQ.getInt("question_id");
                        int uid = rsQ.getInt("user_id");
                        String qText = rsQ.getString("question_text");
                        Timestamp qTime = rsQ.getTimestamp("created_at");
                        String askerName = rsQ.getString("asker_name");
                        int replyCount = rsQ.getInt("reply_count");
        %>
        <tr>
            <td><%= qid %></td>
            <td><%= uid %> (<%= askerName %>)</td>
            <td>
                <div><%= qText %></div>
                <div style="font-size:11px; color:#6b7280; margin-top:3px;">
                    Asked at <%= qTime %>
                </div>
            </td>
            <td>
                <span class="status-pill <%= replyCount == 0 ? "status-none" : "status-some" %>">
                    <%= replyCount == 0 ? "Not answered" : "Answered" %>
                </span>
                <div class="reply-list">
                    <%= replyCount %> repl<%= replyCount == 1 ? "y" : "ies" %>
                </div>

                <%
                    // list existing replies
                    String sqlR =
                        "SELECT r.reply_text, r.created_at, u2.name AS rep_name " +
                        "FROM Replies r " +
                        "JOIN CustomerRep cr ON r.rep_id = cr.user_id " +
                        "JOIN User u2 ON cr.user_id = u2.user_id " +
                        "WHERE r.question_id = ? " +
                        "ORDER BY r.created_at ASC";

                    PreparedStatement psR = conn.prepareStatement(sqlR);
                    psR.setInt(1, qid);
                    ResultSet rsR = psR.executeQuery();
                    while (rsR.next()) {
                %>
                <div class="reply-item">
                    <div class="reply-meta">
                        <strong><%= rsR.getString("rep_name") %></strong>
                        • <%= rsR.getTimestamp("created_at") %>
                    </div>
                    <div><%= rsR.getString("reply_text") %></div>
                </div>
                <%
                    }
                    rsR.close();
                    psR.close();
                %>
            </td>
            <td>
                <form method="post" style="margin:0;">
                    <textarea name="reply_text" placeholder="Type your reply..."></textarea>
                    <input type="hidden" name="reply_question_id" value="<%= qid %>">
                    <button type="submit" class="btn btn-reply">Send Reply</button>
                </form>

                <form method="post" style="margin:8px 0 0 0;">
                    <button type="submit" class="btn btn-delete"
                            name="delete_question" value="<%= qid %>"
                            onclick="return confirmDeleteQ(<%= qid %>);">
                        Delete Question
                    </button>
                </form>
            </td>
        </tr>
        <%
                    }

                    if (!hasRows) {
        %>
        <tr><td colspan="5" style="text-align:center; padding:12px;">No questions found.</td></tr>
        <%
                    }

                    rsQ.close();
                    psQ.close();
                } catch (SQLException eList) {
        %>
        <tr><td colspan="5" style="color:red;">Error loading questions: <%= eList.getMessage() %></td></tr>
        <%
                } finally {
                    try { if (conn != null && db != null) db.closeConnection(conn); } catch (Exception ignore) {}
                }
            }
        %>
    </table>

</div>

</body>
</html>
