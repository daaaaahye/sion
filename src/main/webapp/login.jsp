<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>管理者ログイン - SMART WATER JP</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <style>
    body {
      font-family: "Meiryo", "Hiragino Kaku Gothic ProN", sans-serif;
      background: #2c3e50;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
    }

    .login-card {
      background: white;
      padding: 40px;
      border-radius: 12px;
      box-shadow: 0 10px 25px rgba(0,0,0,0.3);
      width: 380px;
      text-align: center;
    }

    .login-card h2 {
      color: #2c3e50;
      margin-bottom: 6px;
      font-size: 22px;
      font-weight: 800;
    }

    .admin-guide {
      font-size: 12px;
      color: #7f8c8d;
      margin-bottom: 26px;
    }

    .input-group {
      margin-bottom: 18px;
      text-align: left;
    }

    .input-group label {
      display: block;
      font-size: 13px;
      color: #7f8c8d;
      margin-bottom: 6px;
      font-weight: bold;
    }

    .input-group input {
      width: 100%;
      padding: 12px;
      border: 1px solid #ddd;
      border-radius: 5px;
      box-sizing: border-box;
      font-size: 14px;
      outline: none;
    }

    .input-group input:focus {
      border-color: #3498db;
      box-shadow: 0 0 0 3px rgba(52,152,219,0.15);
    }

    .password-wrap {
      position: relative;
    }

    .toggle-eye {
      position: absolute;
      right: 10px;
      top: 50%;
      transform: translateY(-50%);
      padding: 6px 10px;
      font-size: 12px;
      border: 1px solid #ddd;
      background: #f3f4f6;
      border-radius: 6px;
      cursor: pointer;
      color: #34495e;
    }
    .toggle-eye:hover { background: #e9ecef; }

    .caps-msg {
      display: none;
      margin-top: 8px;
      font-size: 12px;
      color: #e67e22;
      font-weight: 700;
    }

    .btn-login {
      width: 100%;
      padding: 15px;
      background: #3498db;
      color: white;
      border: none;
      border-radius: 5px;
      font-weight: bold;
      cursor: pointer;
      transition: 0.3s;
      font-size: 16px;
      margin-top: 6px;
    }
    .btn-login:hover { background: #2980b9; }

    .error-msg {
      color: #e74c3c;
      font-size: 12px;
      margin: 14px 0 12px;
      background: #fdf2f2;
      padding: 10px;
      border-radius: 6px;
      font-weight: 700;
    }
  </style>
</head>

<body>
  <div class="login-card">
    <h2>💧 SMART WATER JP</h2>
    <div class="admin-guide">上水道料金 管理者専用システムです。</div>

    <!-- ✅ HTML5 기본 validation 유지 -->
    <form id="loginForm" action="login_process.jsp" method="post" autocomplete="off">
      <div class="input-group">
        <label>社員番号 (ID)</label>
        <input type="text" name="emp_id" id="emp_id" placeholder="社員番号を入力してください" required>
      </div>

      <div class="input-group">
        <label>パスワード</label>

        <div class="password-wrap">
          <input type="password" name="password" id="password" placeholder="パスワードを入力してください" required>
          <button type="button" class="toggle-eye" id="toggleBtn">表示</button>
        </div>

        <div class="caps-msg" id="capsMsg">Caps Lock が ON です。</div>
      </div>

      <%-- 로그인 실패 시 에러 메시지 --%>
      <% if(request.getParameter("error") != null) { %>
        <div class="error-msg">
          社員番号またはパスワードが<br>正しくありません。
        </div>
      <% } %>

      <button type="submit" class="btn-login">ログイン</button>
    </form>
  </div>

  <script>
    // ✅ 비밀번호 보기 토글
    const pw = document.getElementById("password");
    const toggleBtn = document.getElementById("toggleBtn");

    toggleBtn.addEventListener("click", () => {
      const isHidden = (pw.type === "password");
      pw.type = isHidden ? "text" : "password";
      toggleBtn.textContent = isHidden ? "非表示" : "表示";
      pw.focus();
    });

    // ✅ CapsLock 감지
    const capsMsg = document.getElementById("capsMsg");
    pw.addEventListener("keyup", (e) => {
      if (e.getModifierState && e.getModifierState("CapsLock")) {
        capsMsg.style.display = "block";
      } else {
        capsMsg.style.display = "none";
      }
    });
    pw.addEventListener("blur", () => {
      capsMsg.style.display = "none";
    });

    // ✅ (2번 방식) 브라우저 말풍선 문구를 일본어로 고정
    const idInput = document.getElementById("emp_id");

    idInput.addEventListener("invalid", () => {
      idInput.setCustomValidity("社員番号を入力してください。");
    });
    pw.addEventListener("invalid", () => {
      pw.setCustomValidity("パスワードを入力してください。");
    });

    idInput.addEventListener("input", () => {
      idInput.setCustomValidity("");
    });
    pw.addEventListener("input", () => {
      pw.setCustomValidity("");
    });
  </script>
</body>
</html>
