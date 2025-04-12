#!/bin/bash

# Set German Mac layout, no dead keys
setxkbmap -model pc105 -layout de -variant mac_nodeadkeys

# Load Xresources (optional DPI settings etc.)
xrdb -merge ~/.Xresources

# Start Desktop/Window Manager
startxfce4
