Class = require 'class'

Crosshair = Class{}

function Crosshair:init(hand)
self.hand = hand
self.x = hand.grab_x - 32 * WINDOW_SCALE
self.y = hand.grab_y - 32 * WINDOW_SCALE
self.texture = love.graphics.newImage('graphics/spotlight5.png')
end

function Crosshair:update(dt)
   
    self.x = self.hand.grab_x - 32 * WINDOW_SCALE
    self.y = self.hand.grab_y - 32 * WINDOW_SCALE
end

function Crosshair:render()
    love.graphics.draw(self.texture, self.x, self.y, 0, WINDOW_SCALE, WINDOW_SCALE)
end
