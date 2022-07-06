--- Online Player List Soft Module
--- Displays a list of current players
--- Uses locale player-list.cfg
--- @usage require('modules/common/online-player-list')
--- ------------------------------------------------------- ---
--- @author Denis Zholob (DDDGamer)
--- @see github: https://github.com/deniszholob/factorio-player-list
--- ======================================================= ---

-- Dependencies --
-- ======================================================= --
-- Factorio
local mod_gui = require('mod-gui') -- From `Factorio\data\core\lualib`

-- Constants --
-- ======================================================= --
PlayerList = {}
