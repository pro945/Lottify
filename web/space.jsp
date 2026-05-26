<%@page import="java.sql.*"%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no"/>
<title>Spaceship Shooter Game for Laptop</title>
<style>
  /* Reset and basics */
  * {
    box-sizing: border-box;
    user-select: none;
  }
  body, html {
    margin: 0;
    padding: 0;
    overflow: hidden;
    background: radial-gradient(circle at center, #000011, #000000 80%);
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    color: #eee;
    height: 100vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }
  #gameContainer {
    position: relative;
    width: 700px;
    height: 600px;
    background: linear-gradient(to bottom, #001022, #000010);
    border-radius: 10px;
    box-shadow: 0 0 30px #00ffffaa;
  }
  canvas {
    display: block;
    background: transparent;
    border-radius: 10px;
  }
  #controls {
    margin-top: 15px;
    display: flex;
    justify-content: center;
    gap: 25px;
  }
  button.control-btn {
    width: 80px;
    height: 50px;
    background-color: #003344;
    border: none;
    border-radius: 10px;
    color: #0ff;
    font-size: 22px;
    box-shadow: 0 0 12px #0ff7;
    transition: background-color 0.2s ease;
    user-select: none;
  }
  button.control-btn:active {
    background-color: #00ffffbb;
    box-shadow: 0 0 25px #00ffffee;
  }
  @media (hover: hover) {
    button.control-btn:hover {
      background-color: #005577;
    }
  }
  #score {
    position: absolute;
    top: 10px;
    left: 10px;
    font-weight: bold;
    font-size: 26px;
    color: #0ff;
    text-shadow: 0 0 10px #00ffffbb;
  }
  #message {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    color: #00ffffdd;
    font-size: 36px;
    font-weight: bold;
    text-align: center;
    z-index: 20;
    text-shadow: 0 0 14px #00ffffee;
  }
</style>
</head>
<body>
<div id="gameContainer">
  <div id="score">Score: 0</div>
  <canvas id="gameCanvas" width="700" height="600" aria-label="Spaceship shooting game"></canvas>
  <div id="message" style="display:none;"></div>
</div>
<div id="controls">
  <button id="leftBtn" class="control-btn" aria-label="Move spaceship left">&#9664;</button>
  <button id="fireBtn" class="control-btn" aria-label="Fire bullet">&#9650;</button>
  <button id="rightBtn" class="control-btn" aria-label="Move spaceship right">&#9654;</button>
</div>
<script>
(() => {
  const canvas = document.getElementById('gameCanvas');
  const ctx = canvas.getContext('2d');

  const width = canvas.width;
  const height = canvas.height;

  // Player spaceship properties
  const shipWidth = 90;
  const shipHeight = 120;
  let shipX = width / 2 - shipWidth / 2;
  const shipY = height - shipHeight - 15;
  const shipSpeed = 3; // slower movement

  // Enemy spaceship properties
  const enemyWidth = 105;
  const enemyHeight = 75;
  let enemyX = Math.random() * (width - enemyWidth);
  let enemyY = -enemyHeight;
  let enemySpeed = 1; // slower enemy speed

  // Bullets array
  const bullets = [];
  const bulletWidth = 9;
  const bulletHeight = 24;
  const bulletSpeed = 4; // slower bullet speed

  // Controls
  let moveLeft = false;
  let moveRight = false;
  let firing = false;
  let fireCooldown = 0;

  // Score
  let score = 0;
  let gameOver = false;

  // DOM Elements
  const messageEl = document.getElementById('message');
  const scoreEl = document.getElementById('score');

  // Load images
  const playerImg = new Image();
  playerImg.src = "s1.jpg"; // Replace with your player spaceship image path
  const enemyImg = new Image();
  enemyImg.src = "s2.jpg"; // Replace with your enemy spaceship image path
  const bulletImg = new Image();
  bulletImg.src = "images/bullet.png"; // Optional bullet image - can fallback

  // Setup keyboard controls
  function keyDownHandler(e) {
    if (gameOver) return;
    if(e.code === 'ArrowLeft' || e.code === 'KeyA') moveLeft = true;
    if(e.code === 'ArrowRight' || e.code === 'KeyD') moveRight = true;
    if(e.code === 'Space') firing = true;
  }
  function keyUpHandler(e) {
    if (gameOver) return;
    if(e.code === 'ArrowLeft' || e.code === 'KeyA') moveLeft = false;
    if(e.code === 'ArrowRight' || e.code === 'KeyD') moveRight = false;
    if(e.code === 'Space') firing = false;
  }
  window.addEventListener('keydown', keyDownHandler);
  window.addEventListener('keyup', keyUpHandler);

  // Touch controls buttons
  if (!gameOver) {
    document.getElementById('leftBtn').addEventListener('mousedown', () => moveLeft = true);
    document.getElementById('leftBtn').addEventListener('mouseup', () => moveLeft = false);
    document.getElementById('leftBtn').addEventListener('touchstart', e => { e.preventDefault(); moveLeft = true; });
    document.getElementById('leftBtn').addEventListener('touchend', e => { e.preventDefault(); moveLeft = false; });

    document.getElementById('rightBtn').addEventListener('mousedown', () => moveRight = true);
    document.getElementById('rightBtn').addEventListener('mouseup', () => moveRight = false);
    document.getElementById('rightBtn').addEventListener('touchstart', e => { e.preventDefault(); moveRight = true; });
    document.getElementById('rightBtn').addEventListener('touchend', e => { e.preventDefault(); moveRight = false; });

    document.getElementById('fireBtn').addEventListener('mousedown', () => firing = true);
    document.getElementById('fireBtn').addEventListener('mouseup', () => firing = false);
    document.getElementById('fireBtn').addEventListener('touchstart', e => { e.preventDefault(); firing = true; });
    document.getElementById('fireBtn').addEventListener('touchend', e => { e.preventDefault(); firing = false; });
  }

  function drawImageCentered(img, x, y, w, h) {
    ctx.drawImage(img, x, y, w, h);
  }

  function drawScore() {
    scoreEl.textContent = 'Score: ' + score;
  }

  function showMessage(text) {
    messageEl.textContent = text;
    messageEl.style.display = 'block';
  }

  // Update game state
  function update() {
    if (gameOver) return;

    // Move spaceship
    if(moveLeft) {
      shipX -= shipSpeed;
      if(shipX < 0) shipX = 0;
    }
    if(moveRight) {
      shipX += shipSpeed;
      if(shipX + shipWidth > width) shipX = width - shipWidth;
    }

    // Move enemy down
    enemyY += enemySpeed;

    if(enemyY > height) {
      // Respawn enemy on top randomly
      enemyY = -enemyHeight;
      enemyX = Math.random() * (width - enemyWidth);
    }

    // Check collision enemy-player
    if(collides({ x: enemyX, y: enemyY, width: enemyWidth, height: enemyHeight }, { x: shipX, y: shipY, width: shipWidth, height: shipHeight })) {
      gameOver = true;
      showMessage("Game Over! Your spaceship was hit.");
    }

    // Firing bullets
    if(firing && fireCooldown <= 0 && !gameOver) {
      bullets.push({ x: shipX + shipWidth / 2 - bulletWidth / 2, y: shipY });
      fireCooldown = 20; // longer cooldown for slower fire rate
    }
    if(fireCooldown > 0) fireCooldown--;

    // Update bullets
    for(let i = bullets.length - 1; i >= 0; i--) {
      bullets[i].y -= bulletSpeed;
      if(bullets[i].y + bulletHeight < 0) {
        bullets.splice(i, 1);
      } else if(collides(bullets[i], { x: enemyX, y: enemyY, width: enemyWidth, height: enemyHeight })) {
        bullets.splice(i, 1);
        score++;
        enemyY = -enemyHeight;
        enemyX = Math.random() * (width - enemyWidth);
        // Increase enemy speed every 5 points
        if(score % 5 === 0) {
          enemySpeed += 0.3; // slower speed increase
        }
      }
    }
  }

  // Collision detection AABB
  function collides(rect1, rect2) {
    return rect1.x < rect2.x + rect2.width &&
           rect1.x + (rect1.width || bulletWidth) > rect2.x &&
           rect1.y < rect2.y + rect2.height &&
           rect1.y + (rect1.height || bulletHeight) > rect2.y;
  }

  // Draw the game scene
  function draw() {
    ctx.clearRect(0, 0, width, height);

    // Draw player spaceship image or fallback rectangle if image not loaded
    if(playerImg.complete && playerImg.naturalWidth !== 0) {
      drawImageCentered(playerImg, shipX, shipY, shipWidth, shipHeight);
    } else {
      ctx.fillStyle = "#00ffff";
      ctx.fillRect(shipX, shipY, shipWidth, shipHeight);
    }

    // Draw enemy spaceship image or fallback
    if(enemyImg.complete && enemyImg.naturalWidth !== 0) {
      drawImageCentered(enemyImg, enemyX, enemyY, enemyWidth, enemyHeight);
    } else {
      ctx.fillStyle = "#ff0033";
      ctx.fillRect(enemyX, enemyY, enemyWidth, enemyHeight);
    }

    // Draw bullets - use image if loaded else rectangle
    bullets.forEach(bullet => {
      if(bulletImg.complete && bulletImg.naturalWidth !== 0) {
        drawImageCentered(bulletImg, bullet.x, bullet.y, bulletWidth, bulletHeight);
      } else {
        ctx.fillStyle = '#0ff';
        ctx.fillRect(bullet.x, bullet.y, bulletWidth, bulletHeight);
      }
    });

    drawScore();
  }

  // Main game loop
  function gameLoop() {
    update();
    draw();
    if(!gameOver) {
      requestAnimationFrame(gameLoop);
    }
  }

  // Start game loop after images load to avoid flickering (but allow fallback)
  let imagesLoaded = 0;
  [playerImg, enemyImg, bulletImg].forEach(img => {
    img.onload = () => {
      imagesLoaded++;
      if(imagesLoaded >= 1) { // don't wait for bullet image necessarily
        gameLoop();
      }
    }
    img.onerror = () => {
      // if any image fails, just start the game anyway with fallback shapes
      imagesLoaded++;
      if(imagesLoaded >= 1) {
        gameLoop();
      }
    }
  });

  // In case images never load (no network), start game after 1 sec timeout to avoid hang
  setTimeout(() => {
    if(imagesLoaded < 1) {
      gameLoop();
    }
  }, 1000);
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
    con = DriverManager.getConnection("jdbc:mysql://localhost:3306/coins?useSSL=false", "root", "root");
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

    %>
