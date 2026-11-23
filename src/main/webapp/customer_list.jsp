<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.util.Random" %>
<%@ include file="/WEB-INF/dbconfig.jspf" %>
<%
    // 1. 세션 체크: 관리자 로그인 상태 확인
    String sessionAdminId = (String) session.getAttribute("adminId");
    if (sessionAdminId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String adminName = (String) session.getAttribute("adminName");
    if (adminName == null) adminName = "管理者";

    request.setCharacterEncoding("UTF-8");
    String searchName = request.getParameter("searchName");
    if (searchName == null) searchName = "";

    Connection connRoot = null;
    Connection connWsms = null;

    DecimalFormat df = new DecimalFormat("¥###,###");
    Random rnd = new Random();

    PreparedStatement pstmtAdmin = null;
    ResultSet rsAdmin = null;

    try {
        Class.forName("org.postgresql.Driver");

        connRoot = sionConnect("root");
        connWsms = sionConnect("wsms");

        // 관리자 이름 동기화
        String sqlAdmin = "SELECT name FROM \"Administrator\" WHERE id = ?";
        pstmtAdmin = connRoot.prepareStatement(sqlAdmin);
        pstmtAdmin.setString(1, sessionAdminId);
        rsAdmin = pstmtAdmin.executeQuery();

        if (rsAdmin.next()) {
            adminName = rsAdmin.getString("name");
            session.setAttribute("adminName", adminName);
        }
%>
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>顧客管理 - SMART WATER</title>
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
       ✅ TOP NAVBAR (완전 정렬 고정 버전)
       =============================== */
    .navbar{
      height:56px;
      background:#243646;
      display:flex;
      align-items:center;
      padding:0 22px;
      gap:26px;
      position:relative;

      /* ✅ 한 줄 고정 */
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

      /* ✅ 높이 통일 */
      align-items: stretch;

      gap:22px;
      margin:0;
      padding:0;
      position:relative;

      /* ✅ 한 줄 고정 + 좁으면 가로 스크롤 */
      flex-wrap: nowrap;
      white-space: nowrap;
      min-width: 0;
      overflow-x: auto;
      overflow-y: hidden;
      scrollbar-width: none;
    }
    .nav-links::-webkit-scrollbar { display:none; }

    .nav-links li{
      /* ✅ baseline 차이 제거 */
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

      /* ✅ 높낮이 완전 고정 */
      height:56px;
      display:flex;
      align-items:center;
      padding:0 4px;
      line-height:1;
    }

    .nav-links a:hover{ color:#ffffff; }

    /* ✅ 1번 메뉴(顧客一覧) 아래 언더라인 고정 */
    .nav-links li:nth-child(1) a::after{
      content:"";
      position:absolute;
      left:0;
      bottom:10px; /* ✅ 56px 높이 기준으로 안정화 */
      width:100%;
      height:2px;
      background:#2aa3ff;
      border-radius:2px;
    }

    /* ===============================
       ✅ ADMIN (통합 버전 + dropdown) - 정렬 고정 포함
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

    /* hover로도 열리게 */
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
       PAGE CONTENT (기존 스타일 유지 + 톤 통일)
       =============================== */
    .main-container { max-width:1200px; margin:30px auto; padding:0 20px; }

    .content-card{
      background:white;
      border-radius:10px;
      padding:24px;
      box-shadow:0 2px 10px rgba(0,0,0,0.05);
    }

    .content-card h2{
      font-size:24px;
      margin-top:0;
      margin-bottom:24px;
      color:#2c3e50;
      line-height:1.1;
      border-left:5px solid #2aa3ff;
      padding-left:12px;
      font-weight:bold;
    }

    .search-box{
      background:#f1f3f5;
      padding:18px;
      border-radius:10px;
      margin:16px auto;
      display:flex;
      gap:12px;
      align-items:flex-end;
      justify-content:center;
      width:100%;
    }

    input[type="text"]{
      padding:10px 14px;
      border-radius:7px;
      border:1px solid #d9dde3;
      width:250px;
      height:40px;
    }

    .btn-search{
      background:#2aa3ff;
      color:white;
      border:none;
      height:40px;
      padding:0 20px;
      border-radius:7px;
      cursor:pointer;
      font-weight:800;
    }

    .btn-reset{
      background:#eee;
      padding:0 20px;
      border-radius:7px;
      border:1px solid #ddd;
      height:40px;
      cursor:pointer;
      color:#333;
      text-decoration:none;
      line-height:40px;
      font-size:14px;
    }

    .list-table{ width:100%; border-collapse:collapse; margin-top:20px; }
    .list-table th{
      background:#f8f9fa;
      padding:14px 12px;
      text-align:left;
      border-bottom:2px solid #dee2e6;
      color:#495057;
      font-size:16px;
    }
    .list-table td{
      padding:12px;
      border-bottom:1px solid #eee;
      font-size:14px;
    }
    .name-link{ color:#3498db; text-decoration:none; font-weight:bold; }
    .usage-badge{ background:#e8f4fd; color:#2980b9; padding:4px 8px; border-radius:4px; font-size:12px; }
  </style>
</head>

<body>

  <!-- ✅ 완전 정렬 고정 메뉴바 적용 (1번 메뉴 언더라인 고정) -->
  <nav class="navbar">
    <a href="main.jsp" class="navbar-brand">💧 SMART WATER JP</a>

    <ul class="nav-links" id="navLinks">
      <li><a href="customer_list.jsp">顧客一覧</a></li>
      <li><a href="district_manage.jsp">管轄区域管理</a></li>
      <li><a href="overdue_list.jsp">延滞管理</a></li>
      <li><a href="deposit.jsp">入金管理</a></li>
      <li><a href="billing_list.jsp">請求管理</a></li>
    </ul>

    <div class="admin-area" id="adminArea">
      <div class="admin-text">
        <div class="admin-name"><%= (adminName == null ? "" : adminName) %> 様</div>
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
      <h2>👥 顧客管理リスト</h2>

      <form class="search-box" action="customer_list.jsp" method="get">
        <input type="text" name="searchName" value="<%= searchName %>" placeholder="顧客名を入力してください">
        <button type="submit" class="btn-search">検索</button>
        <a href="customer_list.jsp" class="btn-reset">リセット</a>
      </form>

      <table class="list-table">
        <thead>
          <tr>
            <th>お名前</th>
            <th>ご住所</th>
            <th>今月の使用量</th>
          </tr>
        </thead>
        <tbody>
        <%
          String sqlCust = "SELECT customer_id, name, address FROM customers";
          if (!searchName.isEmpty()) sqlCust += " WHERE name LIKE ? ORDER BY name ASC";
          else sqlCust += " ORDER BY name ASC";

          PreparedStatement pstmtCust = connWsms.prepareStatement(sqlCust);
          if (!searchName.isEmpty()) pstmtCust.setString(1, "%" + searchName + "%");
          ResultSet rsCust = pstmtCust.executeQuery();

          while (rsCust.next()) {
        %>
          <tr>
            <td>
              <a href="customer_detail.jsp?customer_id=<%= rsCust.getString("customer_id") %>" class="name-link">
                <%= rsCust.getString("name") %> 様
              </a>
            </td>
            <td><%= rsCust.getString("address") %></td>
            <td><span class="usage-badge"><%= rnd.nextInt(141) + 10 %> m³</span></td>
          </tr>
        <%
          }
          rsCust.close();
          pstmtCust.close();
        %>
        </tbody>
      </table>

    </div>
  </div>

  <script>
    // ✅ ADMIN DROPDOWN (click to toggle)
    const adminArea = document.getElementById("adminArea");
    const adminDropdown = document.getElementById("adminDropdown");

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
  </script>

</body>
</html>

<%
    } catch (Exception e) {
        out.println("<div style='color:red; background:#fff; padding:20px; border:2px solid red; margin:20px;'>");
        out.println("<h3>에러 발생 상세:</h3>");
        out.println("<p>" + e.getMessage() + "</p>");
        out.println("<pre>");
        e.printStackTrace(new java.io.PrintWriter(out));
        out.println("</pre>");
        out.println("</div>");
    } finally {
        if (rsAdmin != null) try { rsAdmin.close(); } catch(SQLException e) {}
        if (pstmtAdmin != null) try { pstmtAdmin.close(); } catch(SQLException e) {}
        if (connRoot != null) try { connRoot.close(); } catch(SQLException e) {}
        if (connWsms != null) try { connWsms.close(); } catch(SQLException e) {}
    }
%>