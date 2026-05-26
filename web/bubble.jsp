<%@page import="java.sql.*"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <title>Bubble Shooter Game</title>
  <style>
    /* Reset and base styles */
    html, body {
      margin: 0;
      padding: 0;
      background: linear-gradient(135deg, #6dd5fa, #2980b9);
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      -webkit-tap-highlight-color: transparent;
      user-select:none;
      overflow: hidden;
      height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
    }
    #game-container {
      position: relative;
      width: 350px;
      height: 600px;
      background: #111c2a;
      border-radius: 15px;
      box-shadow: 0 8px 20px rgba(0,0,0,0.6);
      overflow: hidden;
      touch-action: none;
    }
    canvas {
      display: block;
      border-radius: 15px;
      background: #0e1623;
      touch-action: none;
      cursor: crosshair;
    }
    #scoreboard {
      position: absolute;
      top: 10px;
      left: 50%;
      transform: translateX(-50%);
      color: #fff;
      font-size: 1.3rem;
      font-weight: bold;
      text-shadow: 0 0 5px #00e0f8;
      user-select:none;
      pointer-events:none;
    }
    #instructions {
      position: absolute;
      bottom: 10px;
      width: 100%;
      text-align: center;
      color: #66ccffcc;
      font-size: 0.9rem;
      user-select:none;
      pointer-events:none;
      padding: 0 10px;
      line-height: 1.2rem;
    }
    /* Mobile friendly adjustments */
    @media (max-width: 400px) {
      #game-container {
        width: 320px;
        height: 580px;
      }
    }
  </style>
</head>
<body>
  <div id="game-container" role="main" aria-label="Bubble Shooter Game">
    <canvas id="gameCanvas" width="350" height="600" tabindex="0" aria-describedby="instructions" aria-live="polite"></canvas>
    <div id="scoreboard" aria-live="polite" aria-atomic="true">Score: 0</div>
    <div id="instructions">
      Click or tap to aim and shoot bubbles. Match 3 or more bubbles of the same color to pop them.
    </div>
  </div>

  <script>
    (function() {
      'use strict';

      const canvas = document.getElementById('gameCanvas');
      const ctx = canvas.getContext('2d');
      const scoreBoard = document.getElementById('scoreboard');

      const WIDTH = canvas.width;
      const HEIGHT = canvas.height;

      const ROWS = 10;
      const COLS = 11;
      const BUBBLE_RADIUS = 15;
      const BUBBLE_DIAM = BUBBLE_RADIUS * 2;
      const SHOOTER_Y = HEIGHT - 50;
      const SHOOTER_X = WIDTH / 2;

      // Bubble colors
      const COLORS = [
        '#e74c3c', // red
        '#f39c12', // orange
        '#f1c40f', // yellow
        '#2ecc71', // green
        '#3498db', // blue
        '#9b59b6'  // purple
      ];

      const BACKGROUND_COLOR = '#0e1623';

      // Game variables
      let bubbles = [];
      let shooterBubble = null;
      let nextBubble = null;
      let angle = Math.PI / 2; // straight up initial angle
      let score = 0;
      let isShooting = false;

      // Directions for neighbor search (hex grid)
      // Even rows have neighbors differently than odd rows
      const NEIGHBOR_OFFSETS_EVEN = [
        {r: -1, c: 0}, {r: -1, c: -1},
        {r: 0, c: -1}, {r: 0, c: 1},
        {r: 1, c: 0}, {r: 1, c: -1}
      ];
      const NEIGHBOR_OFFSETS_ODD = [
        {r: -1, c: 0}, {r: -1, c: 1},
        {r: 0, c: -1}, {r: 0, c: 1},
        {r: 1, c: 0}, {r: 1, c: 1}
      ];

      // Initialize the grid with nulls
      function initBubbles() {
        bubbles = new Array(ROWS);
        for(let r=0; r<ROWS; r++) {
          bubbles[r] = new Array(COLS).fill(null);
        }

        // Fill top 5 rows randomly with bubbles
        for(let r=0; r<5; r++) {
          for(let c=0; c<(r % 2 === 0 ? COLS : COLS - 1); c++) {
            const colorIndex = Math.floor(Math.random() * COLORS.length);
            bubbles[r][c] = {
              color: COLORS[colorIndex],
              r: r,
              c: c
            };
          }
        }
      }

      // Calculate bubble's pixel position given row and column
      function bubblePosition(r, c) {
        const xOffset = (r % 2 === 0) ? BUBBLE_RADIUS : BUBBLE_DIAM; 
        const x = c * BUBBLE_DIAM + xOffset;
        const y = r * (BUBBLE_RADIUS * 1.73); // 1.73 ~ sqrt(3), vertical spacing for hex grid
        return {x, y};
      }

      // Draw a bubble circle with shading and glow
      function drawBubble(x, y, color, alpha=1) {
        ctx.save();
        ctx.globalAlpha = alpha;
        const gradient = ctx.createRadialGradient(x - 5, y - 5, BUBBLE_RADIUS/4, x, y, BUBBLE_RADIUS);
        gradient.addColorStop(0, '#ffffff88');
        gradient.addColorStop(1, color);
        ctx.fillStyle = gradient;
        ctx.shadowColor = color;
        ctx.shadowBlur = 15;
        ctx.beginPath();
        ctx.arc(x, y, BUBBLE_RADIUS, 0, Math.PI * 2);
        ctx.fill();

        // Inner light highlight
        ctx.shadowColor = 'transparent';
        ctx.fillStyle = 'rgba(255,255,255,0.3)';
        ctx.beginPath();
        ctx.arc(x - 6, y - 6, BUBBLE_RADIUS / 2, 0, Math.PI * 2);
        ctx.fill();

        ctx.restore();
      }

      // Draw shooter cannon base
      function drawShooterBase() {
        ctx.save();
        ctx.fillStyle = '#222';
        ctx.strokeStyle = '#444';
        ctx.lineWidth = 4;
        ctx.shadowColor = '#00e0f8';
        ctx.shadowBlur = 8;
        ctx.beginPath();
        ctx.arc(SHOOTER_X, SHOOTER_Y + 20, 35, 0, Math.PI, true);
        ctx.fill();
        ctx.stroke();
        ctx.restore();
      }

      // Draw shooting bubble cannon with pointing arrow
      function drawShooter(angle) {
        const length = 50;
        const endX = SHOOTER_X + length * Math.cos(angle);
        const endY = SHOOTER_Y - length * Math.sin(angle);

        // Cannon arm
        ctx.save();
        ctx.lineCap = 'round';
        ctx.strokeStyle = '#00e0f8';
        ctx.lineWidth = 8;
        ctx.shadowColor = '#00e0f8';
        ctx.shadowBlur = 15;
        ctx.beginPath();
        ctx.moveTo(SHOOTER_X, SHOOTER_Y);
        ctx.lineTo(endX, endY);
        ctx.stroke();

        // Arrow tip
        ctx.fillStyle = '#00e0f8';
        ctx.beginPath();
        ctx.moveTo(endX, endY);
        ctx.lineTo(endX - 12 * Math.cos(angle - Math.PI / 6), endY + 12 * Math.sin(angle - Math.PI / 6));
        ctx.lineTo(endX - 12 * Math.cos(angle + Math.PI / 6), endY + 12 * Math.sin(angle + Math.PI / 6));
        ctx.closePath();
        ctx.fill();
        ctx.restore();
      }

      // Draw all bubbles in grid
      function drawGrid() {
        for(let r=0; r<ROWS; r++) {
          for(let c=0; c<COLS; c++) {
            const b = bubbles[r][c];
            if(b !== null) {
              const pos = bubblePosition(r, c);
              drawBubble(pos.x, pos.y, b.color);
            }
          }
        }
      }

      // Draw the current shooter's bubble
      function drawShooterBubble() {
        if(shooterBubble) {
          drawBubble(shooterBubble.x, shooterBubble.y, shooterBubble.color);
        }
      }

      // Clamp the shooter angle between some limits to prevent shooting backward
      function clampAngle(a) {
        const minAngle = 0.1;
        const maxAngle = Math.PI - 0.1;
        if (a < minAngle) return minAngle;
        if (a > maxAngle) return maxAngle;
        return a;
      }

      // Generate random bubble color
      function randomColor() {
        return COLORS[Math.floor(Math.random() * COLORS.length)];
      }

      // Create a new shooter bubble at the shooter position
      function createShooterBubble() {
        const color = nextBubble ? nextBubble.color : randomColor();
        shooterBubble = {
          x: SHOOTER_X,
          y: SHOOTER_Y,
          color: color,
          radius: BUBBLE_RADIUS,
          speed: 10,
          moving: false,
          vx: 0,
          vy: 0
        };
        nextBubble = {color: randomColor()};
      }

      // Draw next bubble preview on the side
      function drawNextBubble() {
        const x = WIDTH - 45;
        const y = HEIGHT - 90;
        ctx.save();
        ctx.font = '16px Segoe UI';
        ctx.fillStyle = '#00e0f8';
        ctx.textAlign = 'center';
        ctx.shadowColor = '#00e0f8';
        ctx.shadowBlur = 10;
        ctx.fillText('Next', x, y - 30);
        if(nextBubble) drawBubble(x, y, nextBubble.color);
        ctx.restore();
      }

      // Check collision with walls and reflect shooterBubble horizontally
      function applyWallCollision() {
        if (shooterBubble.x - BUBBLE_RADIUS <= 0) {
          shooterBubble.x = BUBBLE_RADIUS;
          shooterBubble.vx = -shooterBubble.vx;
        } else if (shooterBubble.x + BUBBLE_RADIUS >= WIDTH) {
          shooterBubble.x = WIDTH - BUBBLE_RADIUS;
          shooterBubble.vx = -shooterBubble.vx;
        }
      }

      // Check if two bubbles collide
      function bubblesCollide(b1x, b1y, b2x, b2y) {
        const dx = b1x - b2x;
        const dy = b1y - b2y;
        return Math.sqrt(dx*dx + dy*dy) <= BUBBLE_DIAM - 1;
      }

      // Find the closest grid position for a bubble based on its x,y coordinates
      function findGridPosition(x, y) {
        let r = Math.round(y / (BUBBLE_RADIUS * 1.73));
        r = Math.min(Math.max(0, r), ROWS - 1);
        let xOffset = (r % 2 === 0) ? BUBBLE_RADIUS : BUBBLE_DIAM;
        let c = Math.round((x - xOffset) / BUBBLE_DIAM);
        c = Math.min(Math.max(0, c), COLS - 1);
        return {r, c};
      }

      // Attach a bubble to grid where it collides or reaches the top
      function attachBubble() {
        const {r, c} = findGridPosition(shooterBubble.x, shooterBubble.y);
        // Place bubble at r,c if empty, else find nearest adjacent empty
        if (!bubbles[r][c]) {
          bubbles[r][c] = {
            color: shooterBubble.color,
            r,
            c
          };
        } else {
          // Find neighbor empty slot closest to current position
          let placed = false;
          const offsets = (r % 2 === 0) ? NEIGHBOR_OFFSETS_EVEN : NEIGHBOR_OFFSETS_ODD;
          for (let offset of offsets) {
            let nr = r + offset.r;
            let nc = c + offset.c;
            if(nr >= 0 && nr < ROWS && nc >=0 && nc < COLS && !bubbles[nr][nc]) {
              bubbles[nr][nc] = {
                color: shooterBubble.color,
                r: nr,
                c: nc
              };
              placed = true;
              break;
            }
          }
          if (!placed) {
            // fallback: place in (r,c) anyway (could overwrite)
            bubbles[r][c] = {
              color: shooterBubble.color,
              r,
              c
            };
          }
        }
      }

      // Find clusters of connected bubbles of the same color starting from r,c using DFS
      function findCluster(r, c, color, visited) {
        const stack = [];
        const cluster = [];
        stack.push({r, c});

        while(stack.length) {
          const current = stack.pop();
          const cr = current.r;
          const cc = current.c;
          if (cr < 0 || cr >= ROWS || cc < 0 || cc >= COLS) continue;
          if (visited[cr][cc]) continue;
          const bubble = bubbles[cr][cc];
          if (!bubble) continue;
          if (bubble.color !== color) continue;
          visited[cr][cc] = true;
          cluster.push(bubble);
          const offsets = (cr % 2 === 0) ? NEIGHBOR_OFFSETS_EVEN : NEIGHBOR_OFFSETS_ODD;
          for(let offset of offsets) {
            stack.push({r: cr + offset.r, c: cc + offset.c});
          }
        }
        return cluster;
      }

      // Remove bubbles in cluster from grid
      function popCluster(cluster) {
        for(let bubble of cluster) {
          bubbles[bubble.r][bubble.c] = null;
        }
      }

      // Update score and scoreboard text
      function updateScore(points) {
        score += points;
        scoreBoard.textContent = 'Score: ' + score;
      }

      // Detect and pop clusters of 3 or more starting from newly placed bubble
      function checkAndPop(r, c) {
        if(!bubbles[r][c]) return;

        // Prepare visited matrix for cluster search
        const visited = new Array(ROWS);
        for(let i=0; i<ROWS; i++) {
          visited[i] = new Array(COLS).fill(false);
        }

        const cluster = findCluster(r, c, bubbles[r][c].color, visited);
        if(cluster.length >= 3) {
          popCluster(cluster);
          updateScore(cluster.length * 10);
          // After popping clusters, drop unattached bubbles if any - optional game feature
          dropUnattachedBubbles();
        }
      }

      // Find bubbles that are connected to the top row
      function findAttachedBubbles() {
        const visited = new Array(ROWS);
        for(let i=0; i<ROWS; i++) {
          visited[i] = new Array(COLS).fill(false);
        }

        // BFS starting from bubbles in top row
        const queue = [];
        for(let c=0; c<COLS; c++) {
          if(bubbles[0][c]) {
            visited[0][c] = true;
            queue.push({r:0, c:c});
          }
        }

        while(queue.length > 0) {
          const {r,c} = queue.shift();
          const offsets = (r % 2 === 0) ? NEIGHBOR_OFFSETS_EVEN : NEIGHBOR_OFFSETS_ODD;
          for(let offset of offsets) {
            let nr = r + offset.r;
            let nc = c + offset.c;
            if(nr >= 0 && nr < ROWS && nc >= 0 && nc < COLS) {
              if(bubbles[nr][nc] && !visited[nr][nc]) {
                visited[nr][nc] = true;
                queue.push({r: nr, c:nc});
              }
            }
          }
        }
        return visited;
      }

      // Remove bubbles that are NOT connected to top row (falling down)
      function dropUnattachedBubbles() {
        const attached = findAttachedBubbles();
        let droppedCount = 0;
        for(let r=0; r<ROWS; r++) {
          for(let c=0; c<COLS; c++) {
            if(bubbles[r][c] && !attached[r][c]) {
              bubbles[r][c] = null;
              droppedCount++;
            }
          }
        }
        if(droppedCount > 0) {
          updateScore(droppedCount * 15);
        }
      }

      // Game over check: if bubbles fill bottom row, game over
      function checkGameOver() {
        for(let c=0; c<COLS; c++) {
          if(bubbles[ROWS - 1][c]) {
            return true;
          }
        }
        return false;
      }

      // Clear all bubbles and show game over message
      function gameOver() {
        // Clear game area
        ctx.clearRect(0, 0, WIDTH, HEIGHT);
        ctx.fillStyle = '#111c2a';
        ctx.fillRect(0, 0, WIDTH, HEIGHT);

        ctx.fillStyle = '#00e0f8';
        ctx.font = 'bold 36px Segoe UI';
        ctx.textAlign = 'center';
        ctx.fillText('Game Over!', WIDTH/2, HEIGHT/2 - 20);
        ctx.font = '20px Segoe UI';
        ctx.fillText('Final Score: ' + score, WIDTH/2, HEIGHT/2 + 20);
        ctx.fillText('Refresh page to play again', WIDTH/2, HEIGHT/2 + 60);
      }

      // Animation and drawing loop
      function gameLoop() {
        // Clear canvas
        ctx.clearRect(0, 0, WIDTH, HEIGHT);
        ctx.fillStyle = BACKGROUND_COLOR;
        ctx.fillRect(0, 0, WIDTH, HEIGHT);

        drawGrid();
        drawNextBubble();
        drawShooterBase();
        drawShooter(angle);
        drawShooterBubble();

        // Update shooter bubble if it is moving
        if(shooterBubble && shooterBubble.moving) {
          shooterBubble.x += shooterBubble.vx;
          shooterBubble.y += shooterBubble.vy;

          applyWallCollision();

          // Check collision with existing bubbles or top wall
          let collided = false;
          outerLoop:
          for(let r=0; r<ROWS; r++) {
            for(let c=0; c<COLS; c++) {
              const b = bubbles[r][c];
              if(b) {
                const pos = bubblePosition(r, c);
                if (bubblesCollide(shooterBubble.x, shooterBubble.y, pos.x, pos.y)) {
                  collided = true;
                  break outerLoop;
                }
              }
            }
          }
          // Check if hit top
          if(shooterBubble.y - BUBBLE_RADIUS <= 0) {
            collided = true;
          }

          if(collided) {
            shooterBubble.moving = false;
            attachBubble();
            // Check for pop clusters
            const pos = findGridPosition(shooterBubble.x, shooterBubble.y);
            checkAndPop(pos.r, pos.c);
            // Reset shooter bubble to nextBubble color
            createShooterBubble();
            // Check for game over
            if (checkGameOver()) {
              gameOver();
              return; // stop game loop
            }
          }
        }
        requestAnimationFrame(gameLoop);
      }

      // Handle mouse and touch events for aiming and shooting
      function onAimMove(clientX, clientY) {
        const rect = canvas.getBoundingClientRect();
        const x = clientX - rect.left;
        const y = clientY - rect.top;
        let dx = x - SHOOTER_X;
        let dy = SHOOTER_Y - y;
        let a = Math.atan2(dy, dx);
        angle = clampAngle(a);
      }

      function onShoot() {
        if(shooterBubble && !shooterBubble.moving) {
          shooterBubble.moving = true;
          shooterBubble.vx = shooterBubble.speed * Math.cos(angle);
          shooterBubble.vy = -shooterBubble.speed * Math.sin(angle);
        }
      }

      // Input event handlers
      canvas.addEventListener('mousemove', e => {
        onAimMove(e.clientX, e.clientY);
      });

      canvas.addEventListener('touchmove', e => {
        if(e.touches.length > 0) {
          onAimMove(e.touches[0].clientX, e.touches[0].clientY);
          e.preventDefault();
        }
      }, {passive:false});

      canvas.addEventListener('click', e => {
        onShoot();
      });

      canvas.addEventListener('touchstart', e => {
        onShoot();
      });

      // Keyboard aiming (left and right arrows), space to shoot
      window.addEventListener('keydown', e => {
        if(e.key === 'ArrowLeft') {
          angle -= 0.1;
          angle = clampAngle(angle);
        } else if(e.key === 'ArrowRight') {
          angle += 0.1;
          angle = clampAngle(angle);
        } else if(e.key === ' ' || e.key === 'Spacebar') {
          onShoot();
        }
      });

      // Initialization
      function init() {
        initBubbles();
        nextBubble = {color: randomColor()};
        createShooterBubble();
        score = 0;
        scoreBoard.textContent = "Score: 0";
        gameLoop();
      }

      init();

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
