<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ include file="/WEB-INF/dbconfig.jspf" %>
<%
    String sessionAdminId = (String) session.getAttribute("adminId");
    String adminName = (String) session.getAttribute("adminName");
    String customerId = request.getParameter("customer_id");

    if (sessionAdminId == null) { response.sendRedirect("login.jsp"); return; }
    if (adminName == null) adminName = "管理者";
    if (customerId == null) customerId = "B02201";

    Connection connRoot = null;
    Connection connWsms = null;
    DecimalFormat df = new DecimalFormat("#,###");

    PreparedStatement pstmtAdmin = null;
    ResultSet rsAdmin = null;

    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Class.forName("org.postgresql.Driver");
        connRoot = sionConnect("root");
        connWsms = sionConnect("wsms");

        // ✅ 관리자 이름 동기화
        String sqlAdmin = "SELECT name FROM \"Administrator\" WHERE id = ?";
        pstmtAdmin = connRoot.prepareStatement(sqlAdmin);
        pstmtAdmin.setString(1, sessionAdminId);
        rsAdmin = pstmtAdmin.executeQuery();
        if (rsAdmin.next()) {
            adminName = rsAdmin.getString("name");
            session.setAttribute("adminName", adminName);
        }

        // ✅ 고객/청구/입금 합산
        String sql =
            "SELECT c.name, c.tel, c.address, " +
            " (SELECT bill_amount FROM public.bill WHERE customer_id = ? ORDER BY billing_date DESC LIMIT 1) as monthly_bill, " +
            " (SELECT COALESCE(SUM(bill_amount), 0) FROM public.bill WHERE customer_id = ?) as total_billed, " +
            " (SELECT COALESCE(SUM(paid_amount), 0) FROM public.deposit WHERE customer_id = ?) as total_paid " +
            "FROM public.customers c WHERE c.customer_id = ?";

        pstmt = connWsms.prepareStatement(sql);
        pstmt.setString(1, customerId);
        pstmt.setString(2, customerId);
        pstmt.setString(3, customerId);
        pstmt.setString(4, customerId);
        rs = pstmt.executeQuery();
%>
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>水道料金の請求書 - SMART WATER</title>
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
           PAGE CONTENT (기존 청구서 스타일 유지)
           =============================== */
        .main-container{
            padding: 80px 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
            min-height: calc(100vh - 56px);
        }

        .bill-wrapper{
            position: relative;
            width: 100%;
            max-width: 700px;
        }

        .btn-print-area{
            position: absolute;
            top: -50px;
            right: 0;
        }

        .btn-print{
            background-color: #2aa3ff;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 7px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 800;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: background 0.2s;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .btn-print:hover { background-color: #1f8fe6; }

        .bill-card{
            width: 100%;
            background: white;
            padding: 60px 50px;
            box-shadow: 0 2px 15px rgba(0,0,0,0.1);
            border-radius: 10px;
            text-align: center;
        }

        .bill-title { font-size: 32px; font-weight: 900; margin-bottom: 10px; color: #000; letter-spacing: 2px; }
        .bill-date { font-size: 14px; color: #666; margin-bottom: 40px; }
        .bill-divider { border-top: 2px solid #243646; margin-bottom: 30px; }

        .info-table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
        .info-table th, .info-table td { border: 1px solid #dee2e6; padding: 15px; text-align: left; font-size: 15px; }
        .info-table th { background-color: #f8f9fa; width: 30%; font-weight: 900; color: #495057; }
        .info-table td { background-color: #fff; width: 70%; }

        .total-wrapper { text-align: right; margin-top: 20px; padding: 20px; background: #fff5f5; border-radius: 8px; margin-bottom: 40px; }
        .total-label { font-size: 16px; color: #444; margin-right: 10px; }
        .total-text { font-size: 26px; font-weight: 900; color: #e74c3c; }

        .footer-notice { text-align: left; font-weight: 900; font-size: 13px; color: #777; line-height: 1.8; border-top: 1px dashed #ccc; padding-top: 20px; }

        @media print {
            body { background: white; }
            .navbar, .btn-print-area { display: none !important; }
            .main-container { padding: 0; min-height: auto; }
            .bill-card { box-shadow: none; border: 1px solid #eee; padding: 0; width: 100%; }
        }
    </style>
</head>
<body>

    <!-- ✅ 통일 메뉴바 적용 (밑줄: 첫번째 메뉴) -->
    <nav class="navbar">
      <a href="main.jsp" class="navbar-brand">💧 SMART WATER JP</a>

      <ul class="nav-links" id="navLinks">
        <!-- ✅ 여기만 is-active (첫번째 메뉴 밑줄) -->
        <li><a href="customer_list.jsp" class="is-active">顧客一覧</a></li>
        <li><a href="district_manage.jsp">管轄区域管理</a></li>
        <li><a href="overdue_list.jsp">延滞管理</a></li>
        <li><a href="deposit.jsp">入金管理</a></li>
        <li><a href="billing_list.jsp">請求管理</a></li>
      </ul>

      <div class="admin-area" id="adminArea">
        <div class="admin-text">
          <div class="admin-name"><%= (adminName == null ? "管理者" : adminName) %> 様</div>
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
        <%
            if (rs.next()) {
                long monthlyBill = rs.getLong("monthly_bill");
                long totalBilled = rs.getLong("total_billed");
                long totalPaid = rs.getLong("total_paid");

                long overdueAmount = (totalBilled - totalPaid) - monthlyBill;
                if (overdueAmount < 0) overdueAmount = 0;

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
                    <div class="bill-date"></div>

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
            <div class="bill-card" style="max-width:700px;">
                <h3 style="color:#e74c3c;">お客様情報が見つかりません</h3>
                <p>入力された顧客 ID: <strong><%= customerId %></strong></p>
                <a href="customer_list.jsp" style="color:#2aa3ff; font-weight:800;">一覧に戻る</a>
            </div>
        <%
            }
        %>
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
    } catch(Exception e) {
        out.println("<div style='color:red; background:#fff; padding:20px; border:2px solid red; margin:20px;'>");
        out.println("<h3>에러 발생 상세:</h3>");
        out.println("<p>" + e.getMessage() + "</p>");
        out.println("<pre>");
        e.printStackTrace(new java.io.PrintWriter(out));
        out.println("</pre>");
        out.println("</div>");
    } finally {
        if (rsAdmin != null) try { rsAdmin.close(); } catch(Exception e) {}
        if (pstmtAdmin != null) try { pstmtAdmin.close(); } catch(Exception e) {}
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (connRoot != null) try { connRoot.close(); } catch(Exception e) {}
        if (connWsms != null) try { connWsms.close(); } catch(Exception e) {}
    }
%>