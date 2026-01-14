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
    int unpaidAmount = 0;   
    int overdueMonths = 0;  

    try {
        Class.forName("org.postgresql.Driver");
        conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");

        // 관리자 정보 동기화
        String sqlAdmin = "SELECT name FROM admins WHERE emp_id = ?";
        PreparedStatement pstmtAdmin = conn.prepareStatement(sqlAdmin);
        pstmtAdmin.setString(1, sessionAdminId);
        ResultSet rsAdmin = pstmtAdmin.executeQuery();
        if(rsAdmin.next()) { 
            adminName = rsAdmin.getString("name"); 
            session.setAttribute("adminName", adminName); 
        }

        // 고객 정보 조회
        String sql = "SELECT name, tel, address FROM public.customers WHERE customer_id = ?";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, customerId); 
        
        rs = pstmt.executeQuery();

        if (rs.next()) {
            name = rs.getString("name");
            phone = rs.getString("tel");
            address = rs.getString("address");
        } else {
            out.println("<script>alert('해당 고객을 찾을 수 없습니다.'); location.href='customer_list.jsp';</script>");
            return;
        }

    } catch (Exception e) {
        e.printStackTrace();
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
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>고객 상세 정보 - SMART WATER</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: "Malgun Gothic", sans-serif; margin: 0; background-color: #f8f9fa; color: #333; }
        
        /* 상단바 스타일 */
        .navbar { background-color: #2c3e50; color: white; height: 60px; display: flex; align-items: center; padding: 0 30px; }
        .navbar-brand { font-size: 18px; font-weight: bold; color: #3498db; text-decoration: none; margin-right: 40px; }
        .nav-links { list-style: none; display: flex; gap: 20px; margin: 0; padding: 0; }
        .nav-links li a { color: #bdc3c7; text-decoration: none; font-size: 14px; font-weight: 500; }
        .nav-links li a.active { color: white; border-bottom: 2px solid #3498db; padding-bottom: 5px; }
        
        .admin-area { padding: 0 30px; margin-left: auto; display: flex; align-items: center; gap: 10px; }
        .admin-text { display: flex; flex-direction: column; text-align: right; font-size: 12px; color: #bdc3c7; }
        .admin-name { font-weight: bold; color: white; }
        .admin-id { font-size: 11px; opacity: 0.8; }
        .admin-icon { width: 32px; height: 32px; border-radius: 50%; background: #fff; display: grid; place-items: center; box-shadow: 0 0 0 2px rgba(255,255,255,.2); }
        .admin-icon svg { width: 20px; height: 20px; }
        .btn-logout { color: #e74c3c; text-decoration: none; font-size: 12px; margin-left: 15px; font-weight: bold; border: 1px solid #e74c3c; padding: 2px 8px; border-radius: 4px; }
        .btn-logout:hover { background: #e74c3c; color: white; }

        .main-container { max-width: 850px; margin: 40px auto; background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        .detail-header { border-bottom: 2px solid #3498db; padding-bottom: 15px; margin-bottom: 30px; }
        .detail-header h2 { margin: 0; color: #2c3e50; font-size: 24px; }
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .info-item { padding: 18px; background: #fafafa; border: 1px solid #eee; border-radius: 8px; }
        .info-label { font-size: 13px; color: #7f8c8d; margin-bottom: 8px; font-weight: bold; }
        .info-value { font-size: 19px; font-weight: bold; color: #2c3e50; }
        
        .btn-group { margin-top: 40px; display: flex; justify-content: space-between; }
        .btn-back { padding: 12px 25px; background: #95a5a6; color: white; text-decoration: none; border-radius: 6px; font-size: 14px; }
        .btn-primary { padding: 12px 25px; background: #3498db; color: white; text-decoration: none; border-radius: 6px; font-size: 14px; }
    </style>
</head>
<body>
    <nav class="navbar">
        <%-- [수정 완료] href 주소를 dbtest.jsp로 변경하였습니다. --%>
        <a href="dbtest.jsp" class="navbar-brand">💧 SMART WATER</a>
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
            <div class="admin-icon" title="管理者">
                <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
                    <path d="M12 12c2.76 0 5-2.46 5-5.5S14.76 1 12 1 7 3.46 7 6.5 9.24 12 12 12Z" stroke="#111827" stroke-width="1.6"/>
                    <path d="M3 23c0-4.2 4-7.6 9-7.6s9 3.4 9 7.6" stroke="#111827" stroke-width="1.6" stroke-linecap="round"/>
                </svg>
            </div>
            <a href="logout.jsp" class="btn-logout">로그아웃</a>
        </div>
    </nav>

    <div class="main-container">
        <div class="detail-header">
            <h2>고객 상세 정보</h2>
        </div>

        <div class="info-grid">
            <div class="info-item">
                <div class="info-label">고객명</div>
                <div class="info-value"><%= name %> 様</div>
            </div>
            <div class="info-item">
                <div class="info-label">전화번호</div>
                <div class="info-value"><%= (phone != null) ? phone : "정보 없음" %></div>
            </div>
            <div class="info-item" style="grid-column: span 2;">
                <div class="info-label">설치 주소</div>
                <div class="info-value"><%= address %></div>
            </div>
            <div class="info-item">
                <div class="info-label">미납 금액</div>
                <div class="info-value">₩<%= df.format(unpaidAmount) %></div>
            </div>
            <div class="info-item">
                <div class="info-label">연체 기간</div>
                <div class="info-value"><%= overdueMonths %>개월</div>
            </div>
        </div>

        <div class="btn-group">
            <a href="customer_list.jsp" class="btn-back">← 고객 목록으로 돌아가기</a>
            <a href="billing.jsp?customer_id=<%= customerId %>" class="btn-primary">청구서 조회</a>
        </div>
    </div>
</body>
</html>