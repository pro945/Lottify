<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
<title>Fruit Cutting Game</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@600&display=swap');

  * {
    box-sizing: border-box;
    user-select: none;
  }
  body, html {
    margin: 0;
    height: 100%;
    overflow: hidden;
    background: linear-gradient(135deg, #7ee8fa 0%, #80ff72 100%);
    font-family: 'Poppins', sans-serif;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: flex-start;
    color: #222;
  }
  header {
    margin: 1rem;
    text-align: center;
    font-size: 2rem;
    font-weight: 700;
    letter-spacing: 1.2px;
    color: #121212;
    text-shadow: 1px 1px 4px rgba(255 255 255 / 0.6);
  }
  #score {
    font-size: 1.4rem;
    font-weight: 600;
    margin-bottom: 0.8rem;
    color: #222;
    text-shadow: 0 1px 2px rgba(255 255 255 / 0.8);
  }
  #gameCanvas {
    background: #fff6e6;
    border-radius: 15px;
    box-shadow: 0 8px 30px rgba(0,0,0,0.2);
    touch-action: none;
    display: block;
    /* max width and height so it doesn't exceed viewport */
    max-width: 100vw;
    max-height: 80vh;
    width: 100%;
    height: auto;
  }
  #instructions {
    margin: 1rem;
    font-size: 1rem;
    color: #222;
    max-width: 420px;
    text-align: center;
    user-select: none;
  }
</style>
</head>
<body>
<header>Fruit Cutting Game ???</header>
<div id="score">Score: 0 | Lives: 3 | Combo: 0x</div>
<canvas id="gameCanvas" width="480" height="640" aria-label="Fruit cutting game canvas"></canvas>
<div id="instructions">Swipe or drag on the screen to slice the flying fruits. Avoid bombs! ?</div>

<script>
(() => {
  const canvas = document.getElementById('gameCanvas');
  const ctx = canvas.getContext('2d');

  // Base design width and height used for coordinates (aspect ratio 3:4)
  const designWidth = 480;
  const designHeight = 640;

  let width = designWidth;
  let height = designHeight;
  let scale = 1;

  // Fruits images as colored circles with fruit types
  const fruitTypes = [
    { name: 'apple', color: '#e74c3c', points: 1 },
    { name: 'orange', color: '#f39c12', points: 1 },
    { name: 'watermelon', color: '#27ae60', points: 2 },
    { name: 'banana', color: '#f1c40f', points: 1 },
    { name: 'kiwi', color: '#2ecc71', points: 1 },
    { name: 'dragonfruit', color: '#d6336c', points: 2 },
    { name: 'golden', color: '#FFD700', points: 5 },
    { name: 'bomb', color: '#333', points: -5, isBomb: true }
  ];

  // Game state
  let fruits = [];
  let particles = [];
  let score = 0;
  let lives = 3;
  let combo = 0;
  let lastSliceTime = 0;
  let gameOver = false;
  let spawnRate = 0.02;
  const gravity = 0.4;

  // Slice trail points to draw slicing line and detect fruit intersects
  let sliceTrail = [];
  const maxTrailLength = 12;

  // Audio elements
  const sliceSound = new Audio('data:audio/wav;base64,UklGRl9vT19XQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YU...'); // Short base64 encoded slice sound
  const bombSound = new Audio('data:audio/wav;base64,UklGRl9vT19XQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YU...'); // Short base64 encoded explosion sound

  // Helper: random number inside range
  const randRange = (min, max) => Math.random() * (max - min) + min;

  // Particle class for effects
  class Particle {
    constructor(x, y, color) {
      this.x = x;
      this.y = y;
      this.vx = randRange(-3, 3);
      this.vy = randRange(-5, -1);
      this.radius = randRange(2, 5) * scale;
      this.color = color;
      this.life = 100;
      this.decay = randRange(0.5, 1.5);
    }

    update() {
      this.x += this.vx;
      this.y += this.vy;
      this.vy += gravity * 0.1;
      this.life -= this.decay;
      this.radius = Math.max(0, this.radius * 0.98);
    }

    draw(ctx) {
      ctx.save();
      ctx.globalAlpha = this.life / 100;
      ctx.fillStyle = this.color;
      ctx.beginPath();
      ctx.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }
  }

  // Fruit class (adjusted to use design coordinates, scaled when drawing)
  class Fruit {
    constructor(type, x, y, vx, vy) {
      this.type = type;
      this.x = x;
      this.y = y;
      this.radius = type.isBomb ? 35 : 30; // base on design scale, scaled on draw
      this.vx = vx;
      this.vy = vy;
      this.rotation = randRange(-0.05, 0.05);
      this.angle = 0;
      this.sliced = false;
      this.sliceAnimationProgress = 0;
      this.leftHalf = null;
      this.rightHalf = null;
      this.toRemove = false;
    }

    update() {
      if (this.sliced) {
        if (this.leftHalf && this.rightHalf) {
          this.leftHalf.x += this.leftHalf.vx;
          this.leftHalf.y += this.leftHalf.vy;
          this.leftHalf.vy += gravity * 0.08;
          this.leftHalf.angle += this.leftHalf.rotation;

          this.rightHalf.x += this.rightHalf.vx;
          this.rightHalf.y += this.rightHalf.vy;
          this.rightHalf.vy += gravity * 0.08;
          this.rightHalf.angle += this.rightHalf.rotation;

          this.sliceAnimationProgress += 0.02;
          if (this.sliceAnimationProgress > 1) {
            this.toRemove = true;
          }
        }
      } else {
        this.x += this.vx;
        this.y += this.vy;
        this.vy += gravity;
        this.angle += this.rotation;

        if (this.y - this.radius > height) {
          this.toRemove = true;
          if (!this.type.isBomb) {
            loseLife();
          }
        }
      }
    }

    draw(ctx) {
      ctx.save();
      // Scale position and radius
      ctx.translate(this.x * scale, this.y * scale);
      ctx.rotate(this.angle);

      if (this.sliced) {
        if (this.leftHalf && this.rightHalf) {
          ctx.save();
          ctx.globalAlpha = 1 - this.sliceAnimationProgress;
          ctx.translate((this.leftHalf.x - this.x) * scale, (this.leftHalf.y - this.y) * scale);
          ctx.rotate(this.leftHalf.angle);
          this.drawHalf(ctx, this.leftHalf.color, true);
          ctx.restore();

          ctx.save();
          ctx.globalAlpha = 1 - this.sliceAnimationProgress;
          ctx.translate((this.rightHalf.x - this.x) * scale, (this.rightHalf.y - this.y) * scale);
          ctx.rotate(this.rightHalf.angle);
          this.drawHalf(ctx, this.rightHalf.color, false);
          ctx.restore();
        }
      } else {
        this.drawFullFruit(ctx, this.type.color);
      }
      ctx.restore();
    }

    drawFullFruit(ctx, color) {
      const scaledRadius = this.radius * scale;
      ctx.fillStyle = color;
      ctx.shadowColor = 'rgba(0,0,0,0.25)';
      ctx.shadowBlur = 8 * scale;
      ctx.shadowOffsetX = 2 * scale;
      ctx.shadowOffsetY = 2 * scale;
      ctx.beginPath();
      ctx.arc(0, 0, scaledRadius, 0, Math.PI * 2);
      ctx.fill();
      ctx.shadowBlur = 0;

      if (this.type.isBomb) {
        // Draw bomb
        ctx.fillStyle = '#555';
        ctx.beginPath();
        ctx.arc(0, 0, scaledRadius * 0.9, 0, Math.PI * 2);
        ctx.fill();
        
        ctx.fillStyle = '#222';
        ctx.beginPath();
        ctx.moveTo(0, -scaledRadius * 0.7);
        ctx.lineTo(scaledRadius * 0.3, -scaledRadius * 0.5);
        ctx.lineTo(0, -scaledRadius * 0.3);
        ctx.closePath();
        ctx.fill();
        
        // Draw fuse
        ctx.strokeStyle = '#f39c12';
        ctx.lineWidth = 2 * scale;
        ctx.beginPath();
        ctx.moveTo(scaledRadius * 0.6, -scaledRadius * 0.5);
        ctx.lineTo(scaledRadius * 0.8, -scaledRadius * 0.7);
        ctx.lineTo(scaledRadius * 0.9, -scaledRadius * 0.5);
        ctx.stroke();
        
        // Draw danger stripes
        ctx.strokeStyle = '#e74c3c';
        ctx.lineWidth = 3 * scale;
        ctx.beginPath();
        ctx.moveTo(-scaledRadius * 0.7, 0);
        ctx.lineTo(scaledRadius * 0.7, 0);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(0, -scaledRadius * 0.7);
        ctx.lineTo(0, scaledRadius * 0.7);
        ctx.stroke();
      } else {
        // Regular fruit drawing
        ctx.fillStyle = 'rgba(255,255,255,0.3)';
        ctx.beginPath();
        ctx.arc(-8 * scale, -5 * scale, 8 * scale, 0, Math.PI * 2);
        ctx.fill();

        if (this.type.name === 'watermelon') {
          ctx.fillStyle = '#e74c3c';
          ctx.beginPath();
          ctx.arc(0, 0, scaledRadius * 0.8, 0, Math.PI * 2);
          ctx.fill();

          for (let i = 0; i < 6; i++) {
            const angle = i * Math.PI / 3;
            const sx = Math.cos(angle) * 10 * scale;
            const sy = Math.sin(angle) * 10 * scale;
            ctx.fillStyle = 'black';
            ctx.beginPath();
            ctx.ellipse(sx, sy, 3 * scale, 6 * scale, angle, 0, Math.PI * 2);
            ctx.fill();
          }
        }
        if (this.type.name === 'banana') {
          ctx.fillStyle = '#f1c40f';
          ctx.beginPath();
          ctx.ellipse(0, 0, scaledRadius * 1.2, scaledRadius * 0.6, 0.6, 0, Math.PI * 2);
          ctx.fill();
        }
        if (this.type.name === 'kiwi') {
          ctx.fillStyle = '#7FBC41';
          ctx.beginPath();
          ctx.arc(0, 0, scaledRadius * 0.9, 0, Math.PI * 2);
          ctx.fill();
          ctx.fillStyle = '#3F6612';
          for (let i = 0; i < 8; i++) {
            const angle = i * Math.PI / 4;
            const sx = Math.cos(angle) * scaledRadius * 0.65;
            const sy = Math.sin(angle) * scaledRadius * 0.65;
            ctx.beginPath();
            ctx.arc(sx, sy, 3 * scale, 0, Math.PI * 2);
            ctx.fill();
          }
        }
        if (this.type.name === 'dragonfruit') {
          ctx.fillStyle = '#fff';
          ctx.beginPath();
          ctx.arc(0, 0, scaledRadius * 0.85, 0, Math.PI * 2);
          ctx.fill();
          ctx.fillStyle = '#d6336c';
          for (let i = 0; i < 15; i++) {
            let angle = i * (Math.PI * 2 / 15);
            let sx = Math.cos(angle) * scaledRadius * 0.75;
            let sy = Math.sin(angle) * scaledRadius * 0.75;
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(sx, sy);
            ctx.strokeStyle = '#d6336c';
            ctx.lineWidth = 1 * scale;
            ctx.stroke();
          }
        }
        if (this.type.name === 'golden') {
          // Golden fruit has special shine
          const gradient = ctx.createRadialGradient(0, 0, 0, 0, 0, scaledRadius);
          gradient.addColorStop(0, '#FFD700');
          gradient.addColorStop(0.5, '#FFEC8B');
          gradient.addColorStop(1, '#FFD700');
          ctx.fillStyle = gradient;
          ctx.beginPath();
          ctx.arc(0, 0, scaledRadius, 0, Math.PI * 2);
          ctx.fill();
          
          // Add shine effect
          for (let i = 0; i < 5; i++) {
            const angle = Math.random() * Math.PI * 2;
            const distance = Math.random() * scaledRadius * 0.7;
            const size = Math.random() * scaledRadius * 0.3 + scaledRadius * 0.1;
            ctx.fillStyle = 'rgba(255,255,255,' + (0.3 + Math.random() * 0.3) + ')';
            ctx.beginPath();
            ctx.arc(
              Math.cos(angle) * distance,
              Math.sin(angle) * distance,
              size, 0, Math.PI * 2
            );
            ctx.fill();
          }
        }
      }
    }

    drawHalf(ctx, color, isLeft) {
      const scaledRadius = this.radius * scale;
      ctx.fillStyle = color;
      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.arc(0, 0, scaledRadius, isLeft ? Math.PI / 2 : -Math.PI / 2, isLeft ? (Math.PI * 3) / 2 : Math.PI / 2, isLeft);
      ctx.closePath();
      ctx.fill();

      ctx.fillStyle = 'rgba(255,255,255,0.25)';
      ctx.beginPath();
      ctx.arc(isLeft ? -scaledRadius * 0.4 : scaledRadius * 0.4, -scaledRadius * 0.3, scaledRadius * 0.2, 0, Math.PI * 2);
      ctx.fill();
    }

    // circle-line intersection in design coordinates
    intersectsLine(p1, p2) {
      const cx = this.x;
      const cy = this.y;
      const radius = this.radius;

      let x1 = p1.x / scale;
      let y1 = p1.y / scale;
      let x2 = p2.x / scale;
      let y2 = p2.y / scale;

      const dx = x2 - x1;
      const dy = y2 - y1;

      const a = dx * dx + dy * dy;
      const b = 2 * (dx * (x1 - cx) + dy * (y1 - cy));
      const c = (x1 - cx) * (x1 - cx) + (y1 - cy) * (y1 - cy) - radius * radius;
      const discriminant = b * b - 4 * a * c;

      if (discriminant < 0) {
        return false;
      } else {
        const t1 = (-b + Math.sqrt(discriminant)) / (2 * a);
        const t2 = (-b - Math.sqrt(discriminant)) / (2 * a);
        if ((t1 >= 0 && t1 <= 1) || (t2 >= 0 && t2 <= 1)) {
          return true;
        }
        return false;
      }
    }

    slice() {
      if (this.sliced) return;
      this.sliced = true;
      
      if (this.type.isBomb) {
        // Bomb explosion
        bombSound.play();
        createExplosion(this.x, this.y, this.type.color);
        score += this.type.points;
        updateScore();
        loseLife();
      } else {
        // Regular fruit slice
        sliceSound.play();
        checkCombo();
        score += this.type.points * (1 + combo * 0.2); // Combo multiplier
        updateScore();
        
        // Create splash particles
        for (let i = 0; i < 15; i++) {
          particles.push(new Particle(
            this.x * scale,
            this.y * scale,
            this.type.color
          ));
        }
      }

      this.leftHalf = {
        x: this.x,
        y: this.y,
        vx: -randRange(2, 4),
        vy: this.vy * 0.6,
        angle: 0,
        rotation: -0.1,
        color: this.type.color
      };
      this.rightHalf = {
        x: this.x,
        y: this.y,
        vx: randRange(2, 4),
        vy: this.vy * 0.6,
        angle: 0,
        rotation: 0.1,
        color: this.type.color
      };
    }
  }

  function createExplosion(x, y, color) {
    for (let i = 0; i < 30; i++) {
      particles.push(new Particle(
        x * scale,
        y * scale,
        i % 2 === 0 ? '#ff0000' : '#ff9900'
      ));
    }
  }

  function checkCombo() {
    const now = Date.now();
    if (now - lastSliceTime < 1000) {
      combo++;
    } else {
      combo = 0;
    }
    lastSliceTime = now;
    updateScore();
  }

  function loseLife() {
    lives--;
    combo = 0; // Reset combo when losing a life
    updateScore();
    if (lives <= 0) {
      endGame();
    }
  }

  function endGame() {
    gameOver = true;
  }

  function spawnFruit() {
    // Higher chance for regular fruits, lower for special ones
    let type;
    const rand = Math.random();
    if (rand < 0.8) {
      type = fruitTypes[Math.floor(Math.random() * 6)]; // Regular fruits
    } else if (rand < 0.95) {
      type = fruitTypes[6]; // Golden fruit
    } else {
      type = fruitTypes[7]; // Bomb
    }

    const x = randRange(50, designWidth - 50);
    const y = designHeight + 40;
    const vx = randRange(-2, 2);
    const vy = type.isBomb ? randRange(-14, -10) : randRange(-16, -12);
    const fruit = new Fruit(type, x, y, vx, vy);
    fruits.push(fruit);
  }

  function checkSlicing() {
    if (sliceTrail.length < 2) return;
    for (let i = 0; i < sliceTrail.length - 1; i++) {
      const p1 = sliceTrail[i];
      const p2 = sliceTrail[i + 1];
      for (let fruit of fruits) {
        if (!fruit.sliced && fruit.intersectsLine(p1, p2)) {
          fruit.slice();
          break;
        }
      }
    }
  }

  function updateScore() {
    scoreEl.textContent = `Score: ${score} | Lives: ${lives} | Combo: ${combo}x`;
  }

  // Variables for mouse/touch
  let isDrawing = false;

  function startSlice(x, y) {
    if (gameOver) return;
    isDrawing = true;
    sliceTrail = [{ x, y, time: Date.now() }];
  }

  function moveSlice(x, y) {
    if (!isDrawing) return;
    const now = Date.now();
    sliceTrail.push({ x, y, time: now });
    if (sliceTrail.length > maxTrailLength) {
      sliceTrail.shift();
    }
    checkSlicing();
  }

  function endSlice() {
    isDrawing = false;
    sliceTrail = [];
  }

  function drawSliceTrail(ctx) {
    if (sliceTrail.length < 2) return;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    for (let i = 0; i < sliceTrail.length - 1; i++) {
      const p1 = sliceTrail[i];
      const p2 = sliceTrail[i + 1];
      const alpha = i / sliceTrail.length;
      ctx.strokeStyle = `rgba(255,255,255,${alpha})`;
      ctx.lineWidth = 15 * alpha * scale;
      ctx.beginPath();
      ctx.moveTo(p1.x, p1.y);
      ctx.lineTo(p2.x, p2.y);
      ctx.stroke();
    }
  }

  function cleanUpFruits() {
    fruits = fruits.filter(f => !f.toRemove);
  }

  function cleanUpParticles() {
    particles = particles.filter(p => p.life > 0);
  }

  function drawGameOver(ctx) {
    ctx.save();
    ctx.fillStyle = 'rgba(0,0,0,0.7)';
    ctx.fillRect(0, 0, width * scale, height * scale);
    ctx.fillStyle = '#FFD700';
    ctx.font = `${48 * scale}px Poppins, sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.shadowColor = '#fff';
    ctx.shadowBlur = 10 * scale;
    ctx.fillText('Game Over', width * scale / 2, height * scale / 2 - 40 * scale);
    ctx.font = `${28 * scale}px Poppins, sans-serif`;
    ctx.fillText('Final Score: ' + score, width * scale / 2, height * scale / 2 + 20 * scale);
    ctx.font = `${22 * scale}px Poppins, sans-serif`;
    ctx.fillText('Refresh to play again', width * scale / 2, height * scale / 2 + 70 * scale);
    ctx.restore();
  }

  // Resize canvas and update scale for responsiveness
  function resize() {
    // Calculate max available size for canvas in viewport keeping aspect ratio 3:4
    const maxWidth = window.innerWidth - 40; // margin
    const maxHeight = window.innerHeight * 0.8;
    const targetWidth = designWidth;
    const targetHeight = designHeight;

    let newWidth = maxWidth;
    let newHeight = (maxWidth * targetHeight) / targetWidth;

    if (newHeight > maxHeight) {
      newHeight = maxHeight;
      newWidth = (maxHeight * targetWidth) / targetHeight;
    }

    canvas.style.width = newWidth + 'px';
    canvas.style.height = newHeight + 'px';

    width = newWidth * (designWidth / newWidth); // keep design coordinate consistent
    height = newHeight * (designHeight / newHeight);
    scale = newWidth / designWidth;

    // We keep logical width and height as design dimensions
    // actual drawing scaled inside draw functions
  }

  window.addEventListener('resize', resize);
  resize();

  // Mouse events
  canvas.addEventListener('mousedown', e => {
    const rect = canvas.getBoundingClientRect();
    const x = (e.clientX - rect.left) * (canvas.width / rect.width);
    const y = (e.clientY - rect.top) * (canvas.height / rect.height);
    startSlice(x, y);
  });
  canvas.addEventListener('mousemove', e => {
    const rect = canvas.getBoundingClientRect();
    const x = (e.clientX - rect.left) * (canvas.width / rect.width);
    const y = (e.clientY - rect.top) * (canvas.height / rect.height);
    moveSlice(x, y);
  });
  window.addEventListener('mouseup', e => {
    endSlice();
  });

  // Touch events
  canvas.addEventListener('touchstart', e => {
    if (e.touches.length > 0) {
      const rect = canvas.getBoundingClientRect();
      const touch = e.touches[0];
      const x = (touch.clientX - rect.left) * (canvas.width / rect.width);
      const y = (touch.clientY - rect.top) * (canvas.height / rect.height);
      startSlice(x, y);
    }
    e.preventDefault();
  }, { passive: false });
  canvas.addEventListener('touchmove', e => {
    if (e.touches.length > 0) {
      const rect = canvas.getBoundingClientRect();
      const touch = e.touches[0];
      const x = (touch.clientX - rect.left) * (canvas.width / rect.width);
      const y = (touch.clientY - rect.top) * (canvas.height / rect.height);
      moveSlice(x, y);
    }
    e.preventDefault();
  }, { passive: false });
  canvas.addEventListener('touchend', e => {
    endSlice();
    e.preventDefault();
  }, { passive: false });

  // Game loop
  function loop() {
    if (gameOver) {
      drawGameOver(ctx);
      return;
    }
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Adjust spawn rate based on score
    spawnRate = Math.min(0.06, 0.02 + (Math.floor(score/10) * 0.01));
    
    // Occasionally spawn fruits
    if (Math.random() < spawnRate) {
      spawnFruit();
    }

    // Update and draw fruits
    for (let fruit of fruits) {
      fruit.update();
      fruit.draw(ctx);
    }

    // Update and draw particles
    for (let particle of particles) {
      particle.update();
      particle.draw(ctx);
    }

    cleanUpFruits();
    cleanUpParticles();

    drawSliceTrail(ctx);

    requestAnimationFrame(loop);
  }

  const scoreEl = document.getElementById('score');
  updateScore();
  loop();

})();
</script>
</body>
</html>