<%@page import="java.sql.*"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Quiz Data: question, options, correct answer index
    String[] questions = {
        "What is the capital of France?",
        "Which planet is known as the Red Planet?",
        "What is the largest mammal?",
        "Who wrote 'Romeo and Juliet'?",
        "What year did the first man land on the moon?"
    };

    String[][] options = {
        {"Paris", "Berlin", "London", "Madrid"},
        {"Earth", "Mars", "Jupiter", "Saturn"},
        {"Elephant", "Blue Whale", "Giraffe", "Rhino"},
        {"William Shakespeare", "Charles Dickens", "Mark Twain", "Leo Tolstoy"},
        {"1965", "1969", "1972", "1959"}
    };

    int[] answers = {0, 1, 1, 0, 1}; // index of correct answers

    // Get current question index and score from request parameters or session
    Integer curQ = (Integer) session.getAttribute("currentQuestion");
    Integer score = (Integer) session.getAttribute("score");
    String selected = request.getParameter("answer");
    String reset = request.getParameter("reset");

    if ("true".equals(reset)) {
        session.invalidate();
        curQ = 0;
        score = 0;
    } else if (curQ == null) {
        curQ = 0;
        score = 0;
    } else if (selected != null) {
        int selectedIndex = Integer.parseInt(selected);
        if (selectedIndex == answers[curQ]) {
            score++;
        }
        curQ++;
    }

    session.setAttribute("currentQuestion", curQ);
    session.setAttribute("score", score);

    boolean quizFinished = curQ >= questions.length;

    // Database logic for coins
    int coins = 0;
    Connection con = null;
    Statement st = null;
    ResultSet rs = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection("jdbc:mysql://localhost:3306/coins?useSSL=false", "root", "root");
        st = con.createStatement();

        rs = st.executeQuery("SELECT coin FROM coins LIMIT 1");

        if (rs.next()) {
            coins = rs.getInt("coin");
            if (quizFinished) {
                // Add coins based on score, e.g., 10 coins per correct answer
                int coinsToAdd = score * 10;
                int newCoins = coins + coinsToAdd;
                st.executeUpdate("UPDATE coins SET coin = " + newCoins);
                coins = newCoins; // Update display to new value
            }
        }
    } catch(Exception e) {
        // Handle error, perhaps log or display
    } finally {
        try { if(rs != null) rs.close(); } catch(Exception e) {}
        try { if(st != null) st.close(); } catch(Exception e) {}
        try { if(con != null) con.close(); } catch(Exception e) {}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Quiz Game JSP</title>
    <style>
        /* Reset */
        * {
            box-sizing: border-box;
        }
        body {
            margin: 0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #72edf2 10%, #5151e5 100%);
            color: #fff;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .quiz-container {
            background: rgba(0, 0, 0, 0.75);
            border-radius: 12px;
            width: 100%;
            max-width: 400px;
            max-height: 600px;
            padding: 25px 30px;
            box-shadow: 0 0 15px rgba(0,0,0,0.3);
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }
        h1 {
            font-size: 1.8rem;
            margin-bottom: 20px;
            text-align: center;
            letter-spacing: 1px;
        }
        .coins-display {
            font-size: 1rem;
            margin-bottom: 15px;
            text-align: center;
            color: #72edf2;
        }
        .question-number {
            font-size: 0.9rem;
            margin-bottom: 10px;
            color: #a0a0a0;
            text-align: center;
        }
        .question-text {
            font-size: 1.2rem;
            margin-bottom: 25px;
            font-weight: 600;
            text-align: center;
        }
        form {
            display: flex;
            flex-direction: column;
            gap: 15px;
        }
        label {
            background: #5151e5;
            padding: 12px 20px;
            border-radius: 10px;
            cursor: pointer;
            transition: background 0.3s ease;
            display: block;
            font-size: 1rem;
            user-select: none;
        }
        input[type="radio"] {
            display: none;
        }
        input[type="radio"]:checked + label {
            background: #72edf2;
            color: #000;
            font-weight: 700;
            box-shadow: 0 0 8px #72edf2;
        }
        button {
            margin-top: 20px;
            padding: 12px;
            font-weight: 700;
            font-size: 1.1rem;
            background: #72edf2;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            color: #000;
            transition: background 0.3s ease;
            user-select: none;
        }
        button:hover {
            background: #4ac3c8;
        }
        .score-container {
            text-align: center;
        }
        .score-container h2 {
            font-size: 2rem;
            margin-bottom: 10px;
            color: #72edf2;
        }
        .score-container p {
            font-size: 1.2rem;
            margin-bottom: 20px;
        }
        .reset-btn {
            background: #fe4a49;
            color: #fff;
            padding: 12px 25px;
            border-radius: 10px;
            font-weight: 700;
            font-size: 1rem;
            border: none;
            cursor: pointer;
            transition: background 0.3s ease;
            user-select: none;
        }
        .reset-btn:hover {
            background: #d13632;
        }
        @media (max-width: 400px) {
            .quiz-container {
                padding: 20px;
                max-width: 100%;
                max-height: 600px;
                height: 100vh;
                border-radius: 0;
            }
            h1 {
                font-size: 1.5rem;
            }
            .question-text {
                font-size: 1rem;
            }
            label {
                font-size: 0.9rem;
                padding: 10px 18px;
            }
            button, .reset-btn {
                font-size: 1rem;
                padding: 10px;
            }
        }
    </style>
</head>
<body>
    <div class="quiz-container" role="main">
        <h1>Quiz Game</h1>
        <div class="coins-display">Coins: <%= coins %></div>
        <%
            if (quizFinished) {
        %>
            <div class="score-container">
                <h2>Quiz Completed!</h2>
                <p>You scored <strong><%= score %></strong> out of <strong><%= questions.length %></strong>.</p>
                <form method="post" action="quiz.jsp">
                    <button class="reset-btn" type="submit" name="reset" value="true">Restart Quiz</button>
                </form>
            </div>
        <%
            } else {
                int qIndex = curQ;
        %>
            <div class="question-number">Question <%= (qIndex + 1) %> of <%= questions.length %></div>
            <div class="question-text"><%= questions[qIndex] %></div>
            <form method="post" action="quiz.jsp" aria-label="Quiz question form">
                <%
                    for (int i = 0; i < options[qIndex].length; i++) {
                %>
                    <input type="radio" id="option<%=i%>" name="answer" value="<%=i%>" required />
                    <label for="option<%=i%>"><%= options[qIndex][i] %></label>
                <%
                    }
                %>
                <button type="submit" aria-label="Submit your answer">Submit</button>
            </form>
        <%
            }
        %>
    </div>
</body>
</html>