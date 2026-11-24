<%@ page import="java.sql.*" %>
<%@ include file="/WEB-INF/dbconfig.jspf" %>
<%

    Connection conn = null;

    try {
        Class.forName("org.postgresql.Driver");
        conn = sionConnect("wsms");
    } catch (Exception e) {
        e.printStackTrace();
    }
%>
