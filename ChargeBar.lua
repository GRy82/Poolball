Class = require 'class'

ChargeBar = Class()

function ChargeBar:init(handObject)
    self.hand = handObject
    self.x = handObject.x
    self.y = handObject.y
    self.percentage = 0
    self.hidden = true
    self.texture = love.graphics.newImage('graphics/Charge_Bar.png')
    chargebBarQuads = {}
    for i = 1, 20, 1 do 
        chargebBarQuads[i] = love.graphics.newQuad((i - 1) * 40, 0, 40, 8, self.texture:getDimensions())
    end
    self.quad = chargebBarQuads[1]
end

function ChargeBar:update(dt)
    local x_correction = 0
    if self == leftChargeBar then
        x_correction = 40 * WINDOW_SCALE
    end

    self.x = self.hand.x + x_correction
    self.y = self.hand.y + 60 * WINDOW_SCALE

    if self.hand.holdCount >= 30 and self.hand.holdCount < 120 then
        self.hidden = false
        self.quad = chargebBarQuads[(1 + math.floor((self.hand.holdCount - 29) / 5))]
    elseif self.hand.holdCount == 120 then
        self.hidden = false
        self.quad = chargebBarQuads[20]
    else
        self.hidden = true
    end
end

function ChargeBar:render()
    love.graphics.draw(self.texture, self.quad, self.x, self.y, 0, WINDOW_SCALE, WINDOW_SCALE)
end
