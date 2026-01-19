<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
   /* 로그인 확인 */
    String sessionAdminId = (String) session.getAttribute("adminId");
    String sessionAdminName = (String) session.getAttribute("adminName");
	
    if (sessionAdminId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Connection connWsms = null;   
    PreparedStatement pstmt = null;
    ResultSet rs = null;
	
    
    /* 총 고객수 & 미납자 변수 생성 및 초기화 */
    int totalCount = 0;   
    int unpaidCount = 0; 

    
    /* DB 연결 */
    try {
        Class.forName("org.postgresql.Driver");

        
        connWsms = DriverManager.getConnection(
            "jdbc:postgresql://localhost:5432/wsms",
            "postgres",
            "1234"
        );

        /* 총 고객수 계산 및 변수 저장 */
        String totalSql = "SELECT COUNT(*) FROM public.customers";
        
        pstmt = connWsms.prepareStatement(totalSql);
        rs = pstmt.executeQuery();
        if (rs.next()) totalCount = rs.getInt(1);
        rs.close(); pstmt.close();
        
        
        
        /* 미납자 수 계산 및 변수 저장 */
        String overdueSql =
        				 "SELECT COUNT(*) FROM (" +
        	             "    SELECT " +
        	             "        c.customer_id " +
        	             "    FROM public.customers c " +
        	             "    JOIN public.bill b ON c.customer_id = b.customer_id " +
        	             "    WHERE b.billing_date <= CURRENT_DATE " +
        	             "    GROUP BY c.customer_id " +
        	             "    HAVING (SELECT COALESCE(SUM(bill_amount), 0) FROM public.bill WHERE customer_id = c.customer_id AND billing_date <= CURRENT_DATE) " +
        	             "           - (SELECT COALESCE(SUM(paid_amount), 0) FROM public.deposit WHERE customer_id = c.customer_id AND paid_at <= CURRENT_DATE) > 0 " +
        	             ") AS unpaid_customers";
        
        pstmt = connWsms.prepareStatement(overdueSql);
        rs = pstmt.executeQuery();
        if (rs.next()) unpaidCount = rs.getInt(1);

        

%>
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>水道管理システム - メイン</title>
    <style>
    	* { box-sizing: border-box; }
		body { margin: 0;
      font-family: system-ui, -apple-system, Segoe UI, Roboto, "Noto Sans KR", Arial, sans-serif;
      background: #f5f6f8;
      color: #111827;}
		/* NAVBAR */
		/* NAVBAR (OFFICIAL) */
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

  /* ADMIN (OFFICIAL) */
  .admin-area{
  margin-left: auto;
  position: relative;
  display: flex;
  align-items: center;   /* ⭐ 핵심 */
  gap: 10px;
}

.admin-text{
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  line-height: 1.2;
  margin: 0;             /* 불필요한 여백 제거 */
  transform: none;       /* ⭐ 제거 */
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
      display: grid;
      place-items: center;
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
  
	  .admin-dropdown:hover{
	  opacity: 1;
	  visibility: visible;
	  pointer-events: auto;
	  transform: translateY(0);
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
      .dropdown-item:hover { 
    background: rgba(17,24,39,.06); 
    }
  

  .dropdown-item.logout {
    color: #b91c1c;
    font-weight: 800;
    font-size: 13px;
    font-weight: bold;
  }
  
  .dropdown-sep { height: 1px; background: rgba(17,24,39,.08); margin: 2px 0; }

  .dropdown-item.logout { color: #b91c1c; font-weight: 800; }

  .wrap{
      max-width: 1150px;
      margin: 18px auto 80px;
      padding: 0 22px;
  }
		
		/* MAINPAGE */
		.main-container { max-width: 1200px; margin: 20px auto; padding: 0 20px;}    
		.image-banner {position: relative; width: 100%; height: 550px; border-radius: 10px; overflow: hidden;}
		.image-banner img { width: 100%; height: 100%; object-fit: cover; }
		.banner-text { position: absolute; bottom: 30px; left: 30px; color: white; font-size: 28px; font-weight: bold; text-shadow: 2px 2px 8px rgba(0,0,0,0.7); }
		.sub-container{display: flex; gap: 20px; padding:20px 0 0 0;}
		.sub-banner{flex: 1; background: white; padding: 25px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.05);}
		.overdue-btn{background: #3498db; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; font-size:15px; font-weight:bold;}
		.sub-item{font-size:20px; font-weight:bold;}
		.sub-item2{font-size:15px;}
      
      
      /* 마우스를 admin-area(이름/사번/아이콘) 위에 올리면 열림 */
	.admin-area:hover .admin-dropdown{
	  opacity: 1;
	  visibility: visible;
	  pointer-events: auto;
	  transform: translateY(0);
	}
      
      
      #navIndicator{
		  position:absolute;
		  bottom: 8px;
		  height: 2px;
		  border-radius: 999px;
		  background: #2aa3ff;
		  opacity: 0;
		  transition: transform .18s ease, width .18s ease, opacity .18s ease;
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
      <li><a href="billing.jsp">請求管理</a></li>
    </ul>
    
    <div id="navIndicator"></div>
    

  <div class="admin-area" id="adminArea">
    <div class="admin-text">
      <div class="admin-name"><%= (sessionAdminName == null ? "" : sessionAdminName) %> 様</div>
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
        <div class="image-banner">
            <div class="img">
           		<img src="img/water.jpg" onerror="this.src='https://via.placeholder.com/1200x450?text=Slide+1'">
        	</div>
			<div class="banner-text">安全な水の管理、市民の幸せのために</div>
      </div>
      <div class ="sub-container">
      	<div class = "sub-banner">
           <p class = "sub-item">📊 本日の要約</p>
           <p class ="sub-item2"><%= String.format("%,d", totalCount) %> 名 | 滞納顧客数: <%= String.format("%,d", unpaidCount) %> 名</p>
           <button onclick="location.href='overdue_list.jsp'" class = " overdue-btn">
                    滞納内訳を詳しく見る
           </button>
        </div>
      </div>
    </div>
    <script>
	    
    const nav = document.getElementById('navLinks');
    const indicator = document.getElementById('navIndicator');
    const links = nav.querySelectorAll('a');

    function moveIndicatorTo(el) {
      const navRect = nav.getBoundingClientRect();
      const rect = el.getBoundingClientRect();
      const left = rect.left - navRect.left;
      indicator.style.width = rect.width + 'px';
      indicator.style.transform = `translateX(${left}px)`;
      indicator.style.opacity = '1';
    }

    links.forEach(a => {
      a.addEventListener('mouseenter', () => moveIndicatorTo(a));
      a.addEventListener('focus', () => moveIndicatorTo(a));
    });

    nav.addEventListener('mouseleave', () => {
      indicator.style.opacity = '0';
    });
    
    
 // ✅ ADMIN DROPDOWN (click to toggle)
    const adminArea = document.getElementById("adminArea");
    const adminDropdown = document.getElementById("adminDropdown");

    // admin-area 클릭(이름/사번/아이콘 포함) -> 토글
    adminArea.addEventListener("click", function (e) {
      e.stopPropagation();
      adminDropdown.classList.toggle("open");
    });

    // 드롭다운 내부 클릭 시 닫히지 않게
    adminDropdown.addEventListener("click", function (e) {
      e.stopPropagation();
    });

    // 바깥 클릭 시 닫기
    document.addEventListener("click", function () {
      adminDropdown.classList.remove("open");
    });

	</script>
</body>
</html>
<%
    } catch (Exception e) {
        out.println("에러 발생: " + e.getMessage());
    } finally { 
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (connWsms != null) try { connWsms.close(); } catch(Exception e) {}
    }
%>