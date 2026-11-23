<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="/WEB-INF/dbconfig.jspf" %>
<%
    String customerId = request.getParameter("id");
    String amount = request.getParameter("amount");

    Connection conn = null;
    try {
        Class.forName("org.postgresql.Driver");
        // 포트 5432 고정
        conn = sionConnect("wsms");

        // [핵심] deposit 테이블에 입금 내역 저장
        String sql = "INSERT INTO deposit (customer_id, paid_at, paid_amount) VALUES (?, CURRENT_TIMESTAMP, ?)";
        PreparedStatement pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, customerId);
        pstmt.setLong(2, Long.parseLong(amount));
        pstmt.executeUpdate();
%>
    <%-- [수정] 성공 시 일본어로 알림을 띄우고 목록 화면으로 강제 이동시킵니다 --%>
    <script>
        alert("入金が完了しました。");
        location.href = "deposit.jsp"; 
    </script>
<%
    } catch (Exception e) {
        out.println("<script>alert('Error: " + e.getMessage() + "'); history.back();</script>");
    } finally {
        if(conn != null) conn.close();
    }
%>