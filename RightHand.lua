Class = require 'class'
--Accounts for the offset origin from the horizontal flip.  
LATERAL_CORRECTION = 40
bonus_rt = 1


RightHand = Class{}

function RightHand:init(texture)
    --set starting variables including position, texture, 
    --neutral texture('neutralFrame'), x and y velocities or 'deRta'
    --and scale to flip the left hand graphic. 
    rightAttachmentCorrection = 8 * WINDOW_SCALE
    rightGrabCorrection_x = -5 * WINDOW_SCALE
    rightGrabCorrection_y = 24 * WINDOW_SCALE

    self.correctionX = 12 * WINDOW_SCALE 
    self.correctionY = 17 * WINDOW_SCALE
    self.x = 230 * WINDOW_SCALE
    self.y = 550 * WINDOW_SCALE
    self.attachmentPoint_x = self.x + self.correctionX
    self.attachmentPoint_y = self.y + self.correctionY
    self.center_x = self.attachmentPoint_x + rightAttachmentCorrection
    self.center_y = self.attachmentPoint_y + rightAttachmentCorrection
    self.grab_x = self.center_x + rightGrabCorrection_x
    self.grab_y = self.center_y + rightGrabCorrection_y
    self.texture = texture

    RhQuads = {}
    RhQuads[1] = love.graphics.newQuad(0, 0, 80, 80, 400, 80)
    RhQuads[2] = love.graphics.newQuad(80, 0, 80, 80, 400, 80)
    RhQuads[3] = love.graphics.newQuad(160, 0, 80, 80, 400, 80)
    RhQuads[4] = love.graphics.newQuad(240, 0, 80, 80, 400, 80)
    RhQuads[5] = love.graphics.newQuad(320, 0, 80, 80, 400, 80)

    self.currentFrame = RhQuads[1]
    self.dx = 0
    self.dy = 0
    self.sx = -1 * WINDOW_SCALE --scale -1 to reverse image.
    self.sy = 1 * WINDOW_SCALE
    self.animationAttachmentX = self.attachmentPoint_x 
    self.animationAttachmentY = self.attachmentPoint_y 
    self.frameChangeCD = 0 -- count down for frame change
    self.lastKey = nil
    self.state = 'open'
    self.acquired = nil
    self.buttonHeld = nil
    self.releaseCount = nil
    self.holdCount = 0
end

function RightHand:update(dt)
--Check for user movement input to the Left Hand, then update position/state.    
    Movement()
    GrabDropDraw() 
    --Shooting prerequisites
    self.currentFrame = RhQuads[1]
    if love.keyboard.isDown('n') then -- 'n' is being held
        self.buttonHeld = true
        self.currentFrame = RhQuads[2]
        if rightHand.acquired ~= nil and rightHand.y > SHOT_LINE then --hand has a ball and is behind shot line.
            self.holdCount = self.holdCount + 1
            --Shoot ball to opponent's contralateral pocket
            if love.keyboard.isDown("i") and rightHand.state == 'shooting' then
                CalculateShot(self.holdCount, rightHand, 'left')
                self.lastKey = 'i'
                self.frameChangeCD = 20
                self.holdCount = 0
            --Defensive play left
            elseif love.keyboard.isDown('j') then
                Defend(rightHand, 'left')
                self.lastKey = 'j'
                self.frameChangeCD = 20
                self.holdCount = 0
            --Defensive play right
            elseif love.keyboard.isDown('l') then
                Defend(rightHand, 'right')
                self.lastKey = 'l'
                self.frameChangeCD = 20
                self.holdCount = 0
            end
        end
    else 
        --action button is not held. Release count either = 0 because it hasn't been held recently, or it's > 0 because it was JUST released.
        self.buttonHeld = false
        self.releaseCount = self.holdCount
    end  

    if self.holdCount >= 30 then
        rightHand.state = 'shooting'
        self.holdCount = math.min(self.holdCount, 120)
        if self.buttonHeld == false then
            CalculateShot(self.releaseCount, rightHand, 'right')
            self.holdCount = 0
            self.lastKey = 'n'
            self.frameChangeCD = 20
        end
    end

    --update position
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
    --update are where center of a held ball would be
    self.center_x = self.attachmentPoint_x + rightAttachmentCorrection
    self.center_y = self.attachmentPoint_y + rightAttachmentCorrection
    --update the point from where unelevated balls are gauged. 
    self.grab_x = self.center_x + rightGrabCorrection_x
    self.grab_y = self.center_y + rightGrabCorrection_y
    --update where ball attaches
    self.attachmentPoint_x = self.x + self.correctionX
    self.attachmentPoint_y = self.y + self.correctionY
    
    --update x and y velocities or 'deRta'
    self.dx = 0
    self.dy = 0

     --Update animation frames.
     if self.lastKey ~= nil then
        if self.lastKey == 'j' then 
            if self.frameChangeCD > 10 and self.frameChangeCD <= 20 then 
                self.currentFrame = RhQuads[5]
            elseif self.frameChangeCD <= 10 and self.frameChangeCD > 0 then
                self.currentFrame = RhQuads[2]
            end
        elseif self.lastKey == 'i' or self.lastKey == 'n' then
            if self.frameChangeCD > 10 and self.frameChangeCD <= 20 then 
                self.currentFrame = RhQuads[4]
            elseif self.frameChangeCD <= 10 and self.frameChangeCD > 0 then
                self.currentFrame = RhQuads[1]
            end
        elseif self.lastKey == 'l' then
            if self.frameChangeCD > 10 and self.frameChangeCD <= 20 then 
                self.currentFrame = RhQuads[3]
            elseif self.frameChangeCD <= 10 and self.frameChangeCD > 0 then
                self.currentFrame = RhQuads[4]
            end
        end
        self.frameChangeCD = self.frameChangeCD - 1
    
    end

    --update wwhere ball will be drawn from during hand animation
    if self.currentFrame == RhQuads[1] then
        self.animationAttachmentX = self.attachmentPoint_x
        self.animationAttachmentY = self.attachmentPoint_y
    elseif self.currentFrame == RhQuads[2] then
        self.animationAttachmentX = self.attachmentPoint_x + rightGrabCorrection_x
        self.animationAttachmentY = self.attachmentPoint_y + rightGrabCorrection_y
    end

end


function RightHand:render()
    --draw hand to screen
    love.graphics.draw(self.texture, self.currentFrame, self.x, self.y, 0, self.sx, self.sy, 80, 0)
end
