Class = require 'class'
--define LeftHand as a class
LeftHand = Class{}
--Speed of hand

function LeftHand:init(texture)
    --set starting variables including position, texture, 
    --neutral texture('neutralFrame'), x and y velocities or 'delta'.
    leftAttachmentCorrection = 8 * WINDOW_SCALE
    leftGrabCorrection_x = 5 * WINDOW_SCALE
    leftGrabCorrection_y = 24 * WINDOW_SCALE

    self.correctionX = 52 * WINDOW_SCALE
    self.correctionY = 17 * WINDOW_SCALE
    self.x = 50 * WINDOW_SCALE
    self.y = 550 * WINDOW_SCALE
    self.attachmentPoint_x = self.x + self.correctionX
    self.attachmentPoint_y = self.y + self.correctionY
    self.center_x = self.attachmentPoint_x + leftAttachmentCorrection
    self.center_y = self.attachmentPoint_y + leftAttachmentCorrection
    self.grab_x = self.center_x + leftGrabCorrection_x
    self.grab_y = self.center_y + leftGrabCorrection_y    
    self.texture = texture

    LhQuads = {}
    LhQuads[1] = love.graphics.newQuad(0, 0, 80, 80, 400, 80)
    LhQuads[2] = love.graphics.newQuad(80, 0, 80, 80, 400, 80)
    LhQuads[3] = love.graphics.newQuad(160, 0, 80, 80, 400, 80)
    LhQuads[4] = love.graphics.newQuad(240, 0, 80, 80, 400, 80)
    LhQuads[5] = love.graphics.newQuad(320, 0, 80, 80, 400, 80)

    self.currentFrame = LhQuads[1]
    self.animationAttachmentX = self.attachmentPoint_x 
    self.animationAttachmentY = self.attachmentPoint_y 
    self.frameChangeCD = 0 -- count down for frame change
    self.lastKey = nil
    self.dx = 0
    self.dy = 0
    self.state = 'open' --open/closed indicating if hand is empty or if it has a ball.
    self.acquired = nil
    self.holdCount = 0
end

local buttonHeld = false

function LeftHand:update(dt)
    --Check for user movement input to the Left Hand, then update position/state.  

    Movement()
    GrabDropDraw()
    --Shooting prerequisites
    self.currentFrame = LhQuads[1]
    if love.keyboard.isDown('c') then -- 'n' is being held
        self.buttonHeld = true
        self.currentFrame = LhQuads[2]
        if leftHand.acquired ~= nil and leftHand.y > SHOT_LINE then --hand has a ball and is behind shot line.
            self.holdCount = self.holdCount + 1
            --Shoot ball to opponent's contralateral pocket
            if love.keyboard.isDown('w') and leftHand.state == 'shooting' then
                CalculateShot(self.holdCount, leftHand, 'right')
                self.lastKey = 'w'
                self.frameChangeCD = 20
                self.holdCount = 0
            --Defensive play left
            elseif love.keyboard.isDown('a') then
                Defend(leftHand, 'left')
                self.lastKey = 'a'
                self.holdCount = 0
                self.frameChangeCD = 20
            --Defensive play right
            elseif love.keyboard.isDown('d') then
                Defend(leftHand, 'right')
                self.lastKey = 'd'
                self.holdCount = 0
                self.frameChangeCD = 20
            end
        end
    else 
        --action button is not held. Release count either = 0 because it hasn't been held recently, or it's > 0 because it was JUST released.
        self.buttonHeld = false
        self.releaseCount = self.holdCount
    end  

    if self.holdCount >= 30 then
        leftHand.state = 'shooting'
        self.holdCount = math.min(self.holdCount, 120)
        if self.buttonHeld == false then
            CalculateShot(self.releaseCount, leftHand, 'left')
            self.holdCount = 0
            self.lastKey = 'c'
            self.frameChangeCD = 20
        end
    end
    
    --update position
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
    --update are where center of a held ball would be
    self.center_x = self.attachmentPoint_x + leftAttachmentCorrection
    self.center_y = self.attachmentPoint_y + leftAttachmentCorrection
    --update the point from where unelevated balls are gauged. 
    self.grab_x = self.center_x + leftGrabCorrection_x
    self.grab_y = self.center_y + leftGrabCorrection_y
    --update where ball attaches
    self.attachmentPoint_x = self.x + self.correctionX 
    self.attachmentPoint_y = self.y + self.correctionY
    --update x and y velocities or 'delta'
    self.dx = 0
    self.dy = 0

    --Update animation frames.
    if self.lastKey ~= nil then
        if self.lastKey == 'a' then 
            if self.frameChangeCD > 10 and self.frameChangeCD <= 20 then 
                self.currentFrame = LhQuads[3]
            elseif self.frameChangeCD <= 10 and self.frameChangeCD > 0 then
                self.currentFrame = LhQuads[4]
            end
        elseif self.lastKey == 'w' or self.lastKey == 'c' then
            if self.frameChangeCD > 10 and self.frameChangeCD <= 20 then 
                self.currentFrame = LhQuads[4]
            elseif self.frameChangeCD <= 10 and self.frameChangeCD > 0 then
                self.currentFrame = LhQuads[1]
            end
        elseif self.lastKey == 'd' then
            if self.frameChangeCD > 10 and self.frameChangeCD <= 20 then 
                self.currentFrame = LhQuads[5]
            elseif self.frameChangeCD <= 10 and self.frameChangeCD > 0 then
                self.currentFrame = LhQuads[2]
            end
        end
        self.frameChangeCD = self.frameChangeCD - 1
    
    end

    --update where ball will be drawn from during hand animation
    if self.currentFrame == LhQuads[1] then
        self.animationAttachmentX = self.attachmentPoint_x
        self.animationAttachmentY = self.attachmentPoint_y
    elseif self.currentFrame == LhQuads[2] then
        self.animationAttachmentX = self.attachmentPoint_x + leftGrabCorrection_x
        self.animationAttachmentY = self.attachmentPoint_y + leftGrabCorrection_y
    end

end


function LeftHand:render()
    --draw hand to screen
    love.graphics.draw(self.texture, self.currentFrame, self.x, self.y, 0, WINDOW_SCALE, WINDOW_SCALE)
end
