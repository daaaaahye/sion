<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%
    String sessionAdminId = (String) session.getAttribute("adminId");
    String adminName = (String) session.getAttribute("adminName");
    String customerId = request.getParameter("customer_id");

    if (sessionAdminId == null) { response.sendRedirect("login.jsp"); return; }
    if (adminName == null) adminName = "관리자";
    if (customerId == null) customerId = "B02201"; 

    Connection connRoot = null;
    Connection connWsms = null;
    DecimalFormat df = new DecimalFormat("#,###");
    
    try {
        Class.forName("org.postgresql.Driver");
        connRoot = DriverManager.getConnection("jdbc:postgresql://localhost:5432/root", "postgres", "1234");
        connWsms = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");
        
        String sqlAdmin = "SELECT name FROM \"Administrator\" WHERE id = ?"; 
        PreparedStatement pstmtAdmin = connRoot.prepareStatement(sqlAdmin);
        pstmtAdmin.setString(1, sessionAdminId);
        ResultSet rsAdmin = pstmtAdmin.executeQuery();
        if(rsAdmin.next()) { 
            adminName = rsAdmin.getString("name"); 
            session.setAttribute("adminName", adminName); 
        }

        String sql = "SELECT c.name, c.tel, c.address, " +
                     " (SELECT bill_amount FROM public.bill WHERE customer_id = ? ORDER BY billing_date DESC LIMIT 1) as monthly_bill, " +
                     " (SELECT COALESCE(SUM(bill_amount), 0) FROM public.bill WHERE customer_id = ?) as total_billed, " +
                     " (SELECT COALESCE(SUM(paid_amount), 0) FROM public.deposit WHERE customer_id = ?) as total_paid " +
                     "FROM public.customers c WHERE c.customer_id = ?";
                     
        PreparedStatement pstmt = connWsms.prepareStatement(sql);
        pstmt.setString(1, customerId);
        pstmt.setString(2, customerId);
        pstmt.setString(3, customerId);
        pstmt.setString(4, customerId);
        ResultSet rs = pstmt.executeQuery();
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>상수도 요금 청구서 - SMART WATER</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: "Malgun Gothic", sans-serif; margin: 0; background-color: #f8f9fa; color: #333; }
        
        /* 네비게이션 바 스타일 */
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

        /* 컨테이너 레이아웃 수정 */
        .main-container { 
            padding: 80px 20px; /* 상단 여백을 넓혀서 카드를 밑으로 내림 */
            display: flex; 
            flex-direction: column; 
            align-items: center; 
            min-height: calc(100vh - 60px); 
        }
        
        /* 카드와 버튼을 감싸는 wrapper (상대 좌표 기준) */
        .bill-wrapper {
            position: relative;
            width: 100%;
            max-width: 700px;
        }

        /* 프린트 버튼 영역 스타일 수정 */
        .btn-print-area { 
            position: absolute;
            top: -50px; /* 카드 위쪽으로 50px 이동 */
            right: 0;   /* 카드의 오른쪽 끝에 맞춤 */
        }
        
        .btn-print { 
            background-color: #3498db; color: white; border: none; padding: 10px 20px; 
            border-radius: 7px; cursor: pointer; font-size: 14px; font-weight: bold;
            display: flex; align-items: center; gap: 8px; transition: background 0.2s;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .btn-print:hover { background-color: #2980b9; }

        /* 기존 청구서 스타일 유지 */
        .bill-card { 
            width: 100%; 
            background: white; 
            padding: 60px 50px; 
            box-shadow: 0 2px 15px rgba(0,0,0,0.1); 
            border-radius: 10px;
            text-align: center;
        }

        .bill-title { font-size: 32px; font-weight: bold; margin-bottom: 10px; color: #000; letter-spacing: 2px; }
        .bill-date { font-size: 14px; color: #666; margin-bottom: 40px; }
        .bill-divider { border-top: 2px solid #2c3e50; margin-bottom: 30px; }

        .info-table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
        .info-table th, .info-table td { border: 1px solid #dee2e6; padding: 15px; text-align: left; font-size: 15px; }
        .info-table th { background-color: #f8f9fa; width: 30%; font-weight: bold; color: #495057; }
        .info-table td { background-color: #fff; width: 70%; }

        .total-wrapper { text-align: right; margin-top: 20px; padding: 20px; background: #fff5f5; border-radius: 8px; margin-bottom: 40px; }
        .total-label { font-size: 16px; color: #444; margin-right: 10px; }
        .total-text { font-size: 26px; font-weight: bold; color: #e74c3c; }

        .footer-notice { text-align: left; font-weight: bold; font-size: 13px; color: #777; line-height: 1.8; border-top: 1px dashed #ccc; padding-top: 20px; }

        @media print {
            body { background: white; }
            .navbar, .btn-print-area { display: none; }
            .main-container { padding: 0; }
            .bill-card { box-shadow: none; border: 1px solid #eee; padding: 0; width: 100%; }
        }
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
        <% 
            if(rs.next()) { 
                long monthlyBill = rs.getLong("monthly_bill"); 
                long totalBilled = rs.getLong("total_billed");
                long totalPaid = rs.getLong("total_paid");
                long overdueAmount = (totalBilled - totalPaid) - monthlyBill;
                if(overdueAmount < 0) overdueAmount = 0;
                long finalTotal = monthlyBill + overdueAmount;
        %>
            <div class="bill-wrapper">
                <div class="btn-print-area">
                    <button class="btn-print" onclick="window.print()">
                        🖨️ 請求書を印刷
                    </button>
                </div>

                <div class="bill-card">
                    <div class="bill-title">水道料金の請求書</div>
                    <div class="bill-date">発行日: 2026年 1月 14日</div>
                    
                    <div class="bill-divider"></div>

                    <table class="info-table">
                        <tr>
                            <th>お名前</th>
                            <td><%= rs.getString("name") %> 様</td>
                        </tr>
                        <tr>
                            <th>お客様番号 (ID)</th>
                            <td><%= customerId %></td>
                        </tr>
                        <tr>
                            <th>ご住所</th>
                            <td><%= rs.getString("address") %></td>
                        </tr>
                        <tr>
                            <th>今月分のご請求額</th>
                            <td><%= df.format(monthlyBill) %>円</td>
                        </tr>
                        <tr>
                            <th>未払金額</th>
                            <td><%= df.format(overdueAmount) %>円</td>
                        </tr>
                    </table>

                    <div class="total-wrapper">
                        <span class="total-label">お支払い合計額</span>
                        <span class="total-text"><%= df.format(finalTotal) %>円</span>
                    </div>

                    <div class="footer-notice">
                        * お振込先: 三菱UFJ銀行 110-123-456789 (smart water)<br>
                        * お問い合わせ: 02-120 (水道お客さまセンター)
                    </div>
                </div>
            </div>
        <% 
            } else { 
        %>
            <div class="bill-card">
                <h3 style="color:#e74c3c;">お客様情報が見つかりません</h3>
                <p>입력된 고객 ID: <strong><%= customerId %></strong></p>
                <a href="customer_list.jsp" style="color:#3498db;">リストに戻る</a>
            </div>
        <% } %>
    </div>
</body>
</html>
<% 
    } catch(Exception e) { e.printStackTrace(); } 
    finally { 
        if(connRoot != null) connRoot.close(); 
        if(connWsms != null) connWsms.close(); 
    }
%>