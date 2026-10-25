#!/usr/bin/env bash
# install-mods.sh - link downloaded workshop items into the server dir and
# emit the -mod=/-serverMod= launch arguments on stdout (one per line).
#
# mods.txt format, one mod per line:
#   <workshop_id> [folder_name] [server]
#   1559212036 cf            -> client mod, loaded as @cf
#   1564026768 cot server    -> server-only mod, loaded via -serverMod=@cot
#
# The DayZ Linux server requires all mod file and folder names to be lowercase,
# so every linked mod tree is lowercased in place before linking.

lowercase_tree() {
    local root="$1" p d b lb
    while IFS= read -r p; do
        d="$(dirname "$p")"; b="$(basename "$p")"
        lb="$(tr '[:upper:]' '[:lower:]' <<< "$b")"
        [ "$b" != "$lb" ] && mv "$p" "$d/$lb"
    done < <(find "$root" -depth -mindepth 1)
}

find_workshop_item() {
    local id="$1" root
    for root in "$HOME/Steam" "$HOME/.steam" "$HOME/steamcmd" "$DAYZ_SERVER_DIR" /home/steam; do
        [ -d "$root/steamapps/workshop/content/221100/$id" ] \
            && { echo "$root/steamapps/workshop/content/221100/$id"; return 0; }
    done
    find /home/steam "$DAYZ_SERVER_DIR" -type d -path "*/workshop/content/221100/$id" 2>/dev/null | head -1
}

install_mods() {
    local server_dir="$1" mods_file="$2"
    local id name kind src link
    local client_mods=() server_mods=()

    while read -r id name kind _; do
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        name="${name:-$id}"
        name="$(tr '[:upper:]' '[:lower:]' <<< "$name")"
        link="$server_dir/@$name"

        if [ ! -e "$link" ]; then
            src="$(find_workshop_item "$id")"
            if [ -z "$src" ]; then
                printf '[dayz] WARNING: workshop item %s not downloaded, skipping\n' "$id" >&2
                continue
            fi
            lowercase_tree "$src"
            ln -sfn "$src" "$link"
        fi

        # Publish mod keys so verifySignatures=2 accepts the mod's clients.
        if [ -d "$link/keys" ]; then
            mkdir -p "$server_dir/keys"
            cp -fu "$link"/keys/*.bikey "$server_dir/keys/" 2>/dev/null || true
        fi

        if [ "${kind:-}" = "server" ]; then
            server_mods+=("@$name")
        else
            client_mods+=("@$name")
        fi
    done < "$mods_file"

    ((${#client_mods[@]})) && printf '%s\n' "-mod=$(IFS=';'; echo "${client_mods[*]}")"
    ((${#server_mods[@]})) && printf '%s\n' "-serverMod=$(IFS=';'; echo "${server_mods[*]}")"
    return 0
}
