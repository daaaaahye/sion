<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%
    request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html; charset=UTF-8");

    // ✅ セッションチェック
    String sessionAdminId = (String) session.getAttribute("adminId");
    String sessionAdminName = (String) session.getAttribute("adminName");
    if (sessionAdminId == null) { response.sendRedirect("login.jsp"); return; }

    String searchStatus = request.getParameter("status");
    if (searchStatus == null) searchStatus = "all";

    int curPage = (request.getParameter("page") != null) ? Integer.parseInt(request.getParameter("page")) : 1;
    int pageSize = 10;
    int offset = (curPage - 1) * pageSize;
    int totalPages = 1;

    Connection conn = null;
    DecimalFormat df = new DecimalFormat("¥###,###");

    try {
        Class.forName("org.postgresql.Driver");
        conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");

        String condition = " WHERE 1=1 ";
        if(searchStatus.equals("unpaid")) condition += " AND d.customer_id IS NULL AND b.billing_date >= CURRENT_DATE - INTERVAL '1 month'";
        else if(searchStatus.equals("overdue")) condition += " AND d.customer_id IS NULL AND b.billing_date < CURRENT_DATE - INTERVAL '1 month'";
        else if(searchStatus.equals("paid")) condition += " AND d.customer_id IS NOT NULL";

        String countSql = "SELECT count(*) FROM bill b LEFT JOIN deposit d ON b.customer_id = d.customer_id " + condition;
        PreparedStatement pstmtCount = conn.prepareStatement(countSql);
        ResultSet rsCount = pstmtCount.executeQuery();
        if(rsCount.next()) {
            int totalRows = rsCount.getInt(1);
            totalPages = (int) Math.ceil((double)totalRows / pageSize);
            if(totalPages == 0) totalPages = 1;
        }
        rsCount.close();
        pstmtCount.close();
%>
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>入金管理 - SMART WATER JP</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { box-sizing: border-box; }
    body{ margin:0; font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; background:#f5f6f8; color:#111827; }

    /* ✅ TOP NAVBAR */
    .navbar{ height:56px; background:#243646; display:flex; align-items:center; padding:0 22px; gap:26px; position:relative; }
    .navbar-brand{ font-weight:800; font-size:16px; color:#2aa3ff; text-decoration:none; }
    .nav-links{ list-style:none; display:flex; gap:22px; margin:0; padding:0; }
    .nav-links a{ color:#cbd5e1; text-decoration:none; font-size:13px; font-weight:600; height:56px; display:flex; align-items:center; padding:0 4px; position:relative; }
    .nav-links li:nth-child(4) a::after{ content:""; position:absolute; left:0; bottom:10px; width:100%; height:2px; background:#2aa3ff; border-radius:2px; }

    /* ✅ ADMIN AREA */
    .admin-area{ margin-left:auto; position:relative; display:flex; align-items:center; gap:10px; cursor:pointer; }
    .admin-text{ display:flex; flex-direction:column; align-items:flex-end; white-space:nowrap; }
    .admin-name{ font-size:12px; font-weight:700; color:#e5edf5; }
    .admin-id{ font-size:11px; color:#9fb0c3; }
    .admin-icon{ width:30px; height:30px; border-radius:50%; background:rgba(255,255,255,.92); display:flex; align-items:center; justify-content:center; box-shadow:0 0 0 2px rgba(255,255,255,.28); }
    .admin-dropdown{ position:absolute; top:100%; right:0; margin-top:6px; min-width:120px; background:rgba(255,255,255,0.72); backdrop-filter: blur(10px); border:1px solid rgba(229,231,235,0.9); border-radius:12px; box-shadow:0 16px 36px rgba(0,0,0,0.18); display:none; flex-direction:column; z-index:1000; overflow:hidden; }
    .admin-dropdown.open{ display:flex; }
    .dropdown-item{ padding:9px 12px; font-size:13px; color:#111827; text-decoration:none; }
    .dropdown-item:hover{ background: rgba(17,24,39,0.06); }

    /* ✅ PAGE CONTENT & ACCENT BAR */
    .main-container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
    .content-card { background: white; border-radius: 10px; padding: 24px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); }

    .title { display: flex; align-items: center; padding-left: 15px; position: relative; font-size: 22px; font-weight: bold; color: #111827; margin-bottom: 12px; }
    .title::before { content: ""; position: absolute; left: 0; top: 50%; transform: translateY(-50%); width: 6px; height: 22px; background-color: #2aa3ff; border-radius: 0; }

    /* ✅ 案内ボックス */
    .search-notice { 
        margin: 10px 0 14px; padding: 12px 14px; border-radius: 10px; 
        background: #f1f6fb; border: 1px solid #dbe9f6; font-size: 13px; 
        line-height: 1.55; color: #4b5563; 
    }

    /* ✅ SEARCH BOX & BUTTON */
    .search-box { margin-bottom: 25px; background: #f8f9fa; padding: 20px; border-radius: 8px; display: flex; align-items: center; gap: 15px; }
    .status-select { height: 40px; padding: 0 12px; border: 1px solid #d1d5db; border-radius: 6px; background: white; min-width: 180px; font-size: 14px; }
    .btn-search { background: #2aa3ff; color: white; border: none; padding: 0 25px; border-radius: 6px; height: 40px; font-weight: bold; cursor: pointer; transition: background 0.2s; font-size: 14px; }
    .btn-search:hover { background: #1f8fe6; }

    /* ✅ TABLE STYLE */
    .list-table { width: 100%; border-collapse: collapse; border: 1px solid #e5e7eb; }
    .list-table th { background: #f9fafb; padding: 14px; font-size: 14px; border: 1px solid #e5e7eb; color: #4b5563; }
    .list-table td { padding: 14px; border: 1px solid #e5e7eb; font-size: 14px; text-align: center; }
    .name-highlight { color: #111827; font-weight: bold; }
    .badge { padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
    
    /* 🛠️ 入金ボタン: 灰色スタイル */
    .btn-deposit { 
        cursor: pointer; border: 1px solid #d1d5db; background-color: #f3f4f6; 
        border-radius: 4px; padding: 5px 12px; font-size: 13px; color: #374151; 
        font-weight: 500; transition: background 0.2s; 
    }
    .btn-deposit:hover { background-color: #e5e7eb; }

    /* ✅ PAGINATION & JUMP BOX */
    .pagination { display: flex; justify-content: center; align-items: center; margin-top: 30px; gap: 4px; }
    .page-item { display: flex; align-items: center; justify-content: center; width: 34px; height: 34px; border: 1px solid #e5e7eb; background: white; text-decoration: none; color: #374151; border-radius: 4px; font-size: 14px; }
    .page-item.active { background: #2aa3ff; color: white; border-color: #2aa3ff; font-weight: bold; }
    .jump-box { display: flex; justify-content: center; align-items: center; gap: 10px; margin-top: 20px; font-size: 14px; }
    .jump-input { width: 50px; height: 32px; text-align: center; border: 1px solid #d1d5db; border-radius: 4px; }
    .btn-jump { background: #2aa3ff; color: white; border: none; border-radius: 4px; padding: 6px 12px; cursor: pointer; font-weight: bold; }
  </style>
</head>
<body>
  <nav class="navbar">
    <a href="main.jsp" class="navbar-brand">💧 SMART WATER JP</a>
    <ul class="nav-links">
      <li><a href="customer_list.jsp">顧客一覧</a></li>
      <li><a href="district_manage.jsp">管轄区域管理</a></li>
      <li><a href="overdue_list.jsp">延滞管理</a></li>
      <li><a href="deposit.jsp">入金管理</a></li>
      <li><a href="billing_list.jsp">請求管理</a></li>
    </ul>
    <div class="admin-area" id="adminArea">
      <div class="admin-text">
        <div class="admin-name"><%= sessionAdminName %> 様</div>
        <div class="admin-id">社員番号 <%= sessionAdminId %></div>
      </div>
      <div class="admin-icon">
        <svg viewBox="0 0 24 24" width="18" fill="none" stroke="currentColor"><path d="M12 12c2.76 0 5-2.46 5-5.5S14.76 1 12 1 7 3.46 7 6.5 9.24 12 12 12Z" stroke-width="1.6"/><path d="M3 23c0-4.2 4-7.6 9-7.6s9 3.4 9 7.6" stroke-width="1.6"/></svg>
      </div>
      <div class="admin-dropdown" id="adminDropdown">
        <a href="admin.jsp" class="dropdown-item">設定</a>
        <div class="dropdown-sep"></div>
        <a href="logout.jsp" class="dropdown-item logout">ログアウト</a>
      </div>
    </div>
  </nav>

  <div class="main-container">
    <div class="content-card">
      <div class="title">💰 入金管理</div>
      <div class="search-notice">
        ※ 入金状態を選択して検索してください。<br>
        ※ 未納および延滞状態の顧客のみ入金処理が可能です。
      </div>

      <form class="search-box" method="get">
        <select name="status" class="status-select">
          <option value="all" <%= searchStatus.equals("all") ? "selected" : "" %>>全体</option>
          <option value="unpaid" <%= searchStatus.equals("unpaid") ? "selected" : "" %>>未納</option>
          <option value="overdue" <%= searchStatus.equals("overdue") ? "selected" : "" %>>延滞</option>
          <option value="paid" <%= searchStatus.equals("paid") ? "selected" : "" %>>完納</option>
        </select>
        <button type="submit" class="btn-search">検索</button>
      </form>

      <table class="list-table">
        <thead>
          <tr><th>氏名</th><th>請求日</th><th>請求金額</th><th>入金状態</th><th>処理</th></tr>
        </thead>
        <tbody>
          <%
            String sqlList = "SELECT c.name, b.customer_id, b.billing_date, b.bill_amount, " +
                         "(SELECT paid_at FROM deposit WHERE customer_id = b.customer_id LIMIT 1) as paid_record " +
                         "FROM bill b JOIN customers c ON b.customer_id = c.customer_id " +
                         "LEFT JOIN deposit d ON b.customer_id = d.customer_id " +
                         condition + " GROUP BY c.name, b.customer_id, b.billing_date, b.bill_amount " +
                         "ORDER BY b.billing_date DESC LIMIT ? OFFSET ?";

            PreparedStatement pstmtList = conn.prepareStatement(sqlList);
            pstmtList.setInt(1, pageSize);
            pstmtList.setInt(2, offset);
            ResultSet rsList = pstmtList.executeQuery();

            while(rsList.next()){
              String cid = rsList.getString("customer_id");
              String bDateStr = rsList.getString("billing_date");
              long amt = rsList.getLong("bill_amount");
              boolean isPaid = (rsList.getTimestamp("paid_record") != null);
              java.sql.Date bd = rsList.getDate("billing_date");
              boolean isOver = bd.before(new java.util.Date(System.currentTimeMillis() - 2592000000L));
          %>
          <tr>
            <td><span class="name-highlight"><%= rsList.getString("name") %></span> 様</td>
            <td><%= bDateStr %></td>
            <td style="text-align:right; padding-right:20px;"><%= df.format(amt) %></td>
            <td>
              <% if(isPaid) { %><span class="badge" style="background:#e8faf0; color:#2ecc71;">完納</span>
              <% } else if(isOver) { %><span class="badge" style="background:#ffdada; color:#e74c3c;">延滞</span>
              <% } else { %><span class="badge" style="background:#fff5f5; color:#c0392b;">未納</span><% } %>
            </td>
            <td><% if(!isPaid) { %><button onclick="openPaymentPopup('<%= cid %>', '<%= bDateStr %>', <%= amt %>)" class="btn-deposit">入金</button><% } else { %>-<% } %></td>
          </tr>
          <% } %>
        </tbody>
      </table>

      <div class="pagination">
        <a href="?status=<%=searchStatus%>&page=1" class="page-item">«</a>
        <a href="?status=<%=searchStatus%>&page=<%= Math.max(1, curPage-1) %>" class="page-item">‹</a>
        <% for(int i=Math.max(1, curPage-2); i<=Math.min(totalPages, Math.max(1, curPage-2)+4); i++) { %>
          <a href="?status=<%=searchStatus%>&page=<%=i%>" class="page-item <%= (i==curPage) ? "active" : "" %>"><%=i%></a>
        <% } %>
        <a href="?status=<%=searchStatus%>&page=<%= Math.min(totalPages, curPage+1) %>" class="page-item">›</a>
        <a href="?status=<%=searchStatus%>&page=<%= totalPages %>" class="page-item">»</a>
      </div>

      <div class="jump-box">
        <input type="number" id="jumpPageInput" class="jump-input" value="<%= curPage %>">
        <span style="color: #6b7280;">/ <%= totalPages %></span>
        <button onclick="goToPage()" class="btn-jump">移動</button>
      </div>
    </div>
  </div>
  <script>
    const adminArea = document.getElementById("adminArea");
    const adminDropdown = document.getElementById("adminDropdown");
    adminArea.addEventListener("click", (e) => { e.stopPropagation(); adminDropdown.classList.toggle("open"); });
    document.addEventListener("click", () => adminDropdown.classList.remove("open"));
    
    function goToPage() {
      let pageNum = document.getElementById("jumpPageInput").value;
      if (pageNum > 0 && pageNum <= <%= totalPages %>) {
        location.href = "?status=<%= searchStatus %>&page=" + pageNum;
      } else { alert("1から<%= totalPages %>の数字を入力してください。"); }
    }

    function openPaymentPopup(customerId, billingDate, totalAmount) {
      let inputAmount = prompt("入金する金額を入力してください。\n(請求額: " + totalAmount + "円)", "");
      if (inputAmount === null) return;
      if (parseInt(inputAmount) !== totalAmount) {
        alert("金額が一致しません。金額をもう一度確認してください。");
        return;
      }
      if (confirm("入金を完了しますか？")) {
        location.href = "pay_action.jsp?id=" + customerId + "&date=" + billingDate + "&amount=" + inputAmount;
      }
    }
  </script>
</body>
</html>
<% } catch (Exception e) { out.println(e.getMessage()); } finally { if(conn!=null) conn.close(); } %>