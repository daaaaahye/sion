<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%
    // 1. 세션 및 파라미터 체크
    String sessionAdminId = (String) session.getAttribute("adminId");
    String sessionAdminName = (String) session.getAttribute("adminName");
    String customerId = request.getParameter("customer_id");

    // 세션이 없으면 로그인 페이지로 이동
    if (sessionAdminId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // 고객 ID가 없으면 리스트로 돌려보냄
    if (customerId == null || customerId.isEmpty()) {
        out.println("<script>alert('不正なアクセスです'); location.href='customer_list.jsp';</script>");
        return;
    }

    Connection connRoot = null; 
    Connection connWsms = null; 
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    DecimalFormat df = new DecimalFormat("#,###");

    String name = "";
    String phone = ""; 
    String address = "";
    long unpaidAmount = 0;   
    int overdueMonths = 0;  

    try {
        // 드라이버 로드 확인
        Class.forName("org.postgresql.Driver");
        
        // 2. DB 연결 (본인의 환경에 맞게 IP/ID/PW 확인 필요)
        connRoot = DriverManager.getConnection("jdbc:postgresql://localhost:5432/root", "postgres", "1234");
        connWsms = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");

        // 3. 관리자 이름 동기화
        String sqlAdmin = "SELECT name FROM \"Administrator\" WHERE id = ?";
        pstmt = connRoot.prepareStatement(sqlAdmin);
        pstmt.setString(1, sessionAdminId);
        rs = pstmt.executeQuery();
        if(rs.next()) { 
            sessionAdminName = rs.getString("name"); 
            session.setAttribute("adminName", sessionAdminName); 
        }
        rs.close(); 
        pstmt.close();

        // 4. 고객 정보 및 미납금 계산
        String sql = "SELECT c.name, c.tel, c.address, " +
                     "       COALESCE(SUM(b.bill_amount), 0) as total_unpaid, " +
                     "       COUNT(b.customer_id) as total_months " +
                     "FROM public.customers c " +
                     "LEFT JOIN public.bill b ON c.customer_id = b.customer_id " +
                     "WHERE c.customer_id = ? " +
                     "GROUP BY c.name, c.tel, c.address";
        
        pstmt = connWsms.prepareStatement(sql);
        pstmt.setString(1, customerId); 
        rs = pstmt.executeQuery();

        if (rs.next()) {
            name = rs.getString("name");
            phone = rs.getString("tel");
            address = rs.getString("address");
            unpaidAmount = rs.getLong("total_unpaid");
            overdueMonths = rs.getInt("total_months");
        } else {
            out.println("<script>alert('該当する顧客が見つかりません (해당 고객을 찾을 수 없습니다).'); location.href='customer_list.jsp';</script>");
            return;
        }
%>
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>顧客詳細情報 - SMART WATER</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: "Meiryo", "Malgun Gothic", sans-serif; margin: 0; background-color: #f8f9fa; color: #333; }
        
        /* 네비바: 좌우 패딩 22px 반영 */
        .navbar { background-color: #2c3e50; color: white; height: 60px; display: flex; align-items: center; padding: 0 22px; }
        .navbar-brand { font-size: 18px; font-weight: bold; color: #3498db; text-decoration: none; margin-right: 40px; }
        .nav-links { list-style: none; display: flex; gap: 20px; margin: 0; padding: 0; }
        .nav-links li a { color: #bdc3c7; text-decoration: none; font-size: 14px; font-weight: 500; }
        .nav-links li a.active { color: white; border-bottom: 2px solid #3498db; padding-bottom: 5px; }
        
        .admin-area { margin-left: auto; display: flex; align-items: center; gap: 10px; }
        .admin-text { display: flex; flex-direction: column; text-align: right; font-size: 12px; color: #bdc3c7; }
        .admin-name { font-weight: bold; color: white; }
        .admin-icon { width: 32px; height: 32px; border-radius: 50%; background: #fff; display: grid; place-items: center; }
        .admin-icon svg { width: 20px; height: 20px; }
        .btn-logout { color: #e74c3c; text-decoration: none; font-size: 12px; margin-left: 15px; border: 1px solid #e74c3c; padding: 2px 8px; border-radius: 4px; font-weight: bold; }

        /* 컨테이너 및 카드: 좌우 체감 여백 45px (20+25) */
        .main-container { max-width: 850px; margin: 40px auto; padding: 0 20px; }
        .content-card { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        
        .detail-header { border-bottom: 2px solid #3498db; padding-bottom: 15px; margin-bottom: 30px; }
        
        /* 페이지 메인 타이틀 폰트 크기: 24px 반영 */
        .detail-header h2 { margin: 0; color: #2c3e50; font-size: 24px; }

        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .info-item { padding: 18px; background: #fafafa; border: 1px solid #eee; border-radius: 8px; }
        .info-label { font-size: 13px; color: #7f8c8d; margin-bottom: 8px; font-weight: bold; }
        .info-value { font-size: 19px; font-weight: bold; color: #2c3e50; }
        
        .btn-group { margin-top: 40px; display: flex; justify-content: space-between; }
        .btn-back { padding: 12px 25px; background: #95a5a6; color: white; text-decoration: none; border-radius: 6px; font-size: 14px; font-weight: bold; }
        .btn-primary { padding: 12px 25px; background: #3498db; color: white; text-decoration: none; border-radius: 6px; font-size: 14px; font-weight: bold; }
    </style>
</head>
<body>
    <nav class="navbar">
        <a href="main.jsp" class="navbar-brand">💧 SMART WATER</a>
        <ul class="nav-links">
            <li><a href="customer_list.jsp" class="active">顧客リスト</a></li>
            <li><a href="district_manage.jsp">管轄区域管理</a></li>
            <li><a href="overdue_list.jsp">滞納管理</a></li>
            <li><a href="deposit.jsp">入金管理</a></li>
            <li><a href="billing_list">請求管理</a></li>
        </ul>
        
        <div class="admin-area">
            <div class="admin-text">
                <div class="admin-name"><%= sessionAdminName %> 様</div>
                <div class="admin-id">社員番号 <%= sessionAdminId %></div>
            </div>
            <div class="admin-icon">
                <svg viewBox="0 0 24 24" fill="none"><path d="M12 12c2.76 0 5-2.46 5-5.5S14.76 1 12 1 7 3.46 7 6.5 9.24 12 12 12Z" stroke="#111827" stroke-width="1.6"/><path d="M3 23c0-4.2 4-7.6 9-7.6s9 3.4 9 7.6" stroke="#111827" stroke-width="1.6" stroke-linecap="round"/></svg>
            </div>
            <a href="logout.jsp" class="btn-logout">ログアウト</a>
        </div>
    </nav>

    <div class="main-container">
        <div class="content-card">
            <div class="detail-header">
                <h2>顧客詳細情報</h2>
            </div>

            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">顧客名</div>
                    <div class="info-value"><%= name %> 様</div>
                </div>
                <div class="info-item">
                    <div class="info-label">電話番号</div>
                    <div class="info-value"><%= (phone != null && !phone.isEmpty()) ? phone : "データなし" %></div>
                </div>
                <div class="info-item" style="grid-column: span 2;">
                    <div class="info-label">設置場所住所</div>
                    <div class="info-value"><%= address %></div>
                </div>
                <div class="info-item">
                    <div class="info-label">未払金額</div>
                    <div class="info-value">¥<%= df.format(unpaidAmount) %></div>
                </div>
                <div class="info-item">
                    <div class="info-label">滞納期間</div>
                    <div class="info-value"><%= overdueMonths %> ヶ月</div>
                </div>
            </div>

            <div class="btn-group">
                <a href="customer_list.jsp" class="btn-back">← 顧客リストへ戻る</a>
                <a href="billing.jsp?customer_id=<%= customerId %>" class="btn-primary">請求書を表示</a>
            </div>
        </div>
    </div>
</body>
</html>
<%
    } catch (Exception e) {
        // 화면에 에러를 직접 출력하여 원인 파악
        out.println("<div style='color:red; background:white; padding:20px; border:2px solid red; margin:20px;'>");
        out.println("<h3>에러가 발생했습니다:</h3>");
        out.println("<p>" + e.getMessage() + "</p>");
        out.println("<pre>");
        e.printStackTrace(new java.io.PrintWriter(out));
        out.println("</pre>");
        out.println("</div>");
    } finally {
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (connRoot != null) try { connRoot.close(); } catch(Exception e) {}
        if (connWsms != null) try { connWsms.close(); } catch(Exception e) {}
    }
%>