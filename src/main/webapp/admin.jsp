<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
  request.setCharacterEncoding("UTF-8");

  // =========================
  // [0] 세션 체크
  // =========================
  String sessionAdminId = (String) session.getAttribute("adminId");
  if (sessionAdminId == null) {
    response.sendRedirect("login.jsp");
    return;
  }

  // =========================
  // [1] DB 연결 정보
  // =========================
  String DB_URL  = "jdbc:postgresql://localhost:5432/root";
  String DB_USER = "postgres";
  String DB_PASS = "1234";

  Connection conn = null;
  PreparedStatement pstmt = null;
  ResultSet rs = null;

  // 화면 표시용 값
  String adminName = "";
  String adminId = sessionAdminId;
  String message = null;
  String error = null;

  // ✅ 인증 상태(세션에 저장)
  Boolean pwVerified = (Boolean) session.getAttribute("pwVerified");
  if (pwVerified == null) pwVerified = false;

  try {
    Class.forName("org.postgresql.Driver");
    conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

    // =========================
    // [2] POST 처리: verify(현재 비번 인증) / save(새 비번 저장)
    // =========================
    if ("POST".equalsIgnoreCase(request.getMethod())) {

      String action = request.getParameter("action"); // verify or save
      String oldId = request.getParameter("oldId");

      if (oldId == null || oldId.trim().isEmpty()) {
        error = "管理者IDが不正です。";
      } else if ("verify".equals(action)) {

        // ----- 현재 비밀번호 인증 -----
        String currentPw = request.getParameter("currentPassword");

        if (currentPw == null || currentPw.trim().isEmpty()) {
          error = "現在のパスワードを入力してください。";
          session.setAttribute("pwVerified", false);
          pwVerified = false;
        } else {
          String sqlCheck = "SELECT password FROM public.\"Administrator\" WHERE id = ?";
          pstmt = conn.prepareStatement(sqlCheck);
          pstmt.setString(1, oldId.trim());
          rs = pstmt.executeQuery();

          String dbPw = null;
          if (rs.next()) dbPw = rs.getString("password");

          rs.close(); rs = null;
          pstmt.close(); pstmt = null;

          if (dbPw == null) {
            error = "管理者情報を取得できませんでした。";
            session.setAttribute("pwVerified", false);
            pwVerified = false;
          } else if (!dbPw.equals(currentPw)) {
            error = "現在のパスワードが正しくありません。";
            session.setAttribute("pwVerified", false);
            pwVerified = false;
          } else {
            // ✅ 인증 성공
            session.setAttribute("pwVerified", true);
            pwVerified = true;
            message = "認証完了しました。新しいパスワードを入力してください。";
          }
        }

      } else if ("save".equals(action)) {

        // ----- 새 비밀번호 저장(인증 완료일 때만) -----
        Boolean verified = (Boolean) session.getAttribute("pwVerified");
        if (verified == null || !verified) {
          error = "先に現在のパスワード認証を行ってください。";
          pwVerified = false;
        } else {
          String newPw = request.getParameter("newPassword");
          String confirmPw = request.getParameter("confirmPassword");

          if (newPw == null || newPw.trim().isEmpty()
              || confirmPw == null || confirmPw.trim().isEmpty()) {
            error = "新しいパスワードを入力してください。";
          } else if (!newPw.equals(confirmPw)) {
            error = "新しいパスワードが一致しません。";
          } else {
            String sqlUpdate =
              "UPDATE public.\"Administrator\" " +
              "SET password = ? " +
              "WHERE id = ?";

            pstmt = conn.prepareStatement(sqlUpdate);
            pstmt.setString(1, newPw.trim());
            pstmt.setString(2, oldId.trim());

            int updated = pstmt.executeUpdate();
            pstmt.close(); pstmt = null;

            if (updated == 1) {
              message = "保存しました。";
              // ✅ 저장 완료 후 인증 초기화
              session.setAttribute("pwVerified", false);
              pwVerified = false;
            } else {
              error = "更新に失敗しました（対象管理者が見つかりません）。";
            }
          }
        }
      }
    }

    // =========================
    // [3] 최신 관리자 정보 조회 (비밀번호는 조회 X)
    // =========================
    String sqlSelect = "SELECT id, name FROM public.\"Administrator\" WHERE id = ?";
    pstmt = conn.prepareStatement(sqlSelect);
    pstmt.setString(1, sessionAdminId);
    rs = pstmt.executeQuery();

    if (rs.next()) {
      adminId = rs.getString("id");
      adminName = rs.getString("name");
    } else {
      error = "管理者情報を取得できませんでした。";
    }

  } catch (Exception e) {
    error = "エラー: " + e.getMessage();
  } finally {
    try { if (rs != null) rs.close(); } catch(Exception ignore) {}
    try { if (pstmt != null) pstmt.close(); } catch(Exception ignore) {}
    try { if (conn != null) conn.close(); } catch(Exception ignore) {}
  }
%>

<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>SMART WATER JP - 設定</title>

  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: system-ui, -apple-system, Segoe UI, Roboto, "Noto Sans KR", Arial, sans-serif;
      background: #f5f6f8;
      color: #111827;
    }

    /* ===============================
       ✅ TOP NAVBAR (완전 통일/고정 버전)
       =============================== */
    .navbar {
      height: 56px;
      background: #243646;
      display: flex;
      align-items: center;
      padding: 0 22px;
      gap: 26px;
      position: relative;

      /* ✅ 한 줄 고정 */
      flex-wrap: nowrap;
    }

    .navbar-brand {
      font-weight: 800;
      font-size: 16px;
      color: #2aa3ff;
      text-decoration: none;
      white-space: nowrap;

      display: inline-flex;
      align-items: center;
      gap: 8px;
      flex: 0 0 auto;
    }

    .nav-links {
      list-style: none;
      display: flex;
      align-items: stretch; /* ✅ 높이 동일 */
      gap: 22px;
      margin: 0;
      padding: 0;
      position: relative;

      /* ✅ 한 줄 고정 + 좁으면 가로 스크롤 */
      flex-wrap: nowrap;
      white-space: nowrap;
      min-width: 0;
      overflow-x: auto;
      overflow-y: hidden;
      scrollbar-width: none;
    }
    .nav-links::-webkit-scrollbar { display: none; }

    .nav-links li {
      display: flex;         /* ✅ baseline 차이 제거 */
      align-items: center;
      flex: 0 0 auto;
    }

    .nav-links a {
      color: #cbd5e1;
      text-decoration: none;
      font-size: 13px;
      font-weight: 600;
      white-space: nowrap;
      position: relative;

      /* ✅ 높낮이 완전 고정 */
      height: 56px;
      display: flex;
      align-items: center;
      padding: 0 4px;     /* 세로 padding 제거 */
      line-height: 1;
    }
    .nav-links a:hover { color: #ffffff; }

    /* ===============================
       ✅ ADMIN (통일 버전)
       =============================== */
    .admin-area{
      margin-left: auto;
      position: relative;
      display: flex;
      align-items: center;
      gap: 10px;
      flex: 0 0 auto;
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
      cursor: pointer;
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
    .dropdown-item.logout { color: #b91c1c; font-weight: 800; }

    /* hover로도 열리게 */
    .admin-area:hover .admin-dropdown,
    .admin-dropdown:hover{
      opacity: 1;
      visibility: visible;
      pointer-events: auto;
      transform: translateY(0);
    }

    /* ===============================
       ✅ PAGE CONTENT (기존 유지)
       =============================== */
    .wrap{
      max-width: 1150px;
      margin: 18px auto 80px;
      padding: 0 22px;
    }

    .page-title h1{
      margin: 0;
      font-size: 26px;
      font-weight: 800;
      letter-spacing: -0.2px;
      color: #111827;
    }

    .page-title p{
      margin: 6px 0 0;
      font-size: 13px;
      color: #8a94a6;
    }

    .pill-row{
      margin-top: 14px;
      display: flex;
      gap: 10px;
      align-items: center;
    }

    .pill{
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 10px 14px;
      border-radius: 999px;
      background: #f1f3f6;
      border: 1px solid #e3e7ee;
      font-size: 13px;
      font-weight: 700;
      color: #4b5563;
      user-select: none;
    }

    .pill .icon{
      width: 18px; height: 18px;
      display: grid; place-items: center;
      border-radius: 6px;
      background: #ffffff;
      border: 1px solid #e5e7eb;
      font-size: 12px;
    }

    .card{
      margin-top: 14px;
      background: #ffffff;
      border: 1px solid #e7ebf0;
      border-radius: 14px;
      padding: 22px;
      box-shadow: 0 6px 18px rgba(17,24,39,.06);
    }

    .card h2{
      margin: 0;
      font-size: 15px;
      font-weight: 800;
      color: #111827;
    }

    .card .sub{
      margin: 6px 0 0;
      font-size: 12px;
      color: #8a94a6;
    }

    .form{
      margin-top: 18px;
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px 18px;
    }

    .field label{
      display: block;
      margin-bottom: 8px;
      font-size: 12px;
      font-weight: 700;
      color: #6b7280;
    }

    .field input{
      width: 100%;
      height: 44px;
      border-radius: 10px;
      border: 1px solid #eef1f5;
      color: #111827;
      padding: 0 14px;
      font-size: 14px;
      outline: none;
      background: #ffffff;
    }

    .field input[readonly]{
      background:#f3f4f6;
      color:#6b7280;
      cursor:not-allowed;
    }

    .field input:focus{
      border-color: #cfd6e3;
      box-shadow: 0 0 0 4px rgba(17,24,39,.06);
    }

    .actions{
      margin-top: 16px;
      display: flex;
      justify-content: flex-end;
      align-items: center;
      gap: 10px;
    }

    .btn{
      height: 38px;
      padding: 0 18px;
      border-radius: 8px;
      background: #0b0f14;
      border: 1px solid #0b0f14;
      color: #ffffff;
      font-weight: 800;
      cursor: pointer;
      font-size: 13px;
      white-space: nowrap;
    }

    .btn[disabled]{
      opacity: .55;
      cursor: not-allowed;
    }

    .msg {
      padding: 10px 12px;
      border-radius: 10px;
      font-size: 13px;
      border: 1px solid #e5e7eb;
      background: #f9fafb;
      color: #111827;
    }
    .msg.ok { border-color: #bbf7d0; background: #f0fdf4; }
    .msg.err { border-color: #fecaca; background: #fef2f2; color: #991b1b; }

    .verified-badge{
      margin-top: 8px;
      font-size: 12px;
      font-weight: 900;
      color: #16a34a;
    }

    .pw-mismatch{
      display:none;
      margin-top: 8px;
      font-size: 12px;
      font-weight: 900;
      color: #b91c1c;
    }

    @media (max-width: 860px){
      .form{ grid-template-columns: 1fr; }

      .navbar{
        height: auto;
        flex-direction: column;
        align-items: center;
        gap: 10px;
        padding: 14px 14px;
      }

      .nav-links{
        flex-direction: column;
        align-items: center;
        gap: 6px;
        overflow: visible;
      }
      .nav-links li{ display:block; }
      .nav-links a{
        height: auto;
        padding: 10px 6px;
      }

      .admin-area{
        padding-top: 11px;
        margin-left: auto;
        position: relative;
        display: flex;
        align-items: center;
        gap: 10px;
        padding-bottom: 17px;
      }

      .admin-text{ display:none; }

      .admin-dropdown{
        left: 50%;
        right: auto;
        transform: translate(-50%, 6px);
      }
      .admin-dropdown.open{
        opacity: 1;
        visibility: visible;
        pointer-events: auto;
        transform: translate(-50%, 0);
      }
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
        <div class="admin-name"><%= (adminName == null ? "" : adminName) %> 様</div>
        <div class="admin-id">社員番号 <%= (adminId == null ? "" : adminId) %></div>
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

  <main class="wrap">
    <section class="page-title">
      <h1>設定</h1>
      <p>システム設定を管理してください</p>
    </section>

    <div class="pill-row">
      <div class="pill"><span class="icon">👤</span>プロフィール</div>
    </div>

    <section class="card">
      <h2>管理者情報</h2>
      <p class="sub">管理者アカウント情報を修正できます</p>

      <% if (message != null) { %>
        <div class="msg ok" style="margin-top:12px;"><%= message %></div>
      <% } %>
      <% if (error != null) { %>
        <div class="msg err" style="margin-top:12px;"><%= error %></div>
      <% } %>

      <form method="post" action="admin.jsp" id="pwForm">
        <input type="hidden" name="oldId" value="<%= (adminId == null ? "" : adminId) %>" />
        <input type="hidden" name="action" id="actionField" value="" />

        <div class="form">
          <div class="field">
            <label>氏名</label>
            <input type="text" value="<%= (adminName == null ? "" : adminName) %>" readonly />
          </div>

          <div class="field">
            <label>社員番号</label>
            <input type="text" value="<%= (adminId == null ? "" : adminId) %>" readonly />
          </div>

          <div class="field" id="maskedBox">
            <label>パスワード</label>
            <div style="display:flex; gap:10px; align-items:center;">
              <input type="text" value="**************" readonly />
              <button class="btn" type="button" id="btnChange" style="height:44px;">変更</button>
            </div>
          </div>

          <div class="field" id="verifyBox" style="display:none;">
            <label>現在のパスワード</label>
            <div style="display:flex; gap:10px; align-items:center;">
              <input type="password" name="currentPassword" id="currentPw"
                     placeholder="現在のパスワード" autocomplete="current-password" />
              <button class="btn" type="button" id="btnVerify" style="height:44px;">確認</button>
            </div>
            <div class="verified-badge" id="verifiedBadge" style="display:none;">認証完了</div>
          </div>

          <div id="newPwBox" style="<%= (pwVerified ? "" : "display:none;") %>">
            <div class="field">
              <label>新しいパスワード</label>
              <input type="password" name="newPassword" id="newPw"
                     placeholder="新しいパスワード" autocomplete="new-password" />
            </div>

            <div class="field">
              <label>新しいパスワード（確認）</label>
              <input type="password" name="confirmPassword" id="confirmPw"
                     placeholder="もう一度入力" autocomplete="new-password" />
              <div id="pwMismatchMsg" class="pw-mismatch">新しいパスワードが一致しません。</div>
            </div>
          </div>
        </div>

        <div class="actions" id="saveBox" style="<%= (pwVerified ? "" : "display:none;") %>">
          <button class="btn" type="submit" id="btnSave">保存</button>
        </div>
      </form>
    </section>
  </main>

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

    // ============================
    // ✅ Password Flow UI
    // ============================
    const pwForm = document.getElementById("pwForm");
    const actionField = document.getElementById("actionField");

    const btnChange = document.getElementById("btnChange");
    const verifyBox = document.getElementById("verifyBox");
    const btnVerify = document.getElementById("btnVerify");

    const verifiedBadge = document.getElementById("verifiedBadge");

    const newPwBox = document.getElementById("newPwBox");
    const saveBox = document.getElementById("saveBox");
    const newPw = document.getElementById("newPw");
    const confirmPw = document.getElementById("confirmPw");
    const btnSave = document.getElementById("btnSave");

    const pwMismatchMsg = document.getElementById("pwMismatchMsg");

    btnChange.addEventListener("click", () => {
      verifyBox.style.display = "block";
      btnVerify.textContent = "確認";
      btnVerify.disabled = false;
      verifiedBadge.style.display = "none";
      document.getElementById("currentPw").focus();
    });

    btnVerify.addEventListener("click", () => {
      actionField.value = "verify";
      pwForm.submit();
    });

    function validateNewPasswords() {
      if (!newPwBox || newPwBox.style.display === "none") return;

      const a = (newPw?.value || "").trim();
      const b = (confirmPw?.value || "").trim();

      if (a === "" || b === "") {
        if (pwMismatchMsg) pwMismatchMsg.style.display = "none";
        if (btnSave) btnSave.disabled = true;
        return;
      }

      if (a !== b) {
        if (pwMismatchMsg) pwMismatchMsg.style.display = "block";
        if (btnSave) btnSave.disabled = true;
      } else {
        if (pwMismatchMsg) pwMismatchMsg.style.display = "none";
        if (btnSave) btnSave.disabled = false;
      }
    }

    if (newPw) newPw.addEventListener("input", validateNewPasswords);
    if (confirmPw) confirmPw.addEventListener("input", validateNewPasswords);

    btnSave.addEventListener("click", (e) => {
      validateNewPasswords();
      if (btnSave.disabled) {
        e.preventDefault();
        return;
      }
      actionField.value = "save";
    });

    const pwVerified = <%= (pwVerified ? "true" : "false") %>;
    if (pwVerified) {
      verifyBox.style.display = "block";
      verifiedBadge.style.display = "block";
      btnVerify.textContent = "認証完了";
      btnVerify.disabled = true;

      newPwBox.style.display = "block";
      saveBox.style.display = "flex";

      if (newPw) newPw.focus();
      if (btnSave) btnSave.disabled = true;

      validateNewPasswords();
    }
  </script>
</body>
</html>
