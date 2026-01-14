<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    /* ===============================
       [1] セッションチェック
       =============================== */
    String sessionAdminId = (String) session.getAttribute("adminId");
    String sessionAdminName = (String) session.getAttribute("adminName");

    if (sessionAdminId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Connection connRoot = null;   // 管理者情報用 (root DB)
    Connection connWsms = null;   // 顧客・請求データ用 (wsms DB)
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    int totalCount = 0;   // 総顧客数
    int overdueCount = 0; // 滞納顧客数

    try {
        Class.forName("org.postgresql.Driver");

        /* ===============================
           [2] DB接続 (ダブル接続)
           =============================== */
        connRoot = DriverManager.getConnection("jdbc:postgresql://localhost:5432/root", "postgres", "1234");
        connWsms = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");

        /* ===============================
           [3] 管理者名の取得 (root DB)
           =============================== */
        String sqlAdmin = "SELECT name FROM \"Administrator\" WHERE id = ?";
        pstmt = connRoot.prepareStatement(sqlAdmin);
        pstmt.setString(1, sessionAdminId);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            sessionAdminName = rs.getString("name");
            session.setAttribute("adminName", sessionAdminName);
        }
        rs.close(); pstmt.close();

        /* ===============================
           [4] 総顧客数の照会 (wsms DB)
           =============================== */
        pstmt = connWsms.prepareStatement("SELECT COUNT(*) FROM public.customers");
        rs = pstmt.executeQuery();
        if (rs.next()) totalCount = rs.getInt(1);
        rs.close(); pstmt.close();

        /* ===============================
           [5] 滞納顧客数の計算 (wsms DB)
           - due_date削除に伴い、billing_dateを使用します。
           - 請求日(billing_date)から1ヶ月経過しても入金がない場合を滞納と見なします。
           =============================== */
        String overdueSql =
            "SELECT COUNT(DISTINCT b.\"customer_id\") " +
            "FROM public.\"bill\" b " +
            "LEFT JOIN public.\"deposit\" d " +
            "  ON b.\"customer_id\" = d.\"customer_id\" " +
            "WHERE b.\"billing_date\" < (CURRENT_DATE - INTERVAL '1 month') " +
            "  AND d.\"customer_id\" IS NULL";

        pstmt = connWsms.prepareStatement(overdueSql);
        rs = pstmt.executeQuery();
        if (rs.next()) overdueCount = rs.getInt(1);

%>
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>水道管理システム - ホーム</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: "Meiryo", "Hiragino Kaku Gothic ProN", sans-serif; margin: 0; background-color: #f8f9fa; }

        .navbar { background-color: #2c3e50; color: white; height: 60px; display: flex; align-items: center; padding: 0 30px; }
        .navbar-brand { font-size: 18px; font-weight: bold; color: #3498db; text-decoration: none; margin-right: 40px; }
        .nav-links { list-style: none; display: flex; gap: 25px; margin: 0; padding: 0; }
        .nav-links li a { color: #bdc3c7; text-decoration: none; font-size: 15px; font-weight: 500; }
        .nav-links li a.active { color: white; border-bottom: 2px solid #3498db; padding-bottom: 5px; }

        .admin-mini-bar { background: #fff; padding: 8px 30px; border-bottom: 1px solid #ddd; display: flex; justify-content: flex-end; font-size: 12px; color: #666; }
        .btn-logout { color: #e74c3c; text-decoration: none; margin-left: 15px; font-weight: bold; border: 1px solid #e74c3c; padding: 2px 8px; border-radius: 4px; }

        .main-container { max-width: 1200px; margin: 20px auto; padding: 0 20px; }

        .image-banner { width: 100%; height: 350px; background: #ccc; border-radius: 10px; margin-bottom: 30px; overflow: hidden; position: relative; }
        .image-banner img { width: 100%; height: 100%; object-fit: cover; }
        .banner-text { position: absolute; bottom: 30px; left: 30px; color: white; font-size: 28px; font-weight: bold; text-shadow: 2px 2px 8px rgba(0,0,0,0.7); }
        
        .summary-card { background: white; padding: 25px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); }
    </style>
</head>
<body>
    <nav class="navbar">
        <a href="main.jsp" class="navbar-brand">💧 SMART WATER JP</a>
        <ul class="nav-links">
            <li><a href="main.jsp" class="active">ホーム</a></li>
            <li><a href="customer_list.jsp">顧客リスト</a></li>
            <li><a href="overdue_list.jsp">滞納管理</a></li>
            <li><a href="district_manage.jsp">管轄区域管理</a></li>
        </ul>
    </nav>

    <div class="admin-mini-bar">
        <span>ログイン管理者: <b><%= (sessionAdminName != null ? sessionAdminName : "管理者") %></b> 様 (社員番号: <%= sessionAdminId %>)</span>
        <a href="logout.jsp" class="btn-logout">ログアウト</a>
    </div>

    <div class="main-container">
        <div class="image-banner">
            <img src="company_photo.jpg" onerror="this.src='https://via.placeholder.com/1200x350?text=Water+Works+Management'">
            <div class="banner-text">安全な水の管理、市民の幸せのために</div>
        </div>

        <div class="summary-card">
            <h3>📊 本日の業務要約</h3>
            <p style="font-size: 16px;">
                総顧客数: <b><%= String.format("%,d", totalCount) %></b> 名 | 
                滞納顧客数: <b style="color: #e74c3c;"><%= String.format("%,d", overdueCount) %></b> 名
            </p>

            <button onclick="location.href='overdue_list.jsp'"
                    style="background: #3498db; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; font-weight: bold;">
                滞納内訳を詳しく見る
            </button>
        </div>
    </div>
</body>
</html>
<%
    } catch (Exception e) {
        out.println("<div style='color:red; padding:20px;'>システムエラー: " + e.getMessage() + "</div>");
    } finally {
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (connRoot != null) try { connRoot.close(); } catch(Exception e) {}
        if (connWsms != null) try { connWsms.close(); } catch(Exception e) {}
    }
%>