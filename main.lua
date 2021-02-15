
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
DIFFICULT_WINS = 0
MODERATE_WINS = 0
EASY_WINS = 0
function love.load()
    --Setup window, background and buttons.
    love.window.setTitle('Pool Ball: Billards Gone Wild')
    screenWidth, screenHeight = love.window.getDesktopDimensions(1)
    menuBarHeight = screenHeight * .105
    windowHeight = screenHeight - menuBarHeight
    windowWidth = windowHeight / 2
    love.window.setMode(windowWidth, windowHeight)
    love.window.setPosition((screenWidth / 2) - (windowWidth / 2), 0)
    WINDOW_SCALE = windowHeight / 720
    StartScreen = love.graphics.newImage('graphics/PB_StartUpScreen.png')
    OptionScreen = love.graphics.newImage('graphics/startup_spectral_table.png')
    trophy = love.graphics.newImage('graphics/trophy.png')
    love.window.setVSync(1)
   
    --Import/connect to the following .lua files.
    require 'LeftHand'
    require 'RightHand'
    require 'Ball'
    require 'Actions'
    require 'Physics'
    require 'Wall'
    require 'Pocket'
    require 'GameLogic'
    require 'computer_AI'
    require 'Crosshair'
    require 'Buttons'
    require 'ChargeBar'

    Class = require 'class'


    --So as not to hard code, these lines mark the perimeter wherein 
    --player hands are permitted to travel. 
    LEFT_WALL_HAND = -15 * WINDOW_SCALE
    RIGHT_WALL_HAND = 255 * WINDOW_SCALE
    BOTTOM_WALL_HAND = 595 * WINDOW_SCALE
    REBOUND_LINE = 320 * WINDOW_SCALE
    SHOT_LINE = 450 * WINDOW_SCALE
    LEFT_WALL_COMP = -15 * WINDOW_SCALE
    RIGHT_WALL_COMP = 255 * WINDOW_SCALE
    TOP_WALL_COMP = 40 * WINDOW_SCALE
    SHOT_LINE_COMP = 270 * WINDOW_SCALE
    --Ball starting positions
    BALL1_X = 125 * WINDOW_SCALE
    BALL1_Y = 375 * WINDOW_SCALE
    BALL2_X = 219 * WINDOW_SCALE
    BALL2_Y = 375 * WINDOW_SCALE
    BALL3_X = 125 * WINDOW_SCALE
    BALL3_Y = 329 * WINDOW_SCALE
    BALL4_X = 219 * WINDOW_SCALE
    BALL4_Y = 329 * WINDOW_SCALE
    --'far right' and 'far left' center coordinates,
    -- and minimal coorndinates for putting a ball in the pocket
    FL_POCKET_CTR_X = 32 * WINDOW_SCALE
    FL_POCKET_CTR_Y = 83 * WINDOW_SCALE
    FL_POCKET_IN_X = 39 * WINDOW_SCALE
    FL_POCKET_IN_Y = 89 * WINDOW_SCALE
    FR_POCKET_CTR_X = 327 * WINDOW_SCALE
    FR_POCKET_CTR_Y = 83 * WINDOW_SCALE
    FR_POCKET_IN_X = 320 * WINDOW_SCALE
    FR_POCKET_IN_Y = 89 * WINDOW_SCALE    

    --Initialize GAME_STATE
    GAME_STATE = 'start-screen'
    PRIOR_STATE = nil
    WINNER = nil
    BLINK_TICKER = 0
    --Initialize Score and keep track of balls in kept in pockets
    P1_BALLS_REMAINING = 6 
    P2_BALLS_REMAINING = 6
    FR_COUNT = 3
    FL_COUNT = 3
    NL_COUNT = 3
    NR_COUNT = 3
    
    TABLE_COUNT = 4
    --The below 2 and above 1 prevent there being > 4 balls on table
    PLAYER1_CAN_DRAW = 0
    COMP_CAN_DRAW = 0
    COMP_POSSESSION_COUNT = 0

    --Thea above 2 help inform AI decision making

    --Create Button Objects
    singleButton = Button(100 * WINDOW_SCALE, 358 * WINDOW_SCALE, 'option-screen', love.graphics.newImage('graphics/PB_single.png'), true)
    multiButton = Button(100 * WINDOW_SCALE, 442 * WINDOW_SCALE, 'option-screen', love.graphics.newImage('graphics/PB_multi.png'), false)
    rulesButton = Button(100 * WINDOW_SCALE, 274 * WINDOW_SCALE, 'option-screen', love.graphics.newImage('graphics/PB_rules.png'), true)
    --Creat Ball-choice buttons, create array carrying them all, set blue ball as default
    MAGNIFY = 1.25 * WINDOW_SCALE
    redBall = Button(190 * WINDOW_SCALE, 100 * WINDOW_SCALE, 'ball', love.graphics.newImage('graphics/balls_red.png'), true)
    blueBall = Button(146 * WINDOW_SCALE, 100 * WINDOW_SCALE, 'ball', love.graphics.newImage('graphics/GreatBalls.png'), true)
    yellowBall = Button(146 * WINDOW_SCALE, 150 * WINDOW_SCALE, 'ball', love.graphics.newImage('graphics/balls_yellow.png'), false)
    orangeBall = Button(190 * WINDOW_SCALE, 150 * WINDOW_SCALE, 'ball', love.graphics.newImage('graphics/balls_orange.png'), false)
    magentaBall = Button(146 * WINDOW_SCALE, 200 * WINDOW_SCALE, 'ball', love.graphics.newImage('graphics/balls_magenta.png'), false)
    iceBall = Button(190 * WINDOW_SCALE, 200 * WINDOW_SCALE, 'ball', love.graphics.newImage('graphics/balls_ice.png'), false)
    darthBall = Button(146 * WINDOW_SCALE, 250 * WINDOW_SCALE, 'ball', love.graphics.newImage('graphics/balls_darthBall.png'), false)
    selected_ball = blueBall  --set blue ball as default
    ballButtons = {blueBall, redBall, yellowBall, orangeBall, magentaBall, iceBall, darthBall, selected_ball}
    --set up ball-selector sprite/animation.
    BallSelector = love.graphics.newImage('graphics/Ball_Selector.png')
    BallSelect1 = love.graphics.newQuad(0, 0, 42, 42, BallSelector:getDimensions())
    BallSelect2 = love.graphics.newQuad(42, 0, 42, 42, BallSelector:getDimensions())
    selectorFrame = BallSelect1
    BALL_SELECTOR_COUNT = 0
    --Create difficulty buttons
    easyButton = Button(158 * WINDOW_SCALE, 335 * WINDOW_SCALE, 'difficulty', nil, true)
    moderateButton = Button(145 * WINDOW_SCALE, 365 * WINDOW_SCALE, 'difficulty', nil, true)
    difficultButton = Button(149 * WINDOW_SCALE, 395 * WINDOW_SCALE, 'difficulty', nil, true)
    selected_difficulty = moderateButton  --set medium difficulty as default
    difficulty_selection_y = moderateButton.y_top
    difficultyButtons = {easyButton, moderateButton, difficultButton, selected_difficulty}
    --Create hand-selection buttons. 
    whiteHandButton = Button(30 * WINDOW_SCALE, 485 * WINDOW_SCALE, 'hand', love.graphics.newImage('graphics/LeftHand.png'), true)
    tanHandButton = Button(120 * WINDOW_SCALE, 485 * WINDOW_SCALE, 'hand', love.graphics.newImage('graphics/BlackHand.png'), true)
    blackHandButton = Button(210 * WINDOW_SCALE, 485 * WINDOW_SCALE, 'hand', love.graphics.newImage('graphics/BlackerHand.png'), true)
    demonHandButton = Button(300 * WINDOW_SCALE, 485 * WINDOW_SCALE, 'hand', love.graphics.newImage('graphics/DemonHand.png'), false)
    blankHand = love.graphics.newImage('graphics/BlankHand.png') -- represents unlocked hand choices.
    selected_hand = tanHandButton
    handButtons = {whiteHandButton, tanHandButton, blackHandButton, demonHandButton, selected_hand}
    --table of all buttons
    allOnePlayerButtons = {ballButtons, difficultyButtons, handButtons}

    --create AI/computer hands
    leftAI = AI(50 * WINDOW_SCALE, 90 * WINDOW_SCALE, 1)
    rightAI = AI(230 * WINDOW_SCALE, 90 * WINDOW_SCALE, -1)
    computerObjects = {leftAI, rightAI}
    --Set default accuracy/error 
    AIerrorCoefficient = 10  * WINDOW_SCALE

    --ball objects
    ball1 = Ball(BALL1_X, BALL1_Y, 1)
    ball2 = Ball(BALL2_X, BALL2_Y, 0)
    ball3 = Ball(BALL3_X, BALL3_Y, 0)
    ball4 = Ball(BALL4_X, BALL4_Y, 0)

    ballObjects = {ball1, ball2, ball3, ball4}
    --create wall objects  --5th arg is TR(topRight), TL, BR or BL, hor or ver. 
    --Point coordinates ordered from by x: low to high.
    wall1 = Wall(43 * WINDOW_SCALE, 79 * WINDOW_SCALE, 50 * WINDOW_SCALE, 85 * WINDOW_SCALE, 'TR', 'A', 'A')
    wall2 = Wall(306 * WINDOW_SCALE, 79 * WINDOW_SCALE, 316 * WINDOW_SCALE, 85 * WINDOW_SCALE, 'TL', 'D', 'D')
    wall3 = Wall(325 * WINDOW_SCALE, 94 * WINDOW_SCALE, 331 * WINDOW_SCALE, 101 * WINDOW_SCALE, 'BR', 'D', 'D')
    wall4 = Wall(325 * WINDOW_SCALE, 344 * WINDOW_SCALE, 329 * WINDOW_SCALE, 348 * WINDOW_SCALE, 'TR', 'E', 'E')
    wall5 = Wall(325 * WINDOW_SCALE, 377 * WINDOW_SCALE, 329 * WINDOW_SCALE, 373 * WINDOW_SCALE, 'BR', 'E', 'E')
    wall6 = Wall(325 * WINDOW_SCALE, 619 * WINDOW_SCALE, 331 * WINDOW_SCALE, 626 * WINDOW_SCALE, 'TR', 'F', 'F')
    wall7 = Wall(306 * WINDOW_SCALE, 635 * WINDOW_SCALE, 316 * WINDOW_SCALE, 641 * WINDOW_SCALE, 'BL', 'F', 'F')
    wall8 = Wall(43 * WINDOW_SCALE, 635 * WINDOW_SCALE, 50 * WINDOW_SCALE, 641 * WINDOW_SCALE, 'BR', 'C', 'C')
    wall9 = Wall(28 * WINDOW_SCALE, 619 * WINDOW_SCALE, 34 * WINDOW_SCALE, 626 * WINDOW_SCALE, 'TL', 'C', 'C')
    wall10 = Wall(30 * WINDOW_SCALE, 373 * WINDOW_SCALE, 34 * WINDOW_SCALE, 377 * WINDOW_SCALE, 'BL', 'B', 'B')
    wall11 = Wall(30 * WINDOW_SCALE, 348 * WINDOW_SCALE, 34 * WINDOW_SCALE, 344 * WINDOW_SCALE, 'TL', 'B', 'B')
    wall12 = Wall(28 * WINDOW_SCALE, 94 * WINDOW_SCALE, 34 * WINDOW_SCALE, 101 * WINDOW_SCALE, 'BL', 'A', 'A')
    --coordinates are now left to right or top to bottom
    wall13 = Wall(50 * WINDOW_SCALE, 85 * WINDOW_SCALE, 309 * WINDOW_SCALE, 85 * WINDOW_SCALE, 'hor', 'A', 'D') 
    wall14 = Wall(325 * WINDOW_SCALE, 101 * WINDOW_SCALE, 325 * WINDOW_SCALE, 344 * WINDOW_SCALE, 'ver', 'D', 'E')
    wall15 = Wall(325 * WINDOW_SCALE, 377 * WINDOW_SCALE, 325 * WINDOW_SCALE, 619 * WINDOW_SCALE, 'ver', 'E', 'F')
    wall16 = Wall(50 * WINDOW_SCALE, 635 * WINDOW_SCALE, 306 * WINDOW_SCALE, 635 * WINDOW_SCALE, 'hor', 'C', 'F')
    wall17 = Wall(34 * WINDOW_SCALE, 377 * WINDOW_SCALE, 34 * WINDOW_SCALE, 619 * WINDOW_SCALE, 'ver','C', 'B')
    wall18 = Wall(34 * WINDOW_SCALE, 101 * WINDOW_SCALE, 34 * WINDOW_SCALE, 344 * WINDOW_SCALE, 'ver','A', 'B')

    walls = {wall1, wall2, wall3, wall4, wall5, wall6, wall7, wall8, wall9,
            wall10, wall11, wall12, wall13, wall14, wall15, wall16, wall17, wall18}
     

    --pocket objects. 'capital letter marcates what sixth of the table it's in.
    topLeft = Pocket(32 * WINDOW_SCALE, 83 * WINDOW_SCALE, 39 * WINDOW_SCALE, 90 * WINDOW_SCALE, 'computer', 'A')
    topRight = Pocket(327 * WINDOW_SCALE, 83 * WINDOW_SCALE, 320 * WINDOW_SCALE, 90 * WINDOW_SCALE, 'computer', 'D')
    sideRight = Pocket(332 * WINDOW_SCALE, 361 * WINDOW_SCALE, 324 * WINDOW_SCALE, 361 * WINDOW_SCALE, 'neutral', 'E') --neutral holes Yi marks the 
    bottomRight = Pocket(327 * WINDOW_SCALE, 637 * WINDOW_SCALE, 320 * WINDOW_SCALE, 630 * WINDOW_SCALE, 'player', 'F')
    bottomLeft = Pocket(32 * WINDOW_SCALE, 637 * WINDOW_SCALE, 39 * WINDOW_SCALE, 630 * WINDOW_SCALE, 'player', 'C')
    sideLeft = Pocket(27 * WINDOW_SCALE, 361 * WINDOW_SCALE, 35 * WINDOW_SCALE, 361 * WINDOW_SCALE, 'neutral', 'B') -- center of hole along y-axis.
    pockets = {topLeft, topRight, sideRight, bottomRight, bottomLeft, sideLeft}

    --Set up music.
    Background_Music = love.audio.newSource('sounds/PoolBall_music.wav', 'static')
    Background_Music.setLooping(Background_Music, true)    
    Background_Music.play(Background_Music)
    --Set up Sound effect
    Wall_Thud = love.audio.newSource('sounds/Wall_Thud.wav', 'static')
    --audio clip 
    Balls_Hard = love.audio.newSource('sounds/Ball_Click_Hard.wav', 'static')
    Balls_Soft = love.audio.newSource('sounds/Ball_Click_Soft.wav', 'static')
    
    --load background image, which is pool table, and it's quads.  
    pool_table = love.graphics.newImage('graphics/the_TABLE2.png')
    pool_lights = {}
    pool_lights[1] = {}
    pool_lights[2] = {}
    pool_lights[3] = {}
    pool_lights[4] = {}
    --One light-less pool table frame will be added to each color group.
    blank = love.graphics.newQuad(360 * 24, 0, 360, 720, pool_table:getDimensions())
    --set quads algorithmically starting with a blank-light frame. 
    for i = 1, 4, 1 do
        for j = 1, 7, 1 do
            if j < 7 then
                pool_lights[i][j] = love.graphics.newQuad((360 * 6 * (i-1)) + (360 * (j-1)), 0, 360, 720, pool_table:getDimensions())
            else
                pool_lights[i][7] = blank
            end
        end
    end
    --set of values used to regulate pool table lighting animation.
    lightQuad = nil
    lightPhase = 7
    flashCycle = 1
    table_counter = 1
    colorKeeper = 1
    brightest = 10

    --load countdown numbers
    number_graphics = love.graphics.newImage('graphics/CountDown.png')
    numbers = {}
    numbers[1] = love.graphics.newQuad(0, 0, 112, 80, number_graphics:getDimensions())
    numbers[2] = love.graphics.newQuad(112, 0, 112, 80, number_graphics:getDimensions())
    numbers[3] = love.graphics.newQuad(224, 0, 112, 80, number_graphics:getDimensions())
    numbers[4] = love.graphics.newQuad(336, 0, 112, 80, number_graphics:getDimensions())
    numberFrame = 1
    numberFrameCounter = 0
end


function love.update(dt)
    --Game can be paused/unpaused with 'p' button.
    function love.keypressed(key)
        if key == 'p' then
            Pause()
        end
    end 

    if GAME_STATE == 'count-down' then
        --At single player game launch, the game counts down from 3 before anyone can move, for a fair start. 
        countDown_scaler = numberFrameCounter * 1 / 15
        if numberFrameCounter > 30 then
            countDown_scaler = (60 - numberFrameCounter) * 1 / 15
        end

        numberFrameCounter = numberFrameCounter + 1
        if numberFrameCounter >= 60 then
            numberFrameCounter = 0
            numberFrame = numberFrame + 1
        end

        if numberFrame > 4 then
            GAME_STATE = 'free-play'
        end
    end
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
    if GAME_STATE == 'free-play' then
        --update crosshairs
        leftPlayerCrosshair:update(dt)
        rightPlayerCrosshair:update(dt)
        --update hands
        rightHand:update(dt)
        leftHand:update(dt)
        --update charge bars
        rightChargeBar:update(dt)
        leftChargeBar:update(dt)
        --Randomize which AI hand updates first, as to prevent unrealistic behavioral trends/biases.
        --    http://lua-users.org/wiki/MathLibraryTutorial   
        math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) ) --THIS WAS BORROWED
        randomUpdate = math.random(2)
        if randomUpdate == 1 then
            rightAI:update(dt)
            leftAI:update(dt)
        else
            leftAI:update(dt)
            rightAI:update(dt)
        end
        
        --update balls after checking for ball on ball collisions
        local first, second = CheckBallOnBall()
 
        --if a ball was scored it will not update until retrieved by defending player. 
        for j = 1, 4, 1 do 
            if ballObjects[j].state ~= 'hidden' then
                ballObjects[j]:update(dt)
            end
        end

        --selects correct animation for the pool table in order to display lights brighten/dim.
        if flashCycle < 50 then -- this part of the phase is brightening, and frames start at 7 and decrease.
            lightPhase = 7 - math.floor((flashCycle - 1) / 7)
        else    --this is the dimming phase from 50-98 where frames start at 1 and climb to 7
            lightPhase = 1 + math.floor((flashCycle-50) / 7) --14 is 7 / 2
        end

        if lightPhase == 1 and brightest == 10 then
            brightest = 1
        elseif lightPhase == 1 and brightest < 10 then
            brightest = brightest + 1
        else
            brightest = 10
        end

        lightQuad = pool_lights[colorKeeper][lightPhase]

        if table_counter >= 392 then
            table_counter = 0
            flashCycle = 0
            colorKeeper = 1
        end

        if flashCycle >= 98 then
            colorKeeper = colorKeeper + 1
            flashCycle = 0 
        end
        --puts cycling on pause for 2 sec while a respective light is on at its brightest. 
        if brightest == 10 then
            table_counter = table_counter + 1
            flashCycle = flashCycle + 1
        end
    end
    ----------------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------------

    --Start screen logic
    if GAME_STATE == 'start-screen' then
        Blinker()
        function love.keypressed(key)
            if key == 'space' then
                GAME_STATE = 'option-screen'
            end
        end
    end
    --Option screen logic: single or multiplayer?
    if GAME_STATE == 'option-screen' then
        local mouse_x, mouse_y = love.mouse.getPosition()
        singleButton:CheckHoverClick(mouse_x, mouse_y)
        multiButton:CheckHoverClick(mouse_x, mouse_y)
        rulesButton:CheckHoverClick(mouse_x, mouse_y)
    end

    if GAME_STATE == 'single' then
        --update single player option availability
        if MODERATE_WINS >= 1 then 
            yellowBall.unlocked = true
        end
        if MODERATE_WINS >= 2 or DIFFICULT_WINS >=1 then
            orangeBall.unlocked = true
        end
        if DIFFICULT_WINS >= 2 then
            iceBall.unlocked = true
        end
        if DIFFICULT_WINS >= 3 then
            magentaBall.unlocked = true
        end
        if DIFFICULT_WINS >= 4 then
            darthBall.unlocked = true
        end
        if DIFFICULT_WINS >= 5 then
            demonHandButton.unlocked = true
        end

        --Gets the text prompt blinking. 
        Blinker()
        --Get mouse position
        mouse_x, mouse_y = love.mouse.getPosition()
        --Check if mouse position aligns with any buttons on the single player screen.
        for j = 1, 3, 1 do
            for i = 1, #allOnePlayerButtons[j] - 1, 1 do
                if allOnePlayerButtons[j][i]:CheckHoverClick(mouse_x, mouse_y) and allOnePlayerButtons[j][i].unlocked == true then
                    allOnePlayerButtons[j][#allOnePlayerButtons[j]] = allOnePlayerButtons[j][i]
                    if allOnePlayerButtons[j] == ballButtons then
                        BALL_SELECTOR_COUNT = 18 --start ball selector animation.
                    end
                end
            end  
        end
        
        --selects for proper animation of the ball selector. Animation changes every 2 frames. 
        if BALL_SELECTOR_COUNT == 0 then
            selectorFrame = BallSelect1
        else
            BALL_SELECTOR_COUNT = BALL_SELECTOR_COUNT - 1
            if BALL_SELECTOR_COUNT % 2 == 1 then    
                selectorFrame = BallSelect2
            else
                selectorFrame = BallSelect1
            end
        end

        function love.keypressed(key)
            if key == 'space' then
                --change game state to countdown/leading in to the match
                GAME_STATE = 'count-down'
                --set difficulty for the match
                if difficultyButtons[#difficultyButtons] == easyButton then
                    AIerrorCoefficient = 13 * WINDOW_SCALE
                elseif difficultyButtons[#difficultyButtons] == moderateButton then
                    AIerrorCoefficient = 10 * WINDOW_SCALE
                elseif  difficultyButtons[#difficultyButtons] == difficultButton then
                    AIerrorCoefficient = 7 * WINDOW_SCALE
                end
                --set textures to all 4 ball objects.
                for j = 1, 4, 1 do
                    ballObjects[j].texture = ballButtons[#ballButtons].texture
                end

                --create hand objects, load hand images.
                HAND_MOVEMENT = 260 * WINDOW_SCALE
                leftHand = LeftHand(handButtons[#handButtons].texture)
                rightHand = RightHand(handButtons[#handButtons].texture)
                --create crosshair objects
                leftPlayerCrosshair = Crosshair(leftHand)
                rightPlayerCrosshair = Crosshair(rightHand)
                --create charge bars
                leftChargeBar = ChargeBar(leftHand)
                rightChargeBar = ChargeBar(rightHand)
            end
        end
    end

    --If game is pause, 'BLINK' the words "press 'p' to unpause" every 90 seconds
    if GAME_STATE == 'paused' then
        Blinker()

    end

    --If game is over, set the string to reflect winner before being printed, and the appropriate
    --x-coordinate for the text to be printed at. 
    if GAME_STATE == 'game-over' then
        Blinker()
        closingString = ''
        x_string = 0
        if WINNER == 'Player-1' then
            closingString = "CONGRATULATIONS!!! YOU ARE THE WINNER!!!"
            x_string = 40 * WINDOW_SCALE
        elseif WINNER == 'Computer' then
            closingString = "GAME OVER. YOU HAVE LOST THE MATCH."
            x_string = 60 * WINDOW_SCALE
        end

        function love.keypressed(key)
            if key == 'space' then
                Background_Music.stop(Background_Music)
                love.load()
                GAME_STATE = 'start-screen'
            end    
        end
    end
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

function love.draw()
    -- set background color
    love.graphics.clear(25/255 * 1, 156/255 * 1, 205/255 * 1, 1)

    if GAME_STATE == 'start-screen' then
        love.graphics.draw(StartScreen, 0, 0, 0, WINDOW_SCALE, WINDOW_SCALE)
        if BLINK_TICKER > 90 then
            love.graphics.printf("press 'space' to continue", 20 * WINDOW_SCALE, 400 * WINDOW_SCALE, 320, "center", 0, WINDOW_SCALE, WINDOW_SCALE)
        end
    elseif GAME_STATE == 'option-screen' then
        love.graphics.draw(OptionScreen, 0, 0, 0, WINDOW_SCALE, WINDOW_SCALE)
        love.graphics.draw(rulesButton.texture, rulesButton.quad, rulesButton.x_left, rulesButton.y_top, 0, WINDOW_SCALE, WINDOW_SCALE)
        love.graphics.draw(singleButton.texture, singleButton.quad, singleButton.x_left, singleButton.y_top, 0, WINDOW_SCALE, WINDOW_SCALE)
        love.graphics.draw(multiButton.texture, multiButton.quad, multiButton.x_left, multiButton.y_top, 0, WINDOW_SCALE, WINDOW_SCALE)
        love.graphics.print('Not Currently Available', 110 * WINDOW_SCALE, 490 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)
    end


    if GAME_STATE == 'single' then
        --Draw ball buttons and associated prompts 
        local ballButtonRadius = 10 * WINDOW_SCALE -- helps to correct origin of mystery circles when drawn.
        color1 = {0, 0, 0, 1} -- Black 
        string1 = '?' -- '?'
        coloredText = {color1, string1} --Black '?' to be used in print function on mystery circles.
        local ballSelector_x = ballButtons[#ballButtons].x_left 
        local ballSelector_y = ballButtons[#ballButtons].y_top
        --Set up/Draw non-selectable elements
        love.graphics.draw(OptionScreen, 0, 0, 0, WINDOW_SCALE, WINDOW_SCALE)
        love.graphics.print("Choose the color of ball-set you want to play with:", 30 * WINDOW_SCALE, 50 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)  
        love.graphics.draw(BallSelector, selectorFrame, ballSelector_x - 11 * WINDOW_SCALE, ballSelector_y - 11 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)
        --go through all ball options. If unlocked, draw the ball. If locked, draw mystery circle with '?'
        for q = 1, #ballButtons, 1 do
            if ballButtons[q].unlocked == true then
                love.graphics.draw(ballButtons[q].texture, ballButtons[q].quad[1], ballButtons[q].x_left, ballButtons[q].y_top, 0, MAGNIFY, MAGNIFY)
            elseif ballButtons[q].unlocked == false then
                love.graphics.circle('fill', ballButtons[q].x_left + ballButtonRadius, ballButtons[q].y_top + ballButtonRadius, ballButtonRadius) 
                love.graphics.print(coloredText,  ballButtons[q].x_left + 7 * WINDOW_SCALE,  ballButtons[q].y_top + 2 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)
            end
        end

        --Draw difficulty words/buttons and draw selector box.
        local difficultySelector_x = difficultyButtons[#difficultyButtons].x_left 
        local difficultySelector_y = difficultyButtons[#difficultyButtons].y_top
        love.graphics.print("Select computer opponent difficulty:", 75 * WINDOW_SCALE, 300 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE) 
        love.graphics.print("Easy", 163 * WINDOW_SCALE, 340 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE) 
        love.graphics.print("Moderate", 150 * WINDOW_SCALE, 370 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE) 
        love.graphics.print("Difficult", 154 * WINDOW_SCALE, 400 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE) 
        love.graphics.rectangle('line', moderateButton.x_left, difficultySelector_y, 68 * WINDOW_SCALE, 25 * WINDOW_SCALE) -- rectangle always sized to moderate button
        
        --Draw hand icons and selector box
        handIconQuad = love.graphics.newQuad(32, 10, 50, 50, 400, 80)
        blankQuad = love.graphics.newQuad(0, 0, 80, 80, 80, 80)
        love.graphics.print("Select your player:", 121 * WINDOW_SCALE, 450 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)
        for i = 1, #handButtons - 1, 1 do
            if handButtons[i].unlocked == true then
                love.graphics.draw(handButtons[i].texture, handIconQuad, handButtons[i].x_left, handButtons[i].y_top, 0, WINDOW_SCALE, WINDOW_SCALE)    
            else
                love.graphics.draw(blankHand, blankQuad, handButtons[i].x_left - 32 * WINDOW_SCALE, handButtons[i].y_top - 10 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)
                love.graphics.print(coloredText, handButtons[i].x_left + 16 * WINDOW_SCALE, handButtons[i].y_top + 12 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)   
            end
        end
        love.graphics.rectangle('line', handButtons[#handButtons].x_left, handButtons[#handButtons].y_top, 40 * WINDOW_SCALE, 40 * WINDOW_SCALE)

        if BLINK_TICKER > 90 then
            love.graphics.print("Press 'space' to continue", 105 * WINDOW_SCALE, 575 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE) 
        end
        
    end


    if GAME_STATE == 'free-play' or GAME_STATE == 'count-down' then
        if GAME_STATE == 'count-down' then
        love.graphics.draw(pool_table, pool_lights[1][7], 0, 0, 0, WINDOW_SCALE, WINDOW_SCALE)
        else
            love.graphics.draw(pool_table, lightQuad, 0, 0, 0, WINDOW_SCALE, WINDOW_SCALE)
        end

        --Print the ball counters for player and computer at bottom and top of screen, respoectively. 
        counterImage = ball1.texture
        counterFrame = love.graphics.newQuad(0, 0, 16, 16, counterImage:getDimensions())

        for i = 1, NL_COUNT, 1 do
            love.graphics.draw(counterImage, counterFrame, 40 + i * 20 * WINDOW_SCALE, 679 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)
        end
        for j = 1, NR_COUNT, 1 do
            love.graphics.draw(counterImage, counterFrame, 320 * WINDOW_SCALE - j * 20 * WINDOW_SCALE, 679 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)
        end
        for k = 1, FL_COUNT, 1 do
            love.graphics.draw(counterImage, counterFrame, 40 + k * 20 * WINDOW_SCALE, 25 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)
        end
        for l = 1, FR_COUNT, 1 do
            love.graphics.draw(counterImage, counterFrame, 320 * WINDOW_SCALE - l * 20 * WINDOW_SCALE, 25 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)
        end

         --pause/rules & instructions prompt
         love.graphics.printf("Press 'p' to pause the game, or to see game manual.", -20 * WINDOW_SCALE, 5 * WINDOW_SCALE, 500, "center", 0, .8 * WINDOW_SCALE, .8 * WINDOW_SCALE)
         --Render crosshairs of player hands before hands, themselves. 
        if leftHand.acquired == nil then
             leftPlayerCrosshair:render()
        end
        if rightHand.acquired == nil then
             rightPlayerCrosshair:render()
        end 
         
         --then balls if not hidden/scored; then hands.
         --Make sure to draw elevated = false balls first
        for j = 1, 2, 1 do    
            for i = 1, 4, 1 do
                if j == 1 and ballObjects[i].state ~= 'hidden' and ballObjects[i].elevated == false then
                    ballObjects[i]:render()
                elseif j == 2 and ballObjects[i].state ~= 'hidden' and ballObjects[i].elevated == true then
                    ballObjects[i]:render()
                end
            end
        end
        --Render the countdown after balls are displayed
        if GAME_STATE == 'count-down' then
            love.graphics.draw(number_graphics, numbers[numberFrame], 175 * WINDOW_SCALE, 360 * WINDOW_SCALE, 0, countDown_scaler * WINDOW_SCALE, countDown_scaler * WINDOW_SCALE, 50, 50)
        end

        leftHand:render()
        rightHand:render()

        if leftChargeBar.hidden == false then
            leftChargeBar:render()
        end
        if rightChargeBar.hidden == false then
            rightChargeBar:render()
        end

        leftAI:render()
        rightAI:render()
        
    elseif GAME_STATE == 'paused' then

        love.graphics.printf("     Left Hand controls            " ..
            "Right Hand controls", 10 * WINDOW_SCALE, 10 * WINDOW_SCALE, 320, "center", 0, WINDOW_SCALE, WINDOW_SCALE)
        
        keyMap = love.graphics.newImage('graphics/keyMap.png')
        love.graphics.draw(keyMap, 16 * WINDOW_SCALE, 30 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)

        love.graphics.printf("Rules of Pool ball:\n\n" ..
        "Objective: Empty your 2 pool pockets of all balls; or any equivalency, such as " ..
        "putting your opponent at a 6-ball deficit. Do this by rolling your balls into the " ..
        "opponent's 2 pockets, while defending your own.\n\n" ..  
        "Pick up/Drop: Both of these are performed with the 'action' button.  If a " ..
        "ball is within the spotlight beneath a hand, it means that the ball is within range " .. 
        "to be picked up. After scoring, retrieve an available ball from one of your own pockets. \n\n" ..
        "Rebounds: A ball being shot at your pockets cannot be picked up unless it first " ..
        "rebounds off a wall, or another ball; hence why it is useful to make a defensive " ..
        "play (see 'Defense' section)\n\n" ..
        "Offense: Holding down the 'action' button for longer than 0.5 seconds and releasing " ..
        "it will shoot a ball towards the opponent's pocket on the same side.  Holding down " ..
        "'action' and pressing forward ('w' for left hand, 'i' for right) will shoot the ball " ..
        "to the opposite side. Shots must be taken behind the line of light bulbs on your side. \n\n" ..
        "Defense: Your pockets can be defended by rolling balls horizontally to knock incoming " ..
        "balls off their course. For the left hand, this is performed by holding the 'action' " ..
        "button, and pressing 'a' or 'd' to throw ball to left or right, respectively." ..
        "", 20 * WINDOW_SCALE, 200 * WINDOW_SCALE, 320, "left", 0, WINDOW_SCALE, WINDOW_SCALE)

        if BLINK_TICKER > 90 then
            love.graphics.printf("press 'p' to return.", 22 * WINDOW_SCALE, 655 * WINDOW_SCALE, 320, "center", 0, WINDOW_SCALE, WINDOW_SCALE)
        end

    elseif GAME_STATE == 'game-over' then
        love.graphics.draw(OptionScreen, 0, 0, 0, WINDOW_SCALE, WINDOW_SCALE)
        love.graphics.print("Total Wins:", 50 * WINDOW_SCALE, 280 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)
        totalWins = EASY_WINS + MODERATE_WINS + DIFFICULT_WINS
        love.graphics.print(totalWins, 200 * WINDOW_SCALE, 280 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)
        love.graphics.print("Easy Mode: ", 50 * WINDOW_SCALE, 300 * WINDOW_SCALE, 0 ,WINDOW_SCALE, WINDOW_SCALE)
        love.graphics.print(EASY_WINS, 200 * WINDOW_SCALE, 300 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)
        love.graphics.print("Moderate Mode: ", 50 * WINDOW_SCALE, 320 * WINDOW_SCALE, 0 ,WINDOW_SCALE, WINDOW_SCALE)
        love.graphics.print(MODERATE_WINS, 200 * WINDOW_SCALE, 320 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)
        love.graphics.print("Difficult Mode: ", 50 * WINDOW_SCALE, 340 * WINDOW_SCALE, 0 ,WINDOW_SCALE, WINDOW_SCALE)
        love.graphics.print(DIFFICULT_WINS, 200 * WINDOW_SCALE, 340 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE)
        love.graphics.printf(closingString, x_string, 240 * WINDOW_SCALE, 500, "left", 0, WINDOW_SCALE, WINDOW_SCALE)
        if BLINK_TICKER > 90 then
            love.graphics.print("Press 'space' to return to home-screen", 65 * WINDOW_SCALE, 400 * WINDOW_SCALE, 0, WINDOW_SCALE, WINDOW_SCALE) 
        end
    end 
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function Blinker()
    BLINK_TICKER = BLINK_TICKER + 1
    if BLINK_TICKER >= 180 then
        BLINK_TICKER = 0
    else 
        BLINK_TICKER = BLINK_TICKER + 1
    end
end