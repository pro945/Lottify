<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Pac-Man Game in JSP</title>
    <style>
        body {
            background: #000;
            color: #fff;
            font-family: Arial, sans-serif;
            text-align: center;
            margin: 0;
            padding: 0;
        }
        h1 {
            margin-top: 10px;
        }
        #gameContainer {
            display: inline-block;
            margin-top: 10px;
            border: 2px solid #fff;
        }
        #info {
            margin-top: 10px;
        }
        #info span {
            margin: 0 15px;
            font-size: 18px;
        }
        #controls {
            margin-top: 10px;
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
        #coinWrap {
            margin-top: 8px;
            font-size: 16px;
            color: #ffd700;
        }
    </style>
</head>
<body>
<h1>Pac-Man Game (JSP + JavaScript)</h1>

<div id="gameContainer">
    <canvas id="gameCanvas"></canvas>
</div>

<div id="info">
    <span>Score: <span id="score">0</span></span>
    <span>Status: <span id="status">Playing...</span></span>
</div>

<div id="coinWrap">
    Coins: <span id="coinCount">--</span>
</div>

<div id="controls">
    Use <b>Arrow Keys</b> to move Pac-Man. <br/>
    Avoid the ghost and eat all dots to win!
</div>

<button id="restartBtn">Restart Game</button>

<script>
    // ====== GAME CONFIG ======
    const tileSize = 24; // size of each grid cell in pixels

    // 0 = empty, 1 = wall, 2 = dot
    const level = [
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
        [1,2,2,2,2,2,2,1,2,2,2,2,2,2,1],
        [1,2,1,1,1,2,2,1,2,2,1,1,1,2,1],
        [1,2,2,2,1,2,2,2,2,2,1,2,2,2,1],
        [1,2,1,2,1,2,1,1,1,2,1,2,1,2,1],
        [1,2,1,2,2,2,2,1,2,2,2,2,1,2,1],
        [1,2,2,2,1,1,2,2,2,1,1,2,2,2,1],
        [1,2,1,2,1,2,2,0,2,2,1,2,1,2,1],
        [1,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
        [1,2,1,1,1,2,1,1,1,2,1,1,1,2,1],
        [1,2,2,2,1,2,2,1,2,2,2,2,2,2,1],
        [1,2,1,2,1,2,1,1,1,2,1,2,1,2,1],
        [1,2,2,2,2,2,2,1,2,2,2,2,2,2,1],
        [1,2,2,2,2,2,2,1,2,2,2,2,2,2,1],
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
    ];

    const rows = level.length;
    const cols = level[0].length;

    // Directions
    const DIR = { LEFT: 0, UP: 1, RIGHT: 2, DOWN: 3 };
    const dr = [0, -1, 0, 1];  // row delta
    const dc = [-1, 0, 1, 0];  // col delta

    // Player (Pac-Man)
    let player;

    // Ghost
    let ghost;

    let currentDir;
    let desiredDir;
    let score;
    let dotsRemaining;
    let running;
    let statusEl, scoreEl;

    let canvas, ctx;

    function initGame() {
        canvas = document.getElementById("gameCanvas");
        ctx = canvas.getContext("2d");
        canvas.width = cols * tileSize;
        canvas.height = rows * tileSize;

        scoreEl = document.getElementById("score");
        statusEl = document.getElementById("status");

        // Count dots
        dotsRemaining = 0;
        for (let r = 0; r < rows; r++) {
            for (let c = 0; c < cols; c++) {
                if (level[r][c] === 2) dotsRemaining++;
            }
        }

        // Initialize player and ghost
        resetGameState();
        attachEvents();
        draw(); // first frame
        setInterval(gameLoop, 180); // approx 5-6 moves per second
    }

    function resetGameState() {
        // Starting positions in grid coordinates
        player = { row: 1, col: 1 };
        ghost = { row: 7, col: 7, dir: DIR.LEFT };
        currentDir = DIR.RIGHT;
        desiredDir = DIR.RIGHT;
        score = 0;
        running = true;
        scoreEl.textContent = score;
        statusEl.textContent = "Playing...";
    }

    function attachEvents() {
        window.addEventListener("keydown", function (e) {
            if (!running) return;
            switch (e.key) {
                case "ArrowLeft": desiredDir = DIR.LEFT; break;
                case "ArrowUp": desiredDir = DIR.UP; break;
                case "ArrowRight": desiredDir = DIR.RIGHT; break;
                case "ArrowDown": desiredDir = DIR.DOWN; break;
            }
        });

        document.getElementById("restartBtn").addEventListener("click", function () {
            location.reload();
        });
    }

    function isWall(row, col) {
        if (row < 0 || row >= rows || col < 0 || col >= cols) return true;
        return level[row][col] === 1;
    }

    function canMove(row, col, dir) {
        const nr = row + dr[dir];
        const nc = col + dc[dir];
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) return false;
        return level[nr][nc] !== 1;
    }

    // ====== MAIN GAME LOOP WITH COLLISION FIX ======
    function gameLoop() {
        if (!running) return;

        // Store previous positions BEFORE moving
        const prevPlayer = { row: player.row, col: player.col };
        const prevGhost = { row: ghost.row, col: ghost.col };

        updatePlayer();
        updateGhost();
        checkCollisions(prevPlayer, prevGhost);
        draw();
    }

    function updatePlayer() {
        // Try to change direction if possible
        if (canMove(player.row, player.col, desiredDir)) {
            currentDir = desiredDir;
        }

        // Move in current direction if possible
        if (canMove(player.row, player.col, currentDir)) {
            player.row += dr[currentDir];
            player.col += dc[currentDir];

            // Eat dot
            if (level[player.row][player.col] === 2) {
                level[player.row][player.col] = 0;
                score += 10;
                dotsRemaining--;
                scoreEl.textContent = score;

                if (dotsRemaining <= 0) {
                    statusEl.textContent = "You Win!";
                    running = false;
                }
            }
        }
    }

    function updateGhost() {
        // If ghost cannot move forward or randomly decides to turn, pick new direction
        if (!canMove(ghost.row, ghost.col, ghost.dir) || Math.random() < 0.2) {
            const possibleDirs = [];
            for (let d = 0; d < 4; d++) {
                if (canMove(ghost.row, ghost.col, d)) {
                    possibleDirs.push(d);
                }
            }
            if (possibleDirs.length > 0) {
                // Simple strategy: randomly choose available direction
                ghost.dir = possibleDirs[Math.floor(Math.random() * possibleDirs.length)];
            }
        }

        // Move ghost
        if (canMove(ghost.row, ghost.col, ghost.dir)) {
            ghost.row += dr[ghost.dir];
            ghost.col += dc[ghost.dir];
        }
    }

    // ====== IMPROVED COLLISION DETECTION ======
    function checkCollisions(prevPlayer, prevGhost) {
        // Case 1: Same tile collision (normal)
        if (ghost.row === player.row && ghost.col === player.col) {
            statusEl.textContent = "Game Over! Ghost caught you.";
            running = false;
            return;
        }

        // Case 2: Cross-over collision (they swapped positions between frames)
        const crossedOver =
            ghost.row === prevPlayer.row &&
            ghost.col === prevPlayer.col &&
            player.row === prevGhost.row &&
            player.col === prevGhost.col;

        if (crossedOver) {
            statusEl.textContent = "Game Over! Ghost collided with you.";
            running = false;
        }
    }

    function drawMap() {
        for (let r = 0; r < rows; r++) {
            for (let c = 0; c < cols; c++) {
                const x = c * tileSize;
                const y = r * tileSize;

                // Background
                ctx.fillStyle = "#000000";
                ctx.fillRect(x, y, tileSize, tileSize);

                if (level[r][c] === 1) {
                    // Wall
                    ctx.fillStyle = "#0033cc";
                    ctx.fillRect(x, y, tileSize, tileSize);
                } else if (level[r][c] === 2) {
                    // Dot
                    ctx.fillStyle = "#ffff66";
                    ctx.beginPath();
                    ctx.arc(
                        x + tileSize / 2,
                        y + tileSize / 2,
                        4,
                        0,
                        Math.PI * 2
                    );
                    ctx.fill();
                } else {
                    // empty floor
                    ctx.fillStyle = "#000000";
                    ctx.fillRect(x, y, tileSize, tileSize);
                }
            }
        }
    }

    function drawPlayer() {
        const x = player.col * tileSize + tileSize / 2;
        const y = player.row * tileSize + tileSize / 2;
        const radius = tileSize / 2 - 2;

        ctx.fillStyle = "#ffff00"; // Pac-Man yellow
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, Math.PI * 2);
        ctx.fill();
    }

    function drawGhost() {
        const x = ghost.col * tileSize + tileSize / 2;
        const y = ghost.row * tileSize + tileSize / 2;
        const radius = tileSize / 2 - 2;

        ctx.fillStyle = "#ff0000"; // red ghost
        ctx.beginPath();
        ctx.arc(x, y, radius, Math.PI, 0); // head
        ctx.lineTo(x + radius, y + radius);
        ctx.lineTo(x - radius, y + radius);
        ctx.closePath();
        ctx.fill();
    }

    function drawGridLines() {
        // (optional)
    }

    function draw() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        drawMap();
        drawPlayer();
        drawGhost();
        drawGridLines();
    }

    // Start the game once the page loads
    window.onload = initGame;
</script>

<%
/* -------------------------
   JDBC coin reading/updating
   -------------------------
   Make sure your MySQL server is running and the database/table exist:
   Database: coins
   Table: coins (with column coin INT)
   Adjust connection URL, user, password below as needed.
*/

Connection con = null;
PreparedStatement psSelect = null;
PreparedStatement psUpdate = null;
ResultSet rs = null;

try {
    // Load driver (optional for newer JDBC, but safe)
    Class.forName("com.mysql.cj.jdbc.Driver");

    // Update these to match your environment:
    String url = "jdbc:mysql://localhost:3306/coins?useSSL=false&allowPublicKeyRetrieval=true";
    String dbUser = "root";
    String dbPass = "root";

    con = DriverManager.getConnection(url, dbUser, dbPass);

    // Select current coin value (assumes a single-row table; adjust as needed)
    psSelect = con.prepareStatement("SELECT coin FROM coins LIMIT 1");
    rs = psSelect.executeQuery();

    if (rs.next()) {
        int coins = rs.getInt("coin");
        int newCoins = coins + 50;

        // Display current coins (inline in the page)
%>
        <script>
            // set coin count into the DOM
            document.getElementById('coinCount').textContent = "<%= coins %>";
        </script>
<%
        // Update coins in DB using PreparedStatement
        psUpdate = con.prepareStatement("UPDATE coins SET coin = ?"); // no WHERE because assumed single-row table
        psUpdate.setInt(1, newCoins);
        psUpdate.executeUpdate();
    } else {
%>
        <script>
            document.getElementById('coinCount').textContent = "No coin data";
        </script>
<%
    }
} catch (Exception e) {
%>
    <script>
        document.getElementById('coinCount').textContent = "Error";
        console.error("DB error: <%= e.getMessage().replace("\"","'") %>");
    </script>
<%
} finally {
    try { if (rs != null) rs.close(); } catch (Exception e) { /* ignore */ }
    try { if (psSelect != null) psSelect.close(); } catch (Exception e) { /* ignore */ }
    try { if (psUpdate != null) psUpdate.close(); } catch (Exception e) { /* ignore */ }
    try { if (con != null) con.close(); } catch (Exception e) { /* ignore */ }
}
%>

</body>
</html>