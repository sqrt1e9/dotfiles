#!/bin/bash
# Remove orphan packages and their configs

orphans=$(pacman -Qdtq)

if [ -n "$orphans" ]; then
    echo "Removing orphans:"
    echo "$orphans"
    sudo pacman -Rns $orphans
else
    echo "No orphan packages found."
fi

