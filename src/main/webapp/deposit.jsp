<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%
    request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html; charset=UTF-8");

    String sessionAdminId = (String) session.getAttribute("adminId");
    if (sessionAdminId == null) { response.sendRedirect("login.jsp"); return; }

    String searchStatus = request.getParameter("status");
    if (searchStatus == null) searchStatus = "all";

    int curPage = (request.getParameter("page") != null) ? Integer.parseInt(request.getParameter("page")) : 1;
    int pageSize = 10;
    int offset = (curPage - 1) * pageSize;
    int totalPages = 1;

    Connection conn = null;
    DecimalFormat df = new DecimalFormat("¥###,###");
    String adminName = "佐藤 健太郎"; 

    try {
        Class.forName("org.postgresql.Driver");
        conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");

        // [필터 조건] 날짜와 무관하게 deposit 테이블 존재 여부로 판단
        String condition = " WHERE 1=1 ";
        if(searchStatus.equals("unpaid")) condition += " AND d.customer_id IS NULL AND b.billing_date >= CURRENT_DATE - INTERVAL '1 month'";
        else if(searchStatus.equals("overdue")) condition += " AND d.customer_id IS NULL AND b.billing_date < CURRENT_DATE - INTERVAL '1 month'";
        else if(searchStatus.equals("paid")) condition += " AND d.customer_id IS NOT NULL";

        String countSql = "SELECT count(*) FROM bill b LEFT JOIN deposit d ON b.customer_id = d.customer_id " + condition;
        PreparedStatement pstmtCount = conn.prepareStatement(countSql);
        ResultSet rsCount = pstmtCount.executeQuery();
        if(rsCount.next()) {
            int totalRows = rsCount.getInt(1);
            totalPages = (int) Math.ceil((double)totalRows / pageSize);
            if(totalPages == 0) totalPages = 1;
        }
%>
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>入金管理 - SMART WATER KR</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">
    <style>
        body { font-family: "Meiryo", sans-serif; margin: 0; background-color: #f8f9fa; }
        .navbar { background-color: #2c3e50; color: white; height: 60px; display: flex; align-items: center; padding: 0 22px; }
        .navbar-brand { font-size: 18px; font-weight: bold; color: #3498db; text-decoration: none; margin-right: 40px; }
        .nav-links { list-style: none; display: flex; gap: 25px; margin: 0; padding: 0; }
        .nav-links li a { color: #bdc3c7; text-decoration: none; font-size: 14px; font-weight: 500; }
        .nav-links li a.active { color: white; border-bottom: 2px solid #3498db; padding-bottom: 5px; }
        .admin-bar { background: #fff; padding: 8px 30px; border-bottom: 1px solid #ddd; display: flex; justify-content: flex-end; font-size: 12px; color: #666; }
        .main-container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
        .content-card { background: white; border-radius: 10px; padding: 24px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); min-height: 500px; }
        
        .search-box { margin-bottom: 20px; background: #f1f3f5; padding: 15px; border-radius: 8px; display: flex; gap: 10px; }
        .btn-search { background: white; border: 1px solid #ddd; cursor: pointer; padding: 2px 10px; border-radius: 4px; height: 32px; }

        /* [보정] 테두리 명확화 및 중앙 정렬 */
        .list-table { width: 100%; border-collapse: collapse; table-layout: fixed; border: 1px solid #dee2e6; }
        .list-table th { background: #f8f9fa; padding: 12px; font-size: 16px; border: 1px solid #dee2e6; text-align: center; }
        .list-table td { padding: 12px; border: 1px solid #dee2e6; font-size: 14px; text-align: center; }
        .text-right { text-align: right !important; padding-right: 30px !important; } 

        /* [요청 반영] 성명 이름 파랗고 굵게 */
        .name-highlight { color: #3498db; font-weight: bold; }

        .badge { padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
        
        /* [요청 반영] 입금 확인 버튼 회색 채우기 */
        .btn-deposit { cursor: pointer; border: 1px solid #ccc; background-color: #f2f2f2; border-radius: 4px; padding: 4px 10px; color: #333; font-size: 13px; }
        .btn-deposit:hover { background-color: #e6e6e6; }

        .pagination { display: flex; justify-content: center; align-items: center; margin-top: 30px; }
        .page-item { display: flex; align-items: center; justify-content: center; width: 32px; height: 32px; border: 1px solid #dee2e6; background-color: #fff; margin: 0 2px; text-decoration: none; color: #333; font-size: 14px; }
        .page-item.active { background-color: #3498db; color: #fff; border-color: #3498db; font-weight: bold; }
        .jump-box { display: flex; justify-content: center; align-items: center; gap: 10px; margin-top: 20px; font-size: 14px; }
        .jump-input { width: 45px; height: 28px; text-align: center; border: 1px solid #ccc; border-radius: 4px; }
    </style>
    <script>
        function openPaymentPopup(customerId, billingDate, totalAmount) {
            let inputAmount = prompt("入金する金額を入力してください。\n(請求額: " + totalAmount + "円)", "");
            if (inputAmount === null) return;
            if (parseInt(inputAmount) !== totalAmount) {
                alert("金額が一致しません。金額をもう一度確認してください。");
                return;
            }
            if (confirm("入金を完了しますか？")) {
                location.href = "pay_action.jsp?id=" + customerId + "&date=" + billingDate + "&amount=" + inputAmount;
            }
        }
        function goToPage() {
            let pageNum = document.getElementById("jumpPageInput").value;
            if (pageNum > 0 && pageNum <= <%= totalPages %>) {
                location.href = "?status=<%= searchStatus %>&page=" + pageNum;
            } else { alert("1から<%= totalPages %>の数字を入力してください。"); }
        }
    </script>
</head>
<body>
    <nav class="navbar">
        <a href="dbtest.jsp" class="navbar-brand">💧 SMART WATER KR</a>
        <ul class="nav-links">
            <li><a href="dbtest.jsp">ホーム</a></li>
            <li><a href="customer_list.jsp">顧客一覧</a></li>
            <li><a href="overdue_list.jsp">滞納者リスト</a></li>
            <li><a href="deposit.jsp" class="active">入金管理</a></li>
            <li><a href="district_manage.jsp">管轄区域管理</a></li>
        </ul>
    </nav>
    <div class="admin-bar"><span>ログイン管理者: <b><%= adminName %></b> 様</span></div>

    <div class="main-container">
        <div class="content-card">
            <h2>💰 入金管理</h2>
            
            <form class="search-box" method="get">
                <select name="status" style="padding:5px; border-radius:4px; border:1px solid #ddd;">
                    <option value="all" <%= searchStatus.equals("all") ? "selected" : "" %>>全体</option>
                    <option value="unpaid" <%= searchStatus.equals("unpaid") ? "selected" : "" %>>未納</option>
                    <option value="overdue" <%= searchStatus.equals("overdue") ? "selected" : "" %>>延滞</option>
                    <option value="paid" <%= searchStatus.equals("paid") ? "selected" : "" %>>完納</option>
                </select>
                <button type="submit" class="btn-search"><i class="bi bi-search"></i></button>
            </form>

            <table class="list-table">
                <thead>
                    <tr><th>氏名</th><th>請求日</th><th>請求金額</th><th>入金状態</th><th>処理</th></tr>
                </thead>
                <tbody>
                    <%
                        // [핵심 수정] 날짜 조건 제외, customer_id 존재 여부로만 완납 판별
                        String sql = "SELECT c.name, b.customer_id, b.billing_date, b.bill_amount, " +
                                     "(SELECT paid_at FROM deposit WHERE customer_id = b.customer_id LIMIT 1) as paid_record " +
                                     "FROM bill b JOIN customers c ON b.customer_id = c.customer_id " +
                                     "LEFT JOIN deposit d ON b.customer_id = d.customer_id " +
                                     condition + " GROUP BY c.name, b.customer_id, b.billing_date, b.bill_amount " +
                                     "ORDER BY b.billing_date DESC LIMIT ? OFFSET ?";
                        
                        PreparedStatement pstmt = conn.prepareStatement(sql);
                        pstmt.setInt(1, pageSize); pstmt.setInt(2, offset);
                        ResultSet rs = pstmt.executeQuery();


                        while(rs.next()){
                            String cid = rs.getString("customer_id"); String bDateStr = rs.getString("billing_date"); long amount = rs.getLong("bill_amount");
                            // paid_record가 존재하면 날짜 상관없이 이 고객은 입금한 것으로 간주
                            boolean isPaid = (rs.getTimestamp("paid_record") != null);
                            Date bDate = rs.getDate("billing_date");
                            boolean isOverdue = bDate.before(new java.util.Date(System.currentTimeMillis() - 2592000000L));
                    %>
                    <tr>
                        <td><span class="name-highlight"><%= rs.getString("name") %></span> 様</td>
                        <td><%= bDateStr %></td>
                        <td class="text-right"><%= df.format(amount) %></td>
                        <td>
                            <% if(isPaid) { %> <span class="badge" style="background:#e8faf0; color:#2ecc71;">完納</span>
                            <% } else if(isOverdue) { %> <span class="badge" style="background:#ffdada; color:#e74c3c;">延滞</span>
                            <% } else { %> <span class="badge" style="background:#fff5f5; color:#c0392b;">未納</span> <% } %>
                        </td>
                        <td>
                            <% if(!isPaid) { %>
                                <button onclick="openPaymentPopup('<%= cid %>', '<%= bDateStr %>', <%= amount %>)" class="btn-deposit">入金</button>
                            <% } else { %> - <% } %>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>

    <% 
    //파일 수정 테스트..............................................
        // POST 방식으로 데이터가 전송되었을 때 처리
        String amountStr = request.getParameter("amount");
        if (amountStr != null && !amountStr.isEmpty()) {
            try {
                int amount = Integer.parseInt(amountStr);
    %>
                <div style="color: blue; font-weight: bold;">
                    ✅ 결과: <%= amount %>원이 정상적으로 입금되었습니다!
                </div>
    <% 
            } catch (NumberFormatException e) {
    %>
                <div style="color: red;">숫자만 입력 가능합니다.</div>
    <% 
            }
        } 
    %>
</div>


            <div class="pagination">
                <a href="?status=<%=searchStatus%>&page=1" class="page-item">«</a>
                <a href="?status=<%=searchStatus%>&page=<%= Math.max(1, curPage-1) %>" class="page-item">‹</a>
                <% for(int i=Math.max(1, curPage-2); i<=Math.min(totalPages, Math.max(1, curPage-2)+4); i++) { %>
                    <a href="?status=<%=searchStatus%>&page=<%=i%>" class="page-item <%= (i==curPage) ? "active" : "" %>"><%=i%></a>
                <% } %>
                <a href="?status=<%=searchStatus%>&page=<%= Math.min(totalPages, curPage+1) %>" class="page-item">›</a>
                <a href="?status=<%=searchStatus%>&page=<%= totalPages %>" class="page-item">»</a>
            </div>
            <div class="jump-box">
                <input type="number" id="jumpPageInput" class="jump-input" value="<%= curPage %>"> / <%= totalPages %>
                <button onclick="goToPage()" style="background:#346aff; color:white; border:none; border-radius:4px; padding:4px 10px; cursor:pointer;">移動</button>
            </div>
        </div>
    </div>
</body>
</html>
<%
    } catch (Exception e) { out.println("Error: " + e.getMessage()); } finally { if(conn != null) conn.close(); }
%>