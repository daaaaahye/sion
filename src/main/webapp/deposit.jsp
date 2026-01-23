<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%
    request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html; charset=UTF-8");

    // ✅ 세션 체크 + 메뉴바 표시용 이름
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

        // [필터 조건] 날짜와 무관하게 deposit 테이블 존재 여부로 판단
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
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">

  <style>
    * { box-sizing: border-box; }
    body{
      margin:0;
      font-family: system-ui, -apple-system, Segoe UI, Roboto, "Noto Sans KR", Arial, sans-serif;
      background:#f5f6f8;
      color:#111827;
    }

    /* ===============================
       ✅ TOP NAVBAR (customer_list.jsp와 동일)
       =============================== */
    .navbar{
      height:56px;
      background:#243646;
      display:flex;
      align-items:center;
      padding:0 22px;
      gap:26px;
      position:relative;
      flex-wrap: nowrap;
    }

    .navbar-brand{
      font-weight:800;
      font-size:16px;
      color:#2aa3ff;
      text-decoration:none;
      white-space:nowrap;
      display:inline-flex;
      align-items:center;
      gap:8px;
      flex:0 0 auto;
    }

    .nav-links{
      list-style:none;
      display:flex;
      align-items: stretch;
      gap:22px;
      margin:0;
      padding:0;
      position:relative;

      flex-wrap: nowrap;
      white-space: nowrap;
      min-width: 0;
      overflow-x: auto;
      overflow-y: hidden;
      scrollbar-width: none;
    }
    .nav-links::-webkit-scrollbar { display:none; }

    .nav-links li{
      display:flex;
      align-items:center;
      flex:0 0 auto;
    }

    .nav-links a{
      color:#cbd5e1;
      text-decoration:none;
      font-size:13px;
      font-weight:600;
      white-space:nowrap;
      position:relative;

      height:56px;
      display:flex;
      align-items:center;
      padding:0 4px;
      line-height:1;
    }

    .nav-links a:hover{ color:#ffffff; }

    /* ✅ 언더게이트(밑줄) - 4번 메뉴(入金管理) 아래 고정 */
    .nav-links li:nth-child(4) a::after{
      content:"";
      position:absolute;
      left:0;
      bottom:10px;
      width:100%;
      height:2px;
      background:#2aa3ff;
      border-radius:2px;
    }

    /* ===============================
       ✅ ADMIN (customer_list.jsp와 동일)
       =============================== */
    .admin-area{
      margin-left:auto;
      position:relative;
      display:flex;
      align-items:center;
      gap:10px;
      flex:0 0 auto;
    }

    .admin-text{
      display:flex;
      flex-direction:column;
      align-items:flex-end;
      line-height:1.2;
      margin:0;
      transform:none;
      white-space:nowrap;
    }

    .admin-name{
      font-size:12px;
      font-weight:700;
      color:#e5edf5;
    }

    .admin-id{
      font-size:11px;
      color:#9fb0c3;
    }

    .admin-icon{
      width:30px;
      height:30px;
      border-radius:50%;
      background:rgba(255,255,255,.92);
      display:flex;
      align-items:center;
      justify-content:center;
      box-shadow:0 0 0 2px rgba(255,255,255,.28);
      user-select:none;
      cursor:pointer;
    }

    .admin-icon svg{ width:18px; height:18px; opacity:.85; }

    .admin-dropdown{
      position:absolute;
      top:100%;
      right:0;
      margin-top:6px;
      min-width:120px;
      background:rgba(255,255,255,.72);
      backdrop-filter: blur(10px);
      -webkit-backdrop-filter: blur(10px);
      border:1px solid rgba(229,231,235,.9);
      border-radius:12px;
      box-shadow:0 16px 36px rgba(0,0,0,.18);
      display:flex;
      flex-direction:column;
      overflow:hidden;
      z-index:1000;

      opacity:0;
      visibility:hidden;
      pointer-events:none;
      transform: translateY(6px);
      transition: opacity .16s ease, transform .16s ease, visibility .16s;
    }

    .admin-dropdown.open{
      opacity:1;
      visibility:visible;
      pointer-events:auto;
      transform: translateY(0);
    }

    .admin-area:hover .admin-dropdown{
      opacity:1;
      visibility:visible;
      pointer-events:auto;
      transform: translateY(0);
    }

    .dropdown-item{
      padding:9px 12px;
      font-size:13px;
      color:#111827;
      text-decoration:none;
      white-space:nowrap;
    }

    .dropdown-item:hover{ background: rgba(17,24,39,.06); }

    .dropdown-sep{
      height:1px;
      background: rgba(17,24,39,.08);
      margin:2px 0;
    }

    .dropdown-item.logout{
      color:#b91c1c;
      font-weight:800;
    }

    /* ===============================
       ✅ PAGE STYLE (기존 유지)
       =============================== */
    .main-container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
    .content-card { background: white; border-radius: 10px; padding: 24px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); min-height: 500px; }

    .search-box { margin-bottom: 20px; background: #f1f3f5; padding: 15px; border-radius: 8px; display: flex; gap: 10px; }
    .btn-search { background: white; border: 1px solid #ddd; cursor: pointer; padding: 2px 10px; border-radius: 4px; height: 32px; }

    .list-table { width: 100%; border-collapse: collapse; table-layout: fixed; border: 1px solid #dee2e6; }
    .list-table th { background: #f8f9fa; padding: 12px; font-size: 16px; border: 1px solid #dee2e6; text-align: center; }
    .list-table td { padding: 12px; border: 1px solid #dee2e6; font-size: 14px; text-align: center; }
    .text-right { text-align: right !important; padding-right: 30px !important; }

    .name-highlight { color: #3498db; font-weight: bold; }

    .badge { padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }

    .btn-deposit { cursor: pointer; border: 1px solid #ccc; background-color: #f2f2f2; border-radius: 4px; padding: 4px 10px; color: #333; font-size: 13px; }
    .btn-deposit:hover { background-color: #e6e6e6; }

    .pagination { display: flex; justify-content: center; align-items: center; margin-top: 30px; }
    .page-item { display: flex; align-items: center; justify-content: center; width: 32px; height: 32px; border: 1px solid #dee2e6; background-color: #fff; margin: 0 2px; text-decoration: none; color: #333; font-size: 14px; }
    .page-item.active { background-color: #3498db; color: #fff; border-color: #3498db; font-weight: bold; }
    .jump-box { display: flex; justify-content: center; align-items: center; gap: 10px; margin-top: 20px; font-size: 14px; }
    .jump-input { width: 45px; height: 28px; text-align: center; border: 1px solid #ccc; border-radius: 4px; }
  </style>

  <script>
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
    function goToPage() {
      let pageNum = document.getElementById("jumpPageInput").value;
      if (pageNum > 0 && pageNum <= <%= totalPages %>) {
        location.href = "?status=<%= searchStatus %>&page=" + pageNum;
      } else { alert("1から<%= totalPages %>の数字を入力してください。"); }
    }
  </script>
</head>

<body>
  <!-- ✅ NAVBAR (customer_list.jsp 메뉴바와 동일 + 4번 밑줄) -->
  <nav class="navbar">
    <a href="main.jsp" class="navbar-brand">💧 SMART WATER JP</a>

    <ul class="nav-links" id="navLinks">
      <li><a href="customer_list.jsp">顧客一覧</a></li>
      <li><a href="district_manage.jsp">管轄区域管理</a></li>
      <li><a href="overdue_list.jsp">延滞管理</a></li>
      <li><a href="deposit.jsp">入金管理</a></li>
      <li><a href="billing_list.jsp">請求管理</a></li>
    </ul>

    <div class="admin-area" id="adminArea">
      <div class="admin-text">
        <div class="admin-name"><%= (sessionAdminName == null ? "" : sessionAdminName) %> 様</div>
        <div class="admin-id">社員番号 <%= (sessionAdminId == null ? "" : sessionAdminId) %></div>
      </div>

      <div class="admin-icon">
        <svg viewBox="0 0 24 24" fill="none">
          <path d="M12 12c2.76 0 5-2.46 5-5.5S14.76 1 12 1 7 3.46 7 6.5 9.24 12 12 12Z"
                stroke="#111827" stroke-width="1.6"/>
          <path d="M3 23c0-4.2 4-7.6 9-7.6s9 3.4 9 7.6"
                stroke="#111827" stroke-width="1.6" stroke-linecap="round"/>
        </svg>
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
      <h2>💰 入金管理</h2>

      <form class="search-box" method="get">
        <select name="status" style="padding:5px; border-radius:4px; border:1px solid #ddd;">
          <option value="all" <%= searchStatus.equals("all") ? "selected" : "" %>>全体</option>
          <option value="unpaid" <%= searchStatus.equals("unpaid") ? "selected" : "" %>>未納</option>
          <option value="overdue" <%= searchStatus.equals("overdue") ? "selected" : "" %>>延滞</option>
          <option value="paid" <%= searchStatus.equals("paid") ? "selected" : "" %>>完納</option>
        </select>
        <button type="submit" class="btn-search"><i class="bi bi-search"></i></button>
      </form>

      <table class="list-table">
        <thead>
          <tr><th>氏名</th><th>請求日</th><th>請求金額</th><th>入金状態</th><th>処理</th></tr>
        </thead>
        <tbody>
          <%
            String sql = "SELECT c.name, b.customer_id, b.billing_date, b.bill_amount, " +
                         "(SELECT paid_at FROM deposit WHERE customer_id = b.customer_id LIMIT 1) as paid_record " +
                         "FROM bill b JOIN customers c ON b.customer_id = c.customer_id " +
                         "LEFT JOIN deposit d ON b.customer_id = d.customer_id " +
                         condition + " GROUP BY c.name, b.customer_id, b.billing_date, b.bill_amount " +
                         "ORDER BY b.billing_date DESC LIMIT ? OFFSET ?";

            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, pageSize);
            pstmt.setInt(2, offset);
            ResultSet rs = pstmt.executeQuery();

            while(rs.next()){
              String cid = rs.getString("customer_id");
              String bDateStr = rs.getString("billing_date");
              long amount = rs.getLong("bill_amount");

              boolean isPaid = (rs.getTimestamp("paid_record") != null);
              java.sql.Date bDate = rs.getDate("billing_date");
              boolean isOverdue = bDate.before(new java.util.Date(System.currentTimeMillis() - 2592000000L));
          %>
          <tr>
            <td><span class="name-highlight"><%= rs.getString("name") %></span> 様</td>
            <td><%= bDateStr %></td>
            <td class="text-right"><%= df.format(amount) %></td>
            <td>
              <% if(isPaid) { %>
                <span class="badge" style="background:#e8faf0; color:#2ecc71;">完納</span>
              <% } else if(isOverdue) { %>
                <span class="badge" style="background:#ffdada; color:#e74c3c;">延滞</span>
              <% } else { %>
                <span class="badge" style="background:#fff5f5; color:#c0392b;">未納</span>
              <% } %>
            </td>
            <td>
              <% if(!isPaid) { %>
                <button onclick="openPaymentPopup('<%= cid %>', '<%= bDateStr %>', <%= amount %>)" class="btn-deposit">入金</button>
              <% } else { %>
                -
              <% } %>
            </td>
          </tr>
          <% }
             rs.close();
             pstmt.close();
          %>
        </tbody>
      </table>

      <%
        String amountStr = request.getParameter("amount");
        if (amountStr != null && !amountStr.isEmpty()) {
          try {
            int amount = Integer.parseInt(amountStr);
      %>
            <div style="color: blue; font-weight: bold; margin-top: 12px;">
              ✅ 結果: <%= amount %>円が正常に入金されました！
            </div>
      <%
          } catch (NumberFormatException e) {
      %>
            <div style="color: red; margin-top: 12px;">数字のみ入力できます。</div>
      <%
          }
        }
      %>

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
        <input type="number" id="jumpPageInput" class="jump-input" value="<%= curPage %>"> / <%= totalPages %>
        <button onclick="goToPage()" style="background:#346aff; color:white; border:none; border-radius:4px; padding:4px 10px; cursor:pointer;">移動</button>
      </div>

    </div>
  </div>

  <script>
    // ✅ ADMIN DROPDOWN (click to toggle)
    const adminArea = document.getElementById("adminArea");
    const adminDropdown = document.getElementById("adminDropdown");

    adminArea.addEventListener("click", function (e) {
      e.stopPropagation();
      adminDropdown.classList.toggle("open");
    });

    adminDropdown.addEventListener("click", function (e) {
      e.stopPropagation();
    });

    document.addEventListener("click", function () {
      adminDropdown.classList.remove("open");
    });
  </script>
</body>
</html>
<%
    } catch (Exception e) {
      out.println("Error: " + e.getMessage());
    } finally {
      if(conn != null) conn.close();
    }
%>
