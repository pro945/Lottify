<%@page import="java.sql.*"%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Classic Nokia Snake Game</title>
<style>
  body, html {
    margin: 0;
    height: 100%;
    background: linear-gradient(135deg, #222, #083d00);
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    user-select: none;
    color: #0f0;
  }
  #gameContainer {
    position: relative;
    width: 700px;
    height: 700px;
    background: radial-gradient(circle at center, #002200, #000700);
    border: 5px solid #0f0;
    border-radius: 15px;
    box-shadow: 0 0 20px #0f0aa;
  }
  canvas {
    display: block;
    background-color: #002200;
    border-radius: 15px;
    margin: auto;
  }
  #score {
    position: absolute;
    top: 10px;
    left: 20px;
    font-size: 28px;
    font-weight: bold;
    text-shadow: 0 0 8px #0f0;
  }
  #message {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    color: #0f0;
    font-size: 36px;
    font-weight: bold;
    text-shadow: 0 0 12px #0f0;
    display: none;
    user-select: none;
  }
  #instructions {
    margin-top: 10px;
    font-size: 18px;
    color: #0f0;
    text-shadow: 0 0 5px #070;
  }
</style>
</head>
<body>
  <div id="gameContainer" style="position: relative;">
    <canvas id="gameCanvas" width="700" height="700" aria-label="Classic Nokia Snake Game"></canvas>
    <div id="score">Score: 0</div>
    <div id="message"></div>
  </div>
  <div id="instructions">Use WASD keys to control the snake. Eat the food to grow.</div>
<script>
(() => {
  const canvas = document.getElementById('gameCanvas');
  const ctx = canvas.getContext('2d');
  const scoreEl = document.getElementById('score');
  const messageEl = document.getElementById('message');

  const width = canvas.width;
  const height = canvas.height;

  // Grid size to simulate "blocks"
  const cellSize = 25;
  const cols = width / cellSize;  // 28 columns
  const rows = height / cellSize; // 28 rows

  // Game state
  let snake = [
    { x: Math.floor(cols/2), y: Math.floor(rows/2) },
  ];
  let direction = { x: 0, y: 0 }; // start stopped
  let nextDirection = { x: 0, y: 0 };
  let food = { x: 0, y: 0 };
  let score = 0;
  let gameOver = false;

  // Colors and style
  const bgColor = '#002200';
  const snakeColor = '#0f0';
  const foodColor = '#f00';
  const gridColor = '#004400';

  function placeFood() {
    while (true) {
      food.x = Math.floor(Math.random() * cols);
      food.y = Math.floor(Math.random() * rows);
      if(!snake.some(s => s.x === food.x && s.y === food.y)) break;
    }
  }

  function drawGrid() {
    ctx.strokeStyle = gridColor;
    ctx.lineWidth = 1;
    for(let x = 0; x <= width; x += cellSize) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, height);
      ctx.stroke();
    }
    for(let y = 0; y <= height; y += cellSize) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
      ctx.stroke();
    }
  }

  function drawRect(x, y, color) {
    ctx.fillStyle = color;
    ctx.shadowColor = color;
    ctx.shadowBlur = 10;
    ctx.fillRect(x * cellSize + 2, y * cellSize + 2, cellSize - 4, cellSize - 4);
    ctx.shadowBlur = 0;
  }

  function update() {
    if(gameOver) return;
    // Validate direction changes (cannot go reverse)
    if((nextDirection.x !== 0 || nextDirection.y !== 0) &&
       (nextDirection.x !== -direction.x || nextDirection.y !== -direction.y)) {
      direction = nextDirection;
    }
    if(direction.x === 0 && direction.y === 0) return; // no movement yet
    // New head position
    const newHead = { x: snake[0].x + direction.x, y: snake[0].y + direction.y };

    // Check wall collision
    if(newHead.x < 0 || newHead.x >= cols || newHead.y < 0 || newHead.y >= rows) {
      endGame();
      return;
    }
    // Removed self-collision check: game only ends on wall hit

    snake.unshift(newHead);

    // Check food collision
    if(newHead.x === food.x && newHead.y === food.y) {
      score++;
      scoreEl.textContent = "Score: " + score;
      placeFood();
    } else {
      snake.pop();
    }
  }

  function endGame() {
    gameOver = true;
    messageEl.textContent = "Game Over! Your score: " + score;
    messageEl.style.display = 'block';
  }

  function draw() {
    // Draw background
    ctx.fillStyle = bgColor;
    ctx.fillRect(0, 0, width, height);
    drawGrid();

    // Draw snake
    snake.forEach((segment, index) => {
      drawRect(segment.x, segment.y, snakeColor);
      if(index === 0){
        // head highlight
        ctx.strokeStyle = '#0f0';
        ctx.lineWidth = 3;
        ctx.strokeRect(segment.x * cellSize + 2, segment.y * cellSize + 2, cellSize - 4, cellSize - 4);
      }
    });

    // Draw food
    drawRect(food.x, food.y, foodColor);
  }

  function gameLoop() {
    update();
    draw();
    if(!gameOver) {
      setTimeout(gameLoop, 130); // speed approx 7.5 frames per second
    }
  }

  // Keyboard controls
  window.addEventListener('keydown', e => {
    if(gameOver && e.key === "Enter") {
      restartGame();
      return;
    }
    switch(e.key.toLowerCase()){
      case 'w':
        if(direction.y === 1) break;
        nextDirection = { x: 0, y: -1 };
        break;
      case 's':
        if(direction.y === -1) break;
        nextDirection = { x: 0, y: 1 };
        break;
      case 'a':
        if(direction.x === 1) break;
        nextDirection = { x: -1, y: 0 };
        break;
      case 'd':
        if(direction.x === -1) break;
        nextDirection = { x: 1, y: 0 };
        break;
    }
  });

  function restartGame() {
    snake = [{ x: Math.floor(cols/2), y: Math.floor(rows/2) }];
    direction = { x: 0, y: 0 };
    nextDirection = { x: 0, y: 0 };
    score = 0;
    gameOver = false;
    scoreEl.textContent = "Score: 0";
    messageEl.style.display = 'none';
    placeFood();
    gameLoop();
  }

  // Initialize game
  placeFood();
  gameLoop();

})();
</script>
</body>
</html>

<%
Connection con = null;
Statement st = null;
ResultSet rs = null;

try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    con = DriverManager.getConnection("jdbc:mysql://localhost:3306/coins?useSSL=false&allowPublicKeyRetrieval=true", "root", "root");
    st = con.createStatement();

    rs = st.executeQuery("SELECT coin FROM coins LIMIT 1");

    if (rs.next()) {
        int coins = rs.getInt("coin");
        int newCoins = coins + 50;

        // Display current coins
%>
        <span id="coinCount"><%= coins %></span>
<%
        // Update coins
        st.executeUpdate("UPDATE coins SET coin = " + newCoins);
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