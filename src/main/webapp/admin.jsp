<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SMART WATER JP</title>

<style>
*{box-sizing:border-box}
body{
  margin:0;
  font-family:system-ui,-apple-system,Segoe UI,Roboto,"Noto Sans KR",Arial,sans-serif;
  background:#f5f6f8;
  color:#111827;
}

/* ================= NAVBAR ================= */
.navbar{
  height:56px;
  background:#243646;
  display:flex;
  align-items:center;
  padding:0 22px;
  gap:26px;
}

.navbar-brand{
  font-weight:800;
  font-size:16px;
  color:#2aa3ff;
  text-decoration:none;
}

/* ================= MENU ================= */
.nav-links{
  list-style:none;
  display:flex;
  gap:22px;
  margin:0;
  padding:0;
  position:relative;
}

.nav-links a{
  color:#cbd5e1;
  text-decoration:none;
  font-size:13px;
  font-weight:600;
  padding:18px 4px 14px;
}

.nav-links a:hover{color:#fff}

/* === single moving indicator === */
.nav-indicator{
  position:absolute;
  bottom:6px;
  height:2px;
  background:#2aa3ff;
  border-radius:999px;
  opacity:0;
  transition:transform .25s ease,width .25s ease,opacity .2s ease;
  pointer-events:none;
}

/* ================= ADMIN ================= */
.admin-area{
  margin-left:auto;
  position:relative;
  display:flex;
  align-items:center;
  gap:10px;

  /* ✅ 핵심: 아이콘 → 드롭다운으로 내려갈 때 hover가 끊기지 않게 “브리지” 만들기 */
  padding-bottom:14px;
}

.admin-text{
  display:flex;
  flex-direction:column;
  align-items:flex-end;
  line-height:1.1;
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
  display:grid;
  place-items:center;
  box-shadow:0 0 0 2px rgba(255,255,255,.28);
  cursor:pointer;
}

/* ================= DROPDOWN ================= */
.admin-dropdown{
  position:absolute;
  top:100%;
  right:0;
  margin-top:6px;       /* ✅ 브리지랑 이어지게 살짝만 띄움 */
  min-width:120px;

  background:rgba(255,255,255,.75);
  backdrop-filter:blur(10px);
  border:1px solid rgba(229,231,235,.9);
  border-radius:12px;
  box-shadow:0 16px 36px rgba(0,0,0,.18);

  display:flex;
  flex-direction:column;
  overflow:hidden;
  z-index:1000;

  /* 기본 닫힘 */
  opacity:0;
  visibility:hidden;
  transform:translateY(6px);
  pointer-events:none;

  transition:opacity .18s ease,transform .18s ease,visibility .18s;
}

/* ✅ 핵심: hover면 열림 (admin-area 위에 있거나, dropdown 위에 있어도 유지) */
.admin-area:hover .admin-dropdown,
.admin-dropdown:hover{
  opacity:1;
  visibility:visible;
  transform:translateY(0);
  pointer-events:auto;
}

.dropdown-item{
  padding:9px 12px;
  font-size:13px;
  color:#111827;
  text-decoration:none;
}
.dropdown-item:hover{
  background:rgba(17,24,39,.06);
}

.dropdown-sep{
  height:1px;
  background:rgba(17,24,39,.08);
}

.dropdown-item.logout{
  color:#b91c1c;
  font-weight:800;
}

/* ================= PAGE ================= */
.wrap{
  max-width:1150px;
  margin:18px auto 80px;
  padding:0 22px;
}
.page-title h1{
  margin:0;
  font-size:26px;
  font-weight:800;
}
.page-title p{
  margin-top:6px;
  font-size:13px;
  color:#8a94a6;
}
.card{
  margin-top:14px;
  background:#fff;
  border:1px solid #e7ebf0;
  border-radius:14px;
  padding:22px;
  box-shadow:0 6px 18px rgba(17,24,39,.06);
}
</style>
</head>

<body>

<nav class="navbar">
  <a class="navbar-brand">💧 SMART WATER JP</a>

  <ul class="nav-links" id="navLinks">
    <li><a>ホーム</a></li>
    <li><a>顧客一覧</a></li>
    <li><a>滞納者リスト</a></li>
    <li><a>管轄区域管理</a></li>
    <span class="nav-indicator" id="navIndicator"></span>
  </ul>

  <div class="admin-area">
    <div class="admin-text">
      <div class="admin-name">佐藤 健太 様</div>
      <div class="admin-id">社員番号 8753210</div>
    </div>

    <div class="admin-icon" id="adminBtn">
      👤
    </div>

    <div class="admin-dropdown" id="adminDropdown">
      <a class="dropdown-item">設定</a>
      <div class="dropdown-sep"></div>
      <a class="dropdown-item logout">ログアウト</a>
    </div>
  </div>
</nav>

<main class="wrap">
  <section class="page-title">
    <h1>설정</h1>
    <p>시스템 설정을 관리하세요</p>
  </section>

  <section class="card">
    설정 화면
  </section>
</main>

<script>
/* ===== 메뉴 밑줄 이동 ===== */
const nav = document.getElementById('navLinks');
const indicator = document.getElementById('navIndicator');
nav.querySelectorAll('a').forEach(a=>{
  a.addEventListener('mouseenter',()=>{
    const r=a.getBoundingClientRect();
    const n=nav.getBoundingClientRect();
    indicator.style.width=r.width+'px';
    indicator.style.transform=`translateX(${r.left-n.left}px)`;
    indicator.style.opacity=1;
  });
});
nav.addEventListener('mouseleave',()=>indicator.style.opacity=0);

/* ✅ hover 방식이므로 클릭 토글 JS는 제거 (필요 없음) */
</script>

</body>
</html>
