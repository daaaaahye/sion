<<<<<<< HEAD
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%
    /**
     * [관리자용 고객 상세 정보 페이지]
     * 작성 목적: 특정 고객의 계량기 정보, 주소, 사용량, 납부 상태 상세 조회
     * 타겟 사용자: 일본 수도국 관리자
     */

    // 1. 세션 체크 (보안)
    String sessionAdminId = (String) session.getAttribute("adminId");
    if (sessionAdminId == null) {
        response.sendRedirect("login.jsp"); // 로그인 안 되어 있으면 튕김
        return;
    }

    // 2. 리스트 페이지에서 넘어온 meter_id 파라미터 수신
    String meterId = request.getParameter("meter_id");
    
    Connection conn = null;
    String adminName = "";
    DecimalFormat df = new DecimalFormat("¥###,###"); // 일본 엔화 콤마 형식

    try {
        Class.forName("org.postgresql.Driver");
        conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/mydb", "postgres", "1234");

        // 3. 접속 중인 관리자 정보 조회 (상단 바 표시용)
        String sqlAdmin = "SELECT name FROM admins WHERE emp_id = ?";
        PreparedStatement pstmtAdmin = conn.prepareStatement(sqlAdmin);
        pstmtAdmin.setString(1, sessionAdminId);
        ResultSet rsAdmin = pstmtAdmin.executeQuery();
        if(rsAdmin.next()) {
            adminName = rsAdmin.getString("name");
        }

        // 4. 해당 meter_id를 가진 고객의 모든 정보 조회
        String sqlCust = "SELECT * FROM customers WHERE meter_id = ?";
        PreparedStatement pstmtCust = conn.prepareStatement(sqlCust);
        pstmtCust.setString(1, meterId);
        ResultSet rs = pstmtCust.executeQuery();

        if (rs.next()) {
            // 조회 결과가 있을 때만 아래 HTML을 렌더링
%>
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= rs.getString("name") %> 様の検針詳細 - SMART WATER JP</title>
    <style>
        /* 기본 폰트: 일본어 환경에서 가장 가독성이 좋은 Meiryo 적용 */
        body { font-family: "Meiryo", "Hiragino Kaku Gothic ProN", sans-serif; margin: 0; background-color: #f4f7f6; color: #333; }
        
        /* 네비게이션 및 바 */
        .navbar { background-color: #2c3e50; color: white; height: 60px; display: flex; align-items: center; padding: 0 30px; }
        .navbar-brand { font-size: 18px; font-weight: bold; color: #3498db; text-decoration: none; }
        .admin-bar { background: #fff; padding: 10px 30px; border-bottom: 1px solid #ddd; text-align: right; font-size: 12px; color: #666; }
        
        /* 메인 컨테이너 */
        .main-container { max-width: 850px; margin: 40px auto; background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        .detail-header { border-bottom: 2px solid #3498db; padding-bottom: 15px; margin-bottom: 30px; display: flex; justify-content: space-between; align-items: flex-end; }
        .detail-header h2 { margin: 0; color: #2c3e50; font-size: 24px; }
        
        /* 정보 레이아웃 (그리드) */
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .info-item { padding: 18px; background: #fafafa; border: 1px solid #eee; border-radius: 8px; }
        .info-label { font-size: 13px; color: #7f8c8d; margin-bottom: 8px; font-weight: bold; }
        .info-value { font-size: 19px; font-weight: bold; color: #2c3e50; }
        
        /* 상태 배지 스타일 */
        .status-badge { padding: 6px 15px; border-radius: 50px; font-size: 13px; font-weight: bold; }
        .status-ok { background: #e8faf0; color: #2ecc71; border: 1px solid #2ecc71; }
        .status-warning { background: #fff5f5; color: #e74c3c; border: 1px solid #e74c3c; }
        
        /* 하단 버튼 */
        .btn-group { margin-top: 40px; display: flex; gap: 15px; }
        .btn-back { padding: 12px 25px; background: #95a5a6; color: white; text-decoration: none; border-radius: 6px; font-size: 14px; transition: 0.2s; }
        .btn-back:hover { background: #7f8c8d; }
        
        code { background: #e9ecef; padding: 2px 6px; border-radius: 4px; font-family: 'Consolas', monospace; color: #e83e8c; }
    </style>
</head>
<body>
    <nav class="navbar">
        <a href="dbtest.jsp" class="navbar-brand">💧 SMART WATER JP</a>
    </nav>
    <div class="admin-bar">
        ログイン中: <b><%= adminName %></b> 様 (社員番号: <%= sessionAdminId %>)
    </div>

    <div class="main-container">
        <div class="detail-header">
            <h2>顧客詳細情報</h2>
            <%-- 연체 금액 존재 여부에 따른 배지 분기 처리 --%>
            <span class="status-badge <%= rs.getInt("overdue_amount") > 0 ? "status-warning" : "status-ok" %>">
                <%= rs.getInt("overdue_amount") > 0 ? "⚠️ 滞納あり" : "✅ 正常稼働中" %>
            </span>
        </div>

        <div class="info-grid">
            <div class="info-item">
                <div class="info-label">氏名 (お名前)</div>
                <div class="info-value"><%= rs.getString("name") %> 様</div>
            </div>
            <div class="info-item">
                <div class="info-label">メーター固有番号</div>
                <div class="info-value"><code><%= rs.getString("meter_id") %></code></div>
            </div>
            <div class="info-item" style="grid-column: span 2;">
                <div class="info-label">設置住所</div>
                <div class="info-value"><%= rs.getString("address") %></div>
            </div>
            <div class="info-item">
                <div class="info-label">当月使用量</div>
                <div class="info-value"><%= String.format("%,d", rs.getInt("usage_amount")) %> m³</div>
            </div>
            <div class="info-item">
                <div class="info-label">未納金額 (税込)</div>
                <div class="info-value" style="color: <%= rs.getInt("overdue_amount") > 0 ? "#e74c3c" : "#2c3e50" %>">
                    <%= df.format(rs.getInt("overdue_amount")) %>
                </div>
            </div>
            
            <%-- 체납 개월 수가 0보다 클 때만 섹션 노출 --%>
            <% if(rs.getInt("overdue_months") > 0) { %>
            <div class="info-item" style="grid-column: span 2; border-left: 5px solid #e74c3c; background-color: #fff9f9;">
                <div class="info-label">滞납期間</div>
                <div class="info-value"><%= rs.getInt("overdue_months") %> ヶ月</div>
            </div>
            <% } %>
        </div>

        <div class="btn-group">
            <a href="customer_list.jsp" class="btn-back">← 顧客一覧に戻る</a>
        </div>
    </div>
</body>
</html>
<%
        } else {
            // DB에 데이터가 없는 경우 (잘못된 meter_id 접근)
            out.println("<script>alert('該当する顧客データが見つかりません。'); history.back();</script>");
        }
    } catch (Exception e) {
        // DB 연결 실패 등 예외 처리
        out.println("<div style='text-align:center; padding:50px; color:red;'>システムエラー: " + e.getMessage() + "</div>");
    } finally {
        if(conn != null) conn.close();
    }
%>
=======
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
        Class.forName("org.postgresql.Driver");

        // 2. DB 연결
        connRoot = DriverManager.getConnection("jdbc:postgresql://localhost:5432/root", "postgres", "1234");
        connWsms = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");

        // 3. 관리자 이름 동기화
        String sqlAdmin = "SELECT name FROM \"Administrator\" WHERE id = ?";
        pstmt = connRoot.prepareStatement(sqlAdmin);
        pstmt.setString(1, sessionAdminId);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            sessionAdminName = rs.getString("name");
            session.setAttribute("adminName", sessionAdminName);
        }
        rs.close();
        pstmt.close();

        // 4. 고객 정보 및 미납금 계산
        String sql =
            "SELECT c.name, c.tel, c.address, " +
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
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <style>
        * { box-sizing: border-box; }
        body{
          margin:0;
          font-family: system-ui, -apple-system, Segoe UI, Roboto, "Noto Sans KR", Arial, sans-serif;
          background:#f5f6f8;
          color:#111827;
        }

        /* ===============================
           ✅ TOP NAVBAR (통일본)
           =============================== */
        .navbar{
          height:56px;
          background:#243646;
          display:flex;
          align-items:center;
          padding:0 22px;
          gap:26px;
          position:relative;
          flex-wrap: nowrap;
        }

        .navbar-brand{
          font-weight:800;
          font-size:16px;
          color:#2aa3ff;
          text-decoration:none;
          white-space:nowrap;

          display:inline-flex;
          align-items:center;
          gap:8px;
          flex:0 0 auto;
        }

        .nav-links{
          list-style:none;
          display:flex;
          align-items: stretch;
          gap:22px;
          margin:0;
          padding:0;
          position:relative;

          flex-wrap: nowrap;
          white-space: nowrap;
          min-width: 0;
          overflow-x: auto;
          overflow-y: hidden;
          scrollbar-width: none;
        }
        .nav-links::-webkit-scrollbar { display:none; }

        .nav-links li{
          display:flex;
          align-items:center;
          flex:0 0 auto;
        }

        .nav-links a{
          color:#cbd5e1;
          text-decoration:none;
          font-size:13px;
          font-weight:600;
          white-space:nowrap;
          position:relative;

          height:56px;
          display:flex;
          align-items:center;
          padding:0 4px;
          line-height:1;
        }

        .nav-links a:hover{ color:#ffffff; }

        /* ✅ 현재 페이지 밑줄(통일 규칙) */
        .nav-links a.is-active::after{
          content:"";
          position:absolute;
          left:0;
          bottom:10px;
          width:100%;
          height:2px;
          background:#2aa3ff;
          border-radius:2px;
        }

        /* ===============================
           ✅ ADMIN (통일본 + dropdown)
           =============================== */
        .admin-area{
          margin-left:auto;
          position:relative;
          display:flex;
          align-items:center;
          gap:10px;
          flex:0 0 auto;
        }

        .admin-text{
          display:flex;
          flex-direction:column;
          align-items:flex-end;
          line-height:1.2;
          margin:0;
          transform:none;
          white-space:nowrap;
        }

        .admin-name{
          font-size:12px;
          font-weight:700;
          color:#e5edf5;
        }

        .admin-id{
          font-size:11px;
          color:#9fb0c3;
        }

        .admin-icon{
          width:30px;
          height:30px;
          border-radius:50%;
          background:rgba(255,255,255,.92);
          display:flex;
          align-items:center;
          justify-content:center;
          box-shadow:0 0 0 2px rgba(255,255,255,.28);
          user-select:none;
          cursor:pointer;
        }

        .admin-icon svg{ width:18px; height:18px; opacity:.85; }

        .admin-dropdown{
          position:absolute;
          top:100%;
          right:0;
          margin-top:6px;
          min-width:120px;
          background:rgba(255,255,255,.72);
          backdrop-filter: blur(10px);
          -webkit-backdrop-filter: blur(10px);
          border:1px solid rgba(229,231,235,.9);
          border-radius:12px;
          box-shadow:0 16px 36px rgba(0,0,0,.18);
          display:flex;
          flex-direction:column;
          overflow:hidden;
          z-index:1000;

          opacity:0;
          visibility:hidden;
          pointer-events:none;
          transform: translateY(6px);
          transition: opacity .16s ease, transform .16s ease, visibility .16s;
        }

        .admin-dropdown.open{
          opacity:1;
          visibility:visible;
          pointer-events:auto;
          transform: translateY(0);
        }

        .admin-area:hover .admin-dropdown{
          opacity:1;
          visibility:visible;
          pointer-events:auto;
          transform: translateY(0);
        }

        .dropdown-item{
          padding:9px 12px;
          font-size:13px;
          color:#111827;
          text-decoration:none;
          white-space:nowrap;
        }

        .dropdown-item:hover{ background: rgba(17,24,39,.06); }

        .dropdown-sep{
          height:1px;
          background: rgba(17,24,39,.08);
          margin:2px 0;
        }

        .dropdown-item.logout{
          color:#b91c1c;
          font-weight:800;
        }

        /* ===============================
           ✅ PAGE CONTENT (상세페이지 전용 스타일)
           =============================== */
        .main-container { max-width: 850px; margin: 40px auto; padding: 0 20px; }
        .content-card { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }

        .detail-header { border-bottom: 2px solid #2aa3ff; padding-bottom: 15px; margin-bottom: 30px; }
        .detail-header h2 { margin: 0; color: #2c3e50; font-size: 24px; }

        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .info-item { padding: 18px; background: #fafafa; border: 1px solid #eee; border-radius: 8px; }
        .info-label { font-size: 13px; color: #7f8c8d; margin-bottom: 8px; font-weight: 800; }
        .info-value { font-size: 19px; font-weight: 900; color: #2c3e50; }

        .btn-group { margin-top: 40px; display: flex; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
        .btn-back { padding: 12px 25px; background: #95a5a6; color: white; text-decoration: none; border-radius: 8px; font-size: 14px; font-weight: 900; }
        .btn-primary { padding: 12px 25px; background: #2aa3ff; color: white; text-decoration: none; border-radius: 8px; font-size: 14px; font-weight: 900; }
    </style>
</head>
<body>

    <!-- ✅ 통일 메뉴바 적용 -->
    <nav class="navbar">
      <a href="main.jsp" class="navbar-brand">💧 SMART WATER JP</a>

      <ul class="nav-links" id="navLinks">
        <!-- 이 페이지는 '상세'지만, 상위 메뉴는 보통 '顧客一覧'를 활성 처리 -->
        <li><a href="customer_list.jsp" class="is-active">顧客一覧</a></li>
        <li><a href="district_manage.jsp">管轄区域管理</a></li>
        <li><a href="overdue_list.jsp">延滞管理</a></li>
        <li><a href="deposit.jsp">入金管理</a></li>
        <li><a href="billing_list.jsp">請求管理</a></li>
      </ul>

      <div class="admin-area" id="adminArea">
        <div class="admin-text">
          <div class="admin-name"><%= (sessionAdminName == null ? "管理者" : sessionAdminName) %> 様</div>
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
                <a href="customer_list.jsp" class="btn-back">← 顧客一覧へ戻る</a>
                <a href="billing.jsp?customer_id=<%= customerId %>" class="btn-primary">請求書を表示</a>
            </div>
        </div>
    </div>

    <script>
      // ✅ ADMIN DROPDOWN (click to toggle)
      (function () {
        const adminArea = document.getElementById("adminArea");
        const adminDropdown = document.getElementById("adminDropdown");
        if (!adminArea || !adminDropdown) return;

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
      })();
    </script>

</body>
</html>
<%
    } catch (Exception e) {
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
>>>>>>> refs/remotes/origin/dev
