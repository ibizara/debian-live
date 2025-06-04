#!/bin/bash

# Apply themes
gsettings set org.mate.interface gtk-theme 'BlueMenta'
gsettings set org.mate.interface icon-theme 'gnome'
gsettings set org.mate.peripherals-mouse cursor-theme 'Adwaita'
gsettings set org.mate.Marco.general theme 'BlueMenta'

# Optional settings
gsettings set org.mate.peripherals-touchpad natural-scroll true
gsettings set org.mate.background picture-filename '/usr/share/backgrounds/wallhaven.png'

# Show hidden files and backup files by default in Caja
gsettings set org.mate.caja.preferences show-hidden-files true
gsettings set org.mate.caja.preferences show-backup-files true

# Enable icons in desired order
gsettings set org.mate.caja.desktop computer-icon-visible true
gsettings set org.mate.caja.desktop home-icon-visible true
gsettings set org.mate.caja.desktop trash-icon-visible true

# Ensure Caja draws the desktop
gsettings set org.mate.background show-desktop-icons true

# Wait briefly, then restart Marco to apply borders immediately
sleep 1 && marco --replace --no-composite &