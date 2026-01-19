<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>

<%
    request.setCharacterEncoding("UTF-8");

    // ✅ DB에서 customers 데이터 읽어서 JS 배열 rows로 만들기
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;

    StringBuilder rowsJs = new StringBuilder();

    try {
        Class.forName("org.postgresql.Driver");
        conn = DriverManager.getConnection(
            "jdbc:postgresql://localhost:5432/wsms",
            "postgres",
            "1234"
        );

        // ✅ DB 컬럼에 맞춰서 조회
        String sql = "SELECT name, district, address FROM customers ORDER BY district ASC, name ASC";

        stmt = conn.createStatement();
        rs = stmt.executeQuery(sql);
        boolean first = true;

        while (rs.next()) {
            String name = rs.getString("name");
            String district = rs.getString("district");
            String address = rs.getString("address");

            // ✅ JS 문자열 안전 처리 (\r 도 같이 제거!!)
            name = (name == null ? "" : name.replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\r", " ")
                    .replace("\n", " "));
            district = (district == null ? "" : district.replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\r", " ")
                    .replace("\n", " "));
            address = (address == null ? "" : address.replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\r", " ")
                    .replace("\n", " "));

            // ✅ 콤마를 "앞에"만 붙여서 마지막 콤마 문제 제거
            if (!first) rowsJs.append(",\n");
            first = false;

            rowsJs.append("{ ")
                  .append("name: \"").append(name).append(" 様\", ")
                  .append("district: \"").append(district).append("\", ")
                  .append("address: \"").append(address).append("\"")
                  .append(" }");
        }

    } catch (Exception e) {
        out.println("<div style='color:red; text-align:center; padding:20px;'>エラー発生: " + e.getMessage() + "</div>");
    } finally {
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (stmt != null) try { stmt.close(); } catch(Exception e) {}
        if (conn != null) try { conn.close(); } catch(Exception e) {}
    }
%>

<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>管轄区域管理 - SMART WATER</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: system-ui, -apple-system, Segoe UI, Roboto, "Noto Sans KR", Arial, sans-serif;
      background: #f5f6f8;
      color: #111827;
    }

    /* ===============================
       ✅ TOP NAVBAR (통합 버전)
       =============================== */
    .navbar {
      height: 56px;
      background: #243646;
      display: flex;
      align-items: center;
      padding: 0 22px;
      gap: 26px;
      position: relative;
    }

    .navbar-brand {
      font-weight: 800;
      font-size: 16px;
      color: #2aa3ff;
      text-decoration: none;
      white-space: nowrap;
    }

    .nav-links {
      list-style: none;
      display: flex;
      align-items: center;
      gap: 22px;
      margin: 0;
      padding: 0;
      position: relative;
    }

    .nav-links a {
      color: #cbd5e1;
      text-decoration: none;
      font-size: 13px;
      font-weight: 600;
      padding: 18px 4px 14px;
      white-space: nowrap;
      display: inline-block;
      position: relative;
    }

    .nav-links a:hover { color: #ffffff; }

    /* ✅ 메뉴바 두 번째 메뉴(管轄区域管理) 아래 언더라인 고정 */
    .nav-links li:nth-child(2) a::after {
      content: "";
      position: absolute;
      left: 0;
      bottom: 6px;
      width: 100%;
      height: 2px;
      background: #2aa3ff;
      border-radius: 2px;
    }

    /* ADMIN */
    .admin-area{
      margin-left: auto;
      position: relative;
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .admin-text{
      display: flex;
      flex-direction: column;
      align-items: flex-end;
      line-height: 1.2;
      margin: 0;
      transform: none;
      white-space: nowrap;
    }

    .admin-name {
      font-size: 12px;
      font-weight: 700;
      color: #e5edf5;
    }

    .admin-id {
      font-size: 11px;
      color: #9fb0c3;
    }

    .admin-icon {
      width: 30px;
      height: 30px;
      border-radius: 50%;
      background: rgba(255,255,255,.92);
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 0 0 2px rgba(255,255,255,.28);
      user-select: none;
    }

    .admin-icon svg { width: 18px; height: 18px; opacity: .85; }

    .admin-dropdown {
      position: absolute;
      top: 100%;
      right: 0;
      margin-top: 6px;
      min-width: 120px;
      background: rgba(255,255,255,.72);
      backdrop-filter: blur(10px);
      -webkit-backdrop-filter: blur(10px);
      border: 1px solid rgba(229,231,235,.9);
      border-radius: 12px;
      box-shadow: 0 16px 36px rgba(0,0,0,.18);
      display: flex;
      flex-direction: column;
      overflow: hidden;
      z-index: 1000;
      opacity: 0;
      visibility: hidden;
      pointer-events: none;
      transform: translateY(6px);
      transition: opacity .16s ease, transform .16s ease, visibility .16s;
    }

    .admin-dropdown.open{
      opacity: 1;
      visibility: visible;
      pointer-events: auto;
      transform: translateY(0);
    }

    .dropdown-item {
      padding: 9px 12px;
      font-size: 13px;
      color: #111827;
      text-decoration: none;
      white-space: nowrap;
    }

    .dropdown-item:hover { background: rgba(17,24,39,.06); }

    .dropdown-sep { height: 1px; background: rgba(17,24,39,.08); margin: 2px 0; }

    .dropdown-item.logout {
      color: #b91c1c;
      font-weight: 800;
    }

    /* 마우스를 admin-area 위에 올리면 드롭다운 열림 */
    .admin-area:hover .admin-dropdown{
      opacity: 1;
      visibility: visible;
      pointer-events: auto;
      transform: translateY(0);
    }

    /* =========================
       PAGE CONTENT (기존 유지)
       ========================= */
    .main-container { max-width:1200px; margin:26px auto; padding:0 20px; }
    .content-card { background:#fff; border-radius:12px; padding:24px; box-shadow:0 4px 12px rgba(0,0,0,0.05); }
    .section-title { font-size:24px; font-weight:bold; color:#2c3e50; margin-bottom:12px; border-left:5px solid #2aa3ff; padding-left:10px; }

    .search-notice { margin:10px 0 14px; padding:12px 14px; border-radius:10px; background:#f1f6fb; border:1px solid #dbe9f6; font-size:13px; line-height:1.55; }

    .search-box { background:#f1f3f5; padding:18px; border-radius:10px; margin-bottom:16px; display:flex; gap:15px; align-items:flex-end; flex-wrap:wrap; }
    .search-group { display:flex; flex-direction:column; gap:8px; }
    .search-group label { font-weight:bold; font-size:13px; }

    select, input[type="text"], .btn-search {
      padding:10px 14px;
      padding-right:40px;
      border-radius:7px;
      border:1px solid #d9dde3;
      font-size:14px;
      height:40px;
    }
    .btn-search { background:#2aa3ff; color:#fff; cursor:pointer; font-weight:800; border:none; }
    .btn-reset { background:#eee; padding:10px 20px; border-radius:6px; border:1px solid #ddd; height:40px; cursor:pointer; }

    .result-count { margin:10px 0; font-size:13px; font-weight:bold; }

    .data-table { width:100%; border-collapse:collapse; margin-top:20px; table-layout: fixed; }
    .data-table th{
      background:#f8f9fa;
      padding:12px;
      text-align:left;
      border-bottom:2px solid #dee2e6;
      color:#495057;
      font-size:16px;
    }
    .data-table td{
      padding:12px;
      font-size: 14px;
      border-bottom:1px solid #eee;
      text-align:left;
      overflow:hidden;
      text-overflow:ellipsis;
      white-space:nowrap;
    }
    .name-link{
      color:#3498db;
      text-decoration:none;
      font-weight:bold;
    }

    .no-result { padding:18px; text-align:center; color:#666; border:1px dashed #ccc; border-radius:10px; margin-top:10px; display:none; }

    .pagination {
      display:flex;
      gap:10px;
      align-items:center;
      justify-content:center;
      margin-top:16px;
    }
    .page-btn{
      padding:10px 16px;
      border:1px solid #d9dde3;
      background:#fff;
      border-radius:8px;
      cursor:pointer;
      font-weight:800;
      height:40px;
    }
    .page-btn:disabled{
      opacity:.45;
      cursor:not-allowed;
    }
    #pageInfo{
      font-size:13px;
      font-weight:800;
    }
  </style>
</head>

<body>

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
        <div class="admin-name"><%= (session.getAttribute("adminName") == null ? "" : session.getAttribute("adminName")) %> 様</div>
        <div class="admin-id">社員番号 <%= (session.getAttribute("adminId") == null ? "" : session.getAttribute("adminId")) %></div>
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
      <div class="section-title">📍 区域・メーター別 詳細管理</div>

      <div class="search-notice">
        ※ 管轄区域および顧客名で検索できます。<br>
        ※ 管轄区域の情報を確認できます。
      </div>

      <form class="search-box" onsubmit="return false;">
        <div class="search-group">
          <label>管轄区域</label>
          <select id="districtSelect">
            <option value="ALL">全ての区域</option>
            <option value="東京都渋谷区">東京都 渋谷区</option>
            <option value="東京都台東区">東京都 台東区</option>
            <option value="東京都中央区">東京都 中央区</option>
            <option value="東京都港区">東京都 港区</option>
            <option value="東京都新宿区">東京都 新宿区</option>
          </select>
        </div>

        <div class="search-group">
          <label>顧客名 検索</label>
          <input type="text" id="nameInput" placeholder="お名前を入力">
        </div>

        <button type="button" class="btn-search" id="btnSearch" style="padding-left:25px; padding-right:25px;">検索</button>
        <button type="button" class="btn-reset" id="btnReset">リセット</button>
      </form>

      <div class="result-count" id="resultCount">検索結果は0件です。</div>

      <table class="data-table" id="dataTable">
        <thead>
          <tr>
            <th>氏名</th>
            <th>管轄区域</th>
            <th>詳細住所</th>
          </tr>
        </thead>
        <tbody id="tbody"></tbody>
      </table>

      <div class="no-result" id="noResult">検索結果がありません。</div>

      <div class="pagination" id="pagination" style="display:none;">
        <button type="button" class="page-btn" id="btnPrev">前へ</button>
        <span id="pageInfo">1 / 1 ページ</span>
        <button type="button" class="page-btn" id="btnNext">次へ</button>
      </div>

    </div>
  </div>

  <script>
    const rows = [
      <%= rowsJs.toString() %>
    ];

    const districtSelect = document.getElementById("districtSelect");
    const nameInput = document.getElementById("nameInput");
    const tbody = document.getElementById("tbody");
    const resultCount = document.getElementById("resultCount");
    const noResult = document.getElementById("noResult");
    const dataTable = document.getElementById("dataTable");
    const pagination = document.getElementById("pagination");
    const btnPrev = document.getElementById("btnPrev");
    const btnNext = document.getElementById("btnNext");
    const pageInfo = document.getElementById("pageInfo");

    const PAGE_SIZE = 20;
    let currentPage = 1;
    let filteredRows = rows;

    function renderTable(data) {
      tbody.innerHTML = "";

      const total = data.length;
      const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
      if (currentPage > totalPages) currentPage = totalPages;

      resultCount.textContent = "検索結果は" + total + "件です。";

      if (total === 0) {
        dataTable.style.display = "none";
        noResult.style.display = "block";
        pagination.style.display = "none";
        return;
      }

      dataTable.style.display = "table";
      noResult.style.display = "none";
      pagination.style.display = "flex";

      const start = (currentPage - 1) * PAGE_SIZE;
      const pageItems = data.slice(start, start + PAGE_SIZE);

      pageItems.forEach(r => {
        const tr = document.createElement("tr");
        tr.innerHTML =
          "<td><a href='#' class='name-link'>" + r.name + "</a></td>" +
          "<td>" + r.district + "</td>" +
          "<td>" + r.address + "</td>";
        tbody.appendChild(tr);
      });

      pageInfo.textContent = currentPage + " / " + totalPages + " ページ";
      btnPrev.disabled = (currentPage === 1);
      btnNext.disabled = (currentPage === totalPages);
    }

    function applyFilter() {
      const d = districtSelect.value;
      const q = nameInput.value.trim().toLowerCase();

      filteredRows = rows.filter(r => {
        const okDistrict = (d === "ALL") || (r.district === d);
        const okName = (!q) || (r.name.toLowerCase().includes(q));
        return okDistrict && okName;
      });

      currentPage = 1;
      renderTable(filteredRows);
    }

    document.getElementById("btnSearch").addEventListener("click", applyFilter);

    document.getElementById("btnReset").addEventListener("click", () => {
      districtSelect.value = "ALL";
      nameInput.value = "";
      filteredRows = rows;
      currentPage = 1;
      renderTable(filteredRows);
    });

    btnPrev.addEventListener("click", () => {
      if (currentPage > 1) {
        currentPage--;
        renderTable(filteredRows);
      }
    });

    btnNext.addEventListener("click", () => {
      const totalPages = Math.max(1, Math.ceil(filteredRows.length / PAGE_SIZE));
      if (currentPage < totalPages) {
        currentPage++;
        renderTable(filteredRows);
      }
    });

    filteredRows = rows;
    renderTable(filteredRows);

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
