<%@page import="java.sql.*"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
<title>Machole Game - Whack the Mole</title>
<style>
  /* Reset & global */
  * {
    box-sizing: border-box;
  }
  body, html {
    margin: 0; padding: 0;
    height: 100%;
    background: linear-gradient(135deg, #74ebd5 0%, #ACB6E5 100%);
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    display: flex;
    justify-content: center;
    align-items: center;
  }
  #game-container {
    background: #f0f4f8;
    border-radius: 16px;
    width: 350px;
    height: 600px;
    box-shadow: 0 12px 25px rgba(0,0,0,0.15);
    display: flex;
    flex-direction: column;
    padding: 20px;
  }
  h1 {
    text-align: center;
    color: #2c3e50;
    margin: 0 0 12px 0;
    font-weight: 700;
    font-size: 1.9rem;
    user-select: none;
  }
  #scoreboard {
    display: flex;
    justify-content: space-around;
    font-size: 1.25rem;
    font-weight: 600;
    margin-bottom: 12px;
    color: #34495e;
  }
  #game-board {
    flex: 1;
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    grid-gap: 14px;
    padding: 0 10px;
  }
  .hole {
    position: relative;
    background: #8e9eab;
    border-radius: 50% / 30%;
    cursor: pointer;
    box-shadow:
      inset 0 8px 10px #6b7a89,
      inset 0 -6px 8px #aab9c6;
    overflow: visible;
    user-select: none;
  }
  .hole:before {
    content: "";
    position: absolute;
    top: 15%;
    left: 50%;
    transform: translateX(-50%);
    width: 80%;
    height: 40%;
    background: radial-gradient(ellipse at center, #333 0%, #000 90%);
    border-radius: 50% / 50%;
    filter: brightness(0.2);
    pointer-events: none;
  }
  .mole {
    position: absolute;
    bottom: 0;
    left: 50%;
    transform: translateX(-50%) translateY(100%);
    width: 70%;
    height: 75%;
    background:
      radial-gradient(circle at 50% 40%, #4a2e18 30%, #3a220e),
      radial-gradient(circle at 40% 48%, #2e1a0c 30%, #1f130a);
    border-radius: 40% 40% 50% 50% / 60% 60% 100% 100%;
    box-shadow:
      inset 0 10px 12px rgba(0,0,0,0.25),
      0 2px 5px rgba(0,0,0,0.35);
    transition: transform 0.3s ease-out;
    z-index: 5;
  }
  .mole.up {
    transform: translateX(-50%) translateY(0%);
    cursor: pointer;
  }
  /* Eyes */
  .mole .eye {
    position: absolute;
    top: 30%;
    width: 12%;
    height: 12%;
    background: #fff;
    border-radius: 50%;
    border: 2px solid #000;
  }
  .mole .eye.left {
    left: 25%;
  }
  .mole .eye.right {
    right: 25%;
  }
  .mole .pupil {
    position: absolute;
    top: 25%;
    left: 50%;
    width: 40%;
    height: 40%;
    background: #000;
    border-radius: 50%;
    transform: translateX(-50%);
  }

  /* Nose */
  .mole .nose {
    position: absolute;
    top: 50%;
    left: 50%;
    width: 14%;
    height: 12%;
    background: #3a220e;
    border-radius: 70% 70% 100% 100% / 100% 100% 60% 60%;
    transform: translateX(-50%);
  }

  #start-btn {
    margin-top: 18px;
    background: #3498db;
    color: white;
    border: none;
    border-radius: 10px;
    padding: 14px;
    font-size: 1.2rem;
    font-weight: 700;
    cursor: pointer;
    box-shadow: 0 6px 14px rgba(52,152,219,0.7);
    user-select: none;
    transition: background-color 0.3s ease;
    outline-offset: 3px;
  }
  #start-btn:hover, #start-btn:focus {
    background: #2980b9;
    outline: none;
  }

  /* Responsive text scaling */
  @media (max-width: 360px) {
    #game-container {
      width: 320px;
      height: 580px;
      padding: 15px;
    }
    h1 {
      font-size: 1.6rem;
    }
    #scoreboard {
      font-size: 1.1rem;
    }
    #start-btn {
      font-size: 1rem;
      padding: 12px;
    }
  }
</style>
</head>
<body>
  <div id="game-container" role="main" aria-label="Whack the mole game">
    <h1>Machole Game</h1>
    <div id="scoreboard" aria-live="polite" aria-atomic="true">
      <div>Score: <span id="score">0</span></div>
      <div>Time: <span id="time">30</span>s</div>
    </div>
    <div id="game-board" aria-label="Game holes" role="grid">
      <div class="hole" data-index="0" role="gridcell" tabindex="0"></div>
      <div class="hole" data-index="1" role="gridcell" tabindex="0"></div>
      <div class="hole" data-index="2" role="gridcell" tabindex="0"></div>
      <div class="hole" data-index="3" role="gridcell" tabindex="0"></div>
      <div class="hole" data-index="4" role="gridcell" tabindex="0"></div>
      <div class="hole" data-index="5" role="gridcell" tabindex="0"></div>
      <div class="hole" data-index="6" role="gridcell" tabindex="0"></div>
      <div class="hole" data-index="7" role="gridcell" tabindex="0"></div>
      <div class="hole" data-index="8" role="gridcell" tabindex="0"></div>
    </div>
    <button id="start-btn" aria-pressed="false" aria-label="Start game">Start Game</button>
  </div>

<script>
  (() => {
    const holes = document.querySelectorAll('.hole');
    const scoreBoard = document.getElementById('score');
    const timeBoard = document.getElementById('time');
    const startBtn = document.getElementById('start-btn');
    const gameDuration = 30; // seconds
    let lastHoleIndex = null;
    let timeUp = false;
    let score = 0;
    let countdownTimer;
    let moleTimer;

    // Create mole element and attach eyes and nose
    function createMole() {
      const mole = document.createElement('div');
      mole.classList.add('mole');

      const leftEye = document.createElement('div');
      leftEye.classList.add('eye', 'left');
      const leftPupil = document.createElement('div');
      leftPupil.classList.add('pupil');
      leftEye.appendChild(leftPupil);

      const rightEye = document.createElement('div');
      rightEye.classList.add('eye', 'right');
      const rightPupil = document.createElement('div');
      rightPupil.classList.add('pupil');
      rightEye.appendChild(rightPupil);

      const nose = document.createElement('div');
      nose.classList.add('nose');

      mole.appendChild(leftEye);
      mole.appendChild(rightEye);
      mole.appendChild(nose);

      return mole;
    }

    // Pick random hole but not the same as last
    function randomHole(holes) {
      let idx;
      do {
        idx = Math.floor(Math.random() * holes.length);
      } while (idx === lastHoleIndex);
      lastHoleIndex = idx;
      return holes[idx];
    }

    // Show mole in a hole
    function showMole() {
      if (timeUp) return;
      const hole = randomHole(holes);
      const mole = createMole();
      hole.appendChild(mole);

      // Animate mole popping up
      requestAnimationFrame(() => {
        mole.classList.add('up');
      });

      // Set mole clicked event
      mole.addEventListener('click', function moleClicked() {
        score++;
        scoreBoard.textContent = score;
        // Whack feedback animation
        mole.style.transform = 'translateX(-50%) translateY(120%) scale(0.9)';
        mole.style.opacity = '0.7';
        mole.removeEventListener('click', moleClicked);
        setTimeout(() => {
          if (mole.parentNode) {
            mole.parentNode.removeChild(mole);
          }
        }, 300);
      });

      // Remove mole after a short while if not clicked
      setTimeout(() => {
        if (mole && mole.parentNode) {
          mole.classList.remove('up');
          setTimeout(() => {
            if (mole.parentNode) mole.parentNode.removeChild(mole);
          }, 300);
        }
      }, randomTime(800, 1400));
    }

    // Return random time between min and max
    function randomTime(min, max) {
      return Math.round(Math.random() * (max - min) + min);
    }

    // Game loop mole pop ups at intervals
    function moleLoop() {
      if (timeUp) return;
      showMole();
      moleTimer = setTimeout(moleLoop, randomTime(700, 1300));
    }

    // Count down timer logic
    function countDown() {
      let timeLeft = gameDuration;
      timeBoard.textContent = timeLeft;
      countdownTimer = setInterval(() => {
        timeLeft--;
        timeBoard.textContent = timeLeft;
        if (timeLeft <= 0) {
          clearInterval(countdownTimer);
          timeUp = true;
          startBtn.disabled = false;
          startBtn.setAttribute('aria-pressed', 'false');
          alert('Time is up! Your score: ' + score);
        }
      }, 1000);
    }

    function clearMoles() {
      holes.forEach(hole => {
        while (hole.firstChild) {
          hole.removeChild(hole.firstChild);
        }
      });
    }

    // Start game function
    function startGame() {
      score = 0;
      timeUp = false;
      scoreBoard.textContent = score;
      timeBoard.textContent = gameDuration;
      startBtn.disabled = true;
      startBtn.setAttribute('aria-pressed', 'true');
      clearMoles();
      moleLoop();
      countDown();
    }

    // Initialize accessibility for holes - allow keyboard click to whack mole
    holes.forEach(hole => {
      hole.addEventListener('keydown', e => {
        if (e.key === 'Enter' || e.key === ' ') {
          const mole = hole.querySelector('.mole.up');
          if (mole) {
            mole.click();
          }
        }
      });
    });

    startBtn.addEventListener('click', startGame);

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