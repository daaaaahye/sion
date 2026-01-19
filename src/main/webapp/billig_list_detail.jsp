<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%
    // billing_list에서 파라미터, 세션 데이터 가져오기
    String sessionAdminId = (String) session.getAttribute("adminId");
    String adminName = (String) session.getAttribute("adminName");
    
    // billing_list에서 가져온 파라미터 저장
    String customerId = request.getParameter("customer_id");
    String billingDate = request.getParameter("billing_date"); 

    // 로그인 확인 - 보안
    if (sessionAdminId == null) { 
        response.sendRedirect("login.jsp"); 
        return; 
    }
    
    // 기본값 설정
    if (adminName == null) adminName = "관리자";
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
%>
<%  
    try {
        Class.forName("org.postgresql.Driver");
        connRoot = DriverManager.getConnection("jdbc:postgresql://localhost:5432/root", "postgres", "1234");
        connWsms = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");
        
        // 관리자 이름 조회
        String sqlAdmin = "SELECT name FROM \"Administrator\" WHERE id = ?"; 
        PreparedStatement pstmtAdmin = connRoot.prepareStatement(sqlAdmin);
        pstmtAdmin.setString(1, sessionAdminId);
        ResultSet rsAdmin = pstmtAdmin.executeQuery();
        if(rsAdmin.next()) { 
            adminName = rsAdmin.getString("name"); 
            session.setAttribute("adminName", adminName); 
        }
        rsAdmin.close();
        pstmtAdmin.close();

        // 고객 및 청구 정보 조회 (선택된 날짜 기준)
        String sql = "SELECT c.name, c.tel, c.address, " + // 고객 이름, 전화번호, 주소 조회
                     " (SELECT bill_amount FROM public.bill WHERE customer_id = ? " +
        			 " AND billing_date = ?) as monthly_bill, " + //선택 고객의 해당 청구월 요금
                     " (SELECT COALESCE(SUM(bill_amount), 0) FROM public.bill WHERE customer_id = ? " +
        			 " AND billing_date <= ?) as total_billed, " + // 선택 고객의 현재까지의 청구액
                     " (SELECT COALESCE(SUM(paid_amount), 0) FROM public.deposit WHERE customer_id = ? " +
        			 " AND paid_at <= ?) as total_paid " + // 선택 고객의 현재까지의 납부액
                     " FROM public.customers c WHERE c.customer_id = ?"; // billing_list에서 선택한 고객 조회
       
       
       // 불러온 날짜 재확인 코드
       String datesql = " SELECT 1 " +
       					" FROM public.bill " +
    		   			" WHERE customer_id = ? AND billing_date = ? ";         

                     
       

       // 선택 날짜 존재 여부 확인
       String checkSql =
           "SELECT 1 FROM bill WHERE customer_id=? AND billing_date=?";
       PreparedStatement chkPstmt = connWsms.prepareStatement(checkSql);
       chkPstmt.setString(1, customerId);
       chkPstmt.setDate(2, java.sql.Date.valueOf(billingDate));
       ResultSet chkRs = chkPstmt.executeQuery();

       if (!chkRs.next()) {
           //해당 날짜 없는 경우
           noBillingDate = true;
           chkRs.close();
           chkPstmt.close();
       }

       chkRs.close();
       chkPstmt.close();

        pstmt = connWsms.prepareStatement(sql);
        
        // JSP 매칭
        pstmt.setString(1, customerId);
        pstmt.setDate(2, java.sql.Date.valueOf(billingDate));
        pstmt.setString(3, customerId);
        pstmt.setDate(4, java.sql.Date.valueOf(billingDate));
        pstmt.setString(5, customerId);
        pstmt.setDate(6, java.sql.Date.valueOf(billingDate));
        pstmt.setString(7, customerId);
        
        rs = pstmt.executeQuery();
        
        if(rs.next()) { 
        	monthlyBill = rs.getObject("monthly_bill", Long.class);
        	totalBilled = rs.getLong("total_billed");
        	totalPaid = rs.getLong("total_paid");
        	
        	if (monthlyBill == null){
        		
        	}
        }else{
            noBillingDate = true;
        }
    }catch (Exception e){
    	e.printStackTrace();
    	System.out.println("에러 발생 : " + e.getMessage());
    	return;
    }

        
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>상수도 요금 청구서 - SMART WATER</title>
    <link rel="stylesheet" href="css/billing.css">
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
                <div class="admin-name"><%= adminName %>様</div>
                <div class="admin-id">사원번호 <%= sessionAdminId %></div>
            </div>
            <div class="admin-icon">
                <svg viewBox="0 0 24 24" fill="none"><path d="M12 12c2.76 0 5-2.46 5-5.5S14.76 1 12 1 7 3.46 7 6.5 9.24 12 12 12Z" stroke="#111827" stroke-width="1.6"/><path d="M3 23c0-4.2 4-7.6 9-7.6s9 3.4 9 7.6" stroke="#111827" stroke-width="1.6" stroke-linecap="round"/></svg>
            </div>
            <a href="logout.jsp" class="btn-logout">로그아웃</a>
        </div>
    </nav>

    <div class="main-container">
    	<% if (noBillingDate){ %>
    		<div class ="error">
    			<h2> 📅 선택한 날짜의 고지서가 없습니다</h2>
    			<p> 선택한 청구일 : <%= billingDate %></p>
    			<button class ="back" onclick="history.back()">이전 페이지로</button>
    		</div>
    	<% } else {
    		long overdueAmount = (totalBilled = totalPaid) - monthlyBill;
    		if (overdueAmount <0 ) overdueAmount = 0;
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
	            <% } %>
	            </div>
	       
    </div>
</body>
</html>
<%
	if (rs != null) rs.close();
	if (pstmt != null) pstmt.close();
	if (connRoot != null) connRoot.close();
	if (connWsms != null) connWsms.close();
%>