<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
<%@ page import="java.util.*" %>
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

<%
    String sessionAdminId = (String) session.getAttribute("adminId");
    if (sessionAdminId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String adminName = (String) session.getAttribute("adminName");
    if (adminName == null) adminName = "管理者";

    request.setCharacterEncoding("UTF-8");

    Connection connRoot = null;
    Connection connWsms = null;

    try {
        Class.forName("org.postgresql.Driver");

        connRoot = DriverManager.getConnection("jdbc:postgresql://localhost:5432/root", "postgres", "1234");
        connWsms = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");

        String sqlAdmin = "SELECT name FROM \"Administrator\" WHERE id = ?";
        PreparedStatement pstmtAdmin = connRoot.prepareStatement(sqlAdmin);
        pstmtAdmin.setString(1, sessionAdminId);
        ResultSet rsAdmin = pstmtAdmin.executeQuery();

        if(rsAdmin.next()) {
            adminName = rsAdmin.getString("name");
            session.setAttribute("adminName", adminName);
        }
%>

<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>請求履歴 - SMART WATER</title>
  <link rel="stylesheet" href="css/billing_list.css">
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

<%
    if (billingDate != null && !billingDate.isEmpty()) {
        sql =
        "SELECT c.customer_id, c.name, b.billing_date, b.bill_amount " +
        "FROM customers c " +
        "JOIN bill b ON c.customer_id = b.customer_id " +
        "WHERE b.billing_date = ? ";

        if (name != null && !name.trim().isEmpty()) {
            sql += " AND c.name LIKE ? ";
        }

        sql += " ORDER BY c.customer_id";

        pstmt = connWsms.prepareStatement(sql);
        pstmt.setDate(1, java.sql.Date.valueOf(billingDate));

        if (name != null && !name.trim().isEmpty()) {
            pstmt.setString(2, "%" + name + "%");
        }

    } else {
        sql =
        "SELECT c.customer_id, c.name, b.billing_date, b.bill_amount " +
        "FROM customers c " +
        "JOIN bill b ON c.customer_id = b.customer_id " +
        "JOIN ( " +
        "   SELECT customer_id, MAX(billing_date) AS latest_date " +
        "   FROM bill GROUP BY customer_id " +
        ") lb ON b.customer_id = lb.customer_id " +
        "AND b.billing_date = lb.latest_date ";

        if (name != null && !name.trim().isEmpty()) {
            sql += " WHERE c.name LIKE ? ";
        }

        sql += " ORDER BY c.customer_id";

        pstmt = connWsms.prepareStatement(sql);

        if (name != null && !name.trim().isEmpty()) {
            pstmt.setString(1, "%" + name + "%");
        }
    }

    rs = pstmt.executeQuery();
%>

  <div class="main-container">
    <div class="content-card">
    	<div class="title">🗓️ 請求履歴</div>
        <div class="search-notice">
        ※ 名前と日付を入力してください。<br>
        ※ 日付を選択しないと、お客様の最近の通知が照会されます。
        </div>

      <div class="customer">
        <form class="search-box" method="get" action="billing_list.jsp">
          <div class="search-group">
            <label>顧客の照会</label>
            <input type="text" name="name" value="<%= name != null ? name : "" %>" placeholder="名前を入力してください">
          </div>

          <div class="search-group">
            <label>日付を選択してください</label>
            <select name="billing_date" onchange="this.form.submit()">
              <option value="">日付を選択してください</option>

              <%
                String dateSql;

                if (name != null && !name.trim().isEmpty()) {
                    dateSql =
                        "SELECT DISTINCT b.billing_date " +
                        "FROM bill b " +
                        "JOIN customers c ON b.customer_id = c.customer_id " +
                        "WHERE c.name LIKE ? " +
                        "ORDER BY b.billing_date";
                    pstmtDate = connWsms.prepareStatement(dateSql);
                    pstmtDate.setString(1, "%" + name + "%");
                } else {
                    dateSql =
                        "SELECT DISTINCT billing_date FROM bill ORDER BY billing_date";
                    pstmtDate = connWsms.prepareStatement(dateSql);
                }

                rsDate = pstmtDate.executeQuery();
                while (rsDate.next()) {
                    String d = rsDate.getDate("billing_date").toString();
              %>
              <option value="<%= d %>" <%= (billingDate != null && d.equals(billingDate)) ? "selected" : "" %>><%= d %></option>
              <%
                }
                if (rsDate != null) try { rsDate.close(); } catch(Exception e) {}
                if (pstmtDate != null) try { pstmtDate.close(); } catch(Exception e) {}
              %>
            </select>
          </div>

          <button type="submit" class="btn-search">検索</button>
          <button type="button" class="btn-reset" onclick="location.href='billing_list.jsp'">初期化</button>
        </form>

        <table class="billing-table">
          <thead>
            <tr>
              <th>会員番号</th>
              <th>顧客名</th>
              <th>請求額</th>
              <th>通知書の照会</th>
            </tr>
          </thead>
          <tbody>
            <%
              while (rs.next()) {
                int billAmount = 0;

                if (billingDate != null && !billingDate.isEmpty()) {
                    String dataSql = "SELECT bill_amount FROM bill WHERE customer_id=? AND billing_date=?";
                    pstmtData = connWsms.prepareStatement(dataSql);
                    pstmtData.setString(1, rs.getString("customer_id"));
                    pstmtData.setDate(2, java.sql.Date.valueOf(billingDate));

                    rsData = pstmtData.executeQuery();
                    if (rsData.next()) billAmount = rsData.getInt("bill_amount");

                    if (rsData != null) try { rsData.close(); } catch(Exception e) {}
                    if (pstmtData != null) try { pstmtData.close(); } catch(Exception e) {}
                } else {
                    billAmount = rs.getInt("bill_amount");
                }

                NumberFormat nf = NumberFormat.getInstance();
                String formattedAmount = nf.format(billAmount);
            %>
            <tr>
              <td><%= rs.getString("customer_id") %></td>
              <td><%= rs.getString("name") %></td>
              <td>¥ <%= formattedAmount %></td>
              <td>
                <button class="btn-view" type="button"
                  onclick="location.href='billing_list_detail.jsp?customer_id=<%= rs.getString("customer_id") %>&billing_date=<%= rs.getString("billing_date") %>'">
                  通知書の照会
                </button>
              </td>
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

<%
    } catch (Exception e) {
        out.println("에러 발생: " + e.getMessage());
    } finally {
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (connRoot != null) try { connRoot.close(); } catch(Exception e) {}
        if (connWsms != null) try { connWsms.close(); } catch(Exception e) {}
    }
%>
