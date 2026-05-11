<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         import="java.sql.*, com.cs336.pkg.ApplicationDB, java.util.*" %>
<%@ page session="true" %>

<%
    // Require login
    Integer userId = (Integer) session.getAttribute("userId");
    String userName = (String) session.getAttribute("name");
    if (userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String msg = null;
    String msgColor = "green";

    // Handle new question
    String questionText = request.getParameter("question_text");
    String submitFlag   = request.getParameter("submit_question");

    // Search / filter inputs
    String searchQuery = request.getParameter("search");
    if (searchQuery == null) searchQuery = "";
    String myOnlyParam = request.getParameter("my_only");  // "YES" if checked

    ApplicationDB db = null;
    Connection conn = null;

    try {
        db = new ApplicationDB();
        conn = db.getConnection();

        if ("YES".equals(submitFlag)) {
            if (questionText == null || questionText.trim().isEmpty()) {
                msg = "Question cannot be empty.";
                msgColor = "red";
            } else {
                PreparedStatement psIns = conn.prepareStatement(
                    "INSERT INTO Questions (user_id, question_text) VALUES (?, ?)"
                );
                psIns.setInt(1, userId);
                psIns.setString(2, questionText.trim());
                psIns.executeUpdate();
                psIns.close();
                msg = "Your question has been posted.";
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
    <title>FAQ & Help Center</title>
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
            width: 1000px;
            background:white;
            padding:24px 28px;
            border-radius:12px;
            box-shadow:0 10px 25px rgba(0,0,0,0.08);
        }
        .top-bar {
            display:flex;
            justify-content:space-between;
            align-items:center;
        }
        h2 { margin:0 0 4px; }
        .subtitle {
            margin:0 0 12px;
            font-size:13px;
            color:#6b7280;
        }
        .back-link {
            text-decoration:none;
            color:#2563eb;
            font-size:13px;
        }
        .back-link:hover { text-decoration:underline; }

        .filter-bar {
            margin-top:10px;
            margin-bottom:12px;
            padding:10px 12px;
            border-radius:10px;
            background:#f9fafb;
            display:flex;
            align-items:center;
            gap:10px;
            flex-wrap:wrap;
            font-size:13px;
        }
        .filter-bar input[type="text"] {
            padding:6px 8px;
            border-radius:8px;
            border:1px solid #d1d5db;
            min-width:220px;
        }
        .filter-bar label {
            display:flex;
            align-items:center;
            gap:4px;
        }
        .filter-bar input[type="checkbox"] {
            accent-color:#111827;
        }
        .filter-bar button {
            padding:7px 12px;
            border:none;
            border-radius:8px;
            background:#111827;
            color:white;
            font-size:13px;
            font-weight:600;
            cursor:pointer;
        }

        .question-box {
            background:#f9fafb;
            padding:12px 14px;
            border-radius:10px;
            margin-bottom:16px;
        }
        textarea {
            width:100%;
            min-height:60px;
            resize:vertical;
            padding:8px 10px;
            border-radius:8px;
            border:1px solid #d1d5db;
            font-size:13px;
        }
        .btn-ask {
            padding:8px 14px;
            border:none;
            border-radius:8px;
            cursor:pointer;
            font-size:13px;
            font-weight:600;
            background:#111827;
            color:white;
            margin-top:8px;
        }
        .btn-ask:hover {
            background:#020617;
        }

        .msg {
            margin-top:10px;
            font-size:13px;
        }

        .q-list {
            margin-top:18px;
        }
        .q-card {
            border:1px solid #e5e7eb;
            border-radius:10px;
            padding:10px 12px;
            margin-bottom:10px;
            background:#ffffff;
        }
        .q-header {
            display:flex;
            justify-content:space-between;
            font-size:12px;
            color:#6b7280;
            margin-bottom:4px;
        }
        .q-text {
            font-size:14px;
            white-space:pre-wrap;
            margin-bottom:6px;
        }
        .q-meta {
            font-size:11px;
            color:#9ca3af;
        }
        .reply-title {
            font-size:12px;
            font-weight:600;
            margin-top:6px;
        }
        .reply-item {
            font-size:12px;
            border-top:1px solid #f3f4f6;
            padding-top:4px;
            margin-top:4px;
        }
        .reply-meta {
            color:#6b7280;
            font-size:11px;
        }
        .empty {
            text-align:center;
            font-size:13px;
            color:#6b7280;
            margin-top:18px;
        }
        .badge-me {
            background:#dbeafe;
            color:#1d4ed8;
            padding:2px 6px;
            border-radius:999px;
            font-size:10px;
            margin-left:6px;
        }
    </style>
</head>
<body>

<div class="shell">

    <div class="top-bar">
        <div>
            <h2>FAQ & Help Center</h2>
            <p class="subtitle">Hi <b><%= userName %></b>, ask a question or browse what others have asked.</p>
        </div>
        <div>
            <a href="buyerHome.jsp" class="back-link">&laquo; Back to Home</a>
        </div>
    </div>

    <% if (msg != null) { %>
        <div class="msg" style="color:<%= msgColor %>;"><%= msg %></div>
    <% } %>

    <!-- SEARCH / FILTER BAR FOR QUESTIONS -->
    <form method="get" action="fqahome.jsp">
        <div class="filter-bar">
            <span>Search questions:</span>
            <input type="text" name="search"
                   placeholder="keywords..."
                   value="<%= searchQuery %>" />

            <label>
                <input type="checkbox" name="my_only" value="YES"
                       <%= "YES".equals(myOnlyParam) ? "checked" : "" %> />
                Asked by me only
            </label>

            <button type="submit">Apply</button>
        </div>
    </form>

    <!-- Ask a question -->
    <div class="question-box">
        <form method="post" action="fqahome.jsp">
            <label style="font-size:13px;">Ask a question (visible to all users):</label>
            <textarea name="question_text" placeholder="Type your question here..."></textarea>
            <input type="hidden" name="submit_question" value="YES" />
            <button type="submit" class="btn-ask">Submit Question</button>
        </form>
    </div>

    <!-- Questions & Answers list -->
    <div class="q-list">
        <%
            if (conn == null && db != null) {
                conn = db.getConnection();
            }
            if (conn != null) {
                try {
                    StringBuilder sqlQ = new StringBuilder(
                        "SELECT q.question_id, q.user_id, q.question_text, q.created_at, u.name AS asker_name " +
                        "FROM Questions q " +
                        "JOIN User u ON q.user_id = u.user_id " +
                        "WHERE 1=1 "
                    );
                    List<Object> paramsQ = new ArrayList<>();

                    // Apply "search" filter
                    if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                        sqlQ.append(" AND q.question_text LIKE ? ");
                        paramsQ.add("%" + searchQuery.trim() + "%");
                    }

                    // Apply "asked by me only" filter
                    if ("YES".equals(myOnlyParam)) {
                        sqlQ.append(" AND q.user_id = ? ");
                        paramsQ.add(userId);
                    }

                    sqlQ.append(" ORDER BY q.created_at DESC");

                    PreparedStatement psQ = conn.prepareStatement(sqlQ.toString());

                    int idxQ = 1;
                    for (Object p : paramsQ) {
                        if (p instanceof String) {
                            psQ.setString(idxQ++, (String)p);
                        } else if (p instanceof Integer) {
                            psQ.setInt(idxQ++, (Integer)p);
                        }
                    }

                    ResultSet rsQ = psQ.executeQuery();

                    boolean hasQ = false;

                    while (rsQ.next()) {
                        hasQ = true;
                        int qid = rsQ.getInt("question_id");
                        int qUserId = rsQ.getInt("user_id");
                        String askerName = rsQ.getString("asker_name");
                        String qText2 = rsQ.getString("question_text");
                        Timestamp qTime = rsQ.getTimestamp("created_at");
        %>
        <div class="q-card">
            <div class="q-header">
                <div>
                    Asked by <strong><%= askerName %></strong>
                    <% if (qUserId == userId) { %>
                        <span class="badge-me">Me</span>
                    <% } %>
                </div>
                <div class="q-meta">#<%= qid %> • <%= qTime %></div>
            </div>
            <div class="q-text"><%= qText2 %></div>

            <div class="reply-title">Answers from customer representatives:</div>

            <%
                // Load replies for this question
                String sqlR =
                    "SELECT r.reply_text, r.created_at, cr.user_id AS rep_user_id, u2.name AS rep_name " +
                    "FROM Replies r " +
                    "JOIN CustomerRep cr ON r.rep_id = cr.user_id " +
                    "JOIN User u2 ON cr.user_id = u2.user_id " +
                    "WHERE r.question_id = ? " +
                    "ORDER BY r.created_at ASC";

                PreparedStatement psR = conn.prepareStatement(sqlR);
                psR.setInt(1, qid);
                ResultSet rsR = psR.executeQuery();

                boolean hasReplies = false;
                while (rsR.next()) {
                    hasReplies = true;
                    String repName = rsR.getString("rep_name");
                    String rText = rsR.getString("reply_text");
                    Timestamp rTime = rsR.getTimestamp("created_at");
            %>
                <div class="reply-item">
                    <div class="reply-meta">
                        <strong><%= repName %></strong> • <%= rTime %>
                    </div>
                    <div><%= rText %></div>
                </div>
            <%
                }
                if (!hasReplies) {
            %>
                <div class="reply-item">
                    <div class="reply-meta">No answers yet. A customer representative will respond soon.</div>
                </div>
            <%
                }
                rsR.close();
                psR.close();
            %>
        </div>
        <%
                    }

                    if (!hasQ) {
        %>
        <div class="empty">
            No questions match your filters.
        </div>
        <%
                    }

                    rsQ.close();
                    psQ.close();
                } catch (SQLException eList) {
        %>
        <div class="empty" style="color:red;">
            Error loading questions: <%= eList.getMessage() %>
        </div>
        <%
                } finally {
                    try { if (conn != null && db != null) db.closeConnection(conn); } catch (Exception ignore) {}
                }
            } else {
        %>
        <div class="empty" style="color:red;">Database connection not available.</div>
        <%
            }
        %>
    </div>

</div>

</body>
</html>
