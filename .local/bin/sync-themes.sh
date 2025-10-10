#!/bin/bash

sync_themes() {
    THEMES=(
        "$HOME/.local/share/sddm/themes/where_is_my_sddm_theme:/usr/share/sddm/themes/where_is_my_sddm_theme"
    )

    for pair in "${THEMES[@]}"; do
        src="${pair%%:*}"    # Everything before the colon
        dest="${pair##*:}"   # Everything after the colon

        echo "Syncing from $src to $dest"

        if [ ! -d "$src" ]; then
            echo "  ❌ Source directory does not exist: $src"
            continue
        fi

        # Create target directory if it doesn't exist
        sudo mkdir -p "$dest"

        # Rsync the source to destination
        sudo rsync -a --delete "$src"/ "$dest"/

        if [ $? -eq 0 ]; then
            echo "  ✅ Synced successfully."
        else
            echo "  ❌ Sync failed for: $src"
        fi
    done
}

# Call the function
sync_themes

