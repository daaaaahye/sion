<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" 
isELIgnored="true" import="java.text.NumberFormat" %>
<%@ include file="db/db.jsp" %>
<%
PreparedStatement pstmt = null;
PreparedStatement pstmtDate = null;
PreparedStatement pstmtData = null;
ResultSet rs = null;
ResultSet rsDate = null;
ResultSet rsData = null;
String sql = null;
String name = request.getParameter("name");
String id = request.getParameter("customer_id");
String amount = request.getParameter("bill_amount");
String billingDate = request.getParameter("billing_date");
%>


<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>월별 청구 내역 - SMART WATER</title>
    <link rel="stylesheet" href="css/billing_list.css" >
</head>
<body>
    <nav class="navbar">
    	<a href="main.jsp" class="navbar-brand">💧 SMART WATER</a>
	    <ul class="nav-links" id="navLinks">
	    	<li><a href="customer_list.jsp">고객 리스트</a></li>
	        <li><a href="district.jsp">관할 구역 관리</a></li>
	        <li><a href="overdue.jsp">연체 관리</a></li>
	        <li><a href="#">입금 관리</a></li>
            <li><a href="#" class="active">청구 관리 </a></li>
            <li class="nav-indicator" id="navIndicator"></li>
	    </ul>
	
	  <div class="admin-area">
	    <div class="admin-text">
	        <div class="admin-name">김 아무개 님</div>
	        <div class="admin-id">사번 2401309</div>
	    </div>
	    <div class="admin-icon">
            <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
                <path d="M12 12c2.76 0 5-2.46 5-5.5S14.76 1 12 1 7 3.46 7 6.5 9.24 12 12 12Z" stroke="#111827" stroke-width="1.6"/>
                <path d="M3 23c0-4.2 4-7.6 9-7.6s9 3.4 9 7.6" stroke="#111827" stroke-width="1.6" stroke-linecap="round"/>
            </svg>
	    </div>
	  </div>
	</nav>
	<form class="search-box" method="get">
	<div class="search-group">
		<label>고객 조회</label>
		<input type="text" name="name" value="<%= name != null ? name : "" %>" placeholder="이름을 입력하세요">
<select name="billing_date" onchange="this.form.submit()">
    <option value="">날짜를 선택하세요</option>
<%
String dateSql;

if (name != null && !name.trim().isEmpty()) {
    dateSql =
        "SELECT DISTINCT b.billing_date " +
        "FROM bill b " +
        "JOIN customers c ON b.customer_id = c.customer_id " +
        "WHERE c.name LIKE ? " +
        "ORDER BY b.billing_date";
    pstmtDate = conn.prepareStatement(dateSql);
    pstmtDate.setString(1, "%" + name + "%");
} else {
    dateSql =
        "SELECT DISTINCT billing_date FROM bill ORDER BY billing_date";
    pstmtDate = conn.prepareStatement(dateSql);
}

rsDate = pstmtDate.executeQuery();
while (rsDate.next()) {
    String d = rsDate.getDate("billing_date").toString();
%>
<option value="<%= d %>" <%= d.equals(billingDate) ? "selected" : "" %>>
 <%= d %>
</option>
<%
}
rsDate.close();
pstmtDate.close();
%>
</select>
	<option value=""></option>
	</div>
	<button type="submit" class="btn-search">검색</button>
	<button type="reset" class="btn-reset" onclick="location.href='billing_list.jsp'" >초기화</button>
</form>

<%
sql =
"SELECT c.customer_id, c.name, b.billing_date, b.bill_amount " +
"FROM customers c " +
"JOIN bill b ON c.customer_id = b.customer_id " +
"JOIN ( " +
"   SELECT customer_id, MAX(billing_date) AS latest_date " +
"   FROM bill " +
"   GROUP BY customer_id " +
") lb ON b.customer_id = lb.customer_id " +
"     AND b.billing_date = lb.latest_date ";

if (name != null && !name.trim().isEmpty()) {
sql +=" WHERE c.name LIKE ? ";
}
sql+=" ORDER BY c.customer_id";
pstmt = conn.prepareStatement(sql);
if (name != null && !name.trim().isEmpty()) {
pstmt.setString(1, "%" + name + "%");
}

rs = pstmt.executeQuery();
%>
<div class="main-container">
    <div class="content-card">
        <div class="header-section">
            <div class="title">🗓️ 청구 내역 </div>
        </div>
       	<div class = "customer">
         <table class="billing-table">
             <thead>
                 <tr>
                 	<th>회원 번호</th>
                 	<th>고객명</th>
                     <!-- <th>날짜 조회</th> -->
              <th>청구 금액</th>
              <!-- <th>납부 상태</th> -->
        <th>고지서 조회</th>
    </tr>
</thead>
<tbody>
<% 
while (rs.next()){

%>
<tr>
<td><%= rs.getString("customer_id") %></td>
<td><%= rs.getString("name") %></td>
<%-- <td>¥ <%= rs.getInt("bill_amount") %></td> --%>
<td>
<% 
int billAmount = 0;
if(billingDate != null && !billingDate.isEmpty()){
	String dataSql =
			"SELECT bill_amount FROM bill WHERE customer_id=? AND billing_date=?";
	pstmtData=conn.prepareStatement(dataSql);
	pstmtData.setString(1,rs.getString("customer_id"));
	pstmtData.setDate(2,java.sql.Date.valueOf(billingDate));
	
	rsData=pstmtData.executeQuery();
	if (rsData.next()){
		billAmount=rsData.getInt("bill_amount");
	}
	rsData.close();
	pstmtData.close();
}
NumberFormat nf = NumberFormat.getInstance();
String formattedAmount = nf.format(billAmount);
%>
¥ <%= formattedAmount %>
</td>
<!-- <td></td> -->
<td><button class="btn-view" type="button" 
    onclick="location.href='billing.jsp?customer_id=<%= rs.getString("customer_id") %>&billing_date=<%= (billingDate != null && rs.getString("customer_id").equals(id)) ? billingDate : rs.getDate("billing_date") %>'" 
    class="active">고지서 조회</button></td>
</tr>
<% 
}

%>
                </tbody>
                
            </table>
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
<%
if (rs != null) rs.close();
if (pstmt != null) pstmt.close();
if (conn != null) conn.close();
%>
</body>
</html>