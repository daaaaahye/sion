<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%
    String sessionAdminId = (String) session.getAttribute("adminId");
    String adminName = (String) session.getAttribute("adminName");
    String customerId = request.getParameter("customer_id");

    if (sessionAdminId == null) { response.sendRedirect("login.jsp"); return; }
    if (adminName == null) adminName = "관리자";
    if (customerId == null) customerId = "C001";

    Connection conn = null;
    DecimalFormat df = new DecimalFormat("#,###");
    
    try {
        Class.forName("org.postgresql.Driver");
        conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");
        
        String sql = "SELECT c.name, c.tel, c.address, COALESCE(SUM(b.bill_amount), 0) as total_bill " +
                     "FROM public.customers c LEFT JOIN public.bill b ON c.customer_id = b.customer_id " +
                     "WHERE c.customer_id = ? GROUP BY c.name, c.tel, c.address";
        PreparedStatement pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, customerId);
        ResultSet rs = pstmt.executeQuery();
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>청구서 발행 - SMART WATER</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: 'Malgun Gothic', sans-serif; margin: 0; background-color: #f8f9fa; }
        .navbar { background-color: #2c3e50; color: white; height: 60px; display: flex; align-items: center; padding: 0 30px; }
        .navbar-brand { font-size: 18px; font-weight: bold; color: #3498db; text-decoration: none; margin-right: 40px; }
        .nav-links { list-style: none; display: flex; gap: 20px; margin: 0; padding: 0; }
        .nav-links li a { color: #bdc3c7; text-decoration: none; font-size: 14px; font-weight: 500; }
        .nav-links li a.active { color: white; border-bottom: 2px solid #3498db; padding-bottom: 5px; }
        .admin-area { padding: 0 30px; margin-left: auto; display: flex; align-items: center; gap: 10px; }
        .admin-text { display: flex; flex-direction: column; text-align: right; font-size: 12px; color: #bdc3c7; }
        .admin-name { font-weight: bold; color: white; }
        .btn-logout { color: #e74c3c; text-decoration: none; font-size: 12px; margin-left: 15px; border: 1px solid #e74c3c; padding: 2px 8px; border-radius: 4px; font-weight: bold; }
        
        .main-container { padding: 40px 20px; display: flex; flex-direction: column; align-items: center; }
        .bill-paper { width: 100%; max-width: 700px; background: white; padding: 50px; border: 1px solid #ccc; box-shadow: 0 4px 20px rgba(0,0,0,0.1); border-radius: 8px; }
        .bill-header { text-align: center; border-bottom: 2px solid #3498db; padding-bottom: 20px; margin-bottom: 30px; }
        .bill-table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
        .bill-table th, .bill-table td { border: 1px solid #eee; padding: 15px; text-align: left; }
        .bill-table th { background: #fcfcfc; width: 30%; color: #7f8c8d; }
        .total-amount { font-size: 24px; font-weight: bold; color: #e74c3c; text-align: right; }
        .btn-print { margin-top: 30px; padding: 12px 30px; background: #3498db; color: white; border: none; border-radius: 5px; cursor: pointer; font-weight: bold; }

        @media print { .navbar, .btn-print { display: none; } .bill-paper { border: none; box-shadow: none; } }
    </style>
</head>
<body>
    <nav class="navbar">
        <a href="dbtest.jsp" class="navbar-brand">💧 SMART WATER</a>
        <ul class="nav-links">
            <li><a href="customer_list.jsp" class="active">고객 리스트</a></li>
            <li><a href="district_manage.jsp">관할 구역 관리</a></li>
            <li><a href="overdue_list.jsp">연체 관리</a></li>
            <li><a href="#">입금 관리</a></li>
            <li><a href="#">청구 관리</a></li>
        </ul>
        <div class="admin-area">
            <div class="admin-text"><div class="admin-name"><%= adminName %> 님</div><div class="admin-id">사원번호 <%= sessionAdminId %></div></div>
            <a href="logout.jsp" class="btn-logout">로그아웃</a>
        </div>
    </nav>
    <div class="main-container">
        <% if(rs.next()) { long total = rs.getLong("total_bill"); %>
            <div class="bill-paper">
                <div class="bill-header"><h1>상수도 요금 청구서</h1><p>발행일: 2026년 1월 14일</p></div>
                <table class="bill-table">
                    <tr><th>성함</th><td><%= rs.getString("name") %> 様</td></tr>
                    <tr><th>전화번호</th><td><%= rs.getString("tel") %></td></tr>
                    <tr><th>주소</th><td><%= rs.getString("address") %></td></tr>
                    <tr><th>총 청구 금액</th><td>₩<%= df.format(total) %></td></tr>
                </table>
                <div class="total-amount">납부하실 금액: ₩<%= df.format(total) %></div>
            </div>
            <button class="btn-print" onclick="window.print()">🖨️ 청구서 인쇄하기</button>
        <% } %>
    </div>
</body>
</html>
<% } catch(Exception e) { e.printStackTrace(); } finally { if(conn != null) conn.close(); } %>