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
-- stdlib
local Event = require('__stdlib__/stdlib/event/event')
local Math = require('__stdlib__/stdlib/utils/math') -- Math.round_to(x, pres)
-- util
local GUI = require('util/GUI')
local Styles = require('util/Styles')
local Sprites = require('util/Sprites')
local Time = require('util/Time')

-- Constants --
-- ======================================================= --
PlayerList = {
  MENU_BTN_NAME = 'btn_menu_player-list',
  MASTER_FRAME_NAME = 'frame_player-list',
  CHECKBOX_OFFLINE_PLAYERS = 'chbx_player-list_players',
  SPRITE_NAMES = {
    menu = Sprites.character,
    inventory = Sprites.item_editor_icon,
    inventory_empty = Sprites.slot_icon_armor
  },
  -- Utf shapes https://www.w3schools.com/charsets/ref_utf_geometric.asp
  -- Utf symbols https://www.w3schools.com/charsets/ref_utf_symbols.asp
  ONLINE_SYMBOL = '●',
  OFFLINE_SYMBOL = '○',
  ADMIN_SYMBOL = '★',
  INVENTORY_TARGET_ALL = not settings.startup["player_list_settings_inventory_target_all"].value,
  INVENTORY_PEEK_ENABLED = settings.startup["player_list_settings_inventory_peek_enabled"].value,
  LIST_MAX_HEIGHT = 600,
  PROGRESS_BAR_HEIGHT = 4,
  ENTRY_MARGIN = 0,
  REFRESH_PERIOD = 1, -- minute
}

-- Event Functions --
-- ======================================================= --

--- When new player joins add the playerlist btn to their GUI
--- Redraw the playerlist frame to update with the new player
--- @param event defines.events.on_player_joined_game
function PlayerList.on_player_joined_game(event)
  local player = game.players[event.player_index]
  PlayerList.draw_playerlist_btn(player)
  PlayerList.draw_playerlist_frame()
end

--- On Player Leave
--- Clean up the GUI in case this mod gets removed next time
--- Redraw the playerlist frame to update
--- @param event defines.events.on_player_left_game
function PlayerList.on_player_left_game(event)
  local player = game.players[event.player_index]
  GUI.destroy_element(mod_gui.get_button_flow(player)[PlayerList.MENU_BTN_NAME])
  GUI.destroy_element(mod_gui.get_frame_flow(player)[PlayerList.MASTER_FRAME_NAME])
  PlayerList.draw_playerlist_frame()
end

--- Toggle playerlist is called if gui element is playerlist button
--- @param event defines.events.on_gui_click
function PlayerList.on_gui_click(event)
  local player = game.players[event.player_index]
  local el_name = event.element.name

  -- Window toggle
  if el_name == PlayerList.MENU_BTN_NAME then
    GUI.toggle_element(mod_gui.get_frame_flow(player)[PlayerList.MASTER_FRAME_NAME])
  end
  -- Checkbox toggle to display only online players or not
  if (el_name == PlayerList.CHECKBOX_OFFLINE_PLAYERS) then
    local player_config = PlayerList.getConfig(player)
    player_config.show_offline_players = not player_config.show_offline_players
    PlayerList.draw_playerlist_frame()
  end
  -- LMB will open the map view to the clicked player
  if (string.find(el_name, "lbl_player_") and
      event.button == defines.mouse_button_type.left) then
    local target_player = game.players[string.sub(el_name, 12)]
    player.zoom_to_world(target_player.position, 2)
  end
end

--- Refresh the playerlist after ? min
--- @param event defines.events.on_tick
function PlayerList.on_tick(event)
  local refresh_period = PlayerList.REFRESH_PERIOD -- minutes
  if (Time.tick_to_min(game.tick) % refresh_period == 0) then
    PlayerList.draw_playerlist_frame()
  end
end

--- When new player uses decon planner
--- @param event defines.events.on_player_deconstructed_area
function PlayerList.on_player_deconstructed_area(event)
  local player = game.players[event.player_index]
  PlayerList.getConfig(player).decon = true
  PlayerList.draw_playerlist_frame()
end

--- When new player mines something
--- @param event defines.events.on_player_mined_item
function PlayerList.on_player_mined_item(event)
  local player = game.players[event.player_index]
  PlayerList.getConfig(player).mine = true
  PlayerList.draw_playerlist_frame()
end

--- When a player changes mod settings
--- @param event defines.events.on_runtime_mod_setting_changed
function PlayerList.on_runtime_mod_setting_changed(event)
  local player = game.players[event.player_index]

  if (
      event.setting == "player_list_settings_max_height" or
          event.setting == "player_list_settings_entry_margin"
      ) then
    PlayerList.draw_playerlist_frame_for_player(player, PlayerList.get_sorted_player_list())
  end
end

-- Event Registration --
-- ======================================================= --
Event.register(defines.events.on_gui_checked_state_changed, PlayerList.on_gui_click)
Event.register(defines.events.on_gui_click, PlayerList.on_gui_click)
Event.register(defines.events.on_player_joined_game, PlayerList.on_player_joined_game)
Event.register(defines.events.on_player_left_game, PlayerList.on_player_left_game)
Event.register(defines.events.on_tick, PlayerList.on_tick)
Event.register(defines.events.on_player_deconstructed_area, PlayerList.on_player_deconstructed_area)
Event.register(defines.events.on_player_mined_item, PlayerList.on_player_mined_item)
Event.register(
  defines.events.on_runtime_mod_setting_changed,
  PlayerList.on_runtime_mod_setting_changed
)


-- Helper Functions --
-- ======================================================= --

--- @param player LuaPlayer
function PlayerList.getLblPlayerName(player)
  return 'lbl_player_' .. player.name
end

--- Create button for player if doesnt exist already
--- @param player LuaPlayer
function PlayerList.draw_playerlist_btn(player)
  if (mod_gui.get_button_flow(player)[PlayerList.MENU_BTN_NAME] == nil) then
    mod_gui.get_button_flow(player).add(
      {
        type = 'sprite-button',
        name = PlayerList.MENU_BTN_NAME,
        sprite = PlayerList.SPRITE_NAMES.menu,
        -- caption = 'Online Players',
        tooltip = { 'player_list.btn_tooltip' }
      }
    )
  end
end

--- Draws a pane on the left listing all of the players currentely on the server
function PlayerList.draw_playerlist_frame()
  local player_list = PlayerList.get_sorted_player_list()

  for i, player in pairs(game.players) do
    PlayerList.draw_playerlist_frame_for_player(player, player_list)
  end
end

--- @return table player_list of all the game players
function PlayerList.get_sorted_player_list()
  local player_list = {}
  -- Copy player list into local list
  for i, player in pairs(game.players) do
    table.insert(player_list, player)
  end

  -- Sort players based on admin role, and time played
  -- Admins first, highest playtime first
  table.sort(player_list, PlayerList.sort_players)

  return player_list
end

--- Draws a pane on the left listing all of the players currentely on the server for specified player
---@param player LuaPlayer
---@param player_list table
function PlayerList.draw_playerlist_frame_for_player(player, player_list)
  local master_frame = mod_gui.get_frame_flow(player)[PlayerList.MASTER_FRAME_NAME]
  -- Draw the vertical frame on the left if its not drawn already
  if master_frame == nil then
    master_frame = mod_gui.get_frame_flow(player).add(
      { type = 'frame', name = PlayerList.MASTER_FRAME_NAME, direction = 'vertical' }
    )
  end
  -- Clear and repopulate player list
  GUI.clear_element(master_frame)

  -- Flow
  local flow_header = master_frame.add({ type = 'flow', direction = 'horizontal' })
  flow_header.style.horizontal_spacing = 20
  flow_header.style.horizontally_stretchable = true

  -- Draw checkbox
  flow_header.add(
    {
      type = 'checkbox',
      name = PlayerList.CHECKBOX_OFFLINE_PLAYERS,
      caption = { 'player_list.checkbox_caption' },
      tooltip = { 'player_list.checkbox_tooltip' },
      state = PlayerList.getConfig(player).show_offline_players or false
    }
  )

  -- Draw total number
  local total = flow_header.add(
    {
      type = 'label',
      caption = { 'player_list.total_players', #game.players, #game.connected_players }
    }
  )
  total.style.horizontal_align = "right"

  -- Add scrollable section to content frame
  local scrollable_content_frame =
  master_frame.add(
    {
      type = 'scroll-pane',
      vertical_scroll_policy = 'auto-and-reserve-space',
      horizontal_scroll_policy = 'never'
    }
  )
  -- scrollable_content_frame.style.maximal_height = PlayerList.LIST_MAX_HEIGHT
  scrollable_content_frame.style.maximal_height = settings.get_player_settings(player)[
      "player_list_settings_max_height"].value

  -- List all players
  for j, list_player in pairs(player_list) do
    if (list_player.connected or PlayerList.getConfig(player).show_offline_players) then
      PlayerList.to_list_add_player_entry(scrollable_content_frame, list_player, player, j % 2 == 1)
    end
  end
end


-- Add target_player entry to the GUI list
---@param container LuaGuiElement to attach more UI elements to
---@param target_player LuaPlayer this is who the entry is about
---@param player LuaPlayer this is who the entry is attached to
---@param stripe boolean wheather or not to use sripe color for row
function PlayerList.to_list_add_player_entry(container, target_player, player, stripe)
  local c = container.add({ type = 'flow', direction = 'vertical' })
  -- c.style.bottom_margin = PlayerList.ENTRY_MARGIN
  c.style.bottom_margin = settings.get_player_settings(player)[
      "player_list_settings_entry_margin"].value

  local color = {
    r = target_player.color.r,
    g = target_player.color.g,
    b = target_player.color.b,
    a = 1
  }

  PlayerList.to_entry_add_entry_info(c, target_player, color, player)
  PlayerList.to_entry_add_player_playtime(c, target_player, color)

  -- c.add { type = "line" }
end

-- Add target_player entry info to entry
---@param container LuaGuiElement to attach more UI elements to
---@param target_player LuaPlayer this is who the entry is about
---@param color Color data object
---@param player LuaPlayer this is who the entry is attached to
function PlayerList.to_entry_add_entry_info(container, target_player, color, player)
  local c = container.add({ type = 'flow', direction = 'horizontal' })

  PlayerList.to_entry_info_add_inventory_button(c, target_player, player)
  PlayerList.to_entry_info_add_player_info(c, target_player, player, color)
  PlayerList.to_entry_info_add_griefer_icons(c, target_player, player)
end

-- Add target_player playtime percentage bar info to entry
---@param container LuaGuiElement to attach more UI elements to
---@param target_player LuaPlayer this is who the entry is about
---@param color Color data object
function PlayerList.to_entry_add_player_playtime(container, target_player, color)
  local played_percentage = 1
  if (game.tick > 0) then
    played_percentage = target_player.online_time / game.tick
  end

  local c = container.add({ type = 'flow', direction = 'horizontal' })

  local entry_bar =
  c.add(
    {
      type = 'progressbar',
      name = 'bar_' .. target_player.name,
      -- style = 'achievement_progressbar',
      value = played_percentage,
      tooltip = { 'player_list.player_tooltip_playtime', Math.round_to(played_percentage * 100, 2) }
    }
  )
  entry_bar.style.color = color
  entry_bar.style.height = PlayerList.PROGRESS_BAR_HEIGHT
  entry_bar.style.horizontally_stretchable = true
end

--- Adds a button to open target_player's inventory if player has permissions
---@param container LuaGuiElement to attach more UI elements to
---@param target_player LuaPlayer this is who the entry is about
---@param player LuaPlayer this is who the entry is attached to
function PlayerList.to_entry_info_add_inventory_button(container, target_player, player)
  -- Add an inventory open button for those with privilages
  if (PlayerList.can_open_inventory(player, target_player)) then
    local inventoryIconName = PlayerList.SPRITE_NAMES.inventory
    if (target_player and
        target_player.get_main_inventory() and -- So this one is nil sometimes
        target_player.get_main_inventory().is_empty()) then
      inventoryIconName = PlayerList.SPRITE_NAMES.inventory_empty
    end
    local btn_sprite = GUI.add_sprite_button(
      container,
      {
        type = 'sprite-button',
        name = 'btn_open_inventory_' .. target_player.name,
        sprite = GUI.get_safe_sprite_name(player, inventoryIconName),
        tooltip = { 'player_list.player_tooltip_inventory', target_player.name }
      },
      -- On Click callback function
      function(event)
        PlayerList.open_player_inventory(player, target_player)
      end
    )
    GUI.element_apply_style(btn_sprite, Styles.small_button)
  end
end

--- Add some target_player info such as playtime, name, if admin or not, etc...
---@param container LuaGuiElement to attach more UI elements to
---@param target_player LuaPlayer this is who the entry is about
---@param player LuaPlayer this is who the entry is attached to
---@param color Color data object
function PlayerList.to_entry_info_add_player_info(container, target_player, player, color)
  -- Is target_player online
  local player_online_status = ''
  if (PlayerList.getConfig(player).show_offline_players) then
    player_online_status = PlayerList.OFFLINE_SYMBOL
    if (target_player.connected) then
      player_online_status = PlayerList.ONLINE_SYMBOL
    end
    player_online_status = player_online_status .. ' '
  end

  -- target_player playtime
  local played_hrs = Time.tick_to_hour(target_player.online_time)
  local played_hrs_str = tostring(Math.round_to(played_hrs, 1))

  -- Is target_player admin
  local player_admin_status = ''
  if (target_player.admin) then
    player_admin_status = ' ' .. PlayerList.ADMIN_SYMBOL
  end

  -- local caption_str = string.format('%s%s - %s%s', player_online_status, played_hrs_str,
  --   target_player.name, player_admin_status)

  local caption_str = { 'player_list.player_label', player_online_status, played_hrs_str,
    target_player.name, player_admin_status }

  -- Add in the entry to the player list
  local entry = container.add(
    {
      type = 'label',
      name = PlayerList.getLblPlayerName(target_player),
      caption = caption_str,
      tooltip = { 'player_list.player_tooltip' }
    }
  )
  entry.style.font_color = color
  entry.style.font = 'default-bold'
end

--- Add mining and decon sprites if target_player has done those actions
---@param container LuaGuiElement to attach more UI elements to
---@param target_player LuaPlayer this is who the entry is about
---@param player LuaPlayer this is who the entry is attached to
function PlayerList.to_entry_info_add_griefer_icons(container, target_player, player)
  local c = container.add({ type = 'flow', direction = 'horizontal' })
  -- local c  = container.add({type = "table", column_count = 2})
  c.style.horizontally_stretchable = true
  c.style.horizontal_align = "right"

  -- Griefer icons: mined/deconed flags
  if (PlayerList.can_see_griefer_stats(player)) then

    -- Add decon planner icon if player deconed something
    if (PlayerList.getConfig(target_player).decon) then
      -- local entry = c.add(
      --   {
      --     type = 'label',
      --     caption = '[img=item.deconstruction-planner]',
      --     tooltip = { 'player_list.player_tooltip_decon' },
      --   }
      -- )
      local sprite = c.add({
        type = 'sprite-button',
        -- type = 'sprite',
        tooltip = { 'player_list.player_tooltip_decon' },
        sprite = GUI.get_safe_sprite_name(player, Sprites.deconstruction_planner),
        enabled = false
      })
      GUI.element_apply_style(sprite, Styles.small_button)
    end

    -- Add axe icon if player mined something
    if (PlayerList.getConfig(target_player).mine) then
      -- local entry = c.add(
      --   {
      --     type = 'label',
      --     caption = '[img=technology.steel-axe]',
      --     tooltip = { 'player_list.player_tooltip_mine' },
      --   }
      -- )
      local sprite = c.add({
        type = 'sprite-button',
        -- type = 'sprite',
        tooltip = { 'player_list.player_tooltip_mine' },
        sprite = GUI.get_safe_sprite_name(player, Sprites.steel_axe),
        enabled = false
      })
      GUI.element_apply_style(sprite, Styles.small_button)
    end
  end
end

--- @param player LuaPlayer
--- @return table playerlist_config for specified player, creates default config if none exist
function PlayerList.getConfig(player)
  if (not global.playerlist_config) then
    global.playerlist_config = {}
  end

  if (not global.playerlist_config[player.name]) then
    global.playerlist_config[player.name] = {
      show_offline_players = false,
      mine = false,
      decon = false,
    }
  end

  return global.playerlist_config[player.name]
end

--- Sort players based on connection, admin role, and time played
--- Connected first, Admins first, highest playtime first
--- TODO: Add custom comparators togglable by user
--- @param a LuaPlayer
--- @param b LuaPlayer
function PlayerList.sort_players(a, b)
  if ((a.connected and b.connected) or (not a.connected and not b.connected)) then
    if ((a.admin and b.admin) or (not a.admin and not b.admin)) then
      return a.online_time > b.online_time
    else
      return a.admin
    end
  else
    return a.connected
  end
end

--- @param player LuaPlayer the one who is doing the opening (display the other player inventory for this player)
--- @param target_player LuaPlayer who's inventory to open
function PlayerList.open_player_inventory(player, target_player)
  player.opened = target_player
  -- Tried to do a toggle, but cant close; for some reason opened is always nil even after setting
  -- if(player.opened == game.players[target_player.name]) then
  --     player.opened = nil
  -- elseif(not player.opened) then
  --     player.opened = game.players[target_player.name]
  -- end
end

--- @param player LuaPlayer the one who is doing the opening (display the other player inventory for this player)
--- @param target_player LuaPlayer who's inventory to open
function PlayerList.can_open_inventory(player, target_player)
  local has_permissions = PlayerList.INVENTORY_PEEK_ENABLED and player.admin;
  local can_target_player = PlayerList.INVENTORY_TARGET_ALL or target_player.admin == false;
  return has_permissions and can_target_player
end

--- @param player LuaPlayer the one who the playerlist is being displayed for
function PlayerList.can_see_griefer_stats(player)
  return player.admin == true
end
