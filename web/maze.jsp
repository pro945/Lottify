<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%
Connection con = null;
Statement st = null;
ResultSet rs = null;
int coins = 0;

try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    con = DriverManager.getConnection("jdbc:mysql://localhost:3306/coins?useSSL=false&allowPublicKeyRetrieval=true", "root", "root");
    st = con.createStatement();

    rs = st.executeQuery("SELECT coin FROM coins LIMIT 1");

    if (rs.next()) {
        coins = rs.getInt("coin");
        int newCoins = coins + 50;

        st.executeUpdate("UPDATE coins SET coin = " + newCoins);
    }
} catch(Exception e) {
    out.println("<span style='color:red;'>Error: " + e.getMessage() + "</span>");
} finally {
    try { if(rs != null) rs.close(); } catch(Exception e) {}
    try { if(st != null) st.close(); } catch(Exception e) {}
    try { if(con != null) con.close(); } catch(Exception e) {}
}
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Maze Game in JSP</title>
    <style>
        body {
            background: #111;
            color: #fff;
            font-family: Arial, sans-serif;
            text-align: center;
            margin: 0;
            padding: 0;
        }
        h1 { margin-top: 15px; }

        #coinBox {
            font-size: 22px;
            background: #222;
            padding: 8px 20px;
            display: inline-block;
            border-radius: 8px;
            margin-bottom: 10px;
            border: 1px solid #555;
        }

        #gameContainer {
            display: inline-block;
            margin-top: 10px;
            border: 2px solid #fff;
        }
        #info span {
            margin: 0 15px;
            font-size: 16px;
        }
        #controls {
            margin-top: 8px;
            font-size: 14px;
            color: #ccc;
        }
        #restartBtn {
            margin-top: 10px;
            padding: 8px 16px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        }
    </style>
</head>
<body>

<h1>Maze Game (JSP + JavaScript)</h1>

<!-- COIN DISPLAY -->
<div id="coinBox">
    Coins: <b><%= coins %></b>
</div>

<div id="gameContainer">
    <canvas id="gameCanvas"></canvas>
</div>

<div id="info">
    <span>Status: <span id="status">Reach the green goal!</span></span>
    <span>Moves: <span id="moves">0</span></span>
</div>

<div id="controls">
    Use <b>Arrow Keys</b> to move the blue player square.<br/>
    Avoid walls and reach the <b>green cell</b> to win.
</div>

<button id="restartBtn">Restart Maze</button>

<script>
    const tileSize = 32;

    const maze = [
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
        [1,0,0,1,0,0,0,1,0,0,0,1,0,0,2,0,1],
        [1,0,1,1,0,1,0,1,0,1,0,1,0,1,1,0,1],
        [1,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,1],
        [1,0,1,1,0,1,1,1,0,1,1,1,1,1,1,0,1],
        [1,0,0,1,0,0,0,1,0,0,0,1,0,0,1,0,1],
        [1,1,0,1,1,1,0,1,1,1,0,1,0,1,1,0,1],
        [1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,1],
        [1,0,1,1,0,1,1,1,0,1,1,1,0,1,0,1,1],
        [1,0,0,1,0,0,0,1,0,0,0,1,0,1,0,0,1],
        [1,1,0,1,1,1,0,1,1,1,0,1,0,1,1,0,1],
        [1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,1],
        [1,0,1,1,0,1,1,1,0,1,1,1,0,1,0,1,1],
        [1,0,0,1,0,0,0,1,0,0,0,1,0,1,0,0,1],
        [1,0,1,1,0,1,0,1,0,1,0,1,0,1,1,0,1],
        [1,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,1],
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
    ];

    const rows = maze.length;
    const cols = maze[0].length;

    let canvas, ctx;
    let player;
    let running = true;
    let movesCount = 0;

    const startPos = { row: 1, col: 1 };

    function initGame() {
        canvas = document.getElementById("gameCanvas");
        ctx = canvas.getContext("2d");
        canvas.width = cols * tileSize;
        canvas.height = rows * tileSize;

        resetGameState();
        attachEvents();
        draw();
    }

    function resetGameState() {
        player = { row: startPos.row, col: startPos.col };
        running = true;
        movesCount = 0;
        document.getElementById("moves").textContent = 0;
        document.getElementById("status").textContent = "Reach the green goal!";
    }

    function attachEvents() {
        window.addEventListener("keydown", function (e) {
            if (!running) return;

            let newRow = player.row;
            let newCol = player.col;

            if (e.key === "ArrowLeft") newCol--;
            else if (e.key === "ArrowUp") newRow--;
            else if (e.key === "ArrowRight") newCol++;
            else if (e.key === "ArrowDown") newRow++;
            else return;

            movePlayer(newRow, newCol);
        });

        document.getElementById("restartBtn").onclick = resetGameState;
    }

    function isInside(row, col) {
        return row >= 0 && row < rows && col >= 0 && col < cols;
    }

    function movePlayer(newRow, newCol) {
        if (!isInside(newRow, newCol)) return;
        if (maze[newRow][newCol] === 1) return;

        player.row = newRow;
        player.col = newCol;

        movesCount++;
        document.getElementById("moves").textContent = movesCount;

        if (maze[newRow][newCol] === 2) {
            document.getElementById("status").textContent = "You Win! 🎉";
            running = false;
        }

        draw();
    }

    function draw() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        for (let r = 0; r < rows; r++) {
            for (let c = 0; c < cols; c++) {
                const x = c * tileSize;
                const y = r * tileSize;

                ctx.fillStyle = maze[r][c] === 1 ? "#555"
                              : maze[r][c] === 2 ? "#00aa00"
                              : "#000";
                ctx.fillRect(x, y, tileSize, tileSize);
            }
        }

        ctx.fillStyle = "#007bff";
        ctx.fillRect(player.col * tileSize + 4, player.row * tileSize + 4, tileSize - 8, tileSize - 8);
    }

    window.onload = initGame;
</script>

</body>
</html>