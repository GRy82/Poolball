Class = require 'class'

Pocket = Class{}

function Pocket:init(Xc, Yc, in_x, in_y, player, sect)
    self.center_x = Xc
    self.center_y = Yc
    self.in_x = in_x
    self.in_y = in_y 
    self.defended_by = player -- can be 'player', 'computer', 'neutral', 'player1', 'player2' 
    self.sector = sect
end

function Pocket:PocketCollision(ballCenter_x, ballCenter_y)
    local xSatisfied = false
    local ySatisfied = false
    --Check for collision on basis of x and y coordinates
    if self.sector == 'A' or self.sector == 'D' then
        if ballCenter_y <= self.in_y then
            ySatisfied = true
        end
    end
    if self.sector == 'A' or self.sector == 'C' then
        if ballCenter_x <= self.in_x then
            xSatisfied = true
        end
    end
    if self.sector == 'F' or self.sector == 'C' then
        if ballCenter_y >= self.in_y then
            ySatisfied = true
        end
    end
    if self.sector == 'D' or self.sector == 'F' then
        if ballCenter_x >= self.in_x then
            xSatisfied = true
        end
    end
    if self.sector == 'B' or self.sector == 'E' then
        if ballCenter_y >= 349 * WINDOW_SCALE and ballCenter_y <= 365 * WINDOW_SCALE then
            ySatisfied = true
        end
        if self.sector == 'B' and ballCenter_x <= self.in_x then
            xSatisfied = true
        elseif self.sector == 'E' and ballCenter_x >= self.in_x then
            xSatisfied = true
        end
    end
    --both x and y positions indicate ball is within the hole. 
    if xSatisfied == true and ySatisfied == true then
        returnTablePock = {}
        returnTablePock[1] = self.center_x
        returnTablePock[2] = self.center_y
        returnTablePock[3] = 0
        returnTablePock[4] = 0
        returnTablePock[5] = self.sector
        returnTablePock[6] = 0.9
        return returnTablePock
    else
        return nil
    end
end