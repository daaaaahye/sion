<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.Locale" %>

<%
    /* ========================================================
       1. 세션 및 관리자 정보
       ======================================================== */
    String sessionAdminId = (String) session.getAttribute("adminId");
    if (sessionAdminId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String adminName = (String) session.getAttribute("adminName");
    if (adminName == null) adminName = "管理者";

    /* ========================================================
       2. 날짜 처리 로직
       ======================================================== */
    String todayStr = LocalDate.now().toString();
    String searchDateParam = request.getParameter("search_date");
    LocalDate baseDate = (searchDateParam == null || searchDateParam.isEmpty())
                         ? LocalDate.now() : LocalDate.parse(searchDateParam);

    if (baseDate.isAfter(LocalDate.now())) {
        baseDate = LocalDate.now();
    }

    String inputDateValue = baseDate.toString();
    DateTimeFormatter displayFormatter = DateTimeFormatter.ofPattern("yyyy年 MM月 dd日", Locale.JAPAN);
    String displayDate = baseDate.format(displayFormatter);

    String dayOfWeekJP;
    switch (baseDate.getDayOfWeek()) {
        case MONDAY:    dayOfWeekJP = "月"; break;
        case TUESDAY:   dayOfWeekJP = "火"; break;
        case WEDNESDAY: dayOfWeekJP = "水"; break;
        case THURSDAY:  dayOfWeekJP = "木"; break;
        case FRIDAY:    dayOfWeekJP = "金"; break;
        case SATURDAY:  dayOfWeekJP = "土"; break;
        default:        dayOfWeekJP = "日";
    }

    /* ========================================================
       3. DB 연동 (수정된 로직 반영)
       ======================================================== */
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Class.forName("org.postgresql.Driver");
        conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");

        String sql =
            "WITH BillingSummary AS (" +
            "    SELECT customer_id, COALESCE(SUM(paid_amount), 0) as total_paid " +
            "    FROM deposit WHERE paid_at <= ? GROUP BY customer_id" +
            "), " +
            "UnpaidDetails AS (" +
            "    SELECT b.customer_id, b.billing_date, " +
            "           SUM(b.bill_amount) OVER (PARTITION BY b.customer_id ORDER BY b.billing_date ASC) as cumulative_bill, " +
            "           s.total_paid " +
            "    FROM bill b " +
            "    LEFT JOIN BillingSummary s ON b.customer_id = s.customer_id " +
            "    WHERE b.billing_date <= ?" +
            ") " +
            "SELECT c.name, " +
            "       (MAX(u.cumulative_bill) - COALESCE(MAX(u.total_paid), 0)) as total_overdue_amount, " +
            "       MIN(CASE WHEN u.cumulative_bill > COALESCE(u.total_paid, 0) THEN u.billing_date END) as oldest_unpaid_date " +
            "FROM customers c " +
            "JOIN UnpaidDetails u ON c.customer_id = u.customer_id " +
            "GROUP BY c.customer_id, c.name " +
            "HAVING (MAX(u.cumulative_bill) - COALESCE(MAX(u.total_paid), 0)) > 0 " +
            "ORDER BY oldest_unpaid_date ASC";

        pstmt = conn.prepareStatement(sql);
        java.sql.Date sqlBaseDate = java.sql.Date.valueOf(baseDate);
        pstmt.setDate(1, sqlBaseDate);
        pstmt.setDate(2, sqlBaseDate);

        rs = pstmt.executeQuery();
%>

<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>延滞管理 - SMART WATER</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: system-ui, -apple-system, Segoe UI, Roboto, "Noto Sans KR", Arial, sans-serif;
      background: #f5f6f8;
      color: #111827;
    }

    /* ===============================
       ✅ TOP NAVBAR (통합 버전)
       =============================== */
    .navbar {
      height: 56px;
      background: #243646;
      display: flex;
      align-items: center;
      padding: 0 22px;
      gap: 26px;
      position: relative;
    }

    .navbar-brand {
      font-weight: 800;
      font-size: 16px;
      color: #2aa3ff;
      text-decoration: none;
      white-space: nowrap;
    }

    .nav-links {
      list-style: none;
      display: flex;
      align-items: center;
      gap: 22px;
      margin: 0;
      padding: 0;
      position: relative;
    }

    .nav-links a {
      color: #cbd5e1;
      text-decoration: none;
      font-size: 13px;
      font-weight: 600;
      padding: 18px 4px 14px;
      white-space: nowrap;
      display: inline-block;
      position: relative;
    }

    .nav-links a:hover { color: #ffffff; }

    /* ✅ 메뉴바 3번째 메뉴(延滞管理) 아래 언더라인 고정 */
    .nav-links li:nth-child(3) a::after {
      content: "";
      position: absolute;
      left: 0;
      bottom: 6px;
      width: 100%;
      height: 2px;
      background: #2aa3ff;
      border-radius: 2px;
    }

    /* ADMIN */
    .admin-area{
      margin-left: auto;
      position: relative;
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .admin-text{
      display: flex;
      flex-direction: column;
      align-items: flex-end;
      line-height: 1.2;
      margin: 0;
      transform: none;
      white-space: nowrap;
    }

    .admin-name {
      font-size: 12px;
      font-weight: 700;
      color: #e5edf5;
    }

    .admin-id {
      font-size: 11px;
      color: #9fb0c3;
    }

    .admin-icon {
      width: 30px;
      height: 30px;
      border-radius: 50%;
      background: rgba(255,255,255,.92);
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 0 0 2px rgba(255,255,255,.28);
      user-select: none;
      cursor: pointer;
    }

    .admin-icon svg { width: 18px; height: 18px; opacity: .85; }

    .admin-dropdown {
      position: absolute;
      top: 100%;
      right: 0;
      margin-top: 6px;
      min-width: 120px;
      background: rgba(255,255,255,.72);
      backdrop-filter: blur(10px);
      -webkit-backdrop-filter: blur(10px);
      border: 1px solid rgba(229,231,235,.9);
      border-radius: 12px;
      box-shadow: 0 16px 36px rgba(0,0,0,.18);
      display: flex;
      flex-direction: column;
      overflow: hidden;
      z-index: 1000;
      opacity: 0;
      visibility: hidden;
      pointer-events: none;
      transform: translateY(6px);
      transition: opacity .16s ease, transform .16s ease, visibility .16s;
    }

    .admin-dropdown.open{
      opacity: 1;
      visibility: visible;
      pointer-events: auto;
      transform: translateY(0);
    }

    .dropdown-item {
      padding: 9px 12px;
      font-size: 13px;
      color: #111827;
      text-decoration: none;
      white-space: nowrap;
    }

    .dropdown-item:hover { background: rgba(17,24,39,.06); }

    .dropdown-sep { height: 1px; background: rgba(17,24,39,.08); margin: 2px 0; }

    .dropdown-item.logout {
      color: #b91c1c;
      font-weight: 800;
    }

    /* hover로도 열리게 */
    .admin-area:hover .admin-dropdown{
      opacity: 1;
      visibility: visible;
      pointer-events: auto;
      transform: translateY(0);
    }

    /* ===============================
       PAGE CONTENT
       =============================== */
    .main-container { max-width:1200px; margin:26px auto; padding:0 20px; }
    .content-card { background:#fff; border-radius:12px; padding:24px; box-shadow:0 4px 12px rgba(0,0,0,0.05); }

    .section-title { font-size:24px; font-weight:bold; color:#2c3e50; margin-bottom:16px; border-left:5px solid #2aa3ff; padding-left:12px; line-height: 1.2; }
    .search-notice { margin:10px 0 14px; padding:12px 14px; border-radius:10px; background:#f1f6fb; border:1px solid #dbe9f6; font-size:13px; line-height:1.55; }

    .search-box { background:#f1f3f5; padding:18px; border-radius:10px; margin-bottom:20px; display:flex; gap:15px; align-items:flex-end; flex-wrap:wrap; }
    .search-group { display:flex; flex-direction:column; gap:8px; }
    .search-group label { font-weight:bold; font-size:13px; }

    input[type="date"], .btn-search { padding:10px 14px; border-radius:7px; border:1px solid #d9dde3; font-size:14px; height:40px; }
    .btn-search { background:#2aa3ff; color:#fff; cursor:pointer; font-weight:800; border:none; padding: 0 25px; }

    .display-base-date { margin: 15px 0 25px; font-size: 22px; font-weight: bold; color: #2aa3ff; display: flex; align-items: center; gap: 8px; }

    .data-table { width:100%; border-collapse:collapse; margin-top:10px; table-layout: fixed; }
    .data-table th { background: #f8f9fa; padding: 14px; border-bottom: 2px solid #dee2e6; color: #495057; font-size: 16px; font-weight: 800; text-align: center; }
    .data-table td { padding: 14px; border-bottom: 1px solid #eee; text-align: center; font-size: 14px; font-weight: normal; color: #333; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

    .name-col { text-align: left !important; padding-left: 25px !important; }
    .amount-text { text-align: right !important; padding-right: 30px !important; }

    .date-badge { background: #f1f6fb; color: #2aa3ff; padding: 4px 10px; border-radius: 6px; font-size: 13px; font-weight: bold; border: 1px solid #dbe9f6; }
  </style>
</head>

<body>

  <!-- ✅ 메뉴바: 통합 버전 적용 -->
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
    <div class="content-card">
      <div class="section-title">📍 滞納顧客の現状</div>

      <div class="search-notice">
        ※ 基準日を選択すると、その時点での滞納情報を確認できます。<br>
        ※ 未納期間は、入金で相殺されていない**最も古い請求日**を基準に表示されます。
      </div>

      <form class="search-box" action="overdue_list.jsp" method="get">
        <div class="search-group">
          <label>基準日を選択</label>
          <input type="date" name="search_date" value="<%= inputDateValue %>" max="<%= todayStr %>">
        </div>
        <button type="submit" class="btn-search">適用</button>
      </form>

      <div class="display-base-date">
        <span>📅</span> <%= displayDate %> (<%= dayOfWeekJP %>) 基準
      </div>

      <table class="data-table">
        <thead>
          <tr>
            <th style="text-align: left; padding-left: 25px;">顧客名</th>
            <th>未納期間</th>
            <th style="text-align: right; padding-right: 30px;">未納合計金額</th>
          </tr>
        </thead>
        <tbody>
          <%
              boolean hasData = false;
              while(rs.next()) {
                  hasData = true;
                  Date oldestDate = rs.getDate("oldest_unpaid_date");
                  long overdueAmount = rs.getLong("total_overdue_amount");
          %>
          <tr>
            <td class="name-col"><%= rs.getString("name") %> 様</td>
            <td><span class="date-badge"><%= (oldestDate != null) ? oldestDate.toString() + " 〜" : "-" %></span></td>
            <td class="amount-text">¥<%= String.format("%,d", overdueAmount) %></td>
          </tr>
          <%
              }
              if(!hasData) {
          %>
          <tr>
            <td colspan="3" style="padding: 60px; color: #9ca3af; text-align: center;">該当する滞納データはありません。</td>
          </tr>
          <% } %>
        </tbody>
      </table>
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
        out.println("<div style='color:red; text-align:center; padding:20px;'>エラー: " + e.getMessage() + "</div>");
    } finally {
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (conn != null) try { conn.close(); } catch(Exception e) {}
    }
%>
