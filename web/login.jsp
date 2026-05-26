<%@page import="java.sql.*" %>
<%
    String s1=request.getParameter("u1");
    String s2=request.getParameter("u2");
   try{
			Class.forName("com.mysql.jdbc.Driver");
			Connection con=DriverManager.getConnection("jdbc:mysql:///coins?useSSL=false&allowPublicKeyRetrieval=true","root","root");
                        Statement st=con.createStatement();
			ResultSet rs=st.executeQuery("select * from registration where username='"+s1+"' AND password='"+s2+"' " );
			if(rs.next())
			{
                         response.sendRedirect("coin.jsp");
			}
			else
			{
		 response.sendRedirect("login.jsp?s1=invalid username and password");	
                  
			}
			con.close();
		}catch(Exception e)
		{
		out.println(e);
		}
   %>