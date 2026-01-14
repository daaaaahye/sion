<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>

<%
    /* ===============================
       1. 로그인 폼에서 전달된 값 받기
       =============================== */
    // login.jsp의 input name="emp_id"
    String empId = request.getParameter("emp_id");
    // login.jsp의 input name="password"
    String password = request.getParameter("password");

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        /* ===============================
           2. PostgreSQL JDBC 드라이버 로드
           =============================== */
        Class.forName("org.postgresql.Driver");

        /* ===============================
           3. 데이터베이스 연결
           - DB명: root (관리자 DB)
           - 계정: postgres
           =============================== */
        conn = DriverManager.getConnection(
            "jdbc:postgresql://localhost:5432/root",
            "postgres",
            "1234"   // ⚠️ PostgreSQL 비밀번호
        );

        /* ===============================
           4. 관리자 계정 조회 SQL
           - 대문자 테이블이므로 "Administrator" 반드시 큰따옴표
           =============================== */
        String sql = "SELECT id, name FROM public.\"Administrator\" WHERE id = ? AND password = ?";
        pstmt = conn.prepareStatement(sql);

        // ? 자리에 값 바인딩
        pstmt.setString(1, empId);
        pstmt.setString(2, password);

        /* ===============================
           5. SQL 실행
           =============================== */
        rs = pstmt.executeQuery();

        /* ===============================
           6. 로그인 성공 / 실패 처리
           =============================== */
        if (rs.next()) {
            // 로그인 성공 → 세션에 관리자 정보 저장
            session.setAttribute("adminId", rs.getString("id"));
            session.setAttribute("adminName", rs.getString("name"));

            // 메인 페이지로 이동
            response.sendRedirect("main.jsp");
        } else {
            // 로그인 실패 → 다시 로그인 페이지
            response.sendRedirect("login.jsp?error=1");
        }

    } catch (Exception e) {
        // 오류 발생 시 메시지 출력
        out.println("로그인 처리 중 오류 발생: " + e.getMessage());
    } finally {
        /* ===============================
           7. 자원 정리 (매우 중요)
           =============================== */
        if (rs != null) try { rs.close(); } catch(Exception e) {}
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (conn != null) try { conn.close(); } catch(Exception e) {}
    }
%>