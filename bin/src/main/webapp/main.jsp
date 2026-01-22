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
		body { font-family: "Meiryo", "Hiragino Kaku Gothic ProN", sans-serif; margin: 0; background-color: #f8f9fa; }
		
		/* NAVBAR */
		.navbar {height: 56px; background: #243646; display: flex; align-items: center; padding: 0 22px; gap: 26px;}
		.navbar-brand {font-weight: 800; font-size: 16px; color: #2aa3ff; text-decoration: none;white-space: nowrap;} 
		.nav-links {list-style: none; display: flex; align-items: center; gap: 22px; margin: 0; padding: 0; position: relative;}
		.nav-links a { color: #cbd5e1; text-decoration: none; font-size: 13px; font-weight: 600; padding: 18px 4px 14px; white-space: nowrap;display: inline-block;}
		.nav-links a:hover {color: #ffffff;}
		.nav-indicator {position: absolute; left: 0; bottom: 6px; height: 2px; width: 0; background: #2aa3ff; border-radius: 999px; transform: translateX(0); 
						transition: transform .22s ease, width .22s ease, opacity .18s ease; opacity: 0; pointer-events: none; list-style : none;}
		
		/* ADMIN */
		.admin-area {margin-left: auto; position: relative; display: flex; align-items: center; gap: 10px; padding-bottom: 14px;} 
		.admin-text {display: flex; flex-direction: column; align-items: flex-end; line-height: 1.1;}
		.admin-name { font-size: 12px; font-weight: 700; color: #e5edf5;}
		.admin-id { font-size: 11px; color: #9fb0c3; }
		.admin-icon { width: 30px; height: 30px; border-radius: 50%; background: rgba(255,255,255,.92);
		  			  display: grid; place-items: center;}
		.admin-dropdown { position: absolute; top: 100%; right: 0; margin-top: 6px; min-width: 120px; background: rgba(255,255,255,.72);
		  backdrop-filter: blur(10px); border-radius: 12px; box-shadow: 0 16px 36px rgba(0,0,0,.18); opacity: 0; visibility: hidden;
		  pointer-events: none; transform: translateY(6px); transition: .16s; z-index : 100; }
		.admin-area:hover .admin-dropdown {opacity: 1; visibility: visible; pointer-events: auto; transform: translateY(0); }
		.dropdown-item { padding: 9px 12px; font-size: 13px; text-decoration: none; color: #111827; display: block;}
		.dropdown-item.logout { color: #b91c1c; font-weight: 800; font-size : 13px; font-weight : bold;}
		
		
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
      
    </style>
</head>
<body>
    <nav class="navbar">
    <a href="#" class="navbar-brand">💧 SMART WATER</a>
	  <ul class="nav-links" id="navLinks">
	      <li><a href="#">고객 리스트</a></li>
	      <li><a href="#">관할 구역 관리</a></li>
	      <li><a href="#">연체 관리</a></li>
	      <li><a href="#">입금 관리</a></li>
          <li><a href="#">청구 관리 </a></li>
          <li class="nav-indicator" id="navIndicator"></li>
	  </ul>
	  
	
	  <div class="admin-area">
	    <div class="admin-text">
	      <div class="admin-name">관리자명</div>
	      <div class="admin-id">사번 000000</div>
	    </div>
	
	    <div class="admin-icon">👤</div>
	
	    <div class="admin-dropdown">
	      <a href="#" class="dropdown-item">設定</a>
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
                    滞納内訳を詳しく見る<!-- 체납내역을 보러가다 --> 
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
