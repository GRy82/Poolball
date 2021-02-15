Class = require 'class'

AI = Class{}

--attachment corrections are where ball origins attach.
--attachment centers are where the center of the balls will be located when picked up.
function AI:init(x, y, scale)
    attachmentCorrection = 8 * WINDOW_SCALE
    grabCorrection_x = 5 * WINDOW_SCALE
    grabCorrection_y = 24 * WINDOW_SCALE
    correctionY = 47 * WINDOW_SCALE
    self.correctionX = 0
    self.originChange = 0


    if scale == 1 then
        self.correctionX = 52 * WINDOW_SCALE
        self.originChange = 0
        self.animationCorrectionX = grabCorrection_x
    elseif scale == -1 then
        self.correctionX = 12 * WINDOW_SCALE
        self.originChange = 80 
        self.animationCorrectionX = -grabCorrection_x
    end

    self.x = x
    self.y = y
    self.attachmentPoint_x = self.x + self.correctionX
    self.attachmentPoint_y = self.y + correctionY
    self.center_x = self.attachmentPoint_x + attachmentCorrection
    self.center_y = self.attachmentPoint_y + attachmentCorrection
    self.grab_x = self.center_x - grabCorrection_x
    self.grab_y = self.center_y - grabCorrection_y
    self.dx = 0
    self.dy = 0
    self.flip = scale
    self.texture = love.graphics.newImage('graphics/CompHand.png')

    CompQuads = {}
    CompQuads[1] = love.graphics.newQuad(0, 0, 80, 80, self.texture:getDimensions())
    CompQuads[2] = love.graphics.newQuad(80, 0, 80, 80, self.texture:getDimensions())
    CompQuads[3] = love.graphics.newQuad(160, 0, 80, 80, self.texture:getDimensions())
    CompQuads[4] = love.graphics.newQuad(240, 0, 80, 80, self.texture:getDimensions())
    CompQuads[5] = love.graphics.newQuad(320, 0, 80, 80, self.texture:getDimensions())


    self.currentFrame = CompQuads[1]
    self.animationAttachmentX = self.attachmentPoint_x 
    self.animationAttachmentY = self.attachmentPoint_y
    self.acquired = nil
    self.intention = {} --index of 1 contains intended action. index of 2 contains object of the action.
    self.intention[1] = nil
    self.intention[2] = nil 
    self.mode = 'normal'
    self.priority = 'none'
    self.delayUtility = 0 -- Help make computer appear to have more human reaction times
    self.frameChangeCD = 0 -- Used to time the changes of animation/frames


end

function AI:update(dt)

    --Prevent movement outside the bounds of what's legal in the game.
    if self.y >= SHOT_LINE_COMP + 17 * WINDOW_SCALE then 
        self.y = self.y - 2  * WINDOW_SCALE
        self.dy = 0
    elseif self.y <= TOP_WALL_COMP - 17 * WINDOW_SCALE then
        self.y = self.y + 2  * WINDOW_SCALE
        self.dy = 0
    end
    local wallCorrect_x = 0 
    if self == rightAI then
        wallCorrect_x = 40 * WINDOW_SCALE
    end
    if self.x <= LEFT_WALL_HAND + wallCorrect_x then
        self.x = self.x + 2 * WINDOW_SCALE
        self.dx = 0
    elseif self.x >= RIGHT_WALL_HAND + wallCorrect_x then
        self.x = self.x -2 * WINDOW_SCALE
        self.dx = 0
    end
    
    --Update the number of balls the computer has, 0-2.
    if self == leftAI then 
        if self.acquired ~= nil then
            COMP_POSSESSION_COUNT = 1
            if rightAI.acquired ~= nil then
                COMP_POSSESSION_COUNT = 2
            end
        end
    elseif self == rightAI then
        if self.acquired ~= nil then
            COMP_POSSESSION_COUNT = 1
            if leftAI.acquired ~= nil then
                COMP_POSSESSION_COUNT = 2
            end
        end     
    end

    self:MakeDecision()
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
    self.attachmentPoint_x = self.x + self.correctionX
    self.attachmentPoint_y = self.y + correctionY
    self.center_x = self.attachmentPoint_x + attachmentCorrection
    self.center_y = self.attachmentPoint_y + attachmentCorrection
    self.grab_x = self.center_x - grabCorrection_x
    self.grab_y = self.center_y - grabCorrection_y


    --ANIMATION BITS-----
    --Once the frame counter/dount down gets down to 10, it cues the middle frame to be active.
    if self.frameChangeCD == 10 and self.currentFrame == CompQuads[3] then
        self.currentFrame = CompQuads[4]
    elseif self.frameChangeCD == 10 and self.currentFrame == CompQuads[5] then
        self.currentFrame = CompQuads[2]
    end   
    
    --if hand is not in its neutral animation frame, then decrement the counter, progressing it towards that
    if self.frameChangeCD <= 0 then
        self.currentFrame = CompQuads[1]
    else 
        self.frameChangeCD = self.frameChangeCD - 1
    end

    --Depending on current animation frame, the ball may be rendered in a slightly different place
    --in order to align with the grasp of the hand.  
    if self.currentFrame == CompQuads[1] then
        self.animationAttachmentX = self.attachmentPoint_x
        self.animationAttachmentY = self.attachmentPoint_y
    elseif self.currentFrame == CompQuads[2] then
        self.animationAttachmentX = self.attachmentPoint_x + self.animationCorrectionX
        self.animationAttachmentY = self.attachmentPoint_y - grabCorrection_y
    end

    --    http://lua-users.org/wiki/MathLibraryTutorial   
    math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) ) --THIS WAS BORROWED
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------

--MakeDecision function gathers relevant information and determines best course of action: 
--AcquireBall, play defense, play offense, reposition?
function AI:MakeDecision()
    --Does computer player have a ball to use?
    self:RePosition()
    if self.acquired == nil then  --If hand possesses no balls
        self.mode = 'normal'
        if COMP_CAN_DRAW > 0 and (FR_COUNT + FL_COUNT) > 0 then
            self:AIDraw()
            return
        else
            if self:AcquireTarget() then
                self:AcquireBall()
                return
            else
                self:RePosition()    
                return
            end
        end
    else            -- Hand possesses a ball
        if self:ThreatAssessment() then   --There is a threat
            if self.center_y >=  SHOT_LINE_COMP * WINDOW_SCALE then
                self:MoveTo(self.x, (SHOT_LINE_COMP - correctionY), self.x, self.y)
                return
            else
                self:Defense()
                return
            end
        else  -- No immediate threat. Consider offense!
             --consider balls possessed by player
            local playerPossessionCount = 0
            for j = 1, 4, 1 do
                if ballObjects[j].possessed == leftHand or ballObjects[j].possessed == rightHand then
                    playerPossessionCount = playerPossessionCount + 1
                end
            end
            --consider position of unheld balls... are they accessible to computer or player?
            local unheldSameSide = 0
            local unheldOtherSide = 0
            for i = 1, 4, 1 do
                if ballObjects[i].state ~= 'scored' and ballObjects.state ~= 'hidden' and
                  ballObjects.elevated == false then
                    if ballObjects[i].center_y >= 360 then
                        unheldOtherSide = unheldOtherSide + 1
                    else 
                        unheldSameSide = unheldSameSide + 1
                    end
                end
            end
            --calculate chance to shoot based on preceding determinations
            -- With 2 possessed and 2 unheld on same side, chance will be 100% to shoot.
            --With 2 possessed and 2 unheld opposite side, chance will be 100% not to shoot.
            --highest possible score is 8, lowest while being able to shoot something is -4.
            local possessionBalance = -1 * unheldOtherSide + 1 * unheldSameSide + 3 * COMP_POSSESSION_COUNT - 3 * playerPossessionCount
            local shotChances = 40 + possessionBalance * 8.33
            --    http://lua-users.org/wiki/MathLibraryTutorial   
            math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) ) --THIS WAS BORROWED
            local randomChance = math.random(100)

            if randomChance <= shotChances then --Proceed to calculate a target and shoot.

                --assess for special cases that occur if in difficult mode
                --Both hands go hyper offensive if player has no balls in hand
                if difficultyButtons[#difficultyButtons] == difficultButton then
                    if playerPossessionCount == 0 and unheldOtherSide <= 1 and COMP_POSSESSION_COUNT == 2 then
                        self.mode = 'hyper'
                        self:RePosition()
                    else 
                        self.mode = 'normal'
                    end
                    --if player has one ball in hand, one comp hand will go hyper offensive, other sits back. 
                    if playerPossessionCount == 1 and unheldOtherSide <= 1 and COMP_POSSESSION_COUNT == 2 
                      and self:MatchIntention(self, 'offense-posture', 'place-holder') == false then
                        self.mode = 'hyper'
                        self.intention[1] = 'offense-posture'
                        self.intention[2] = 'place-holder'
                        self:RePosition()
                    else
                        self.mode = 'normal'
                        self.intention[1] = nil
                        self.intention[2] = nil
                    end
                end
                -----------------------
                if self.center_y < SHOT_LINE_COMP then
                    self:Offense()
                else
                    self:RePosition()
                end 
            end 
        end
    end
end

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

function AI:RePosition()
    --Argument will be 1 or 2, that number representing how many balls are possessed by computer.
    --If just one, hand with ball takes a stance in the middle. If two, take stance evenly.
    --Return to neutral position if ball is possessed, and no urgent threats present.
    
    local destinationY = 0
    local destinationX = 0 

    if self.mode == 'hyper' then
        destinationY = SHOT_LINE_COMP - 70 * WINDOW_SCALE
    elseif self.mode == 'normal' then
        destinationY = 90 * WINDOW_SCALE
    end

    if COMP_POSSESSION_COUNT == 1 and self.acquired ~= nil then
        if self == leftAI then
            destinationX = 110 * WINDOW_SCALE
        elseif self == rightAI then
            destinationX = 170 * WINDOW_SCALE
        end
    else 
        if self == leftAI then
            destinationX = 50 * WINDOW_SCALE
        elseif self == rightAI then
            destinationX = 230 * WINDOW_SCALE
        end
    end

    if GetDifference(destinationX, destinationY, self.x, self.y) <= 5 * WINDOW_SCALE then 
        self.dx = 0
        self.dy = 0
    else
        self:MoveTo(destinationX, destinationY, self.x, self.y)
    end   
end

----------------------------------------------------------------------
----------------------------------------------------------------------

function AI:ThreatAssessment()
    --Check for incoming threats, and determine whether to play offense or defense.
     
    threats = {}
    local threatCount = 0
    if self == leftAI then
        otherHand = rightAI
    else
        otherHand = leftAI
    end

    for i = 1, 4, 1 do
        if self.acquired ~= ballObjects[i] and otherHand.acquired ~= ballObjects[i] 
            and ballObjects[i].dy < -200 * WINDOW_SCALE  and ballObjects[i].y < (SHOT_LINE - 16 * WINDOW_SCALE) then
                
            threats[i] = true 
            threatCount = threatCount + 1 
        else
            threats[i] = false
        end  
    end

    if threatCount > 0 then
        return true
    else 
        return false
    end
end

---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

--Threats were already established. Check that other hand isn't already performing the same task, then...
--Executes defensive move. 
function AI:Defense()

    local threatDistance = nil
    local shortestDistance = 5000
    local closestThreat = nil
    for i = 1, 4, 1 do
        if threats[i] == true then
            if COMP_POSSESSION_COUNT == 2 then
                if self.center_x < 180 * WINDOW_SCALE then
                    threatDistance = GetDifference(ballObjects[i].center_x, ballObjects[i].center_y, FL_POCKET_IN_X, FL_POCKET_IN_Y) 
                elseif self.center_x >= 180 * WINDOW_SCALE then
                    threatDistance = GetDifference(ballObjects[i].center_x, ballObjects[i].center_y, FR_POCKET_IN_X, FR_POCKET_IN_Y) 
                end
            elseif COMP_POSSESSION_COUNT == 1 then
                threatDistance = GetDifference(ballObjects[i].center_x, ballObjects[i].center_y, self.center_x, self.center_y) 
            end
            if threatDistance < shortestDistance then
                shortestDistance = threatDistance
                closestThreat = ballObjects[i]
            end
        end
    end

    local threatened_x = nil
    local threatened_y = nil
    local threatDirection = 0
    local x_edge = nil

    if closestThreat == nil then
        return
    end
    
    if closestThreat.x > 180 * WINDOW_SCALE then
        threatened_x = FR_POCKET_IN_X
        threatened_y = FR_POCKET_IN_Y
        threatDirection = 'right'
    elseif closestThreat.x <= 180 * WINDOW_SCALE then
        threatened_x = FL_POCKET_IN_X
        threatened_y = FL_POCKET_IN_Y
        threatDirection = 'left'
    end
    
    if GetDifference(closestThreat.x, closestThreat.y, threatened_x, threatened_y) <= 215 * WINDOW_SCALE then
        if self:MatchIntention(self, 'defense', closestThreat) == false then
            self.intention[1] = 'defense'
            self.intention[2] = closestThreat
        end
    end

    if GetDifference(closestThreat.x, closestThreat.y, self.center_x, self.center_y) <= 150 * WINDOW_SCALE then
            --animation bit----
            if (threatDirection == 'right' and self == leftAI) or (threatDirection == 'left' and self == rightAI) then
                self.currentFrame = CompQuads[5]
            elseif (threatDirection == 'right' and self == rightAI) or (threatDirection == 'left' and self == leftAI) then
                self.currentFrame = CompQuads[3]
            end
            self.frameChangeCD = 20 
            -------------------
            
            --Set course of defensive ball. Reset intention value.
            Defend(self, threatDirection)
            self.intention[1] = nil
            self.intention[2] = nil
    end

    self:OffensiveReset()

end

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function AI:SelectTarget()
--Choose which pocket to shoot at based on multifactoral point system.
    leftScore = 0
    rightScore = 0
    for k = 1, 4, 1 do
        if ballObjects[k].possessed == leftHand or ballObjects[k].possessed == rightHand then -- detect held balls of player.
            if ballObjects[k].center_x >= 180 then 
                rightScore = rightScore - 3
                leftScore = leftScore - 2
            else
                rightScore = rightScore - 2
                leftScore = leftScore - 3
            end
        elseif ballObjects[k].possessed == nil and ballObjects[k].y > self.acquired.y then -- check for unheld balls just beside a pocket, and balls obstructing line of fire.
            -- Check for ball precariously close to opponent's pocket.
            if ballObjects[k].center_y >= bottomRight.in_y - 16 * WINDOW_SCALE then
                if ballObjects[k].center_x <= bottomLeft.in_x + 16 * WINDOW_SCALE then
                    leftScore = leftScore + 2                
                elseif ballObjects[k].center_x >= bottomRight.in_x - 16 * WINDOW_SCALE then
                    rightScore = rightScore + 2            
                end
             --Check for ball in line of fire. 
            else
                --prevent 0's in denominator
                local x_diff = bottomRight.in_x - self.acquired.center_x
                if x_diff == 0 then
                  x_diff = .00001  
                end
                local shotAngleRight = math.atan(x_diff / (bottomRight.in_y - self.acquired.center_y)) --should be pos
                local shotAngleLeft = math.atan(x_diff / (bottomLeft.in_y - self.acquired.center_y)) -- should be neg
                --Come down to the y of the ball. Determine the x along the shot line at that 'y'
                local shotLineRight_x = self.acquired.center_x + math.abs(math.tan(shotAngleRight) * (ballObjects[k].center_y - self.acquired.center_y))
                local shotLineLeft_x = self.acquired.center_x - math.abs(math.tan(shotAngleLeft) * (ballObjects[k].center_y - self.acquired.center_y))
                --perpendicular distance between ball center and the shot line
                perpendicularRight = math.abs(math.cos(shotAngleRight) * math.abs(shotLineRight_x - ballObjects[k].center_x))
                perpendicularLeft = math.abs(math.cos(shotAngleLeft) * math.abs(shotLineLeft_x - ballObjects[k].center_x))
    
                if perpendicularRight <= 16 * WINDOW_SCALE and perpendicularRight > 4 * WINDOW_SCALE then
                    rightScore = rightScore - 2
                elseif perpendicularRight <= 4 * WINDOW_SCALE then
                    rightScore = rightScore + 1
                end
                if perpendicularLeft <= 16 * WINDOW_SCALE and perpendicularLeft > 4 * WINDOW_SCALE then
                    leftScore = leftScore - 2
                elseif perpendicularLeft <= 4 * WINDOW_SCALE then
                    leftScore = leftScore + 1
                end
            end
        end
    end

    local targetSelected = nil
    local highestScore = 0
    local scoreDifference = 0 -- To convey the magnitude, or the difference in advantage, of targeting one pocket over the other. 
    if leftScore > rightScore then
        targetSelected = 'left'
        highestScore = leftScore
        lowerScore = rightScore
    elseif rightScore > leftScore then
        targetSelected = 'right'
        highestScore = rightScore
        lowerScore = leftScore
    else
         --    http://lua-users.org/wiki/MathLibraryTutorial   
        math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) ) --THIS WAS BORROWED
        local randomSide = math.random(2)
        if randomSide == 1 then
            targetSelected = 'right'
        else
            targetSelected = 'left'
        end
    end

    if leftScore ~= rightScore then
        scoreDifference = highestScore - lowerScore
    end
    
    --Commit to decision based on difficulty level. Higher difficulty means more commitment. 
     --    http://lua-users.org/wiki/MathLibraryTutorial   
     math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) ) --THIS WAS BORROWED
    local commitmentProbability = math.random(100)
    local threshold = 0
    for l = 1, 3, 1 do
        --easy, mod, diff: 70%, 80%, 90%, respectively
        if difficultyButtons[#difficultyButtons] == difficultyButtons[l] then
            threshold = 60 + 10 * l
        end
    end
    --here is where the pockets get switched if they're not committed to the 'correct' decision.
    if commitmentProbability > threshold then
        if targetSelected == 'right' then
            targetSelected = 'left'
        else
            targetSelected = 'right'
        end
    end

    return targetSelected, scoreDifference
end

 --Randomize force being used, and create delay that corresponds to hypothetical button being held.
function AI:Offense()
    targetString, preferenceDifferenceMagnitude = self:SelectTarget()

    --    http://lua-users.org/wiki/MathLibraryTutorial   
    math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) ) --THIS WAS BORROWED
    local randomForce = math.random(900, 1300) * WINDOW_SCALE
    local correspondingTime = 30 + ((randomForce / 1300 * WINDOW_SCALE) * 90)
    --when wait time is initialized, then toggle to the "pre-shot" frame 
    self.currentFrame = CompQuads[2]
    self.frameChangeCD = correspondingTime
    
    --Because if difficult mode, the two shots collide too easily, have the other shot go the other way. 
    if self:MatchIntention(self, 'shooting', 'targetString') and self.mode == 'hyper' --If other hadn already has intention of shooting at 
      and preferenceDifferenceMagnitude < 3 then--desired pocket, and we're in difficult mode, and the difference in pocket vulnerability is negligible,
        if targetString == 'right' then         -- then shoot at the other pocket instead
            targetString = 'left'
        else
            targetString = 'right'
        end
    end

    --When wait time is exceeded. (Animation bit)
    if self.delayUtility > correspondingTime then
        CalculateShot(randomForce, self, targetString)
        self.currentFrame = CompQuads[4]
        self.frameChangeCD = 10 
        --reset delay because shot is fired. 
        self.delayUtility = 0
        --reset hyper mode if in difficult mode
        if self.mode == 'hyper' then
            self.intention[1] = nil
            self.intention[2] = nil
        end
    else
        self.delayUtility = self.delayUtility + 1
    end

end

--if an offensive shot was building up to be fired, but then another task was prioritized, reset the 
--delayUtility to 0 and animation frame to [1].
function AI:OffensiveReset()
    self.currentFrame = CompQuads[1]
    self.delayUtility = 0
    self.frameChangeCD = 0
end

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

--(1.) Check for unpossessed/eligible balls to grab.
--(2.) Of those eligible, which is the closest?
--(3.) Is this ball already the AcquiredTarget of other hand?
function AI:AcquireTarget()
    local candidates = {}
    local shortestMeasure = 10000
    local closestBall = nil
    local candidatesNumber = 0
    local lastCandidate = nil
    --Which balls are grabbable?
    for i = 1, 4, 1 do
        if ballObjects[i].center_y <= (REBOUND_LINE + 30 * WINDOW_SCALE) and ballObjects[i].state == 'rebound' 
            and ballObjects[i].elevated == false and ballObjects[i].possessed == nil then
            
            candidates[i] = true 
            candidatesNumber = candidatesNumber + 1
            lastCandidate = ballObjects[i]
        else
            candidates[i] = false
        end  
    end

    --Which grabbable ball is closest?
    for j = 1, 4, 1 do
        if candidates[j] == true then
            local tempMeasure = GetDifference(self.grab_x, self.grab_y, ballObjects[j].center_x, ballObjects[j].center_y)
            if tempMeasure < shortestMeasure then
                shortestMeasure = tempMeasure
                closestBall = ballObjects[j]
                if candidatesNumber > 1 and lastCandidate ~= ballObjects[j] then
                    local secondClosestBall = ballObjects[j]
                end
            end
            
        end    
    end

    if closestBall == nil then
        self.intention[1] = nil
        return false
    end

    if self:MatchIntention(self, 'grabbing', closestBall) == false then
        self.intention[1] = 'grabbing'
        self.intention[2] = closestBall
        return true
    elseif candidatesNumber > 1 then
        self.intention[1] = 'grabbing'
        self.intention[2] = secondClosestBall
        return true
    else
        return false
    end
    --See if the proposed intention of this hand is already the intention of the other hand.
    --Return the closest ball and whether it's true/false that intentions are same when comparing hands.
end


--After a human-like delay in reaction time...
--Pursues ball and Picks it up.
function AI:AcquireBall()
    --As long as ball remains grabbable, and other AI hand didn't have the intention of grabbing this 
    --ball first, then this hand continues pursuit and pick-up of ball.
    local targetBall = self.intention[2]
    if targetBall ~= nil then
        --if ball is still grabbable and hand is in pursuit, but not there yet.
        if self.grab_x ~= targetBall.x and self.grab_y ~= targetBall.y
            and targetBall.possessed == nil and targetBall.state == 'rebound' and 
            targetBall.elevated == false and targetBall.center_y <= (REBOUND_LINE + 30 * WINDOW_SCALE) then

            self:MoveTo(targetBall.x, targetBall.y, self.grab_x, self.grab_y)

        --If ball is in range(20 pixels) and ready to grab
            if GetDifference(self.grab_x, self.grab_y, targetBall.x, targetBall.y) < 5 * WINDOW_SCALE then
                self.frameChangeCD = 8              --animation component
                self.currentFrame = CompQuads[2]    --animation component
                self.dx = 0
                self.dy = 0
                self.acquired = targetBall

                if self == leftAI then
                    targetBall.elevated = true
                    targetBall.possessed = leftAI
                else 
                    targetBall.elevated = true
                    targetBall.possessed = rightAI
                end
                self.intention[1] = nil
                self.intention[2] = nil
                return
                
            end
        else
            self.intention[1] = nil
            self.intention[2] = nil
            return
        end
    end
end

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

--Set dx and dy for the AI/hand object.
function AI:MoveTo(destination_x, destination_y, departure_x, departure_y)
    local diff_x = (destination_x - departure_x)
    local diff_y = (destination_y - departure_y)
    local theta = nil
    local x_direction = 0
    local y_direction = 0

    --reverse direction of travel if necessary
    if diff_x < 0 then
        x_direction = -1
    elseif diff_x > 0 then
        x_direction = 1
    elseif diff_x == 0 then
        x_direction = 0
    end

    if diff_y < 0 then
        y_direction = -1
    elseif diff_y > 0 then
        y_direction = 1
    elseif diff_y == 0 then
        y_direction = 0
    end
    --make positive for sake of trigonometry.
    diff_x = math.abs(diff_x)
    diff_y = math.abs(diff_y)

    theta = math.atan(diff_y / diff_x)

    self.dx = x_direction * HAND_MOVEMENT * math.cos(theta)
    self.dy = y_direction * HAND_MOVEMENT * math.sin(theta)

end
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

--Read the intention of the other AI hand object
function AI:MatchIntention(handObject, propInt, propObj)
    local otherCompHand
    if handObject == computerObjects[1] then
        otherCompHand = computerObjects[2]
    else
        otherCompHand = computerObjects[1]
    end

    if otherCompHand.intention ~= nil then
        if propInt == otherCompHand.intention[1] and propObj == otherCompHand.intention[2] then
            return true
        else 
            return false
        end
    else
        return false
    end
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------

function AI:AIDraw()
    self.intention[1] = 'grabbing'
    targetPocket = nil
    if FL_COUNT > 0 and FR_COUNT < 1 then
        targetPocket = topLeft
    elseif FL_COUNT < 1 and FR_COUNT > 0 then
        targetPocket = topRight
    else
        local LeftPockDistance = GetDifference(self.center_x, self.center_y, topLeft.in_x, topLeft.in_y)
        local RightPockDistance = GetDifference(self.center_x, self.center_y, topRight.in_x, topRight.in_y)
        if RightPockDistance < LeftPockDistance and self:MatchIntention(self, 'grabbing', topRight) == false then
            targetPocket = topRight
        elseif LeftPockDistance <= RightPockDistance and self:MatchIntention(self, 'grabbing', topLeft) == false then
            targetPocket = topLeft
        else 
            return
        end
    end    
    
    local xCorrect = nil
    if targetPocket == topLeft then
        if self == rightAI then
            xCorrect = 12
        else
            xCorrect = 52
        end
    elseif targetPocket == topRight then
        if self == leftAI then
            xCorrect = 66
        else
            xCorrect = 30
        end
    end
    xCorrect = xCorrect * WINDOW_SCALE

    self.intention[2] = targetPocket
    self:MoveTo(targetPocket.in_x - xCorrect, targetPocket.in_y - correctionY, self.x, self.y)

    if (self.x >= (topRight.in_x - xCorrect) or self.x <= (topLeft.in_x - xCorrect)) 
        and self.y <= (topLeft.in_y - correctionY) then

        self.currentFrame = CompQuads[2] --animation component
        self.frameChangeCD = 8           --animation component

        for i = 1, 4, 1 do
            if ballObjects[i].state == 'hidden' then
                ballObjects[i].state = 'rebound'
                ballObjects[i].elevated = true
                ballObjects[i].x = self.attachmentPoint_x
                ballObjects[i].y = self.attachmentPoint_y
                ballObjects[i].dx = 0
                ballObjects[i].dy = 0
                COMP_CAN_DRAW = COMP_CAN_DRAW - 1
                TABLE_COUNT = TABLE_COUNT + 1
                self.acquired = ballObjects[i]
                self.intention[1] = nil
                self.intention[2] = nil
                if self == rightAI then
                    ballObjects[i].possessed = rightAI
                else
                    ballObjects[i].possessed = leftAI
                end 
                if self.attachmentPoint_x < 100 * WINDOW_SCALE then
                    FL_COUNT = FL_COUNT - 1
                elseif self.attachmentPoint_x > 250 * WINDOW_SCALE then
                    FR_COUNT = FR_COUNT - 1
                else
                    return
                end
                return
            end
        end
        self.intention[1] = nil
        self.intention[2] = nil
    end
end
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

function AI:render()
    love.graphics.draw(self.texture, self.currentFrame, self.x, self.y, 0, self.flip * WINDOW_SCALE, WINDOW_SCALE, self.originChange, 0)
end
