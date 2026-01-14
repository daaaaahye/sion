<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.util.Random" %>
<%
    String sessionAdminId = (String) session.getAttribute("adminId");
    if (sessionAdminId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String adminName = (String) session.getAttribute("adminName"); 
    if (adminName == null) adminName = "관리자"; 

    request.setCharacterEncoding("UTF-8");
    String searchName = request.getParameter("searchName");
    if (searchName == null) searchName = "";

    Connection conn = null;
    DecimalFormat df = new DecimalFormat("¥###,###");
    Random rnd = new Random(); 

    
    try {
        Class.forName("org.postgresql.Driver");
        conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");

        String sqlAdmin = "SELECT name FROM admins WHERE emp_id = ?";
        PreparedStatement pstmtAdmin = conn.prepareStatement(sqlAdmin);
        pstmtAdmin.setString(1, sessionAdminId);
        ResultSet rsAdmin = pstmtAdmin.executeQuery();
        
        if(rsAdmin.next()) { 
            adminName = rsAdmin.getString("name"); 
            session.setAttribute("adminName", adminName); 
        }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>고객관리 - SMART WATER</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: "Malgun Gothic", sans-serif; margin: 0; background-color: #f8f9fa; }
        .navbar { background-color: #2c3e50; color: white; height: 60px; display: flex; align-items: center; padding: 0 30px; }
        .navbar-brand { font-size: 18px; font-weight: bold; color: #3498db; text-decoration: none; margin-right: 40px; }
        .nav-links { list-style: none; display: flex; gap: 20px; margin: 0; padding: 0; }
        .nav-links li a { color: #bdc3c7; text-decoration: none; font-size: 14px; font-weight: 500; }
        .nav-links li a.active { color: white; border-bottom: 2px solid #3498db; padding-bottom: 5px; }
        .admin-area { padding: 0 30px; margin-left: auto; display: flex; align-items: center; gap: 10px; }
        .admin-text { display: flex; flex-direction: column; text-align: right; font-size: 12px; color: #bdc3c7; }
        .admin-name { font-weight: bold; color: white; }
        .admin-icon { width: 32px; height: 32px; border-radius: 50%; background: #fff; display: grid; place-items: center; box-shadow: 0 0 0 2px rgba(255,255,255,.2); }
        .admin-icon svg { width: 20px; height: 20px; }
        .btn-logout { color: #e74c3c; text-decoration: none; font-size: 12px; margin-left: 15px; border: 1px solid #e74c3c; padding: 2px 8px; border-radius: 4px; font-weight: bold; }
        
        .search-box { background: #f1f3f5; padding: 18px; border-radius: 10px; margin: 16px auto; display: flex; gap: 12px; align-items: flex-end; justify-content: center; width: 100%; max-width: 700px; }   
        input[type="text"] { padding: 10px 14px; border-radius: 7px; border: 1px solid #d9dde3; width: 250px; }
        .btn-search { background: #3498db; color: white; border: none; height: 40px; padding: 0 20px; border-radius: 7px; cursor: pointer; font-weight: bold; }
        .btn-reset { background: #eee; padding: 0 20px; border-radius: 7px; border: 1px solid #ddd; height: 40px; cursor: pointer; color: #333; text-decoration: none; line-height: 40px; font-size: 14px; }
        
        .main-container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
        .content-card { background: white; border-radius: 10px; padding: 25px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); }
        .list-table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        .list-table th { background: #f8f9fa; padding: 12px; text-align: left; border-bottom: 2px solid #dee2e6; color: #495057; }
        .list-table td { padding: 12px; border-bottom: 1px solid #eee; }
        .name-link { color: #3498db; text-decoration: none; font-weight: bold; }
        .usage-badge { background: #e8f4fd; color: #2980b9; padding: 4px 8px; border-radius: 4px; font-size: 12px; }
    </style>
</head>
<body>
    <nav class="navbar">
        <a href="main.jsp" class="navbar-brand">💧 SMART WATER</a>
        <ul class="nav-links">
            <li><a href="customer_list.jsp" class="active">고객 리스트</a></li>
            <li><a href="district_manage.jsp">관할 구역 관리</a></li>
            <li><a href="overdue_list.jsp">연체 관리</a></li>
            <li><a href="#">입금 관리</a></li>
            <li><a href="#">청구 관리</a></li>
        </ul>
        <div class="admin-area">
            <div class="admin-text">
                <div class="admin-name"><%= adminName %> 님</div>
                <div class="admin-id">사원번호 <%= sessionAdminId %></div>
            </div>
            <div class="admin-icon">
                <svg viewBox="0 0 24 24" fill="none"><path d="M12 12c2.76 0 5-2.46 5-5.5S14.76 1 12 1 7 3.46 7 6.5 9.24 12 12 12Z" stroke="#111827" stroke-width="1.6"/><path d="M3 23c0-4.2 4-7.6 9-7.6s9 3.4 9 7.6" stroke="#111827" stroke-width="1.6" stroke-linecap="round"/></svg>
            </div>
            <a href="logout.jsp" class="btn-logout">로그아웃</a>
        </div>
    </nav>

    <div class="main-container">
        <div class="content-card">
            <h2>👥 顧客管理リスト</h2>
            <form class="search-box" action="customer_list.jsp" method="get">
                <input type="text" name="searchName" value="<%= searchName %>" placeholder="お客様名を入力してください">
                <button type="submit" class="btn-search">検索</button>
                <a href="customer_list.jsp" class="btn-reset">クリア</a>
            </form>
            <table class="list-table">
                <thead><tr><th>お名前</th><th>ご住所</th><th>今月ご使用量</th></tr></thead>
                <tbody>
                <%
                    String sqlCust = "SELECT customer_id, name, address FROM customers";
                    if (!searchName.isEmpty()) sqlCust += " WHERE name LIKE ? ORDER BY name ASC";
                    else sqlCust += " ORDER BY name ASC";
                    
                    PreparedStatement pstmtCust = conn.prepareStatement(sqlCust);
                    if (!searchName.isEmpty()) pstmtCust.setString(1, "%" + searchName + "%");
                    ResultSet rs = pstmtCust.executeQuery();
                    
                    while(rs.next()) {
                %>
                    <tr>
                        <td><a href="customer_detail.jsp?customer_id=<%= rs.getString("customer_id") %>" class="name-link"><%= rs.getString("name") %> 様</a></td>
                        <td><%= rs.getString("address") %></td>
                        <td><span class="usage-badge"><%= rnd.nextInt(141) + 10 %> m³</span></td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
<% } catch (Exception e) { e.printStackTrace(); } finally { if(conn != null) conn.close(); } %>