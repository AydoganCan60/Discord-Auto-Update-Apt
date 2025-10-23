#!/usr/bin/env bash

JSON_FILE="/tmp/discord-version.json"
URL="https://discord.com/api/download?platform=linux&format=deb"

if [ -f "$JSON_FILE" ]; then
    CURRENT_VERSION=$(jq -r '.version' "$JSON_FILE")
else

    if dpkg -s discord &>/dev/null; then
        CURRENT_VERSION=$(dpkg -s discord | grep Version | awk '{print $2}')
    else
        CURRENT_VERSION="0.0.112"
    fi
fi

echo "[*] Current discord version: $CURRENT_VERSION"

DEB_URL=$(curl -s -I -L "$URL" | grep -i "^location:" | tail -n1 | awk '{print $2}' | tr -d '\r\n')
NEW_VERSION=$(basename "$DEB_URL" | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')

if [ -z "$NEW_VERSION" ]; then
    echo "[!] Cannot get version information, skipping upgrade"
    exit 0
fi

if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
    echo "[*] New version found: $NEW_VERSION. Downloading and installing..."
    TMP_FILE="/tmp/discord.deb"
    
    if ! curl -L -o "$TMP_FILE" "$DEB_URL"; then
        echo "[!] First download failed, trying 1 more time..."
        sleep 2
        if ! curl -L -o "$TMP_FILE" "$DEB_URL"; then
            echo "[!] The second download also fails, skipping the Discord update."
            rm -f "$TMP_FILE"
            exit 0
        fi
    fi

    sudo apt install -y "$TMP_FILE"
    echo "[+] Discord $NEW_VERSION installed."
    rm -f "$TMP_FILE"

    echo "{\"version\":\"$NEW_VERSION\"}" > "$JSON_FILE"
else
    echo "[✓] Discord already up to date: $CURRENT_VERSION"
fi
