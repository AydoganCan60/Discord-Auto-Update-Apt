# Discord-Auto-Update-Apt

**Automatic Discord Update Script (Using apt)**

This repository provides an easy way to automatically or semi-automatically update Discord `.deb` packages on Debian/Ubuntu-based systems (e.g. Ubuntu, Debian, Linux Mint).

> This repo contains two key files:
>
> * `discord-auto-update.sh` — the main update script to be placed in `/usr/local/bin/`
> * `99discord` — an apt configuration snippet to be placed under `/etc/apt/apt.conf.d/`

---

## Table of Contents

* Overview
* Requirements
* File Descriptions
* Installation (Step-by-Step)
* Testing
* Auto Execution (cron & systemd examples)
* Troubleshooting / Logs
* Releases (Alternative Method Section)
* Contributing
* License

---

## Requirements

* Debian/Ubuntu-based distro
* `sudo` privileges
* `curl` or `wget`
* `jq` (recommended for version parsing)

---

## File Descriptions

### `discord-auto-update.sh`

This Bash script automatically checks, downloads, and installs the latest version of Discord.

**Script content:**

```bash
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
```

**Example location:** `/usr/local/bin/discord-auto-update.sh`

Make sure it is executable:

```bash
sudo chmod +x /usr/local/bin/discord-auto-update.sh
```

---

### `99discord`

This file triggers the update script after each `apt update` command.

**File content:**

```bash
APT::Update::Post-Invoke {"if [ -x /usr/local/bin/discord-auto-update.sh ]; then /usr/local/bin/discord-auto-update.sh; fi";};
```

**Example location:** `/etc/apt/apt.conf.d/99discord`

---

## Installation (Step-by-Step)

1. Clone the repository:

```bash
git clone https://github.com/yourusername/Discord-Auto-Update-Apt.git
cd Discord-Auto-Update-Apt
```

2. Copy the files to the correct locations:

```bash
sudo cp discord-auto-update.sh /usr/local/bin/
sudo chmod 755 /usr/local/bin/discord-auto-update.sh
sudo cp 99discord /etc/apt/apt.conf.d/
```

3. Test the script manually:

```bash
sudo /usr/local/bin/discord-auto-update.sh
```

4. Run apt update to verify integration:

```bash
sudo apt update
```

---


## Troubleshooting / Logs

To debug manually:

```bash
bash -x /usr/local/bin/discord-auto-update.sh
```

Logs:

* `/var/log/discord-autoupdate.log`
* `/var/log/syslog`

---

## Releases

Check the [Releases](../../releases) section for pre-packaged `.deb` files or alternate installation methods.

> Note: The repository owner may demonstrate a different method for installing via the Releases section (for example, manual installation steps or alternative automation).

---

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-update`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to your branch (`git push origin feature/my-update`)
5. Open a Pull Request

---

## License

You can apply any open-source license (e.g., MIT, GPLv3).
