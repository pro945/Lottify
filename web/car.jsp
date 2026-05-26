car-racing-game.html
html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Stylish 3-Car Racing Game - 6 Lanes & Speed Boost</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Orbitron&display=swap');

  /* Reset */
  * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }
  body, html {
    height: 100%;
    background: linear-gradient(180deg, #222 0%, #111 100%);
    font-family: 'Orbitron', sans-serif;
    overflow: hidden;
  }

  #game {
    position: relative;
    width: 900px;
    height: 600px;
    margin: 30px auto;
    background: linear-gradient(to bottom, #3a3a3a 0%, #1c1c1c 100%);
    border-radius: 20px;
    box-shadow:
      0 0 15px 5px #0ff,
      inset 0 0 60px #0ff;
    overflow: hidden;
    user-select: none;
  }

  /* Road */
  .road {
    position: absolute;
    left: 50%;
    top: 0;
    transform: translateX(-50%);
    width: 600px;
    height: 100%;
    background: linear-gradient(to bottom, #555 0%, #333 100%);
    border-radius: 0 0 40px 40px;
    box-shadow: inset 0 0 20px #000;
  }

  /* Lane Lines */
  .lane-line {
    position: absolute;
    width: 8px;
    height: 60px;
    background: #fff;
    opacity: 0.7;
    border-radius: 4px;
    animation: laneMove 1s linear infinite;
  }
  /* Position lane lines between 6 lanes */
  /* 6 lanes = 7 lane lines (except edges) spaced every 100px starting at lane 0: 100, 200, 300, 400, 500, 600 */
  .lane-line:nth-child(1) { left: 100px; }
  .lane-line:nth-child(2) { left: 200px; animation-delay: 0.2s; }
  .lane-line:nth-child(3) { left: 300px; animation-delay: 0.4s; }
  .lane-line:nth-child(4) { left: 400px; animation-delay: 0.6s; }
  .lane-line:nth-child(5) { left: 500px; animation-delay: 0.8s; }
  .lane-line:nth-child(6) { left: 600px; animation-delay: 1s; }

  @keyframes laneMove {
    0% { top: 0; }
    100% { top: 600px; }
  }

  /* Cars */
  .car {
    position: absolute;
    bottom: 20px;
    width: 60px;
    height: 120px;
    border-radius: 14px;
    box-shadow: inset 0 0 10px rgba(255,255,255,0.2),
                0 8px 10px rgba(0,0,0,0.7);
    transition: left 0.15s;
  }
  /* User car - blue */
  #user-car {
    background:
        linear-gradient(135deg, #1e3c72 25%, #2a5298 100%);
    left: 250px;
    z-index: 10;
    border: 3px solid #3db8f5;
  }
  #user-car::before {
    content: '';
    position: absolute;
    top: 12px;
    left: 8px;
    width: 44px;
    height: 96px;
    background: radial-gradient(circle at center, #72c6ff 10%, transparent 70%);
    border-radius: 10px;
  }
  #user-car::after {
    content: '';
    position: absolute;
    top: 12px;
    left: 24px;
    width: 12px;
    height: 96px;
    background: repeating-linear-gradient(
      45deg,
      #0a2540,
      #0a2540 5px,
      #4498e6 5px,
      #4498e6 8px
    );
    border-radius: 6px;
  }

  /* Computer car 1 - red with flames */
  #comp-car1 {
    background:
      linear-gradient(135deg, #8b0000 25%, #c53030 100%);
    left: 150px;
    bottom: 500px;
    border: 3px solid #ff3b3b;
    z-index: 9;
  }
  #comp-car1::before {
    content: '';
    position: absolute;
    top: 20px;
    left: 10px;
    width: 40px;
    height: 80px;
    background: radial-gradient(circle at center, #ff5c5c 15%, transparent 70%);
    border-radius: 14px;
  }
  #comp-car1 .flame {
    position: absolute;
    bottom: -30px;
    left: 8px;
    height: 40px;
    width: 44px;
    background: linear-gradient(45deg, #ff5500, #ff2200);
    clip-path: polygon(10% 100%, 30% 0%, 50% 100%, 70% 0%, 90% 100%);
    animation: flameFlicker 0.3s infinite alternate;
    border-radius: 10px;
  }
  @keyframes flameFlicker {
    0% { transform: scaleY(1);}
    100% { transform: scaleY(1.8);}
  }

  /* Computer car 2 - green electric */
  #comp-car2 {
    background:
      linear-gradient(135deg, #004d00 25%, #00cc00 100%);
    left: 500px;
    bottom: 800px;
    border: 3px solid #33ff33;
    z-index: 9;
  }
  #comp-car2::before {
    content: '';
    position: absolute;
    top: 18px;
    left: 12px;
    width: 36px;
    height: 84px;
    background:
      repeating-linear-gradient(
        45deg,
        #00aa00,
        #00aa00 5px,
        #00ff00 5px,
        #00ff00 7px
      );
    border-radius: 12px;
  }
  #comp-car2 .lightning {
    position: absolute;
    top: 30px;
    left: 22px;
    width: 16px;
    height: 60px;
    clip-path: polygon(0 0, 80% 0, 30% 35%, 80% 35%, 20% 100%, 50% 60%, 0 60%);
    background: yellow;
    filter: drop-shadow(0 0 5px yellow);
    animation: pulseLight 1.4s infinite ease-in-out;
  }
  @keyframes pulseLight {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
  }

  /* Obstacle - rolling rocks */
  .obstacle {
    position: absolute;
    width: 50px;
    height: 50px;
    background: radial-gradient(circle at center, #555, #222);
    border-radius: 50%;
    box-shadow:
      inset -5px -5px 15px #666,
      inset 6px 6px 10px #111;
    border: 2px solid #444;
    filter: drop-shadow(1px 1px 3px black);
  }

  /* Score display */
  #score {
    position: absolute;
    top: 12px;
    left: 20px;
    font-size: 22px;
    color: #0ff;
    text-shadow: 0 0 8px #0ff;
    font-weight: 700;
  }

  /* Game Over */
  #game-over {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    color: #f03;
    font-size: 48px;
    font-weight: 800;
    text-shadow: 0 0 20px #f03;
    display: none;
    text-align: center;
    line-height: 1.2;
  }

  /* Instructions */
  #instructions {
    position: absolute;
    bottom: 10px;
    left: 50%;
    transform: translateX(-50%);
    font-size: 16px;
    color: #aaa;
    text-shadow: 0 0 3px #111;
  }

  /* Speed boost indicator */
  #speed-boost-indicator {
    position: absolute;
    top: 50px;
    left: 20px;
    font-size: 20px;
    color: #ff0;
    text-shadow: 0 0 8px #ff0;
    font-weight: 700;
    display: none;
  }

</style>
</head>
<body>

<div id="game" tabindex="0" aria-label="Car racing game">
  <div class="road">
    <div class="lane-line" style="top:0;"></div>
    <div class="lane-line" style="top:150px;"></div>
    <div class="lane-line" style="top:300px;"></div>
    <div class="lane-line" style="top:450px;"></div>
    <div class="lane-line" style="top:600px;"></div>
    <div class="lane-line" style="top:750px;"></div>
  </div>

  <div id="score" aria-live="polite">Distance: 0m</div>
  <div id="speed-boost-indicator">Speed Boost!</div>
  <div id="game-over" role="alert">GAME OVER<br>Refresh to Restart</div>
  <div id="instructions">Use ? &rarr; keys to move your car, Hold SPACE to speed up</div>

  <div id="user-car" class="car" aria-label="Your car"></div>
  <div id="comp-car1" class="car" aria-label="Computer car 1"><div class="flame"></div></div>
  <div id="comp-car2" class="car" aria-label="Computer car 2"><div class="lightning"></div></div>
</div>

<script>
(() => {
  const game = document.getElementById('game');
  const userCar = document.getElementById('user-car');
  const compCar1 = document.getElementById('comp-car1');
  const compCar2 = document.getElementById('comp-car2');
  const scoreDisplay = document.getElementById('score');
  const gameOverDisplay = document.getElementById('game-over');
  const speedBoostIndicator = document.getElementById('speed-boost-indicator');

  const roadWidth = 600;
  const totalLanes = 6;
  const laneWidth = roadWidth / totalLanes;

  // Calculate lanes center positions relative to #game left edge
  const roadLeftX = (game.clientWidth - roadWidth) / 2;
  const lanes = [];
  for(let i = 0; i < totalLanes; i++) {
    lanes.push(roadLeftX + laneWidth * i + (laneWidth - 60)/2); // center car (60 px) in lane
  }

  // user car lane index, starting at lane 2 (third lane)
  let userLane = 2;
  // comp cars lanes
  let comp1Lane = 0;
  let comp2Lane = 5;

  // user car vertical fixed bottom margin:
  const userCarBottom = 20;

  // Variables for cars' vertical positions (y)
  let comp1Y = 500;
  let comp2Y = 800;

  // Speed config
  let baseSpeed = 6; // base speed of obstacles and computer cars (pixels per frame)
  let speed = baseSpeed;
  let speedBoostMultiplier = 1.7;
  let frameCount = 0;
  let distance = 0;
  let gameOver = false;
  let speedBoostActive = false;

  // Obstacles array
  let obstacles = [];

  // Obstacle spawn timer
  let obstacleTimer = 0;
  const obstacleInterval = 90; // frames per obstacle spawn (~1.5 sec at 60fps)

  // Initialize cars positions
  function setPositions() {
    userCar.style.left = lanes[userLane] + 'px';
    userCar.style.bottom = userCarBottom + 'px';

    compCar1.style.left = lanes[comp1Lane] + 'px';
    compCar1.style.bottom = comp1Y + 'px';

    compCar2.style.left = lanes[comp2Lane] + 'px';
    compCar2.style.bottom = comp2Y + 'px';
  }

  // Move computer cars down the screen (increasing y)
  // They loop when off screen (y > 700)
  // Randomly change lanes when resetting
  function updateComputerCars() {
    comp1Y += speed * 0.8;
    comp2Y += speed * 0.9;

    // Reset and random lane change when off screen bottom
    if (comp1Y > 700) {
      comp1Y = -140 - Math.random() * 200; // spawn above screen top with randomness
      let newLane;
      do {
        newLane = Math.floor(Math.random() * lanes.length);
      } while (newLane === userLane);
      comp1Lane = newLane;
    }
    if (comp2Y > 700) {
      comp2Y = -140 - Math.random() * 200;
      let newLane;
      do {
        newLane = Math.floor(Math.random() * lanes.length);
      } while (newLane === userLane || newLane === comp1Lane);
      comp2Lane = newLane;
    }

    compCar1.style.bottom = comp1Y + 'px';
    compCar1.style.left = lanes[comp1Lane] + 'px';

    compCar2.style.bottom = comp2Y + 'px';
    compCar2.style.left = lanes[comp2Lane] + 'px';
  }

  // Create a new obstacle element starting from top y = -50 moving down positive y
  function createObstacle(lane) {
    const obs = document.createElement('div');
    obs.classList.add('obstacle');
    obs.dataset.lane = lane;
    game.appendChild(obs);
    let spawnY = -50; // start above visible top
    obs.style.left = lanes[lane] + 'px';
    obs.style.top = spawnY + 'px';
    return {el: obs, lane: lane, y: spawnY};
  }

  // Spawn obstacle at random lane
  function spawnObstacle() {
    // avoid spawning in the same lane as user or close computer cars
    let possibleLanes = lanes.map((_, i) => i);

    // filter lanes occupied by comp cars within close to top (to avoid instant impossible collisions)
    if (comp1Y < 150 && comp1Y > -100) {
      possibleLanes = possibleLanes.filter(l => l !== comp1Lane);
    }
    if (comp2Y < 150 && comp2Y > -100) {
      possibleLanes = possibleLanes.filter(l => l !== comp2Lane);
    }
    // also avoid user's lane sometimes to keep fairness
    if (Math.random() < 0.7) {
      possibleLanes = possibleLanes.filter(l => l !== userLane);
    }

    if (possibleLanes.length === 0) {
      // fallback allow any lane if none found
      possibleLanes = lanes.map((_, i) => i);
    }

    let lane = possibleLanes[Math.floor(Math.random() * possibleLanes.length)];
    const obs = createObstacle(lane);
    obstacles.push(obs);
  }

  // Update obstacles positions moving downward
  function updateObstacles() {
    for (let i = obstacles.length - 1; i >= 0; i--) {
      const obs = obstacles[i];
      obs.y += speed;
      if (obs.y > 650) {
        // Remove from DOM and array
        obs.el.remove();
        obstacles.splice(i, 1);
      } else {
        obs.el.style.top = obs.y + 'px';
      }
    }
  }

  // Check collision with obstacles & computer cars
  // Simple AABB collision detection based on rectangles
  function checkCollision() {
    // User car size
    const userRect = {
      left: lanes[userLane],
      right: lanes[userLane] + 60,
      top: userCarBottom + 120,
      bottom: userCarBottom
    };

    // Check collision with obstacles
    for (const obs of obstacles) {
      const obsRect = {
        left: lanes[obs.lane],
        right: lanes[obs.lane] + 50,
        top: obs.y + 50,
        bottom: obs.y
      };
      if (rectIntersect(userRect, obsRect)) {
        return true;
      }
    }

    // Check with comp cars rectangles (approximate)
    const comp1Rect = {
      left: lanes[comp1Lane],
      right: lanes[comp1Lane] + 60,
      top: comp1Y + 120,
      bottom: comp1Y
    };
    const comp2Rect = {
      left: lanes[comp2Lane],
      right: lanes[comp2Lane] + 60,
      top: comp2Y + 120,
      bottom: comp2Y
    };
    if (rectIntersect(userRect, comp1Rect) || rectIntersect(userRect, comp2Rect)) {
      return true;
    }
    return false;
  }

  // Rectangle collision helper
  function rectIntersect(r1, r2) {
    return !(r2.left > r1.right || 
             r2.right < r1.left || 
             r2.top < r1.bottom || 
             r2.bottom > r1.top);
  }

  // Handle user car movement
  function moveUserCar(direction) {
    if (gameOver) return;
    // direction: -1 left, +1 right
    let newLane = userLane + direction;
    if (newLane >= 0 && newLane < lanes.length) {
      userLane = newLane;
      userCar.style.left = lanes[userLane] + 'px';
    }
  }

  // Handle speed boost activation / deactivation
  function setSpeedBoost(active) {
    if (active) {
      speed = baseSpeed * speedBoostMultiplier;
      speedBoostActive = true;
      speedBoostIndicator.style.display = 'block';
    } else {
      speed = baseSpeed;
      speedBoostActive = false;
      speedBoostIndicator.style.display = 'none';
    }
  }

  // Game loop
  function gameLoop() {
    if (gameOver) return;

    frameCount++;
    distance += speed * 0.1;
    scoreDisplay.textContent = 'Distance: ' + Math.floor(distance) + 'm';

    updateComputerCars();
    updateObstacles();

    if (frameCount % obstacleInterval === 0) {
      spawnObstacle();
    }

    if (checkCollision()) {
      // End game
      gameOver = true;
      gameOverDisplay.style.display = 'block';
    }

    requestAnimationFrame(gameLoop);
  }

  // Keyboard control setup
  window.addEventListener('keydown', e => {
    if (gameOver) return;
    if (e.key === 'ArrowLeft') {
      moveUserCar(-1);
    } else if (e.key === 'ArrowRight') {
      moveUserCar(1);
    } else if (e.key === ' ' && !speedBoostActive) {
      setSpeedBoost(true);
    }
  });
  window.addEventListener('keyup', e => {
    if (e.key === ' ' && speedBoostActive) {
      setSpeedBoost(false);
    }
  });

  // Initial setup
  setPositions();
  game.focus();
  gameLoop();

})();
</script>
</body>
</html>

