<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%
    String sessionAdminId = (String) session.getAttribute("adminId");
    String adminName = (String) session.getAttribute("adminName");

    String customerId = request.getParameter("customer_id");
    String billingDate = request.getParameter("billing_date");

    if (sessionAdminId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    if (adminName == null) adminName = "管理者";
    if (customerId == null || customerId.isEmpty() ||
        billingDate == null || billingDate.isEmpty()) {
        out.println("<h3>잘못된 접근입니다.</h3>");
        return;
    }

    Connection connRoot = null;
    Connection connWsms = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    DecimalFormat df = new DecimalFormat("#,###");
    boolean noBillingDate = false;

    Long monthlyBill = null;
    long totalBilled = 0;
    long totalPaid = 0;

    try {
        Class.forName("org.postgresql.Driver");
        connRoot = DriverManager.getConnection("jdbc:postgresql://localhost:5432/root", "postgres", "1234");
        connWsms = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");

        String sqlAdmin = "SELECT name FROM \"Administrator\" WHERE id = ?";
        PreparedStatement pstmtAdmin = connRoot.prepareStatement(sqlAdmin);
        pstmtAdmin.setString(1, sessionAdminId);
        ResultSet rsAdmin = pstmtAdmin.executeQuery();
        if (rsAdmin.next()) {
            adminName = rsAdmin.getString("name");
            session.setAttribute("adminName", adminName);
        }
        rsAdmin.close();
        pstmtAdmin.close();

        String checkSql = "SELECT 1 FROM bill WHERE customer_id=? AND billing_date=?";
        PreparedStatement chkPstmt = connWsms.prepareStatement(checkSql);
        chkPstmt.setString(1, customerId);
        chkPstmt.setDate(2, java.sql.Date.valueOf(billingDate));
        ResultSet chkRs = chkPstmt.executeQuery();
        if (!chkRs.next()) noBillingDate = true;
        chkRs.close();
        chkPstmt.close();

        String sql =
            "SELECT c.name, c.tel, c.address, " +
            " (SELECT bill_amount FROM public.bill WHERE customer_id = ? AND billing_date = ?) as monthly_bill, " +
            " (SELECT COALESCE(SUM(bill_amount), 0) FROM public.bill WHERE customer_id = ? AND billing_date <= ?) as total_billed, " +
            " (SELECT COALESCE(SUM(paid_amount), 0) FROM public.deposit WHERE customer_id = ? AND paid_at <= ?) as total_paid " +
            " FROM public.customers c WHERE c.customer_id = ?";

        pstmt = connWsms.prepareStatement(sql);
        pstmt.setString(1, customerId);
        pstmt.setDate(2, java.sql.Date.valueOf(billingDate));
        pstmt.setString(3, customerId);
        pstmt.setDate(4, java.sql.Date.valueOf(billingDate));
        pstmt.setString(5, customerId);
        pstmt.setDate(6, java.sql.Date.valueOf(billingDate));
        pstmt.setString(7, customerId);

        rs = pstmt.executeQuery();

        if (rs.next()) {
            monthlyBill = rs.getObject("monthly_bill", Long.class);
            totalBilled = rs.getLong("total_billed");
            totalPaid = rs.getLong("total_paid");
            if (monthlyBill == null) noBillingDate = true;
        } else {
            noBillingDate = true;
        }

    } catch (Exception e) {
        e.printStackTrace();
        return;
    }
%>

<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>상수도 요금 청구서 - SMART WATER</title>

  <!-- 기존 청구서 CSS -->
  <link rel="stylesheet" href="css/billing.css">

  <!-- ✅ main.jsp와 메뉴바 규격 100% 동일 강제 (충돌 방지용 !important 포함) -->
  <style>
    /* body 기본(메뉴바 기준 통일) */
    body{
      margin: 0 !important;
      font-family: system-ui, -apple-system, Segoe UI, Roboto, "Noto Sans KR", Arial, sans-serif !important;
      background: #f5f6f8 !important;
      color: #111827 !important;
    }

    /* NAVBAR (main.jsp 동일 규격) */
    .navbar{
      height: 56px !important;
      background: #243646 !important;
      display: flex !important;
      align-items: center !important;
      padding: 0 22px !important;
      gap: 26px !important;
      position: relative !important;
    }

    .navbar-brand{
      font-weight: 800 !important;
      font-size: 16px !important;
      color: #2aa3ff !important;
      text-decoration: none !important;
      white-space: nowrap !important;
    }

    .nav-links{
      list-style: none !important;
      display: flex !important;
      align-items: center !important;
      gap: 22px !important;
      margin: 0 !important;
      padding: 0 !important;
      position: relative !important;
    }

    .nav-links a{
      color: #cbd5e1 !important;
      text-decoration: none !important;
      font-size: 13px !important;
      font-weight: 600 !important;
      padding: 18px 4px 14px !important;
      white-space: nowrap !important;
      display: inline-block !important;
      position: relative !important;
      border-bottom: 0 !important; /* 이 페이지는 언더라인 없음 */
    }

    .nav-links a:hover{ color: #ffffff !important; }

    /* ADMIN (main.jsp 동일 규격) */
    .admin-area{
      margin-left: auto !important;
      position: relative !important;
      display: flex !important;
      align-items: center !important;
      gap: 10px !important;
    }

    .admin-text{
      display: flex !important;
      flex-direction: column !important;
      align-items: flex-end !important;
      line-height: 1.2 !important;
      margin: 0 !important;
      transform: none !important;
      white-space: nowrap !important;
    }

    .admin-name{
      font-size: 12px !important;
      font-weight: 700 !important;
      color: #e5edf5 !important;
    }

    .admin-id{
      font-size: 11px !important;
      color: #9fb0c3 !important;
    }

    .admin-icon{
      width: 30px !important;
      height: 30px !important;
      border-radius: 50% !important;
      background: rgba(255,255,255,.92) !important;
      display: flex !important;
      align-items: center !important;
      justify-content: center !important;
      box-shadow: 0 0 0 2px rgba(255,255,255,.28) !important;
      user-select: none !important;
    }

    .admin-icon svg{ width: 18px !important; height: 18px !important; opacity: .85 !important; }

    .admin-dropdown{
      position: absolute !important;
      top: 100% !important;
      right: 0 !important;
      margin-top: 6px !important;
      min-width: 120px !important;
      background: rgba(255,255,255,.72) !important;
      backdrop-filter: blur(10px) !important;
      -webkit-backdrop-filter: blur(10px) !important;
      border: 1px solid rgba(229,231,235,.9) !important;
      border-radius: 12px !important;
      box-shadow: 0 16px 36px rgba(0,0,0,.18) !important;
      display: flex !important;
      flex-direction: column !important;
      overflow: hidden !important;
      z-index: 1000 !important;
      opacity: 0 !important;
      visibility: hidden !important;
      pointer-events: none !important;
      transform: translateY(6px) !important;
      transition: opacity .16s ease, transform .16s ease, visibility .16s !important;
    }

    .admin-dropdown.open{
      opacity: 1 !important;
      visibility: visible !important;
      pointer-events: auto !important;
      transform: translateY(0) !important;
    }

    .dropdown-item{
      padding: 9px 12px !important;
      font-size: 13px !important;
      color: #111827 !important;
      text-decoration: none !important;
      white-space: nowrap !important;
    }

    .dropdown-item:hover{ background: rgba(17,24,39,.06) !important; }

    .dropdown-sep{ height: 1px !important; background: rgba(17,24,39,.08) !important; margin: 2px 0 !important; }

    .dropdown-item.logout{
      color: #b91c1c !important;
      font-weight: 800 !important;
    }

    /* hover로도 열림 (main.jsp 동일) */
    .admin-area:hover .admin-dropdown{
      opacity: 1 !important;
      visibility: visible !important;
      pointer-events: auto !important;
      transform: translateY(0) !important;
    }
  </style>
</head>

<body>

  <!-- ✅ main.jsp와 동일 메뉴바 -->
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
        <div class="admin-name"><%= (adminName == null ? "" : adminName) %> 様</div>
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
    <% if (noBillingDate) { %>
      <div class="error">
        <h2>📅 선택한 날짜의 고지서가 없습니다</h2>
        <p>선택한 청구일 : <%= billingDate %></p>
        <button class="back" onclick="history.back()">이전 페이지로</button>
      </div>
    <% } else {
        long overdueAmount = (totalBilled - totalPaid) - monthlyBill;
        if (overdueAmount < 0) overdueAmount = 0;
        long finalTotal = monthlyBill + overdueAmount;
    %>

      <div class="btn-print-area">
        <button class="btn-print" onclick="window.print()">🖨️ 請求書を印刷する</button>
      </div>

      <div class="bill-card">
        <div class="bill-title">水道料金の請求書</div>
        <div class="bill-date">請求年月: <%= billingDate %></div>

        <div class="bill-divider"></div>

        <table class="info-table">
          <tr><th>お名前(고객명)</th><td><%= rs.getString("name") %> 様</td></tr>
          <tr><th>お客様番号 (ID)</th><td><%= customerId %></td></tr>
          <tr><th>ご住所(주소)</th><td><%= rs.getString("address") %></td></tr>
          <tr><th>今月分のご請求金額(이번달 청구액)</th><td><%= df.format(monthlyBill) %>円</td></tr>
          <tr><th>未払金額(연체료)</th><td><%= df.format(overdueAmount) %>円</td></tr>
        </table>

        <div class="total-wrapper">
          <span class="total-label">お支払い合計額(지불 합계)</span>
          <span class="total-text"><%= df.format(finalTotal) %>円</span>
        </div>

        <div class="footer-notice">
          * お振込先: 三菱UFJ銀行 110-123-456789 (smart water)<br>
          * お問い合わせ: 02-120 (水道お客さまセンター)*
        </div>
      </div>
    <% } %>
  </div>

  <script>
    // ✅ main.jsp와 동일한 드롭다운 토글
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
    if (rs != null) rs.close();
    if (pstmt != null) pstmt.close();
    if (connRoot != null) connRoot.close();
    if (connWsms != null) connWsms.close();
%>
