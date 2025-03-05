local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'Tokyo Night Storm'
config.window_background_opacity = 0.9
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.window_decorations = "RESIZE"
config.window_padding = {
  left = '2cell',
  right = '1cell',
  top = '1cell',
  bottom = '1cell',
}

return config
