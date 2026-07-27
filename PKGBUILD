# Maintainer: Jochem Kuipers <jochem@kuipers.cc>
pkgname=thrm-bin
pkgver=3.6.2
pkgrel=4
pkgdesc='Flydigi BS-series laptop cooler controller (prebuilt)'
arch=('x86_64')
url='https://github.com/TIANLI0/THRM'
license=('MIT')
depends=('gtk3' 'webkit2gtk-4.1' 'hidapi')
optdepends=('bluez: BS1 BLE support')
provides=('thrm')
conflicts=('thrm')
options=('!strip' '!debug')
# Embedded icon.ico span in upstream thrm-core (go:embed). Refresh on version bump via update.sh.
_tray_icon_offset=8233952
_tray_icon_span=372526
source=(
  "https://github.com/TIANLI0/THRM/releases/download/v${pkgver}/THRM-linux-amd64-portable.tar.gz"
  "LICENSE::https://raw.githubusercontent.com/TIANLI0/THRM/v${pkgver}/LICENSE"
  '99-flydigi-fan.rules'
  'tray-icon.png'
)
sha256sums=(
  '3d146a8e42a58d076f9719d3b4af2e653e5b4ae5b3fcbda22a8fb3c33c7bbf4f'
  'bb4f94dbe3dcfdc66e27d35cae627a73c9e8f66ec792971e569d272893b08ac6'
  'd267175637ab454a65e12fe619e244d4d202ade38ecf4c12b4e254a90ecdfbc8'
  'c81b2923d5377a6b1f629f0d4a8127001b973e7e6dd72d5d383c205ba327b966'
)

package() {
  cd "$srcdir/THRM-linux-amd64"

  # Upstream writes logs/telemetry next to the binary (GetInstallDir = dirname(exe)).
  install -Dm755 thrm "$pkgdir/usr/lib/thrm/thrm"
  install -Dm755 thrm-core "$pkgdir/usr/lib/thrm/thrm-core"
  install -dm1777 "$pkgdir/usr/lib/thrm/logs"
  install -dm1777 "$pkgdir/usr/lib/thrm/telemetry"

  # Linux systray only decodes PNG; replace the embedded .ico once using committed tray-icon.png.
  local core="$pkgdir/usr/lib/thrm/thrm-core"
  local png="$srcdir/tray-icon.png"
  local png_size
  png_size=$(stat -c%s "$png")
  (( png_size <= _tray_icon_span )) || return 1
  dd if="$png" of="$core" bs=1 seek="${_tray_icon_offset}" conv=notrunc status=none
  dd if=/dev/zero of="$core" bs=1 seek="$((_tray_icon_offset + png_size))" \
    count="$((_tray_icon_span - png_size))" conv=notrunc status=none

  install -dm755 "$pkgdir/usr/bin"
  ln -s ../lib/thrm/thrm "$pkgdir/usr/bin/thrm"
  ln -s ../lib/thrm/thrm-core "$pkgdir/usr/bin/thrm-core"

  install -Dm644 "$srcdir/99-flydigi-fan.rules" "$pkgdir/usr/lib/udev/rules.d/99-flydigi-fan.rules"
  install -Dm644 "$srcdir/tray-icon.png" "$pkgdir/usr/share/icons/hicolor/256x256/apps/thrm.png"
  install -Dm644 "$srcdir/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"

  install -Dm644 /dev/stdin "$pkgdir/usr/share/applications/thrm.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=THRM Fan Control
Comment=Flydigi BS Series Fan Controller
Exec=/usr/bin/thrm
Icon=thrm
Terminal=false
Categories=Utility;
EOF
}
