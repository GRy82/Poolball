Class = require 'class'

Wall = Class{}

BUMPER_COEFFICIENT = .7

function Wall:init(x1, y1, x2, y2, orientation, sect1, sect2)
    self.corner1_x = x1
    self.corner1_y = y1
    self.corner2_x = x2
    self.corner2_y = y2
    self.orientation = orientation --'ver', 'hor', 
    --or facing some combination of top/bottom, left/right, ie. 'TR' or 'BL'
    self.sector1 = sect1
    self.sector2 = sect2
end


--Check for wall collisions, and change velocities accordingly.
function Wall:WallCollision(ballCenter_x, ballCenter_y, dx, dy)
    local xSatisfied = false
    local ySatisfied = false
    --Check for horizontal wall collisions
    if self.orientation == 'hor' then
        if ballCenter_x >= self.corner1_x and ballCenter_x <= self.corner2_x then
            xSatisfied = true
            if (self.sector1 == 'A' or self.sector1 == 'D') and ballCenter_y <= self.corner1_y + 8 * WINDOW_SCALE then
                ySatisfied = true
                dy = -dy
                ballCenter_y = ballCenter_y + 2 * WINDOW_SCALE
            elseif (self.sector1 == 'C' or self.sector1 == 'F') and ballCenter_y >= self.corner1_y - 8 * WINDOW_SCALE then
                ySatisfied = true
                dy = -dy
                ballCenter_y = ballCenter_y - 2 * WINDOW_SCALE
            end
        end
    end
    --Check for vertical wall collisions
    if self.orientation == 'ver' then
        local side = ''
        if self.sector1 == 'B' or self.sector2 == 'B' then
            side = 'left'
        elseif self.sector1 == 'E' or self.sector2 == 'E' then
            side = 'right'
        end
        if ballCenter_y >= self.corner1_y and ballCenter_y <= self.corner2_y then
            ySatisfied = true
            if ballCenter_x >= self.corner1_x - 8 * WINDOW_SCALE and side == 'right' then    
                xSatisfied = true
                dx = -dx
                ballCenter_x = ballCenter_x - 2 * WINDOW_SCALE
            elseif ballCenter_x <= self.corner1_x + 8 * WINDOW_SCALE and side == 'left' then  
                xSatisfied = true
                dx = -dx
                ballCenter_x = ballCenter_x + 2 * WINDOW_SCALE 
            end
        end
    end
    --Check for diagonal wall collisions
    --check first that y is satisfied
    if self.orientation ~= 'ver' and self.orientation ~= 'hor' then
        local x1Correction = -3.5 * WINDOW_SCALE
        local y1Correction = -3.5 * WINDOW_SCALE
        local x2Correction = 3.5 * WINDOW_SCALE
        local y2Correction = 3.5 * WINDOW_SCALE
        
        if ballCenter_y >= self.corner1_y + y1Correction and ballCenter_y <= self.corner2_y + y2Correction then
            ySatisfied = true
            --check that x is satisfied
            if ballCenter_x >= self.corner1_x + x1Correction and ballCenter_x <= self.corner2_x + x2Correction then
                xSatisfied = true
                local temp = dx
                dx = dy
                dy = temp
            end
        end
        --Check which way the ball should be pushed so that it doesn't get stuck on the wall.
        if self.orientation == 'TR' then
            ballCenter_x = ballCenter_x - 1 * WINDOW_SCALE
            ballCenter_y = ballCenter_y + 1 * WINDOW_SCALE
        elseif self.orientation == 'TL' then
            ballCenter_x = ballCenter_x + 1 * WINDOW_SCALE
            ballCenter_y = ballCenter_y + 1 * WINDOW_SCALE
        elseif self.orientation == 'BL' then
            ballCenter_x = ballCenter_x + 1 * WINDOW_SCALE 
            ballCenter_y = ballCenter_y - 1 * WINDOW_SCALE
        elseif self.orientation == 'BR' then
            ballCenter_x = ballCenter_x - 1 * WINDOW_SCALE 
            ballCenter_y = ballCenter_y - 1 * WINDOW_SCALE
        end
        --check for directional reversal based on angle of shot
        if (self.orientation == 'TL' or self.orientation == 'BL') then
            if (dy > dx and dx < 0) or (dx > dy and dy < 0) then
                dx = -dx
                dy = -dy
            end 
        elseif (self.orientation == 'TR' or self.orientation == 'BR') then
            if (dy > dx and dx > 0) or (dx > dy and dy > 0) then
                dx = -dx
                dy = -dy
            end
        end
        --Corner case of x or y = 0.
        if (dx == 0 or dy == 0) and (self.orientation == 'BR' or self.orientation == 'TL') then
            dx = -dx
            dy = -dy
        end 
        
    
    end

    --now check that x is satisfied

    returnTableWall = {}

    if xSatisfied == true and ySatisfied == true then
        returnTableWall[1] = ballCenter_x
        returnTableWall[2] = ballCenter_y
        returnTableWall[3] = dx * BUMPER_COEFFICIENT
        returnTableWall[4] = dy * BUMPER_COEFFICIENT
        returnTableWall[5] = 'rebound'
        return returnTableWall
    end

    return nil
end