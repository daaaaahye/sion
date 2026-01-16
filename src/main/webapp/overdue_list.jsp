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
       3. DB 연동
       ======================================================== */
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Class.forName("org.postgresql.Driver");
        conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");

        String sql = 
            "SELECT c.name, MIN(b.billing_date) AS oldest_unpaid_date, " +
            "(SELECT COALESCE(SUM(bill_amount), 0) FROM public.bill WHERE customer_id = c.customer_id AND billing_date <= ?) " +
            "- (SELECT COALESCE(SUM(paid_amount), 0) FROM public.deposit WHERE customer_id = c.customer_id AND paid_at <= ?) AS total_overdue_amount " +
            "FROM public.customers c " +
            "JOIN public.bill b ON c.customer_id = b.customer_id " +
            "WHERE b.billing_date <= ? " +
            "GROUP BY c.customer_id, c.name " +
            "HAVING (SELECT COALESCE(SUM(bill_amount), 0) FROM public.bill WHERE customer_id = c.customer_id AND billing_date <= ?) " +
            "       - (SELECT COALESCE(SUM(paid_amount), 0) FROM public.deposit WHERE customer_id = c.customer_id AND paid_at <= ?) > 0 " +
            "ORDER BY oldest_unpaid_date ASC";

        pstmt = conn.prepareStatement(sql);
        java.sql.Date sqlBaseDate = java.sql.Date.valueOf(baseDate);
        pstmt.setDate(1, sqlBaseDate);
        pstmt.setDate(2, sqlBaseDate);
        pstmt.setDate(3, sqlBaseDate);
        pstmt.setDate(4, sqlBaseDate);
        pstmt.setDate(5, sqlBaseDate);

        rs = pstmt.executeQuery();
%>

<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>滞納管理 - SMART WATER JP</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { box-sizing: border-box; }
    body { font-family: "Meiryo","Hiragino Kaku Gothic ProN",sans-serif; margin:0; background:#f8f9fa; color:#333; }

    /* Navbar */
    .navbar { height:56px; background:#243646; display:flex; align-items:center; padding:0 22px; gap:26px; }
    .navbar-brand { display:flex; align-items:center; gap:8px; font-weight:800; font-size:16px; color:#2aa3ff; text-decoration:none; white-space:nowrap; }
    .nav-links { list-style:none; display:flex; align-items:center; gap:18px; margin:0; padding:0; }
    .nav-links a { color:#cbd5e1; text-decoration:none; font-size:13px; font-weight:600; padding:18px 6px 14px; border-bottom:2px solid transparent; white-space:nowrap; }
    .nav-links a:hover { color:#fff; }
    .nav-links a.active { color:#fff; border-bottom-color:#2aa3ff; }

    /* Admin Area */
    .admin-area { margin-left:auto; display:flex; align-items:center; gap:10px; }
    .admin-text { display:flex; flex-direction:column; align-items:flex-end; line-height:1.1; white-space:nowrap; }
    .admin-name { font-size:12px; font-weight:700; color:#e5edf5; }
    .admin-id { font-size:11px; color:#9fb0c3; }
    .admin-icon { width:30px; height:30px; border-radius:50%; background:#fff; display:grid; place-items:center; box-shadow:0 0 0 2px rgba(255,255,255,.35); }
    .admin-icon svg { width:18px; height:18px; opacity:.75; }

    /* Container & Card */
    .main-container { max-width:1200px; margin:26px auto; padding:0 20px; }
    .content-card { background:#fff; border-radius:12px; padding:24px; box-shadow:0 4px 12px rgba(0,0,0,0.05); }
    
    /* 섹션 타이틀 (24px) */
    .section-title { font-size:24px; font-weight:bold; color:#2c3e50; margin-bottom:16px; border-left:5px solid #2aa3ff; padding-left:12px; line-height: 1.2; }

    .search-notice { margin:10px 0 14px; padding:12px 14px; border-radius:10px; background:#f1f6fb; border:1px solid #dbe9f6; font-size:13px; line-height:1.55; }

    .search-box { background:#f1f3f5; padding:18px; border-radius:10px; margin-bottom:20px; display:flex; gap:15px; align-items:flex-end; flex-wrap:wrap; }
    .search-group { display:flex; flex-direction:column; gap:8px; }
    .search-group label { font-weight:bold; font-size:13px; }

    input[type="date"], .btn-search {
      padding:10px 14px;
      border-radius:7px;
      border:1px solid #d9dde3;
      font-size:14px;
      height:40px;
    }
    .btn-search { background:#2aa3ff; color:#fff; cursor:pointer; font-weight:800; border:none; padding: 0 25px; }

    /* 기준 날짜 표시 (22px) */
    .display-base-date { margin: 15px 0 25px; font-size: 22px; font-weight: bold; color: #2aa3ff; display: flex; align-items: center; gap: 8px; }

    /* Table 스타일 (14px 통일) */
    .data-table { width:100%; border-collapse:collapse; margin-top:10px; table-layout: fixed; }
    
    .data-table th { 
      background: #f8f9fa; 
      padding: 14px; 
      border-bottom: 2px solid #dee2e6; 
      color: #495057; 
      font-size: 14px; 
      font-weight: 800; 
      text-align: center; 
    }
    
    .data-table td { 
      padding: 14px; 
      border-bottom: 1px solid #eee; 
      text-align: center; 
      font-size: 14px; 
      font-weight: normal; 
      color: #333;
      overflow: hidden; 
      text-overflow: ellipsis; 
      white-space: nowrap; 
    }
    
    /* 이름 컬럼: 왼쪽 정렬 (볼드 제거) */
    .name-col { text-align: left !important; padding-left: 25px !important; font-weight: normal !important; }
    
    /* 금액 컬럼: 오른쪽 정렬 (볼드 제거) */
    .amount-text { text-align: right !important; padding-right: 30px !important; font-weight: normal !important; }
    
    .date-badge { background: #f1f6fb; color: #2aa3ff; padding: 4px 10px; border-radius: 6px; font-size: 13px; font-weight: bold; border: 1px solid #dbe9f6; }
  </style>
</head>

<body>

  <nav class="navbar">
    <a href="main.jsp" class="navbar-brand">💧 SMART WATER JP</a>
    <ul class="nav-links">
      <li><a href="customer_list.jsp">顧客一覧</a></li>
      <li><a href="district_manage.jsp">管轄区域管理</a></li>
      <li><a href="overdue_list.jsp" class="active">滞納管理</a></li>
      <li><a href="deposit_list.jsp">入금管理</a></li>
      <li><a href="billing_list.jsp">請求管理</a></li>
    </ul>

    <div class="admin-area">
      <div class="admin-text">
        <div class="admin-name"><%= adminName %> 様</div>
        <div class="admin-id">社員番号 <%= sessionAdminId %></div>
      </div>
      <div class="admin-icon">
        <svg viewBox="0 0 24 24" fill="none">
          <path d="M12 12c2.76 0 5-2.46 5-5.5S14.76 1 12 1 7 3.46 7 6.5 9.24 12 12 12Z" stroke="#111827" stroke-width="1.6"/>
          <path d="M3 23c0-4.2 4-7.6 9-7.6s9 3.4 9 7.6" stroke="#111827" stroke-width="1.6" stroke-linecap="round"/>
        </svg>
      </div>
    </div>
  </nav>

  <div class="main-container">
    <div class="content-card">
      <div class="section-title">📍 滞納顧客の現状</div>

      <div class="search-notice">
        ※ 基準日を選択すると、その時点での滞納情報を確認できます。<br>
        ※ 未納期間は支払期限が過ぎた最も古い請求日を基準に表示されます.
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
            <td><span class="date-badge"><%= oldestDate %> 〜</span></td>
            <td class="amount-text">¥<%= String.format("%,d", overdueAmount) %></td>
          </tr>
          <% } 
             if(!hasData) { %>
          <tr>
            <td colspan="3" style="padding: 60px; color: #9ca3af; text-align: center;">該当する滞納データはありません。</td>
          </tr>
          <% } %>
        </tbody>
      </table>
    </div>
  </div>

</body>
</html>

<%
    } catch (Exception e) {
        out.println("<div style='color:red; text-align:center; padding:20px;'>エラー 발생: " + e.getMessage() + "</div>");
    } finally {
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (conn != null) try { conn.close(); } catch(Exception e) {}
    }
%>