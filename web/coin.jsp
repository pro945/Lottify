<%@page import="java.sql.*" %>
<html>
<head>
   <link rel="stylesheet" href="style.css">
</head>
<body>
    <%@include file="Menu.html"%>
    <div id="mydata">
        <center>
            <h2>Your Coin Balance</h2>
            <div class="coin-container" style="font-size: 24px;">
                ? 
                <%
                Connection con = null;
                Statement st = null;
                ResultSet rs = null;

                try {
                    Class.forName("com.mysql.jdbc.Driver");
                    con = DriverManager.getConnection("jdbc:mysql:///coins?useSSL=false", "root", "root");
                    st = con.createStatement();
                    rs = st.executeQuery("SELECT coin FROM coins LIMIT 1"); // or WHERE user_id = ? if needed

                    if(rs.next()) {
                        int coins = rs.getInt("coin");
                %>
                     <span id="coinCount"><%= coins %></span>
                <%
                    } else {
                        out.println("<span>No coin data found.</span>");
                    }
                } catch(Exception e) {
                    out.println("<span>Error: " + e.getMessage() + "</span>");
                } finally {
                    try { if(rs != null) rs.close(); } catch(Exception e) {}
                    try { if(st != null) st.close(); } catch(Exception e) {}
                    try { if(con != null) con.close(); } catch(Exception e) {}
                }
                %>
            </div>
        </center>
    </div>
</body>
</html>		