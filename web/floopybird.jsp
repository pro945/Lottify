<%@page import="java.sql.*"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no"/>
    <title>Flappy Bird JSP Game</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap');
        body, html {
            margin: 0;
            padding: 0;
            background: linear-gradient(to bottom, #70c5ce, #5dade2);
            height: 100%;
            font-family: 'Press Start 2P', cursive;
            display: flex;
            justify-content: center;
            align-items: center;
            -webkit-tap-highlight-color: transparent;
        }
        #game-container {
            position: relative;
            width: 350px;
            height: 600px;
            background: #70c5ce;
            box-shadow: 0 0 30px rgba(0,0,0,0.25);
            border-radius: 12px;
            overflow: hidden;
            touch-action: manipulation;
            user-select: none;
        }
        canvas {
            display: block;
            background: #4ec0ca;
        }
        #score {
            position: absolute;
            top: 20px;
            width: 100%;
            text-align: center;
            font-size: 24px;
            color: #fff;
            text-shadow: 2px 2px 4px #0009;
            pointer-events: none;
            user-select: none;
            z-index: 10;
        }
        #message {
            position: absolute;
            top: 50%;
            width: 100%;
            text-align: center;
            color: #fff;
            text-shadow: 3px 3px 7px #000c;
            font-size: 24px;
            font-weight: bold;
            transform: translateY(-50%);
            padding: 0 20px;
            pointer-events: none;
            user-select: none;
            z-index: 10;
        }
        #start-instruction {
            font-size: 16px;
            margin-top: 8px;
            color: #eee;
            text-shadow: 1px 1px 3px #0009;
        }
    </style>
</head>
<body>
    <div id="game-container" role="main" aria-label="Flappy Bird game">
        <div id="score">Score: 0</div>
        <canvas id="gameCanvas" width="350" height="600" aria-live="polite"></canvas>
        <div id="message">
            Tap or Click to Start<br />
            <span id="start-instruction">Press SPACE or Tap to flap</span>
        </div>
    </div>
    <script>
        (() => {
            'use strict';
            
            const canvas = document.getElementById('gameCanvas');
            const ctx = canvas.getContext('2d');
            const scoreElement = document.getElementById('score');
            const messageElement = document.getElementById('message');
            const container = document.getElementById('game-container');

            const W = canvas.width;
            const H = canvas.height;

            // Game variables
            let bird = null;
            let pipes = [];
            let frame = 0;
            let score = 0;
            let highScore = 0;
            let gameState = 'Start'; // 'Start', 'Playing', 'GameOver'

            // Bird properties
            class Bird {
                constructor() {
                    this.x = 60;
                    this.y = H / 2;
                    this.radius = 12;
                    this.gravity = 0.4;  // decreased gravity for slower fall (was 0.6)
                    this.lift = -8;      // decreased lift flap power for slower flap (was -10)
                    this.velocity = 0;
                    this.rotation = 0;
                }
                update() {
                    this.velocity += this.gravity;
                    this.velocity *= 0.9;
                    this.y += this.velocity;

                    if(this.y + this.radius > H - groundHeight) {
                        this.y = H - groundHeight - this.radius;
                        if (gameState === 'Playing') {
                            setGameOver();
                        }
                        this.velocity = 0;
                    }
                    if(this.y - this.radius < 0) {
                        this.y = this.radius;
                        this.velocity = 0;
                    }

                    // Rotation for tilt effect
                    if(this.velocity >= 0) {
                        this.rotation = Math.min(Math.PI / 4, this.rotation + 0.1);
                    } else {
                        this.rotation = -0.5;
                    }
                }
                draw() {
                    ctx.save();
                    ctx.translate(this.x, this.y);
                    ctx.rotate(this.rotation);
                    ctx.fillStyle = '#FFD100'; // Bright yellow bird body
                    // Draw bird body circle
                    ctx.beginPath();
                    ctx.ellipse(0, 0, this.radius + 3, this.radius + 2, 0, 0, Math.PI * 2);
                    ctx.fill();
                    ctx.strokeStyle = '#CC9900';
                    ctx.lineWidth = 2;
                    ctx.stroke();

                    // Draw wing as small ellipse
                    ctx.fillStyle = '#FFA500';
                    ctx.beginPath();
                    ctx.ellipse(0, 5, this.radius / 2, this.radius / 3, -Math.PI / 6, 0, Math.PI * 2);
                    ctx.fill();

                    // Draw eye - white circle with black pupil
                    ctx.fillStyle = '#fff';
                    ctx.beginPath();
                    ctx.arc(5, -5, 4, 0, Math.PI * 2);
                    ctx.fill();

                    ctx.fillStyle = '#000';
                    ctx.beginPath();
                    ctx.arc(6, -5, 2, 0, Math.PI * 2);
                    ctx.fill();

                    ctx.restore();
                }
                flap() {
                    this.velocity = this.lift;
                }
                getBounds() {
                    return { x: this.x - this.radius, y: this.y - this.radius, width: this.radius * 2, height: this.radius * 2 };
                }
            }

            // Pipe properties
            class Pipe {
                constructor(x) {
                    this.x = x;
                    this.width = 52;
                    this.gap = 120;
                    this.topHeight = Math.floor(Math.random() * 140) + 50;
                    this.bottomY = this.topHeight + this.gap;
                    this.passed = false; // for scoring
                }
                update() {
                    this.x -= 2;
                }
                draw() {
                    ctx.fillStyle = '#2ecc71'; // bright green pipe
                    // Draw top pipe
                    ctx.fillRect(this.x, 0, this.width, this.topHeight);
                    // Draw bottom pipe
                    ctx.fillRect(this.x, this.bottomY, this.width, H - this.bottomY - groundHeight);

                    // Add dark border for pipes
                    ctx.strokeStyle = '#27ae60';
                    ctx.lineWidth = 3;
                    ctx.strokeRect(this.x, 0, this.width, this.topHeight);
                    ctx.strokeRect(this.x, this.bottomY, this.width, H - this.bottomY - groundHeight);
                }
                isOffscreen() {
                    return this.x + this.width < 0;
                }
                collide(bird) {
                    // Bird rectangle
                    const b = bird.getBounds();
                    // Check top pipe collision
                    if (b.x + b.width > this.x && b.x < this.x + this.width) {
                        if (b.y < this.topHeight || (b.y + b.height) > this.bottomY) {
                            return true;
                        }
                    }
                    return false;
                }
            }

            const groundHeight = 112;

            // Draw background
            function drawBackground() {
                // Sky fallback
                ctx.fillStyle = '#70c5ce';
                ctx.fillRect(0, 0, W, H);
                // Draw background base (ground)
                ctx.fillStyle = '#deaa4a';
                ctx.fillRect(0, H - groundHeight, W, groundHeight);

                // Draw ground grass top layer lines for pattern
                ctx.strokeStyle = '#a87e24';
                ctx.lineWidth = 4;
                ctx.beginPath();
                for(let i = 0; i < W; i += 20) {
                    ctx.moveTo(i, H - groundHeight + 10);
                    ctx.lineTo(i + 10, H - groundHeight);
                    ctx.lineTo(i + 15, H - groundHeight + 10);
                }
                ctx.stroke();
            }

            // Reset the game to initial state
            function resetGame() {
                bird = new Bird();
                pipes = [];
                frame = 0;
                score = 0;
                scoreElement.textContent = "Score: 0";
                gameState = 'Start';
                messageElement.style.display = 'block';
                messageElement.innerHTML = 'Tap or Click to Start<br/><span id="start-instruction">Press SPACE or Tap to flap</span>';
            }

            // Start the game play
            function startGame() {
                if (gameState !== 'Playing') {
                    gameState = 'Playing';
                    messageElement.style.display = 'none';
                }
            }

            // Set game over state
            function setGameOver() {
                gameState = 'GameOver';
                messageElement.style.display = 'block';
                messageElement.innerHTML = 'Game Over<br/>Score: ' + score + '<br/>Tap / Press SPACE to Restart';
                if(score > highScore) {
                    highScore = score;
                }
            }

            // Main game loop
            function loop() {
                ctx.clearRect(0, 0, W, H);

                drawBackground();

                if(gameState === 'Playing') {
                    if(frame % 90 === 0) {
                        pipes.push(new Pipe(W));
                    }
                    pipes.forEach(pipe => pipe.update());

                    if(pipes.length > 0 && pipes[0].isOffscreen()) {
                        pipes.shift();
                    }

                    // Check collisions
                    for(let pipe of pipes) {
                        if(pipe.collide(bird)) {
                            setGameOver();
                        }
                    }

                    // Check score
                    for(let pipe of pipes) {
                        if(!pipe.passed && pipe.x + pipe.width < bird.x) {
                            score++;
                            pipe.passed = true;
                            scoreElement.textContent = "Score: " + score;
                        }
                    }

                    bird.update();
                    
                }

                // Draw pipes
                pipes.forEach(pipe => pipe.draw());

                // Draw bird
                bird.draw();

                // Draw ground overlay for clarity is already included in drawBackground

                frame++;
                requestAnimationFrame(loop);
            }

            // Flap action handler
            function flapHandler(e) {
                e.preventDefault();
                if(gameState === 'Start') {
                    startGame();
                }
                if(gameState === 'Playing') {
                    bird.flap();
                }
                if(gameState === 'GameOver') {
                    resetGame();
                }
            }

            // Keyboard input handler
            function keyHandler(e) {
                if(e.code === 'Space' || e.key === ' ') {
                    flapHandler(e);
                }
            }

            // Touch input improve for mobile
            container.addEventListener('touchstart', flapHandler, {passive:false});
            container.addEventListener('mousedown', flapHandler);
            window.addEventListener('keydown', keyHandler);

            resetGame();
            loop();

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
