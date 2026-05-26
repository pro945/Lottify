<%@page import="java.sql.*"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Minesweeper Game 4x4 with Diamonds</title>
    <style>
        /* Reset and base */
        * {
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #1e1e2f;
            color: #e0e0e0;
            margin: 0;
            padding: 10px;
            display: flex;
            flex-direction: column;
            align-items: center;
            min-height: 600px;
            max-width: 350px;
            margin-left: auto;
            margin-right: auto;
            user-select: none;
        }

        h1 {
            margin-bottom: 5px;
            font-weight: 700;
            text-shadow: 0 0 10px #00bcd4aa;
        }

        #gameInfo {
            margin-bottom: 10px;
            display: flex;
            justify-content: space-between;
            width: 100%;
            font-size: 1.2rem;
        }

        #board {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            grid-gap: 6px;
            background: #282c3f;
            padding: 8px;
            border-radius: 12px;
            box-shadow: 0 0 15px #00bcd4bb;
            touch-action: manipulation;
            user-select: none;
            width: 100%;
            max-width: 280px;
        }

        .cell {
            background: #404561;
            border-radius: 6px;
            height: 50px;
            width: 50px;
            display: flex;
            justify-content: center;
            align-items: center;
            font-weight: 700;
            font-size: 1.4rem;
            color: #e0e0e0;
            cursor: pointer;
            box-shadow: inset 0 1px 0 #6f7491, inset 0 -1px 0 #2a2f4c;
            transition: background 0.25s, color 0.25s;
            user-select: none;
        }

        .cell.revealed {
            background: #aab2ce;
            color: #333;
            cursor: default;
            box-shadow: inset 0 1px 1px #f0f0f0;
        }

        .cell.mine {
            background: #e53935;
            color: white;
            cursor: default;
            box-shadow: 0 0 8px #e5393544 inset;
        }

        .cell.flagged {
            background: #2979ff;
            color: white;
            cursor: pointer;
        }

        .cell.disabled {
            cursor: default;
        }

        #resetButton {
            margin-top: 12px;
            background: #00bcd4;
            color: #fff;
            font-weight: 700;
            border: none;
            border-radius: 12px;
            padding: 12px 24px;
            cursor: pointer;
            box-shadow: 0 4px 12px #00bcd4bb;
            transition: background 0.3s ease;
            width: 100%;
            max-width: 280px;
            user-select: none;
        }

        #resetButton:hover {
            background: #0097a7;
        }

        /* Number colors */
        .num1 img { filter: drop-shadow(0 0 1px #1976d2); }
        .num2 img { filter: drop-shadow(0 0 1px #388e3c); }
        .num3 img { filter: drop-shadow(0 0 1px #d32f2f); }
        .num4 img { filter: drop-shadow(0 0 1px #512da8); }
        .num5 img { filter: drop-shadow(0 0 1px #fbc02d); }
        .num6 img { filter: drop-shadow(0 0 1px #00796b); }
        .num7 img { filter: drop-shadow(0 0 1px #455a64); }
        .num8 img { filter: drop-shadow(0 0 1px #000000); }

        /* Responsive scaling for smaller screens */
        @media (max-width: 380px) {
            #board {
                grid-template-columns: repeat(4, 1fr);
                grid-gap: 5px;
            }
            .cell {
                height: 44px;
                width: 44px;
                font-size: 1.2rem;
            }
            #resetButton {
                padding: 10px 20px;
                font-size: 1rem;
            }
            #gameInfo {
                font-size: 1rem;
            }
        }
    </style>
</head>
<body>
    <h1>Minesweeper 4x4</h1>
    <div id="gameInfo">
        <div>Mines: <span id="mineCount">4</span></div>
        <div>Time: <span id="timer">0</span>s</div>
        <div>Coins: <span id="coinCount">
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
        out.print(coins);

        // Update coins
        st.executeUpdate("UPDATE coins SET coin = " + newCoins);
    } else {
        out.print("No coin data found.");
    }
} catch(Exception e) {
    out.print("Error: " + e.getMessage());
} finally {
    try { if(rs != null) rs.close(); } catch(Exception e) {}
    try { if(st != null) st.close(); } catch(Exception e) {}
    try { if(con != null) con.close(); } catch(Exception e) {}
}
%>
        </span></div>
    </div>
    <div id="board" aria-label="Minesweeper game board" role="grid"></div>
    <button id="resetButton" aria-label="Reset the game">Restart</button>

    <script>
        (() => {
            const rows = 4;
            const cols = 4;
            const totalMines = 4;
            let board = [];
            let revealedCount = 0;
            let flaggedCount = 0;
            let gameOver = false;
            let timerInterval = null;
            let startTime = null;

            const boardEl = document.getElementById('board');
            const mineCountEl = document.getElementById('mineCount');
            const timerEl = document.getElementById('timer');
            const resetButton = document.getElementById('resetButton');

            // Diamond image URL - you can replace this URL with your own diamond image if needed
            const diamondImgURL = 'Diamonds.jpg';

            mineCountEl.textContent = totalMines;

            function createBoard() {
                board = [];
                revealedCount = 0;
                flaggedCount = 0;
                gameOver = false;
                startTime = null;
                clearInterval(timerInterval);
                timerEl.textContent = 0;

                boardEl.innerHTML = '';
                // Fix template literal usage with string concatenation for JSP compatibility
                boardEl.style.gridTemplateColumns = 'repeat(' + cols + ', 1fr)';

                // Create 2D array with cell objects
                for(let r=0; r < rows; r++){
                    const row = [];
                    for(let c=0; c < cols; c++){
                        row.push({
                            row: r,
                            col: c,
                            mine: false,
                            revealed: false,
                            flagged: false,
                            adjacentMines: 0,
                            element: null
                        });
                    }
                    board.push(row);
                }

                // Place mines randomly
                let minesPlaced = 0;
                while(minesPlaced < totalMines) {
                    const r = Math.floor(Math.random() * rows);
                    const c = Math.floor(Math.random() * cols);
                    if(!board[r][c].mine) {
                        board[r][c].mine = true;
                        minesPlaced++;
                    }
                }

                // Calculate adjacent mines for each cell
                for(let r=0; r < rows; r++){
                    for(let c=0; c < cols; c++){
                        board[r][c].adjacentMines = countAdjacentMines(r, c);
                    }
                }

                // Create HTML cells
                for(let r=0; r < rows; r++){
                    for(let c=0; c < cols; c++){
                        const cell = document.createElement('div');
                        cell.classList.add('cell');
                        cell.setAttribute('data-row', r);
                        cell.setAttribute('data-col', c);
                        cell.setAttribute('role','button');
                        cell.setAttribute('tabindex','0');
                        cell.setAttribute('aria-label','Unrevealed cell');

                        // Accessibility keyboard support
                        cell.addEventListener('keydown', e => {
                            if(gameOver) return;
                            if(e.key === 'Enter' || e.key === ' ') {
                                e.preventDefault();
                                revealCell(r,c);
                            } else if(e.key === 'ContextMenu' || (e.shiftKey && e.key === 'F')) {
                                e.preventDefault();
                                toggleFlag(r,c);
                            }
                        });

                        // Left click reveal
                        cell.addEventListener('click', e => {
                            if(gameOver) return;
                            revealCell(r,c);
                        });

                        // Right click flag
                        cell.addEventListener('contextmenu', e => {
                            e.preventDefault();
                            if(gameOver) return;
                            toggleFlag(r,c);
                        });

                        // Touch: long press to flag (on mobile)
                        makeLongPressFlag(cell, r, c);

                        board[r][c].element = cell;
                        boardEl.appendChild(cell);
                    }
                }
            }

            function countAdjacentMines(row, col){
                let count = 0;
                for(let dr = -1; dr <= 1; dr++){
                    for(let dc = -1; dc <= 1; dc++){
                        if(dr === 0 && dc === 0) continue;
                        const nr = row + dr;
                        const nc = col + dc;
                        if(nr >= 0 && nr < rows && nc >= 0 && nc < cols){
                            if(board[nr][nc].mine) count++;
                        }
                    }
                }
                return count;
            }

            function revealCell(row, col){
                if(gameOver) return;
                const cell = board[row][col];
                if(cell.revealed || cell.flagged) return;

                if(!startTime){
                    startTime = Date.now();
                    timerInterval = setInterval(updateTimer, 1000);
                }

                cell.revealed = true;
                revealedCount++;
                const el = cell.element;
                el.classList.add('revealed');
                el.setAttribute('aria-label', 'Revealed cell');

                if(cell.mine){
                    el.classList.add('mine');
                    el.textContent = '💣';
                    endGame(false);
                    return;
                }

                if(cell.adjacentMines > 0){
                    el.classList.add('num' + cell.adjacentMines);
                    el.textContent = '';
                    const img = document.createElement('img');
                    img.src = diamondImgURL;
                    img.alt = cell.adjacentMines + ' diamonds';
                    img.style.width = '24px';
                    img.style.height = '24px';
                    el.appendChild(img);
                } else {
                    el.textContent = '';
                    // reveal neighbors recursively
                    for(let dr = -1; dr <= 1; dr++){
                        for(let dc = -1; dc <= 1; dc++){
                            const nr = row + dr;
                            const nc = col + dc;
                            if(nr >= 0 && nr < rows && nc >=0 && nc < cols){
                                if(!board[nr][nc].revealed){
                                    revealCell(nr,nc);
                                }
                            }
                        }
                    }
                }

                checkWin();
            }

            function toggleFlag(row,col){
                if(gameOver) return;
                const cell = board[row][col];
                if(cell.revealed) return;
                const el = cell.element;
                if(cell.flagged){
                    cell.flagged = false;
                    flaggedCount--;
                    el.classList.remove('flagged');
                    el.textContent = '';
                    el.setAttribute('aria-label', 'Unrevealed cell');
                } else {
                    if(flaggedCount >= totalMines) return; // limit flags
                    cell.flagged = true;
                    flaggedCount++;
                    el.classList.add('flagged');
                    el.textContent = '🚩';
                    el.setAttribute('aria-label', 'Flagged cell');
                }
                mineCountEl.textContent = totalMines - flaggedCount;
            }

            function updateTimer(){
                if(!startTime) return;
                const elapsed = Math.floor((Date.now() - startTime)/1000);
                timerEl.textContent = elapsed;
            }

            function checkWin(){
                if(revealedCount === rows*cols - totalMines && !gameOver){
                    endGame(true);
                }
            }

            function endGame(won){
                gameOver = true;
                clearInterval(timerInterval);
                revealAllMines();
                setTimeout(() => {
                    if(won){
                        alert('🎉 Congratulations! You cleared the minefield!');
                    } else {
                        alert('💥 Boom! You hit a mine. Game over.');
                    }
                }, 100);
                disableBoard();
            }

            function revealAllMines(){
                for(let r=0; r < rows; r++){
                    for(let c=0; c < cols; c++){
                        const cell = board[r][c];
                        if(cell.mine && !cell.revealed){
                            const el = cell.element;
                            el.classList.add('revealed', 'mine');
                            el.textContent = '💣';
                        }
                    }
                }
            }

            function disableBoard(){
                for(let r=0; r < rows; r++){
                    for(let c=0; c < cols; c++){
                        const el = board[r][c].element;
                        el.classList.add('disabled');
                    }
                }
            }

            // Long press implementation for mobile flagging
            function makeLongPressFlag(element, row, col){
                let timerId = null;
                let moved = false;

                element.addEventListener('touchstart', e => {
                    moved = false;
                    timerId = setTimeout(() => {
                        toggleFlag(row, col);
                    }, 700);
                });
                element.addEventListener('touchmove', e => {
                    moved = true;
                    if(timerId){
                        clearTimeout(timerId);
                        timerId = null;
                    }
                });
                element.addEventListener('touchend', e => {
                    if(timerId){
                        clearTimeout(timerId);
                        timerId = null;
                        if(!moved){
                            // treat as tap - reveal
                            revealCell(row, col);
                        }
                    }
                });
            }

            resetButton.addEventListener('click', e => {
                createBoard();
            });

            // Initialize on page load
            createBoard();
        })();
    </script>
</body>
</html>