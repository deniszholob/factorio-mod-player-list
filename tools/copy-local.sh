#!/bin/bash
# @usage: bash tools/copy-local.sh
# Be carefull about editing in factorio folder, as this will overwrite anything there

MOD_NAME="ddd-player-list" # MUST be the same as in "src/info.json" !!!
FACTORIO_DIR_WIN="$APPDATA/Factorio/mods/"
FACTORIO_DIR_LIX=~/.var/app/com.valvesoftware.Steam/.factorio/mods
FACTORIO_DIR="$FACTORIO_DIR_LIX"
RELEASE_FILE_NAME="$MOD_NAME"

echo "===== Current dir:"
pwd #output: your-path-to-this-repository/factorio-softmod-pack
# ls -al

echo "Remove previous contents"
rm -rfv "$FACTORIO_DIR/$RELEASE_FILE_NAME"

echo "===== Copy scr folder to factorio mods folder"
# Copies everything including dot files/folders
cp -rfv "./src" "$FACTORIO_DIR/$RELEASE_FILE_NAME"

echo "===== Copied folder contents:"
ls -al "$FACTORIO_DIR/$RELEASE_FILE_NAME"

echo "Done."
