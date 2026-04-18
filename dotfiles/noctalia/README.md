# Noctalia theme assets
#
# This directory contains the raw color scheme and theme assets for Noctalia.
# It is the single source of truth for all visual theming on this workstation.
#
# Structure:
#   colors.conf          — base Noctalia palette (hex values, named variables)
#   wallpaper/           — wallpapers and hyprpaper assets
#   gtk/                 — GTK CSS overrides
#   waybar/              — waybar style.css (sources colors from colors.conf)
#   foot/                — foot color scheme snippet (included from dotfiles/foot/foot.ini)
#
# How colors flow:
#   colors.conf defines the palette → each app config sources or copies the values.
#   Centralizing here avoids maintaining colors in 5 different places.
#
# The NixOS module for Noctalia lives in modules/theming/noctalia.nix.
# System-level theming (GTK env vars, installed packages) is handled there.
# Visual configuration (actual colors, CSS) lives here and is applied via home-manager.
