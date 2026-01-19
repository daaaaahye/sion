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
    // 1. 세션 체크: 관리자 로그인 상태 확인
    String sessionAdminId = (String) session.getAttribute("adminId");
    if (sessionAdminId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String adminName = (String) session.getAttribute("adminName");
    if (adminName == null) adminName = "管理者";

    request.setCharacterEncoding("UTF-8");
    String searchName = request.getParameter("searchName");
    if (searchName == null) searchName = "";

    Connection connRoot = null;
    Connection connWsms = null;

    DecimalFormat df = new DecimalFormat("¥###,###");
    Random rnd = new Random();

    try {
        Class.forName("org.postgresql.Driver");

        connRoot = DriverManager.getConnection("jdbc:postgresql://localhost:5432/root", "postgres", "1234");
        connWsms = DriverManager.getConnection("jdbc:postgresql://localhost:5432/wsms", "postgres", "1234");

        // 관리자 이름 동기화
        String sqlAdmin = "SELECT name FROM \"Administrator\" WHERE id = ?";
        PreparedStatement pstmtAdmin = connRoot.prepareStatement(sqlAdmin);
        pstmtAdmin.setString(1, sessionAdminId);
        ResultSet rsAdmin = pstmtAdmin.executeQuery();

        if (rsAdmin.next()) {
            adminName = rsAdmin.getString("name");
            session.setAttribute("adminName", adminName);
        }
%>

<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>請求管理 - SMART WATER</title>
  <link rel="stylesheet" href="css/billing_list.css" >

  <!-- ✅ 통합 메뉴바 스타일 추가 -->
  <style>
    /* ===============================
       ✅ TOP NAVBAR (통합 버전)
       =============================== */
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

    /* ✅ 메뉴바 5번째 메뉴(請求管理) 아래 언더라인 고정 */
    .nav-links li:nth-child(5) a::after {
      content: "";
      position: absolute;
      left: 0;
      bottom: 6px;
      width: 100%;
      height: 2px;
      background: #2aa3ff;
      border-radius: 2px;
    }

    /* ADMIN */
    .admin-area{
      margin-left: auto;
      position: relative;
      display: flex;
      align-items: center;
      gap: 10px;
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

    .dropdown-item.logout {
      color: #b91c1c;
      font-weight: 800;
    }

    /* hover로도 열리게 */
    .admin-area:hover .admin-dropdown{
      opacity: 1;
      visibility: visible;
      pointer-events: auto;
      transform: translateY(0);
    }
  </style>
</head>

<body>

  <!-- ✅ 메뉴바: 통합 버전 적용 -->
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
      <div class="header-section">
        <div class="title">🗓️ 請求履歴</div>
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
              <option value="<%= d %>" <%= d.equals(billingDate) ? "selected" : "" %>>
                <%= d %>
              </option>
              <%
                }
                rsDate.close();
                pstmtDate.close();
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
            %>
            <tr>
              <td><%= rs.getString("customer_id") %></td>
              <td><%= rs.getString("name") %></td>
              <td>
                <%
                  int billAmount = 0;

                  if (billingDate != null && !billingDate.isEmpty()) {
                      String dataSql =
                          "SELECT bill_amount FROM bill WHERE customer_id=? AND billing_date=?";
                      pstmtData = connWsms.prepareStatement(dataSql);
                      pstmtData.setString(1, rs.getString("customer_id"));
                      pstmtData.setDate(2, java.sql.Date.valueOf(billingDate));

                      rsData = pstmtData.executeQuery();
                      if (rsData.next()) {
                          billAmount = rsData.getInt("bill_amount");
                      }
                      rsData.close();
                      pstmtData.close();
                  } else {
                      // billingDate 없을 때는 현재 rs의 bill_amount 사용
                      billAmount = rs.getInt("bill_amount");
                  }

                  NumberFormat nf = NumberFormat.getInstance();
                  String formattedAmount = nf.format(billAmount);
                %>
                ¥ <%= formattedAmount %>
              </td>
              <td>
                <button class="btn-view" type="button"
                  onclick="location.href='billing.jsp?customer_id=<%= rs.getString("customer_id") %>&billing_date=<%= rs.getString("billing_date") %>'">
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
  </script>

</body>
</html>

<%
    } catch (Exception e) {
        out.println("에러 발생: " + e.getMessage());
    } finally {
        if (rsData != null) try { rsData.close(); } catch(Exception e) {}
        if (pstmtData != null) try { pstmtData.close(); } catch(Exception e) {}
        if (rsDate != null) try { rsDate.close(); } catch(Exception e) {}
        if (pstmtDate != null) try { pstmtDate.close(); } catch(Exception e) {}
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (connRoot != null) try { connRoot.close(); } catch(Exception e) {}
        if (connWsms != null) try { connWsms.close(); } catch(Exception e) {}
    }
%>
