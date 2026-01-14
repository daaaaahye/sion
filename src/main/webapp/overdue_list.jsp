<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.Locale" %>

<%
    /* ========================================================
       1. セッション管理 (세션 관리)
       ======================================================== */
    String adminName = (String) session.getAttribute("adminName");
    String adminId = (String) session.getAttribute("adminId");
    
    // 未ログイン時のリダイレクト (미로그인 시 리다이렉트)
    if (adminName == null || adminId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    /* ========================================================
       2. 日付および曜日の処理 (날짜 및 요일 처리)
       ======================================================== */
    String searchDateParam = request.getParameter("search_date");

    LocalDate baseDate;
    if (searchDateParam == null || searchDateParam.isEmpty()) {
        baseDate = LocalDate.now(); 
    } else {
        baseDate = LocalDate.parse(searchDateParam); 
    }

    String inputDateValue = baseDate.toString();
    DateTimeFormatter displayFormatter = DateTimeFormatter.ofPattern("yyyy年 MM月 dd日", Locale.JAPAN);
    String displayDate = baseDate.format(displayFormatter);

    String dayOfWeekJP;
    switch (baseDate.getDayOfWeek()) {
        case MONDAY:    dayOfWeekJP = "月"; break;
        case TUESDAY:   dayOfWeekJP = "火"; break;
        case WEDNESDAY: dayOfWeekJP = "水"; break;
        case THURSDAY:  dayOfWeekJP = "木"; break;
        case FRIDAY:    dayOfWeekJP = "金"; break;
        case SATURDAY:  dayOfWeekJP = "土"; break;
        default:        dayOfWeekJP = "日";
    }
%>

<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>滞納顧客管理 - SMART WATER JP</title>
    <style>
        /* CSS 스타일은 동일하게 유지됩니다 */
        * { box-sizing: border-box; }
        body { font-family: 'Hiragino Kaku Gothic ProN', 'Meiryo', sans-serif; margin: 0; background-color: #f5f6f8; color: #111827; }
        .navbar { background-color: #243646; min-height: 70px; display: flex; align-items: center; padding: 10px 4%; position: sticky; top: 0; z-index: 1000; }
        .navbar-brand { font-size: 20px; font-weight: 800; color: #2aa3ff; text-decoration: none; margin-right: 20px; }
        .nav-links { list-style: none; display: flex; gap: 15px; margin: 0; padding: 0; }
        .nav-links li a { color: #cbd5e1; text-decoration: none; font-size: 14px; font-weight: 600; }
        .nav-links li a.active { color: #ffffff; border-bottom: 3px solid #e74c3c; padding-bottom: 5px; }
        .admin-area { margin-left: auto; display: flex; align-items: center; gap: 10px; }
        .admin-name { font-size: 14px; font-weight: 700; color: #ffffff; }
        .admin-id { font-size: 11px; color: #9fb0c3; }
        .admin-icon { width: 32px; height: 32px; border-radius: 50%; background: #ffffff; display: grid; place-items: center; }
        .filter-container { max-width: 1400px; width: 92%; margin: 20px auto 0; display: flex; justify-content: flex-end; }
        .date-selector { background: white; padding: 10px 18px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); display: flex; align-items: center; gap: 10px; }
        .date-input { padding: 6px 10px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 14px; }
        .btn-search { background: #243646; color: white; border: none; padding: 7px 15px; border-radius: 6px; font-size: 13px; font-weight: bold; cursor: pointer; }
        .main-container { max-width: 1400px; width: 92%; margin: 20px auto 60px; }
        .content-card { background: white; border-radius: 16px; padding: 40px; box-shadow: 0 8px 24px rgba(0,0,0,.06); border-top: 8px solid #e74c3c; }
        .display-base-date { margin-bottom: 30px; text-align: right; }
        .display-base-date .date-value { font-size: clamp(18px, 4vw, 36px); font-weight: 900; color: #111827; padding-bottom: 8px; border-bottom: 5px solid #e74c3c; display: inline-block; }
        .section-header { margin-bottom: 40px; }
        .section-title { font-size: 28px; font-weight: 800; margin: 0 0 10px 0; }
        .section-subtitle { font-size: 15px; color: #6b7280; line-height: 1.5; }
        .table-wrapper { overflow-x: auto; width: 100%; margin-top: 20px; }
        .data-table { width: 100%; border-collapse: collapse; min-width: 600px; }
        .data-table th { background: #fff5f5; padding: 15px; color: #b91c1c; border-bottom: 3px solid #fee2e2; }
        .data-table td { padding: 18px 15px; border-bottom: 1px solid #f0f0f0; text-align: center; font-size: 16px; }
        .text-right { text-align: right !important; }
        .warn-badge { background: #fee2e2; color: #b91c1c; padding: 5px 12px; border-radius: 30px; font-weight: bold; font-size: 12px; }
    </style>
</head>
<body>
    
    <nav class="navbar">
        <a href="#" class="navbar-brand">💧 SMART WATER JP</a>
        <ul class="nav-links">
            <li><a href="#">顧客一覧</a></li>
            <li><a href="#">管轄区域管理</a></li>
            <li><a href="#" class="active">滞納管理</a></li>
            <li><a href="#">入金管理</a></li>
            <li><a href="#">請求照会</a></li>
        </ul>

        <div class="admin-area">
            <div class="admin-text">
                <div class="admin-name"><%= adminName %> 様</div>
                <div class="admin-id">社員番号 <%= adminId %></div>
            </div>
            <div class="admin-icon">👤</div>
        </div>
    </nav>

    <div class="filter-container">
        <form action="overdue_list.jsp" method="get" class="date-selector">
            <label for="base-date">日付変更</label>
            <input type="date" name="search_date" id="base-date" class="date-input" value="<%= inputDateValue %>">
            <button type="submit" class="btn-search">適用</button>
        </form>
    </div>

    <div class="main-container">
        <div class="content-card">
            <div class="display-base-date">
                <span class="date-value"><%= displayDate %> (<%= dayOfWeekJP %>)</span>
            </div>

            <div class="section-header">
                <h2 class="section-title">🚨 滞納顧客の現状</h2>
                <p class="section-subtitle">現在、料金の支払いが確認できていない顧客リストです。</p>
            </div>
            
            <div class="table-wrapper">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>顧客名</th>
                            <th>滞納期間</th>
                            <th>滞納金額</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><b>田中 太郎</b></td>
                            <td><span class="warn-badge">3ヶ月</span></td>
                            <td class="text-right" style="color:#e74c3c; font-weight:bold;">4,500円</td>
                        </tr>
                        <tr>
                            <td><b>鈴木 一郎</b></td>
                            <td><span class="warn-badge">5ヶ月</span></td>
                            <td class="text-right" style="color:#e74c3c; font-weight:bold;">12,400円</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

</body>
</html>