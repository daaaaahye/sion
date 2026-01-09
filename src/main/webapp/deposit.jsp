<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%
    // [1. 보안 및 세션 체크]
    String sessionAdminId = (String) session.getAttribute("adminId");
    if (sessionAdminId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // [2. 검색 조건 설정] (요구사항: 미납, 완납, 연체 검색)
    String searchStatus = request.getParameter("status");
    if (searchStatus == null) searchStatus = "all";

    Connection conn = null;
    DecimalFormat df = new DecimalFormat("¥###,###");
    String adminName = "";

    try {
        Class.forName("org.postgresql.Driver");
        conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/mydb", "postgres", "");

        // 관리자 이름 가져오기
        PreparedStatement pstmtAdmin = conn.prepareStatement("SELECT name FROM admins WHERE emp_id = ?");
        pstmtAdmin.setString(1, sessionAdminId);
        ResultSet rsAdmin = pstmtAdmin.executeQuery();
        if(rsAdmin.next()) { adminName = rsAdmin.getString("name"); }
%>
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>入金管理 - SMART WATER KR</title>
    <style>
        body { font-family: "Meiryo", sans-serif; margin: 0; background-color: #f8f9fa; }
        .navbar { background-color: #2c3e50; color: white; height: 60px; display: flex; align-items: center; padding: 0 30px; }
        .navbar-brand { font-size: 18px; font-weight: bold; color: #3498db; text-decoration: none; margin-right: 40px; }
        .nav-links { list-style: none; display: flex; gap: 25px; margin: 0; padding: 0; }
        .nav-links li a { color: #bdc3c7; text-decoration: none; font-size: 14px; font-weight: 500; }
        .nav-links li a.active { color: white; border-bottom: 2px solid #3498db; padding-bottom: 5px; }
        .admin-bar { background: #fff; padding: 8px 30px; border-bottom: 1px solid #ddd; display: flex; justify-content: flex-end; font-size: 12px; color: #666; }
        .main-container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
        .content-card { background: white; border-radius: 10px; padding: 25px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); }
        .search-box { margin-bottom: 20px; background: #f1f3f5; padding: 15px; border-radius: 8px; display: flex; gap: 10px; }
        .list-table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        .list-table th { background: #f8f9fa; padding: 12px; text-align: left; border-bottom: 2px solid #dee2e6; }
        .list-table td { padding: 12px; border-bottom: 1px solid #eee; font-size: 14px; }
        .name-link { color: #3498db; text-decoration: none; font-weight: bold; }
        .badge { padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
    </style>
</head>
<body>
    <nav class="navbar">
        <a href="dbtest.jsp" class="navbar-brand">💧 SMART WATER KR</a>
        <ul class="nav-links">
            <li><a href="dbtest.jsp">ホーム</a></li>
            <li><a href="customer_list.jsp">顧客一覧</a></li>
            <li><a href="overdue_list.jsp">滞納者リスト</a></li>
            <li><a href="district_manage.jsp">管轄区域管理</a></li>
            <li><a href="deposit.jsp">入金管理</a></li>
        </ul>
    </nav>
    <div class="admin-bar">
        <span>로그인 관리자: <b><%= adminName %></b> 님 (사원번호: <%= sessionAdminId %>)</span>
        <a href="logout.jsp" style="margin-left:15px; color:#e74c3c; text-decoration:none;">로그아웃</a>
    </div>

    <div class="main-container">
        <div class="content-card">
            <h2>💰 입금 관리 메뉴</h2>
            
            <form class="search-box" method="get" action="deposit.jsp">
                <select name="status" style="padding:5px;">
                    <option value="all" <%= searchStatus.equals("all") ? "selected" : "" %>>전체 보기</option>
                    <option value="unpaid" <%= searchStatus.equals("unpaid") ? "selected" : "" %>>미납</option>
                    <option value="overdue" <%= searchStatus.equals("overdue") ? "selected" : "" %>>연체</option>
                    <option value="paid" <%= searchStatus.equals("paid") ? "selected" : "" %>>완납</option>
                </select>
                <button type="submit">검색</button>
            </form>

            <table class="list-table">
                <thead>
                    <tr>
                        <th>고객명</th>
                        <th>이번달 사용료</th>
                        <th>미납액</th>
                        <th>입금상태</th>
                        <th>처리</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        // 요구사항: 검색 조건에 따른 쿼리 분기
                        String sql = "SELECT * FROM customers";
                        if(searchStatus.equals("unpaid")) sql += " WHERE overdue_amount > 0 AND overdue_months < 2";
                        else if(searchStatus.equals("overdue")) sql += " WHERE overdue_months >= 2";
                        else if(searchStatus.equals("paid")) sql += " WHERE overdue_amount = 0";
                        sql += " ORDER BY name ASC";

                        Statement stmt = conn.createStatement();
                        ResultSet rs = stmt.executeQuery(sql);
                        while(rs.next()){
                            int overdueAmt = rs.getInt("overdue_amount");
                            int overdueMths = rs.getInt("overdue_months");
                            int currentFee = rs.getInt("usage_amount") * 200; // 이번달 사용료 예시 계산
                    %>
                    <tr>
                        <td>
                            <a href="customer_detail.jsp?meter_id=<%= rs.getString("meter_id") %>" class="name-link">
                                <%= rs.getString("name") %> 님
                            </a>
                        </td>
                        <td><%= df.format(currentFee) %></td>
                        <td><%= df.format(overdueAmt) %></td>
                        <td>
                            <% if(overdueMths >= 2) { %>
                                <span class="badge" style="background:#ffdada; color:#e74c3c;">연체</span>
                            <% } else if(overdueAmt > 0) { %>
                                <span class="badge" style="background:#fff5f5; color:#c0392b;">미납</span>
                            <% } else { %>
                                <span class="badge" style="background:#e8faf0; color:#2ecc71;">완납</span>
                            <% } %>
                        </td>
                        <td>
                            <% if(overdueAmt > 0) { %>
                                <button onclick="location.href='pay_process.jsp?id=<%= rs.getString("meter_id") %>'">입금 확인</button>
                            <% } else { %> - <% } %>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
<%
    } catch (Exception e) { out.println("Error: " + e.getMessage()); } finally { if(conn != null) conn.close(); }
%>