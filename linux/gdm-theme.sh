#!/usr/bin/env bash
# OPTIONAL: themes the GDM login screen (the screen you see at boot) with the Lumora wallpaper.
# Debian/Ubuntu with GDM only. Takes effect after a reboot.
#   sudo bash linux/gdm-theme.sh            install
#   sudo bash linux/gdm-theme.sh --undo     restore the stock login screen
#
# If the login screen ever fails to load, switch to a text console (Ctrl+Alt+F3), log in, and run:
#   sudo update-alternatives --remove gdm-theme.gresource /usr/local/share/gnome-shell/lumora-gdm.gresource
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT=/usr/local/share/gnome-shell/lumora-gdm.gresource

if [ "$(id -u)" -ne 0 ]; then echo "Run with sudo."; exit 1; fi

if [ "${1:-}" = "--undo" ]; then
  update-alternatives --remove gdm-theme.gresource "$OUT" 2>/dev/null || true
  rm -f "$OUT"
  echo "Restored the stock login screen. Reboot to apply."
  exit 0
fi

if ! update-alternatives --query gdm-theme.gresource >/dev/null 2>&1; then
  echo "This system does not use the gdm-theme.gresource alternative; not supported here."
  exit 1
fi

apt-get install -y libglib2.0-dev-bin

SRC="$(readlink -f /usr/share/gnome-shell/gdm-theme.gresource)"
W="$(mktemp -d)"
trap 'rm -rf "$W"' EXIT
mkdir -p "$W/theme"

echo "==> Extracting $SRC"
for r in $(gresource list "$SRC"); do
  f="${r#/org/gnome/shell/theme/}"
  mkdir -p "$W/theme/$(dirname "$f")"
  gresource extract "$SRC" "$r" > "$W/theme/$f"
done

cp "$ROOT/boot/live-theme/background.png" "$W/theme/lumora-bg.png"
for css in "$W"/theme/gdm*.css "$W"/theme/gnome-shell*.css; do
  [ -f "$css" ] || continue
  cat >> "$css" <<'CSS'

/* Lumora */
#lockDialogGroup {
  background: #130B20 url(lumora-bg.png);
  background-size: cover;
}
.unlock-dialog-clock-time, .login-dialog-clock-time { color: #00F0FF; font-weight: 700; }
.login-dialog-prompt-entry {
  border-radius: 999px;
  background-color: rgba(44, 31, 77, 0.85);
  border: 1px solid #B026FF;
  color: #F1E9FF;
}
.login-dialog-prompt-entry:focus { border-color: #00F0FF; }
CSS
done

{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<gresources><gresource prefix="/org/gnome/shell/theme">'
  (cd "$W/theme" && find . -type f | sed 's|^\./||' | while read -r f; do echo "<file>$f</file>"; done)
  echo '</gresource></gresources>'
} > "$W/lumora.gresource.xml"

glib-compile-resources --sourcedir="$W/theme" --target="$W/lumora-gdm.gresource" "$W/lumora.gresource.xml"

mkdir -p "$(dirname "$OUT")"
cp "$W/lumora-gdm.gresource" "$OUT"
update-alternatives --install /usr/share/gnome-shell/gdm-theme.gresource gdm-theme.gresource "$OUT" 100
echo "Done. Reboot to see the new login screen."
