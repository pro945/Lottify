<%@page import="java.sql.*" %>
<%
    String s1 = request.getParameter("un");
    String s2 = request.getParameter("uc");
    String s3 = request.getParameter("up");

try
 {
     Class.forName("com.mysql.jdbc.Driver");
     Connection con=DriverManager.getConnection("jdbc:mysql:///coins?useSSL=false","root","root");
     Statement st=con.createStatement();
     st.executeUpdate("insert into registration values('"+s1+"','"+s2+"','"+s3+"')");
     con.close();
		}
		catch(Exception e)
		{
		out.println(e);
		}
	    response.sendRedirect("Login.html");    
%>