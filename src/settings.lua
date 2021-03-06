data:extend({
  -- STARTUP SETTINGS --
  {
    type = "bool-setting",
    name = "player_list_settings_inventory_peek_enabled",
    setting_type = "startup",
    default_value = true,
    order = "1",
    auto_trim = true,
  },
  {
    type = "bool-setting",
    name = "player_list_settings_inventory_target_all",
    setting_type = "startup",
    default_value = false,
    order = "2",
  },

  -- GLOBAL SETTINGSS --
  {
    type = "int-setting",
    name = "player_list_settings_refresh_period",
    setting_type = "runtime-global",
    default_value = 60,
    minimum_value = 1,
    order = "1",
  },

  -- PLAYER SETTINGS --
  {
    type = "int-setting",
    name = "player_list_settings_max_height",
    setting_type = "runtime-per-user",
    default_value = 600,
    order = "1",
  },
  {
    type = "int-setting",
    name = "player_list_settings_entry_margin",
    setting_type = "runtime-per-user",
    default_value = 0,
    order = "2",
  },
  {
    type = "int-setting",
    name = "player_list_settings_playtime_bar_height",
    setting_type = "runtime-per-user",
    default_value = 4,
    minimum_value = 4,
    maximum_value  = 10,
    order = "3",
  },
})
