-- Time Helper Module
-- Common Time functions
-- @usage local Time = require('util/Time')
-- ------------------------------------------------------- --
-- @author Denis Zholob (DDDGamer)
-- github: https://github.com/deniszholob/factorio-mod-player-list
-- ======================================================= --

Time = {
  NEW_PLAYER_TIME = 30, -- minutes
  NEW_PLAYER_GAME_TIME = 8 -- hrs
}

-- Returns hours converted from game ticks
-- @param t - Factorio game tick
function Time.tick_to_hour(t)
  return Time.tick_to_sec(t) / 3600
end

-- Returns minutes converted from game ticks
-- @param t - Factorio game tick
function Time.tick_to_min(t)
  return Time.tick_to_sec(t) / 60
end

-- Returns seconds converted from game ticks
-- @param t - Factorio game tick
function Time.tick_to_sec(t)
  -- return game.speed * (t / 60)
  return (t / 60)
end

return Time
