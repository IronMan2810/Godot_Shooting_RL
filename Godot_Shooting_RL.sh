#!/bin/sh
echo -ne '\033c\033]0;Godot_Shooting_RL\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Godot_Shooting_RL.x86_64" "$@"
