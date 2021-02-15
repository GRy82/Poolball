--Determines distance between two objects
function GetDifference(position_x, position_y, other_x, other_y)
    difference_x = math.abs(position_x - other_x)
    difference_y = math.abs(position_y - other_y)
    difference = math.sqrt((difference_x * difference_x) + (difference_y * difference_y))
    return difference   
end

--return 'positive' or 'negative' or '0'
function Sign(number)
    if number > 0 then 
        return 1
    elseif number < 0 then
        return -1
    else 
        return 0
    end
end

--Determine which sixth of the table the ball is on, so we are not 
--checking for every collision every frame. 
--Each sector has 4 walls and a pocket, and possibly ball(s)
function GetSector(ball_x, ball_y)
    if ball_x < 180 * WINDOW_SCALE then
        if ball_y < 240 * WINDOW_SCALE then
            sector = 'A'
        elseif ball_y >= 480 * WINDOW_SCALE then
            sector = 'C'
        else 
            sector = 'B'
        end
    else
        if ball_y < 240 * WINDOW_SCALE then
            sector = 'D'
        elseif ball_y >= 480 * WINDOW_SCALE then
            sector = 'F'
        else 
            sector = 'E'
        end
    end    

    return sector
end


function ObjectsFromSector(sectorString)
    --a table which will be populated with all pockets/walls in a sector, and will be returned.
    sectorObjects = {}
    --choose the correct pocket from the sector
    for i = 1, 6, 1 do
        if pockets[i].sector == sectorString then
            sectorObjects[1] = pockets[i]
        end
    end
    --choose the 4 walls from that sector
    local wallCount = 2
    for j = 1, 18, 1 do
        if walls[j].sector1 == sectorString or walls[j].sector2 == sectorString then
            sectorObjects[wallCount] = walls[j]
            wallCount = wallCount + 1 
        end
    end

    return sectorObjects
end


function SlidingFriction(friction)
    friction = math.min(friction + .012, 1.01)
    return  friction
end


function CalculateVelocity(holdCounter)
    SHOT_VEL = 900 * WINDOW_SCALE --this is just the starting shot speed
    local SHOT_MAX = 1300 * WINDOW_SCALE --This is the maximum speed a ball can roll
    SHOT_VEL = SHOT_VEL + (4.4 * (holdCounter-30)) 
    SHOT_VEL = math.min(SHOT_VEL, SHOT_MAX)
    return SHOT_VEL
end

function CalculateShot(holdCounter, shootingHand, targetHole)
    --Calculate Shot(dx and dy of the ball that's currently acquired)
    if shootingHand == rightHand or shootingHand == leftHand then
        SHOT_VEL = CalculateVelocity(holdCounter)
    else
        --If function is called by an AI, then holdCounter is actually the random velocity.
        SHOT_VEL = holdCounter 
    end

    --reset values to reflect ball not being possessed, and hand not possessing anything. 
    if shootingHand == leftHand or shootingHand == rightHand then
        shootingHand.state = 'open'
    end
    shootingHand.acquired.possessed = nil
    shootingHand.acquired.elevated = false
    shootingHand.acquired.state = 'shot'
    
    --Designate target
    if targetHole == 'left' then
        targetHole_x = FL_POCKET_IN_X
    elseif targetHole == 'right' then
        targetHole_x = FR_POCKET_IN_X
    end
    if shootingHand == leftAI or shootingHand == rightAI then
        targetHole_y = 631 * WINDOW_SCALE --WOULD be a NR_POCKET_IN_Y but variable not needed. Just hard-coding this.
    elseif shootingHand == leftHand or shootingHand == rightHand then
        targetHole_y = FR_POCKET_IN_Y
    end
    --Provide some element of luck, affecting precision as ball rolls to target. --The higher the velocity, the more imprecise the shot. 
    --Change setting depending on player/AI, and if AI, then based on selected difficulty. 
    local errorSetting = 10 * WINDOW_SCALE
    if shootingHand == leftAI or shootingHand == rightAI then
        errorSetting = AIerrorCoefficient
    end
    local error = (SHOT_VEL / 1300 * WINDOW_SCALE) * errorSetting
    --    http://lua-users.org/wiki/MathLibraryTutorial   
    math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) ) --THIS WAS BORROWED
    local randomError = math.random(-error ,error)                                                        
    local x_aim = targetHole_x + randomError
    --calculate line of travel, and magnitude/speed. 
    local shotDistance_x = shootingHand.acquired.center_x - x_aim
    local shotDistance_y = shootingHand.acquired.center_y - targetHole_y
    local hypotenuse = math.sqrt((shotDistance_x * shotDistance_x) + (shotDistance_y * shotDistance_y))
    shootingHand.acquired.dx = 0
    shootingHand.acquired.dy = 0
    shootingHand.acquired.dx = -(shotDistance_x / hypotenuse) * SHOT_VEL
    shootingHand.acquired.dy = -(shotDistance_y / hypotenuse) * SHOT_VEL
    shootingHand.acquired = nil
end


function Defend(hand, side)
    -- Velocity of ball moving to side is 
    --1300 * (distance between self and way-ward wall / half the width of playable field)
    --This will produce a useful and appropriate amount of force no matter where you're defending from.
    if hand == rightHand or hand == leftHand then
        hand.state = 'open' 
    end    
    hand.acquired.possessed = nil
    hand.acquired.elevated = false
    hand.acquired.state = 'shot'

        if side == 'left' then
            hand.acquired.dx = math.min((-1300 * WINDOW_SCALE * GetDifference(hand.center_x, hand.center_y, 34 * WINDOW_SCALE, hand.center_y) / (195 * WINDOW_SCALE)), -850 * WINDOW_SCALE)
            hand.acquired.dy = 0
        elseif side == 'right' then
            hand.acquired.dx = math.max((1300 * WINDOW_SCALE * GetDifference(hand.center_x, hand.center_y, 326 * WINDOW_SCALE, hand.center_y) / (195 * WINDOW_SCALE)), 850 * WINDOW_SCALE)
            hand.acquired.dy = 0
        end

    hand.acquired = nil
end


function CheckBallOnBall()
    --Check for collisions with other balls.
    --Get distance between ball and other balls. 
    for i = 1, 4, 1 do
        for j = 1, 4, 1 do
            if ballObjects[i] ~= ballObjects[j] and ballObjects[i] ~= 'scored' and 
                ballObjects[j] ~= 'scored' and ballObjects[i].elevated == false 
                and ballObjects[j].elevated == false then
                -- get difference/distance between ball centers
                local distance = GetDifference(ballObjects[i].center_x, ballObjects[i].center_y, 
                    ballObjects[j].center_x, ballObjects[j].center_y)
                -- if 
                if distance <= 17 * WINDOW_SCALE then
                    BallCollision(i, j)
                    return
                end
            end
        end
    end

    return 
end

function BallCollision(object1, object2)
    collisionBall1 = ballObjects[object1]
    collisionBall2 = ballObjects[object2]
    --prevent re-processing of the same collission for x component
    if collisionBall1.x > collisionBall2.x then
        collisionBall1.x = collisionBall1.x + 1 * WINDOW_SCALE
        collisionBall2.x = collisionBall2.x - 1 * WINDOW_SCALE
    elseif collisionBall1.x < collisionBall2.x then
        collisionBall1.x = collisionBall1.x - 1 * WINDOW_SCALE
        collisionBall2.x = collisionBall2.x + 1 * WINDOW_SCALE
    end
    --prevent re-processing of the same collission for y component
    if collisionBall1.y > collisionBall2.y then
        collisionBall1.y = collisionBall1.y + 1 * WINDOW_SCALE
        collisionBall2.y = collisionBall2.y - 1 * WINDOW_SCALE
    elseif collisionBall1.y < collisionBall2.y then
        collisionBall1.y = collisionBall1.y - 1 * WINDOW_SCALE
        collisionBall2.y = collisionBall2.y + 1 * WINDOW_SCALE
    end
    --initialize variables representing x, y, and combined velocities for each ball. 
    dx1 = collisionBall1.dx
    dy1 = collisionBall1.dy
    hyp1 = math.sqrt(dx1^2 + dy1^2)
    dx2 = collisionBall2.dx
    dy2 = collisionBall2.dy
    hyp2 = math.sqrt(dx2^2 + dy2^2)
    net_hyp = hyp1 + hyp2
    --establish angle of initial velocity vector of first ball
    if dx1 < 0 then 
        theta1 = math.rad(180) + math.atan(dy1/dx1)
    elseif dx1 > 0 and dy1 >= 0 then
        theta1 = math.atan(dy1/dx1) 
    elseif dx1 > 0 and dy1 < 0 then
        theta1 = math.rad(360) + math.atan(dy1/dx1)
    elseif dx1 == 0 and dy1 == 0 then
        theta1 = 0
    elseif dx1 == 0 and dy1 > 0 then 
        theta1 = math.rad(90)
    else
        theta1 = math.rad(270)
    end
    --establish angle of initial velocity vector of second ball
    if dx2 < 0 then 
        theta2 = math.rad(180) + math.atan(dy2/dx2)
    elseif dx2 > 0 and dy2 >= 0 then
        theta2 = math.atan(dy2/dx2) 
    elseif dx2 > 0 and dy2 < 0 then
        theta2 = math.rad(360) + math.atan(dy2/dx2)
    elseif dx2 == 0 and dy2 == 0 then
        theta2 = 0
    elseif dx2 == 0 and dy2 > 0 then 
        theta2 = math.rad(90)
    else
        theta2 = math.rad(270)
    end
    --distance between center of balls in x and y directions
    x_component = collisionBall2.x - collisionBall1.x
    y_component = collisionBall2.y - collisionBall1.y
    --determines angle of contact between two balls based on the triangle they form.
    if x_component == 0 then
        phi = math.rad(180)
    else
        phi = math.atan(y_component / x_component)
    end
    --determines x and y componenet velocities with grid reoriented with x along the line of contact of balls.
    dx1r = hyp1 * math.cos(theta1 - phi)
    dy1r = hyp1 * math.sin(theta1 - phi)
    dx2r = hyp2 * math.cos(theta2 - phi)
    dy2r = hyp2 * math.sin(theta2 - phi) 
    --x components are swapped. Y remain same.  
    dx1fr = dx2r
    dx2fr = dx1r
    dy1fr = dy1r
    dy2fr = dy2r
    --Reconvert back to original grid
    collisionBall1.dx = math.cos(phi) * dx1fr + math.cos(phi + 3.14159265 / 2) * dy1fr
    collisionBall1.dy = math.sin(phi) * dx1fr + math.sin(phi + 3.14159265 / 2) * dy1fr
    collisionBall2.dx = math.cos(phi) * dx2fr + math.cos(phi + 3.14159265 / 2) * dy2fr
    collisionBall2.dy = math.sin(phi) * dx2fr + math.sin(phi + 3.14159265 / 2) * dy2fr
    --play ball collision sound
    if net_hyp < 800 * WINDOW_SCALE then
        Balls_Soft.play(Balls_Soft)
    else 
        Balls_Hard.play(Balls_Hard)
    end
    --Balls are officially rebounds and can be picked up.
    collisionBall1.state = 'rebound'
    collisionBall2.state = 'rebound'

end