#!/usr/bin/env bash
# Build the Lumora OS ISO (Debian 13 "trixie", amd64, GNOME).
# Needs a Debian/Ubuntu host, ~15 GB free disk and internet. Takes 30-60 minutes.
#   bash linux/build-iso.sh            (normal user, uses sudo)
#   WORK=/path/to/dir bash linux/build-iso.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${WORK:-$HOME/lumora-iso}"
if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

echo "==> Installing build tools"
$SUDO apt-get update
$SUDO apt-get install -y live-build debootstrap squashfs-tools xorriso debian-archive-keyring \
  ca-certificates grub-common fonts-dejavu-core

mkdir -p "$WORK"
cd "$WORK"
$SUDO lb clean --purge 2>/dev/null || true

echo "==> Configuring"
lb config \
  --distribution trixie \
  --architectures amd64 \
  --archive-areas "main contrib non-free-firmware" \
  --debian-installer none \
  --iso-volume "LUMORA" \
  --iso-application "Lumora OS" \
  --iso-publisher "Lumora" \
  --bootappend-live "boot=live components quiet splash locales=en_US.UTF-8 keyboard-layouts=us"

echo "==> Applying Lumora overlay"
cp -a "$ROOT/overlay/." config/

echo "==> Branding the live boot menus"
BL=/usr/share/live/build/bootloaders
if [ -d "$BL" ]; then
  cp -a "$BL" config/bootloaders
  DJ=/usr/share/fonts/truetype/dejavu
  FONT="Unifont Regular 16"; FONT_SMALL="Unifont Regular 16"
  FONTS_BUILT=0

  # GRUB (UEFI and BIOS): theme, logo, panel, fonts
  while IFS= read -r d; do
    cp -f "$ROOT/boot/live-theme/"* "$d/"
    if command -v grub-mkfont >/dev/null 2>&1 && [ -f "$DJ/DejaVuSans.ttf" ] &&
       grub-mkfont -s 20 -o "$d/regular20.pf2" "$DJ/DejaVuSans.ttf" &&
       grub-mkfont -s 14 -o "$d/regular14.pf2" "$DJ/DejaVuSans.ttf"; then
      FONTS_BUILT=1
    fi
  done < <(find config/bootloaders -type d -name live-theme)

  # Make the ISO's grub.cfg load our fonts before it loads the theme
  FONTS_LOADED=0
  if [ "$FONTS_BUILT" = 1 ]; then
    while IFS= read -r cfg; do
      sed -i '0,/^[[:space:]]*set theme=/s//loadfont \/boot\/grub\/live-theme\/regular20.pf2\nloadfont \/boot\/grub\/live-theme\/regular14.pf2\n&/' "$cfg"
      FONTS_LOADED=1
    done < <(grep -rl --include='*.cfg' '^[[:space:]]*set theme=' config/bootloaders || true)
  fi
  if [ "$FONTS_BUILT" = 1 ] && [ "$FONTS_LOADED" = 1 ]; then
    FONT="DejaVu Sans Regular 20"; FONT_SMALL="DejaVu Sans Regular 14"
  fi
  while IFS= read -r t; do
    sed -i "s/@FONT_SMALL@/$FONT_SMALL/g; s/@FONT@/$FONT/g" "$t"
  done < <(find config/bootloaders -path '*live-theme/theme.txt')

  # syslinux/isolinux (legacy BIOS): splash with logo and Lumora colors
  find config/bootloaders -name splash.png -exec cp -f "$ROOT/boot/splash.png" {} \;
  find config/bootloaders -name stdmenu.cfg -exec sh -c 'cat "$1" >> "$2"' _ "$ROOT/boot/syslinux-colors.cfg" {} \;
else
  echo "   live-build bootloader templates not found; the live boot menu keeps its default look."
fi

echo "==> Building ISO"
$SUDO lb build

ISO="$(ls -1 "$WORK"/*.iso | head -n1)"
echo
echo "Done: $ISO"
echo "Test in a VM:  qemu-system-x86_64 -m 4096 -enable-kvm -cdrom \"$ISO\""
echo "Live login (if asked): user 'user', password 'live'"
