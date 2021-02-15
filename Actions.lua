function Movement()
    --MOVEMENT CONTROLS
    local RLarrowCounter_Lt = 0
    local UDarrowCounter_Lt = 0
    local coefficient = math.sqrt(2) --used to calc speed during diagonal movement
    local RLarrowCounter_Rt = 0
    local UDarrowCounter_Rt = 0
    --Left Hand Directionals
    if love.keyboard.isDown("w") and leftHand.y > REBOUND_LINE and leftHand.state ~= 'shooting' then
        UDarrowCounter_Lt = -1
        if RLarrowCounter_Lt == 0 then
            leftHand.dy = -HAND_MOVEMENT
        else
            leftHand.dy = -HAND_MOVEMENT / coefficient
            if RLarrowCounter_Lt == 1 then
                leftHand.dx = HAND_MOVEMENT / coefficient
            else
                leftHand.dx = -HAND_MOVEMENT / coefficient
            end
        end
    end
    if love.keyboard.isDown("s") and leftHand.y < BOTTOM_WALL_HAND and leftHand.state ~= 'shooting' then
        UDarrowCounter_Lt = 1
        if RLarrowCounter_Lt == 0 then
            leftHand.dy = HAND_MOVEMENT
        else
            leftHand.dy = HAND_MOVEMENT / coefficient
            if RLarrowCounter_Lt == 1 then
                leftHand.dx = HAND_MOVEMENT / coefficient
            else
                leftHand.dx = -HAND_MOVEMENT / coefficient
            end
        end
    end
    if love.keyboard.isDown("d") and leftHand.x < RIGHT_WALL_HAND and leftHand.state ~= 'shooting' then
        RLarrowCounter = 1
        if UDarrowCounter_Lt == 0 then
            leftHand.dx = HAND_MOVEMENT
        else
            leftHand.dx = HAND_MOVEMENT / coefficient
            if UDarrowCounter_Lt == 1 then
                leftHand.dy = HAND_MOVEMENT / coefficient
            else
                leftHand.dy = -HAND_MOVEMENT / coefficient
            end
        end
    end
    if love.keyboard.isDown("a") and leftHand.x > LEFT_WALL_HAND and leftHand.state ~= 'shooting' then
        RLarrowCounter = -1
        if UDarrowCounter_Lt == 0 then
            leftHand.dx = -HAND_MOVEMENT
        else
            leftHand.dx = -HAND_MOVEMENT / coefficient
            if UDarrowCounter_Lt == 1 then
                leftHand.dy = HAND_MOVEMENT / coefficient
            else
                leftHand.dy = -HAND_MOVEMENT / coefficient
            end
        end
    end
    if love.keyboard.isDown("i") and rightHand.y > REBOUND_LINE and rightHand.state ~= 'shooting' then
        UDarrowCounter_Rt = -1
        if RLarrowCounter_Rt == 0 then
            rightHand.dy = -HAND_MOVEMENT
        else
            rightHand.dy = -HAND_MOVEMENT / coefficient
            if RLarrowCounter_Rt == 1 then
                rightHand.dx = HAND_MOVEMENT / coefficient
            else
                rightHand.dx = -HAND_MOVEMENT / coefficient
            end
        end
    end
    if love.keyboard.isDown("k") and rightHand.y < BOTTOM_WALL_HAND and rightHand.state ~= 'shooting' then
        UDarrowCounter_Rt = 1
        if RLarrowCounter_Rt == 0 then
            rightHand.dy = HAND_MOVEMENT
        else
            rightHand.dy = HAND_MOVEMENT / coefficient
            if RLarrowCounter_Rt == 1 then
                rightHand.dx = HAND_MOVEMENT / coefficient
            else
                rightHand.dx = -HAND_MOVEMENT / coefficient
            end
        end
    end
    if love.keyboard.isDown("l") and rightHand.x < RIGHT_WALL_HAND + 40 * WINDOW_SCALE and rightHand.state ~= 'shooting' then
        RLarrowCounter_Rt = 1
        if UDarrowCounter_Rt == 0 then
            rightHand.dx = HAND_MOVEMENT
        else
            rightHand.dx = HAND_MOVEMENT / coefficient
            if UDarrowCounter_Rt == 1 then
                rightHand.dy = HAND_MOVEMENT / coefficient
            else
                rightHand.dy = -HAND_MOVEMENT / coefficient
            end
        end
    end
    if love.keyboard.isDown("j") and rightHand.x > LEFT_WALL_HAND + 40 * WINDOW_SCALE and rightHand.state ~= 'shooting' then
        RLarrowCounter_Rt = -1
        if UDarrowCounter_Rt == 0 then
            rightHand.dx = -HAND_MOVEMENT
        else
            rightHand.dx = -HAND_MOVEMENT / coefficient
            if UDarrowCounter_Rt == 1 then
                rightHand.dy = HAND_MOVEMENT / coefficient
            else
                rightHand.dy = -HAND_MOVEMENT / coefficient
            end
        end
    end
    return
end


--Grabbing/Dropping controls
--Left hand grabbing
function GrabDropDraw()
    function love.keyreleased(key)
        local hand = nil
        if key == 'c' then
            hand = leftHand
        elseif key == 'n' then
            hand = rightHand
        else
            return
        end

        if hand.state == 'open' then
            local target = Grab(hand.grab_x, hand.grab_y)
            if target ~= nil then 
                if hand == leftHand then
                    target.possessed = leftHand
                elseif hand == rightHand then
                    target.possessed = rightHand
                end
                target.elevated = true
                target.dx = 0
                target.dy = 0
                hand.state = 'closed'
                hand.acquired = target
                target = nil 
            else
                Draw(hand)
            end
        elseif hand.state == 'closed' then
            local dropee = hand.acquired  
            local ballsInVicinity = Drop(hand.grab_x, hand.grab_y)
            if ballsInVicinity < 2 then   
                dropee.elevated = false
                dropee.x = hand.grab_x - halfBallDiameter
                dropee.y = hand.grab_y - halfBallDiameter
                dropee.possessed = nil
                hand.state = 'open'
                hand.acquired = nil  
                dropee = nil
            end 
        end
    end
end

--triggered by n bar and 'empty' state. Returns true if no other balls are too close,
--and will allow ball to be set down. If other balls are directly underneath it, will
--return false.
function Drop(pos_x, pos_y) --these are the "center_x and y" values. 
    tooCloseCount = 0 --the count of how many balls are too close. If value climbs higher
    --return number of balls it's too close to, including itself.
    diff_1 = GetDifference(pos_x, pos_y, ball1.center_x, ball1.center_y)
    diff_2 = GetDifference(pos_x, pos_y, ball2.center_x, ball2.center_y)
    diff_3 = GetDifference(pos_x, pos_y, ball3.center_x, ball3.center_y)
    diff_4 = GetDifference(pos_x, pos_y, ball4.center_x, ball4.center_y)
    diffs = {diff_1, diff_2, diff_3, diff_4}
    
    for k = 1, 4, 1 do
        if diffs[k] <= 17 * WINDOW_SCALE then
            tooCloseCount = tooCloseCount + 1
        end
    end

    return tooCloseCount

end

--triggered by n bar and 'empty' state. Returns closest ball object if ball is in range.
function Grab(hand_x, hand_y)
    --get spacial difference of hand to each ball
    difference_1 = GetDifference(hand_x, hand_y, ball1.center_x, ball1.center_y)
    difference_2 = GetDifference(hand_x, hand_y, ball2.center_x, ball2.center_y)
    difference_3 = GetDifference(hand_x, hand_y, ball3.center_x, ball3.center_y)
    difference_4 = GetDifference(hand_x, hand_y, ball4.center_x, ball4.center_y)
    --determine the shortest distance, construct table to store distances, 
    --table to store those closest or tied for closest, a count of the candidates,
    --and a variable to represent the random ball to be returned if there are ties.
    closest = math.min(difference_1, difference_2, difference_3, difference_4)
    differences = {difference_1, difference_2, difference_3, difference_4}
    candidates = {}
    trueCount = 0
    returnBall = 0
    --Determine which ball(s) are candidates to be grabbed.
    for i = 1, 4, 1 do
        if differences[i] == closest and differences[i] < 32 * WINDOW_SCALE and ballObjects[i].state == 'rebound' 
            and ballObjects[i].possessed == nil then
            candidates[i] = true
            trueCount = trueCount + 1
        else 
            candidates[i] = false
        end
    end
    --If no candidates, return nil. If 1, return that ball.
    --If multiple candidates, return random candidate.
    if trueCount < 1 then
        return nil
    elseif trueCount == 1 then
        if candidates[1] == true then
            return ball1
        elseif candidates[2] == true then
            return ball2
        elseif candidates[3] == true then
            return ball3
        elseif candidates[4] == true then
            return ball4
        end
    else --Match random number to candidate
        randomNum = math.random(trueCount)
        temp = 1
        for j = 1, 4, 1 do
            if candidates[j] == true then
                if temp == randomNum then
                    returnBall = j
                else
                    temp = temp + 1
                end
            end
        end

        --return that candidate's ball
        if returnBall == 1 then
            return ball1
        elseif returnBall == 2 then
            return ball2
        elseif returnBall == 3 then
            return ball3
        elseif returnBall == 4 then
            return ball4
        end
    end
end

function Draw(hand)

    local location = false
    --If hand is at bottom edge of the table
    if hand.attachmentPoint_y > 612 * WINDOW_SCALE then
        --if hand is at left edge of table/ at bottomLeft pocket
        if hand.attachmentPoint_x < 37 * WINDOW_SCALE then
            if NL_COUNT > 0 and PLAYER1_CAN_DRAW > 0 then
                location = true
            end
        --if hand is at right edge of table/ at bottomRight pocket
        elseif hand.attachmentPoint_x > 307 * WINDOW_SCALE then
            if NR_COUNT > 0 and PLAYER1_CAN_DRAW > 0 then
                location = true
            end
        end
    end

    --Location near pocket confirmed. 
    --Proceed to pick up ball if ball is available at respective pocket.
    --If ball is available, update count of balls at that pocket
    if location == true then
        for i = 1, 4, 1 do
            if ballObjects[i].state == 'hidden' then
                ballObjects[i].state = 'rebound'
                ballObjects[i].elevated = true
                ballObjects[i].x = hand.attachmentPoint_x
                ballObjects[i].y = hand.attachmentPoint_y
                ballObjects[i].dx = 0
                ballObjects[i].dy = 0
                hand.state = 'closed'
                hand.acquired = ballObjects[i]
                PLAYER1_CAN_DRAW = PLAYER1_CAN_DRAW - 1
                TABLE_COUNT = TABLE_COUNT + 1
                if hand == leftHand then
                    ballObjects[i].possessed = leftHand
                else
                    ballObjects[i].possessed = rightHand
                end
                if hand.attachmentPoint_x < 37 * WINDOW_SCALE then
                    NL_COUNT = NL_COUNT - 1
                elseif hand.attachmentPoint_x > 307 * WINDOW_SCALE then
                    NR_COUNT = NR_COUNT - 1
                else
                    return
                end
                return
            end
        end
    else
        return 
    end

end