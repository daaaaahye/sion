<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ include file="/WEB-INF/dbconfig.jspf" %>
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
        out.println("<h3>間違ったアプローチです</h3>");
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

    PreparedStatement pstmtAdmin = null;
    ResultSet rsAdmin = null;

    try {
        Class.forName("org.postgresql.Driver");
        connRoot = sionConnect("root");
        connWsms = sionConnect("wsms");


        String sqlAdmin = "SELECT name FROM \"Administrator\" WHERE id = ?";
        pstmtAdmin = connRoot.prepareStatement(sqlAdmin);
        pstmtAdmin.setString(1, sessionAdminId);
        rsAdmin = pstmtAdmin.executeQuery();
        if (rsAdmin.next()) {
            adminName = rsAdmin.getString("name");
            session.setAttribute("adminName", adminName);
        }
        if (rsAdmin != null) rsAdmin.close();
        if (pstmtAdmin != null) pstmtAdmin.close();

        String checkSql = "SELECT 1 FROM bill WHERE customer_id=? AND billing_date=?";
        PreparedStatement chkPstmt = connWsms.prepareStatement(checkSql);
        chkPstmt.setString(1, customerId);
        chkPstmt.setDate(2, java.sql.Date.valueOf(billingDate));
        ResultSet chkRs = chkPstmt.executeQuery();
        if (!chkRs.next()) noBillingDate = true;
        if (chkRs != null) chkRs.close();
        if (chkPstmt != null) chkPstmt.close();

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
        out.println("<div style='color:red; background:#fff; padding:20px; border:2px solid red; margin:20px;'>");
        out.println("<h3>에러 발생:</h3>");
        out.println("<p>" + e.getMessage() + "</p>");
        out.println("<pre>");
        e.printStackTrace(new java.io.PrintWriter(out));
        out.println("</pre>");
        out.println("</div>");
        return;
    }
%>

<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>上水道料金 請求書 - SMART WATER</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <link rel="stylesheet" href="<%=request.getContextPath()%>/css/billing_list_detail.css?v=1">
</head>

<body>

  <nav class="navbar">
    <a href="main.jsp" class="navbar-brand">💧 SMART WATER JP</a>

    <ul class="nav-links" id="navLinks">
      <li><a href="customer_list.jsp">顧客一覧</a></li>
      <li><a href="district_manage.jsp">管轄区域管理</a></li>
      <li><a href="overdue_list.jsp">延滞管理</a></li>
      <li><a href="deposit.jsp">入金管理</a></li>
      <li><a href="billing_list.jsp" class="is-active">請求管理</a></li>
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
        <h2>📅 選択した日付の告知書がありません</h2>
        <p>選択した請求日: <%= billingDate %></p>
        <button class="back" onclick="history.back()">前のページへ</button>
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
          <tr><th>お名前</th><td><%= rs.getString("name") %> 様</td></tr>
          <tr><th>お客様番号</th><td><%= customerId %></td></tr>
          <tr><th>ご住所</th><td><%= rs.getString("address") %></td></tr>
          <tr><th>今月分のご請求金額</th><td><%= df.format(monthlyBill) %>円</td></tr>
          <tr><th>未払金額</th><td><%= df.format(overdueAmount) %>円</td></tr>
        </table>

        <div class="total-wrapper">
          <span class="total-label">お支払い合計額</span>
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
    (function () {
      const adminArea = document.getElementById("adminArea");
      const adminDropdown = document.getElementById("adminDropdown");
      if (!adminArea || !adminDropdown) return;

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
    })();
  </script>

</body>
</html>

<%
    try { if (rs != null) rs.close(); } catch(Exception e) {}
    try { if (pstmt != null) pstmt.close(); } catch(Exception e) {}
    try { if (connRoot != null) connRoot.close(); } catch(Exception e) {}
    try { if (connWsms != null) connWsms.close(); } catch(Exception e) {}
%>
