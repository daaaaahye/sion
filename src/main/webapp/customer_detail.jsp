<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%
    // 1. 세션 및 파라미터 체크
    String sessionAdminId = (String) session.getAttribute("adminId");
    String adminName = (String) session.getAttribute("adminName");
    String customerId = request.getParameter("customer_id");

    if (sessionAdminId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    if (adminName == null) adminName = "관리자";

    if (customerId == null || customerId.isEmpty()) {
        out.println("<script>alert('잘못된 접근입니다.'); location.href='customer_list.jsp';</script>");
        return;
    }

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    DecimalFormat df = new DecimalFormat("#,###");

    String name = "";
    String phone = ""; 
    String address = "";
    long unpaidAmount = 0;   // 금액이 클 수 있으므로 long 권장
    int overdueMonths = 0;  

    try {
        Class.forName("org.postgresql.Driver");
        conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");

        // [수정] 1. 관리자 이름 최신화
        String sqlAdmin = "SELECT name FROM public.admins WHERE emp_id = ?";
        pstmt = conn.prepareStatement(sqlAdmin);
        pstmt.setString(1, sessionAdminId);
        rs = pstmt.executeQuery();
        if(rs.next()) { 
            adminName = rs.getString("name"); 
            session.setAttribute("adminName", adminName); 
        }
        if (rs != null) rs.close();
        if (pstmt != null) pstmt.close();

        // [수정] 2. 고객 정보 및 미납금 계산 쿼리
        // bill_id 에러를 방지하기 위해 COUNT(*) 사용, phone 대신 tel 사용
        String sql = "SELECT c.name, c.tel, c.address, " +
                     "       COALESCE(SUM(b.bill_amount), 0) as total_unpaid, " +
                     "       COUNT(b.customer_id) as total_months " +
                     "FROM public.customers c " +
                     "LEFT JOIN public.bill b ON c.customer_id = b.customer_id " +
                     "WHERE c.customer_id = ? " +
                     "GROUP BY c.name, c.tel, c.address";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, customerId); // 파라미터 설정 (Parameter 1)
        rs = pstmt.executeQuery();

        if (rs.next()) {
            name = rs.getString("name");
            phone = rs.getString("tel"); // DB 컬럼명이 tel인 경우
            address = rs.getString("address");
            unpaidAmount = rs.getLong("total_unpaid"); 
            overdueMonths = rs.getInt("total_months");
        } else {
            out.println("<script>alert('해당 고객을 찾을 수 없습니다.'); location.href='customer_list.jsp';</script>");
            return;
        }

    } catch (Exception e) {
        e.printStackTrace();
        out.println("에러 발생: " + e.getMessage());
    } finally {
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (conn != null) try { conn.close(); } catch(Exception e) {}
    }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>고객 상세 정보 - SMART WATER</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: "Malgun Gothic", sans-serif; margin: 0; background-color: #f8f9fa; color: #333; }
        .navbar { background-color: #2c3e50; color: white; height: 60px; display: flex; align-items: center; padding: 0 30px; }
        .navbar-brand { font-size: 18px; font-weight: bold; color: #3498db; text-decoration: none; margin-right: 40px; }
        .nav-links { list-style: none; display: flex; gap: 20px; margin: 0; padding: 0; }
        .nav-links li a { color: #bdc3c7; text-decoration: none; font-size: 14px; }
        .nav-links li a.active { color: white; border-bottom: 2px solid #3498db; padding-bottom: 5px; }
        .admin-area { padding: 0 30px; margin-left: auto; display: flex; align-items: center; gap: 10px; }
        .admin-text { text-align: right; font-size: 12px; color: #bdc3c7; }
        .admin-name { font-weight: bold; color: white; }
        .btn-logout { color: #e74c3c; text-decoration: none; font-size: 12px; margin-left: 15px; border: 1px solid #e74c3c; padding: 2px 8px; border-radius: 4px; }
        
        .main-container { max-width: 850px; margin: 40px auto; background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        .detail-header { border-bottom: 2px solid #3498db; padding-bottom: 15px; margin-bottom: 30px; }
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .info-item { padding: 18px; background: #fafafa; border: 1px solid #eee; border-radius: 8px; }
        .info-label { font-size: 13px; color: #7f8c8d; margin-bottom: 8px; font-weight: bold; }
        .info-value { font-size: 19px; font-weight: bold; color: #2c3e50; }
        .btn-group { margin-top: 40px; display: flex; justify-content: space-between; }
        .btn-back { padding: 12px 25px; background: #95a5a6; color: white; text-decoration: none; border-radius: 6px; }
        .btn-primary { padding: 12px 25px; background: #3498db; color: white; text-decoration: none; border-radius: 6px; }
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
            <a href="logout.jsp" class="btn-logout">로그아웃</a>
        </div>
    </nav>

    <div class="main-container">
        <div class="detail-header">
            <h2>お客様詳細情報</h2>
        </div>

        <div class="info-grid">
            <div class="info-item">
                <div class="info-label">お客様名</div>
                <div class="info-value"><%= name %> 様</div>
            </div>
            <div class="info-item">
                <div class="info-label">電話番号</div>
                <div class="info-value"><%= (phone != null) ? phone : "정보 없음" %></div>
            </div>
            <div class="info-item" style="grid-column: span 2;">
                <div class="info-label">設置場所住所</div>
                <div class="info-value"><%= address %></div>
            </div>
            <div class="info-item">
                <div class="info-label">未払金額</div>
                <div class="info-value">₩<%= df.format(unpaidAmount) %></div>
            </div>
            <div class="info-item">
                <div class="info-label">滞納期間</div>
                <div class="info-value"><%= overdueMonths %>ヶ月</div>
            </div>
        </div>

        <div class="btn-group">
            <a href="customer_list.jsp" class="btn-back">← 顧客リストへ戻る</a>
            <a href="billing.jsp?customer_id=<%= customerId %>" class="btn-primary">請求書を見る</a>
        </div>
    </div>
</body>
</html>