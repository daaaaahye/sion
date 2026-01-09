<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%
    // [1. セキュリティ及びセッションチェック] ログイン状態の確認
    String sessionAdminId = (String) session.getAttribute("adminId");
    if (sessionAdminId == null) {
        response.sendRedirect("login.jsp"); 
        return;
    }

    String adminName = "";
    Connection connWsms = null;
    Connection connRoot = null;
    DecimalFormat df = new DecimalFormat("#,###원");

    try {
        Class.forName("org.postgresql.Driver");
        
        // [중요] 요청하신 대로 포트 5432를 사용하며, 각각 wsms와 root DB에 연결합니다.
        connRoot = DriverManager.getConnection("jdbc:postgresql://localhost:5432/root", "postgres", "");
        connWsms = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "");
        
        // [2. root DB의 Administrator 테이블에서 관리자 이름 조회]
        String sqlAdmin = "SELECT name FROM public.\"Administrator\" WHERE id = ?";
        PreparedStatement pstmtAdmin = connRoot.prepareStatement(sqlAdmin);
        pstmtAdmin.setString(1, sessionAdminId);
        ResultSet rsAdmin = pstmtAdmin.executeQuery();
        if(rsAdmin.next()) {
            adminName = rsAdmin.getString("name");
        }
%>
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>入金管理 - SMART WATER KR</title>
    <style>
        /* 기존 디자인 스타일 100% 유지 */
        * { box-sizing: border-box; }
        body { font-family: "Meiryo", "Hiragino Kaku Gothic ProN", sans-serif; margin: 0; background-color: #f8f9fa; color: #333; }
        .navbar { background-color: #2c3e50; color: white; height: 60px; display: flex; align-items: center; padding: 0 30px; position: sticky; top: 0; z-index: 1000; }
        .navbar-brand { font-size: 18px; font-weight: bold; color: #3498db; text-decoration: none; margin-right: 40px; }
        .nav-links { list-style: none; display: flex; gap: 25px; margin: 0; padding: 0; }
        .nav-links li a { color: #bdc3c7; text-decoration: none; font-size: 15px; font-weight: 500; }
        .nav-links li a.active { color: white; border-bottom: 3px solid #3498db; padding-bottom: 5px; }
        .admin-mini-bar { background: #fff; padding: 8px 30px; border-bottom: 1px solid #ddd; display: flex; justify-content: flex-end; font-size: 12px; color: #666; }
        .btn-logout { color: #e74c3c; text-decoration: none; margin-left: 15px; font-weight: bold; }
        .main-container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
        .content-card { background: white; border-radius: 12px; padding: 25px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
        .section-title { font-size: 20px; font-weight: bold; color: #2c3e50; margin-bottom: 20px; border-left: 5px solid #3498db; padding-left: 10px; }
        .table-wrapper { overflow-x: auto; width: 100%; }
        .data-table { width: 100%; border-collapse: collapse; min-width: 700px; }
        .data-table th { background: #f8f9fa; padding: 15px; text-align: center; border-bottom: 2px solid #eee; font-size: 14px; }
        .data-table td { padding: 15px; border-bottom: 1px solid #eee; text-align: center; font-size: 14px; }
        .btn-pay { background: #3498db; color: white; padding: 8px 15px; border-radius: 5px; text-decoration: none; font-weight: bold; font-size: 12px; }
        code { background:#e9ecef; padding:3px 6px; border-radius:4px; font-family: 'Consolas', monospace; }
    </style>
</head>
<body>
    <nav class="navbar">
        <a href="dbtest.jsp" class="navbar-brand">💧 SMART WATER KR</a>
        <ul class="nav-links">
            <li><a href="customer_list.jsp">顧客一覧</a></li>
            <li><a href="overdue_list.jsp">滞納者リスト</a></li>
            <li><a href="district_manage.jsp">管轄区域管理</a></li>
            <li><a href="deposit.jsp" class="active">入金管理</a></li>
        </ul>
    </nav>

    <div class="admin-mini-bar">
        <span>ログイン管理者: <b><%= adminName %></b> 様 (社員番号: <%= sessionAdminId %>)</span>
        <a href="logout.jsp" class="btn-logout">ログアウト</a>
    </div>

    <div class="main-container">
        <div class="content-card">
            <div class="section-title">💰 入金管理 (請求内訳照会)</div>
            
            <div class="table-wrapper">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>顧客番号</th>
                            <th>氏名</th>
                            <th>請求金額</th>
                            <th>納付期限</th>
                            <th>処理</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            // [3. wsms DB의 bill 테이블에서 미납 청구 내역 조회]
                            String sql = "SELECT b.customer_id, c.name, b.bill_amount, b.due_date " +
                                         "FROM public.bill b " +
                                         "JOIN public.customers c ON b.customer_id = c.customer_id " +
                                         "ORDER BY b.due_date ASC";
                            
                            Statement stmt = connWsms.createStatement();
                            ResultSet rs = stmt.executeQuery(sql);
                            boolean hasData = false;
                            while(rs.next()) {
                                hasData = true;
                        %>
                        <tr>
                            <td><code><%= rs.getString("customer_id") %></code></td>
                            <td><b><%= rs.getString("name") %> 様</b></td>
                            <td style="color: #e74c3c; font-weight: bold;"><%= df.format(rs.getLong("bill_amount")) %></td>
                            <td><%= rs.getDate("due_date") %></td>
                            <td>
                                <a href="pay_input.jsp?id=<%= rs.getString("customer_id") %>&amt=<%= rs.getLong("bill_amount") %>" class="btn-pay">入金処理</a>
                            </td>
                        </tr>
                        <% 
                            }
                            if(!hasData) {
                                out.println("<tr><td colspan='5' style='padding:50px; color:#999;'>未納の請求内訳がありません。</td></tr>");
                            }
                        %>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</body>
</html>
<%
    } catch (Exception e) {
        out.println("<div style='text-align:center; padding:20px; color:red;'>エラー発生: " + e.getMessage() + "</div>");
    } finally {
        if(connWsms != null) connWsms.close();
        if(connRoot != null) connRoot.close();
    }
%>