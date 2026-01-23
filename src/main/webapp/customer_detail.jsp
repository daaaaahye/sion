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