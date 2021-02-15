--possible states, thus far, include 'free-play', '4-ball-p1', '4-ball-p2', '4-ball-comp', 
--'paused', 'count-down', 'game-over'. 
--while paused, screen will display rules, objectives, player-controls. While paused all ball objects
-- will have dx, dy = 0, all player controls but 'p' will be frozen with their old value being saved,
-- and then restored once unpaused. 'p' button pauses game. 'p' button will not work in multiplayer. 



function Pause()
    if GAME_STATE ~= 'paused' then
        PRIOR_STATE = GAME_STATE
        GAME_STATE = 'paused'
    else
        GAME_STATE = PRIOR_STATE
        PRIOR_STATE = nil
    end
end

function ScoreUpdate(sector)
    if sector == 'A' or sector == 'D' then
        P1_BALLS_REMAINING = P1_BALLS_REMAINING - 1
        P2_BALLS_REMAINING = P2_BALLS_REMAINING + 1
        if sector == 'A' then 
            FL_COUNT = FL_COUNT + 1
            TABLE_COUNT = TABLE_COUNT - 1
            PLAYER1_CAN_DRAW = PLAYER1_CAN_DRAW + 1
        elseif sector == 'D' then
            FR_COUNT = FR_COUNT + 1
            TABLE_COUNT = TABLE_COUNT - 1
            PLAYER1_CAN_DRAW = PLAYER1_CAN_DRAW + 1
        end
    elseif sector == 'C' or sector == 'F' then
        P2_BALLS_REMAINING = P2_BALLS_REMAINING - 1
        P1_BALLS_REMAINING = P1_BALLS_REMAINING + 1
        if sector == 'F' then 
            NR_COUNT = NR_COUNT + 1
            TABLE_COUNT = TABLE_COUNT - 1
            COMP_CAN_DRAW = COMP_CAN_DRAW + 1
        elseif sector == 'C' then
            NL_COUNT = NL_COUNT + 1
            TABLE_COUNT = TABLE_COUNT - 1
            COMP_CAN_DRAW = COMP_CAN_DRAW + 1
        end
    end

    if P1_BALLS_REMAINING == 0 or P2_BALLS_REMAINING == 0 then
        GAME_STATE = 'game-over'

        if P1_BALLS_REMAINING == 0 then
            WINNER = 'Player-1'
            if difficultyButtons[#difficultyButtons] == difficultButton then
                DIFFICULT_WINS = DIFFICULT_WINS + 1
            elseif difficultyButtons[#difficultyButtons] == moderateButton then
                MODERATE_WINS = MODERATE_WINS + 1
            elseif difficultyButtons[#difficultyButtons] == easyButton then
                EASY_WINS = EASY_WINS + 1
            end
        elseif P2_BALLS_REMAINING == 0 then
            WINNER = 'Computer'
        end
    end
end

