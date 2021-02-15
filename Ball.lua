Class = require 'class'

PIXELS_PER_ANIM_CHANGE = 12.5 * WINDOW_SCALE --12.5 is 1/4 the circumference pi * d. If more frames are ever added, 12.5 will become a number that is a smaller % of 50(circumference)
halfBallDiameter =  8 * WINDOW_SCALE

Ball = Class{}

function Ball:init(x, y, frame)

    self.width = 16 * WINDOW_SCALE
    self.height = 16 * WINDOW_SCALE
    self.x = x
    self.y = y
    self.center_x = self.x + halfBallDiameter
    self.center_y = self.y + halfBallDiameter
    self.dx = 0
    self.dy = 0
    self.texture = love.graphics.newImage('graphics/GreatBalls.png')

    ballQuads = {}
    ballQuads[1] = {}
    ballQuads[1][1] = love.graphics.newQuad(0, 0, 16, 16, self.texture:getDimensions())
    ballQuads[1][2] = love.graphics.newQuad(16*4, 0, 16, 16, self.texture:getDimensions())
    ballQuads[1][3] = love.graphics.newQuad(16*5, 0, 16, 16, self.texture:getDimensions()) 
    ballQuads[1][4] = love.graphics.newQuad(16*3, 0, 16, 16, self.texture:getDimensions())
    ballQuads[2] = {}
    ballQuads[2][1] = love.graphics.newQuad(0, 0, 16, 16, self.texture:getDimensions())
    ballQuads[2][2] = love.graphics.newQuad(16*2, 0, 16, 16, self.texture:getDimensions()) 
    ballQuads[2][3] = love.graphics.newQuad(16*5, 0, 16, 16, self.texture:getDimensions()) 
    ballQuads[2][4] = love.graphics.newQuad(16*1, 0, 16, 16, self.texture:getDimensions())
    ballQuads[3] = {}
    ballQuads[3][1] = love.graphics.newQuad(0, 0, 16, 16, self.texture:getDimensions())
    ballQuads[3][2] = love.graphics.newQuad(16*6, 0, 16, 16, self.texture:getDimensions())
    ballQuads[3][3] = love.graphics.newQuad(16*5, 0, 16, 16, self.texture:getDimensions()) 
    ballQuads[3][4] = love.graphics.newQuad(16*7, 0, 16, 16, self.texture:getDimensions())
    ballQuads[4] = {}
    ballQuads[4][1] = love.graphics.newQuad(0, 0, 16, 16, self.texture:getDimensions())
    ballQuads[4][2] = love.graphics.newQuad(16*8, 0, 16, 16, self.texture:getDimensions()) 
    ballQuads[4][3] = love.graphics.newQuad(16*5, 0, 16, 16, self.texture:getDimensions()) 
    ballQuads[4][4] = love.graphics.newQuad(16*9, 0, 16, 16, self.texture:getDimensions())

    --Animation-related member variables.
    self.pixelsPerFrame = math.sqrt((self.dx * self.dx) + (self.dy * self.dy)) --This is also the hypotenuse of dy and dx triangle, ie. resultant vector.
    self.animChangesPerFrame = self.pixelsPerFrame / PIXELS_PER_ANIM_CHANGE
    self.angle = nil
    self.animationAngle = nil
    self.frameIndex = 1
    self.animSet = 1
    self.currentFrame = ballQuads[self.animSet][self.frameIndex]

    --Functional member variables
    self.elevated = false
    self.possessed = nil -- will be nil, 'player_left' or 'player_right'
    self.state = 'rebound' --states at this time include: rebound, shot
    self.sector = GetSector(self.center_x, self.center_y)
    self.rollingFriction = .992
    self.slidingFriction = .9
    self.timer = 0
    self.hole = nil
    self.lastX = self.x
    self.lastY = self.y
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

function Ball:update(dt)


    self.distanceTracker = self.distanceTracker 

    --Get sector of table that ball is in and check collisions with objects present. 

    possibleCollisions  = {}
    self.sector = GetSector(self.center_x, self.center_y)
    possibleCollisions = ObjectsFromSector(self.sector)

    --table deltaSet contains new values for x, y, dx, and dy of colliding ball. 
    --Check for ball going in pocket
    local deltaSet = {}
    local in_pocket = false
    deltaSet = possibleCollisions[1]:PocketCollision(self.center_x, self.center_y)
    if deltaSet ~= nil and (self.state =='shot' or self.state == 'rebound') and self.possessed == nil then
        self.x = deltaSet[1] - halfBallDiameter
        self.y = deltaSet[2] - halfBallDiameter
        self.dx = deltaSet[3]
        self.dy = deltaSet[4]
        self.hole = deltaSet[5]--keeps track of which pocket was entered.
        self.slidingFriction = deltaSet[6]
        self.state = 'scored'
        in_pocket = true
    end
    
    --When ball enters pocket, it pauses 1 second then becomes hidden.
    if self.state == 'scored' then
        self.timer = self.timer + 1
        if self.timer >= 10 then 
            for p = 1, 4, 1 do
                if self == ballObjects[p] then --label balls so they'll be stashed in unique location.
                    g = p
                end
            end 
            --if ball goes in one of the north/south pockets
            if self.hole ~= 'B' and self.hole ~= 'E' then
                self.x = 20 * WINDOW_SCALE + g * 20 * WINDOW_SCALE  --Hide the balls 'off of the set' and without overlap
                self.y = 0
            --side pockets. Ball goes to the player that the pocket is to the right of.  
            else
                local deviation = 0 
                if self.hole == 'E' then
                    proposed_y = 610 * WINDOW_SCALE --ball goes to player1
                else
                    proposed_y = 96 * WINDOW_SCALE --ball goes to player2
                end 
                while Drop(172 + deviation + 8 * WINDOW_SCALE, proposed_y + 8 * WINDOW_SCALE) > 0 do -- Should multiple balls enter a side pocket, 
                    deviation = deviation + 32 * WINDOW_SCALE                                       -- may they be placed in on table in non-overlap.
                end
                self.x = 172 * WINDOW_SCALE + deviation
                self.y = proposed_y
            end
            self.dx = 0
            self.dy = 0
            ScoreUpdate(self.hole)
            self.state = 'hidden'
            if self.hole == 'E' or self.hole == 'B' then
                self.state = 'rebound'
            end
            self.timer = 0
            self.hole = nil
            in_pocket = false
        end
    end

    --Check for collision with walls.
    if in_pocket == false and self.possessed == nil then   
        for i = 2, 5, 1 do
            deltaSet = {}
            deltaSet = possibleCollisions[i]:WallCollision(self.center_x, self.center_y, self.dx, self.dy)
            if deltaSet ~= nil and (self.state == 'shot' or self.state == 'rebound') then
                self.x = deltaSet[1] - halfBallDiameter
                self.y = deltaSet[2] - halfBallDiameter
                self.dx = deltaSet[3]
                self.dy = deltaSet[4]
                self.state = deltaSet[5]
                self.slidingFriction = .9
                Wall_Thud.play(Wall_Thud)
            end   
        end
    end
    ---------------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------------
    --Follow the position of the hand that picked it up
    if self.elevated == true then
        if self.possessed ~= nil then
            self.center_x = self.x + halfBallDiameter
            self.center_y = self.y + halfBallDiameter
            self.dx = 0
            self.dy = 0
            self.slidingFriction = .9
            if self.possessed == leftHand then
                self.x = leftHand.attachmentPoint_x
                self.y = leftHand.attachmentPoint_y
            elseif self.possessed == rightHand then
                self.x = rightHand.attachmentPoint_x 
                self.y = rightHand.attachmentPoint_y          
            elseif self.possessed == leftAI then
                self.x = leftAI.attachmentPoint_x 
                self.y = leftAI.attachmentPoint_y            
            elseif self.possessed == rightAI then
                self.x = rightAI.attachmentPoint_x
                self.y = rightAI.attachmentPoint_y           
            end
        end
    else
        --Has positional autonomy
        self.slidingFriction = SlidingFriction(self.slidingFriction)
        --Sliding friction is eliminated once ball is conceivably rolling 
        if self.slidingFriction < 1 then
            self.dx = self.dx * self.slidingFriction * self.rollingFriction
            self.dy = self.dy * self.slidingFriction * self.rollingFriction
        else
            self.dx = self.dx * self.rollingFriction  
            self.dy = self.dy * self.rollingFriction 
        end
        
        --calculate multidirectional magnitude of ball.
        local magnitude = math.sqrt((self.dx * self.dx) + (self.dy * self.dy))
        
        --to prevent infintessimally small ball movements. And reset sliding friction once ball stops.
        if magnitude < (7 * WINDOW_SCALE) and self.state ~= 'hidden' and self.state ~= 'scored' then
            self.dx = 0
            self.dy = 0
            self.slidingFriction = .9
            self.state = 'rebound'
        end

        --Place limit on where balls can travel 
        ballSeperator2 = 2 * WINDOW_SCALE 
        if self.center_x > 332 * WINDOW_SCALE then 
            self.x = self.x - ballSeperator2
        elseif self.center_x < 27 * WINDOW_SCALE then 
            self.x = self.x + ballSeperator2
        end
        if self.center_y > 637 * WINDOW_SCALE then
            self.y = self.y - ballSeperator2
        elseif self.center_y < 83 * WINDOW_SCALE then
            self.y = self.y + ballSeperator2
        end

        --Update Position
        self.x = self.x + self.dx * dt
        self.y = self.y + self.dy * dt
        self.center_x = self.x + halfBallDiameter
        self.center_y = self.y + halfBallDiameter
    end 
    -----------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------
    --animate it
    self.pixelsPerFrame = math.sqrt((self.dx * self.dx) + (self.dy * self.dy)) --This is also the hypotenuse of dy and dx triangle, ie. resultant vector.
    self.animChangesPerFrame = self.pixelsPerFrame / PIXELS_PER_ANIM_CHANGE
    self.angle = math.abs(math.deg(math.atan(self.dy/self.dx)))

    --If ball became possessed before this update. ELSE: Carry out animation frame-changing process.
    if self.possessed ~= nil then
        self.x = self.possessed.animationAttachmentX
        self.y = self.possessed.animationAttachmentY
    elseif self.possessed == nil and self.slidingFriction >= 1 then
        --Determine direction of ball and then the angle of travel based on that.
        if self.dy > 0 then 
            if self.dx > 0 then 
                self.animationAngle = 360 - self.angle
            elseif self.dx < 0 then 
                self.animationAngle = 180 + self.angle
            elseif self.dx == 0 then
                self.animationAngle = 270
            end
        elseif self.dy < 0 then
            if self.dx > 0 then
                self.animationAngle = self.angle
            elseif self.dx < 0 then
                self.animationAngle = 180 - self.angle
            elseif self.dx == 0 then
                self.animationAngle = 90
            end
        else
            if self.dx > 0 then
                self.animationAngle = 0
            elseif self.dx < 0 then
                self.animationAngle = 180
            elseif self.dy == 0 then
                self.animationAngle = 0
            end
        end
        --Based on direction of ball travel, assign corresponding animation set.
        local animationDirection = nil
        if self.animationAngle >= 67.5 and self.animationAngle < 112.5 then
            self.animSet = 1
            animationDirection = 'forward'
        elseif self.animationAngle >= 112.5 and self.animationAngle < 157.5 then
            self.animSet = 4
            animationDirection = 'forward'
        elseif self.animationAngle >= 157.5 and self.animationAngle < 202.5 then
            self.animSet = 2
            animationDirection = 'back'
        elseif self.animationAngle >= 202.5 and self.animationAngle < 247.5 then
            self.animSet = 3
            animationDirection = 'back'
        elseif self.animationAngle >= 247.5 and self.animationAngle < 292.5 then
            self.animSet = 1
            animationDirection = 'back'
        elseif self.animationAngle >= 292.5 and self.animationAngle < 337.5 then
            self.animSet = 4
            animationDirection = 'back'
        elseif self.animationAngle >= 337.5 and self.animationAngle <= 359 or self.animationAngle < 22.5 and self.animationAngle >= 0 then
            self.animSet = 2
            animationDirection = 'forward'
        elseif self.animationAngle >= 22.5 and self.animationAngle < 67.5 then
            self.animSet = 3
            animationDirection = 'forward'
        end
        --Determine which frame within the animation set to use.  
        local totalChange = math.sqrt((self.x - self.lastX) * (self.x - self.lastX) + (self.y - self.lastY) * (self.y - self.lastY))
        if totalChange >= 10 * WINDOW_SCALE and self.elevated == false then
            -- reset to start frame because you've reached end of the animation set.
            if animationDirection == 'forward' and self.frameIndex == 4 then
                self.frameIndex = 0
            elseif animationDirection == 'back' and self.frameIndex == 1 then
                self.frameIndex = 5
            end
            --PLay the animation forward or in reverse depending on direction. Progress 1 frame
            if animationDirection == 'forward' then
                self.frameIndex = self.frameIndex + 1
                self.lastX = self.x
                self.lastY = self.y
            elseif animationDirection == 'back' then
                self.frameIndex = self.frameIndex - 1
                self.lastX = self.x
                self.lastY = self.y
            end 
        end
    end
    --Define/re-establish what the current frame of ball should be.
    self.currentFrame = ballQuads[self.animSet][self.frameIndex]
end


function Ball:render()
    love.graphics.draw(self.texture, self.currentFrame, self.x, self.y, 0, WINDOW_SCALE, WINDOW_SCALE)
end