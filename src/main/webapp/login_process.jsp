<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.Connection,java.sql.DriverManager,java.sql.PreparedStatement,java.sql.ResultSet" %>
<%@ include file="/WEB-INF/dbconfig.jspf" %>

<%
request.setCharacterEncoding("UTF-8");

String empId = request.getParameter("emp_id");
String password = request.getParameter("password");

// 서버에서도 빈값 방어
if (empId == null || password == null || empId.trim().isEmpty() || password.trim().isEmpty()) {
    response.sendRedirect("login.jsp?error=1");
    return;
}

Connection conn = null;
PreparedStatement pstmt = null;
ResultSet rs = null;

try {
    Class.forName("org.postgresql.Driver");

    conn = sionConnect("root");

    String sql = "SELECT id, name FROM public.\"Administrator\" WHERE id = ? AND password = ?";
    pstmt = conn.prepareStatement(sql);

    pstmt.setString(1, empId.trim());
    pstmt.setString(2, password.trim());

    rs = pstmt.executeQuery();

    if (rs.next()) {
        session.setAttribute("adminId", rs.getString("id"));
        session.setAttribute("adminName", rs.getString("name"));
        response.sendRedirect("main.jsp");
    } else {
        response.sendRedirect("login.jsp?error=1");
    }

} catch (Exception e) {
    out.println("로그인 처리 중 오류 발생: " + e.getMessage());
} finally {
    try { if (rs != null) rs.close(); } catch (Exception e) {}
    try { if (pstmt != null) pstmt.close(); } catch (Exception e) {}
    try { if (conn != null) conn.close(); } catch (Exception e) {}
}
%>
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body></body>
</html>