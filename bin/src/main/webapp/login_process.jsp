<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>

<%
    request.setCharacterEncoding("UTF-8");

    String empId = request.getParameter("emp_id");
    String password = request.getParameter("password");

    // ✅ 서버에서도 빈값 방어
    if (empId == null || password == null || empId.trim().isEmpty() || password.trim().isEmpty()) {
        response.sendRedirect("login.jsp?error=1");
        return;
    }

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Class.forName("org.postgresql.Driver");

        conn = DriverManager.getConnection(
            "jdbc:postgresql://localhost:5432/root",
            "postgres",
            "1234"
        );

        String sql = "SELECT id, name FROM public.\"Administrator\" WHERE id = ? AND password = ?";
        pstmt = conn.prepareStatement(sql);

        pstmt.setString(1, empId.trim());
        pstmt.setString(2, password.trim());

        rs = pstmt.executeQuery();

        if (rs.next()) {
            // 로그인 성공 → 세션에 관리자 정보 저장
            session.setAttribute("adminId", rs.getString("id"));
            session.setAttribute("adminName", rs.getString("name"));

            // 메인 페이지로 이동
            response.sendRedirect("main.jsp");
        } else {
            // 로그인 실패
            response.sendRedirect("login.jsp?error=1");
        }

    } catch (Exception e) {
        out.println("로그인 처리 중 오류 발생: " + e.getMessage());
    } finally {
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (conn != null) try { conn.close(); } catch(Exception e) {}
    }
%>
