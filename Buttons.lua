Class = require 'class'
--Initialize Button class.
Button = Class{}

function Button:init(x, y, buttonType, texture, unlockInput)
    self.x_left = x
    self.y_top = y

    if texture ~= nil then
        self.texture = texture
    end

    self.type = buttonType
    self.unlocked = unlockInput
    if buttonType == 'option-screen' then
        self.x_right = x + 160 * WINDOW_SCALE
        self.y_bottom = y + 40 * WINDOW_SCALE
        self.off_hover = love.graphics.newQuad(0, 0, 160, 40, 320, 40)
        self.hover = love.graphics.newQuad(160, 0, 160, 40, 320, 40)
        self.quad = self.off_hover
    elseif buttonType == 'ball' then
        self.x_right = x + 16 * MAGNIFY
        self.y_bottom = y + 16 * MAGNIFY
        self.quad = {}
        self.quad[1] = love.graphics.newQuad(0, 0, 16, 16, self.texture:getDimensions())
        self.quad[2] = love.graphics.newQuad(16, 0, 16, 16, self.texture:getDimensions())
        self.quad[3] = love.graphics.newQuad(32, 0, 16, 16, self.texture:getDimensions())
        self.quad[4] = love.graphics.newQuad(48, 0, 16, 16, self.texture:getDimensions())
    elseif buttonType == 'difficulty' then
        self.x_right = x + 60 * WINDOW_SCALE
        self.y_bottom = y + 25 * WINDOW_SCALE
    elseif buttonType == 'hand' then
        self.x_right = x + 80 * WINDOW_SCALE
        self.y_bottom = y + 80 * WINDOW_SCALE
        self.quad = love.graphics.newQuad(0, 0, 80, 80, 400, 80)
    end

   
end

--Checks whether mouse is hovering over a button, and/or whether it is clicked.
function Button:CheckHoverClick(mouse_x, mouse_y)
    if self.type == 'option-screen' then
        if mouse_x >= self.x_left and mouse_x <= self.x_right then
            if mouse_y >= self.y_top and mouse_y <= self.y_bottom then
                self.quad = self.hover
                if love.mouse.isDown(1) then
                    if self == singleButton then
                        GAME_STATE = 'single'
                    elseif self == rulesButton then
                        Pause()
                    else
                        return
                    end

                end
            else
                self.quad = self.off_hover
            end
        else
            self.quad = self.off_hover
        end
    else 
        if mouse_x >= self.x_left and mouse_x <= self.x_right then
            if mouse_y >= self.y_top and mouse_y <= self.y_bottom then
                if love.mouse.isDown(1) then
                    return true
                end
            end
        end
    end
end