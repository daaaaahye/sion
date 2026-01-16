<%@ page import="java.sql.*" %>
<%
    String url = "jdbc:postgresql://localhost:5432/wsms";
    String user = "postgres";
    String password = "1234";

    Connection conn = null;

    try {
        Class.forName("org.postgresql.Driver");
        conn = DriverManager.getConnection(url, user, password);
    } catch (Exception e) {
        e.printStackTrace();
    }
%>
