# Maintainer: Jochem Kuipers <jochem@kuipers.cc>
pkgname=thrm-bin
pkgver=3.6.2
pkgrel=5
pkgdesc='Flydigi BS-series laptop cooler controller (prebuilt)'
arch=('x86_64')
url='https://github.com/TIANLI0/THRM'
license=('MIT')
depends=('gtk3' 'webkit2gtk-4.1' 'hidapi')
makedepends=('python')
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
  'd4be9169291886ef90c0fdd2bf70f02140ca13faddb14a2d08ea0307495ec8cd'
)

package() {
  cd "$srcdir/THRM-linux-amd64"

  # Upstream writes logs/telemetry next to the binary (GetInstallDir = dirname(exe)).
  install -Dm755 thrm "$pkgdir/usr/lib/thrm/thrm"
  install -Dm755 thrm-core "$pkgdir/usr/lib/thrm/thrm-core"
  install -dm1777 "$pkgdir/usr/lib/thrm/logs"
  install -dm1777 "$pkgdir/usr/lib/thrm/telemetry"

  # Linux systray only decodes PNG; replace embedded .ico with committed tray-icon.png.
  # (dd seek was corrupting the write; slice-assign is reliable.)
  python - "$pkgdir/usr/lib/thrm/thrm-core" "$srcdir/tray-icon.png" \
    "$_tray_icon_offset" "$_tray_icon_span" <<'PY'
from pathlib import Path
import sys
core_path, png_path = Path(sys.argv[1]), Path(sys.argv[2])
off, span = int(sys.argv[3]), int(sys.argv[4])
png = png_path.read_bytes()
if len(png) > span:
    raise SystemExit(f"tray-icon.png too large ({len(png)} > {span})")
core = bytearray(core_path.read_bytes())
core[off : off + span] = png + b"\x00" * (span - len(png))
core_path.write_bytes(core)
PY

  install -dm755 "$pkgdir/usr/bin"
  ln -s ../lib/thrm/thrm "$pkgdir/usr/bin/thrm"
  ln -s ../lib/thrm/thrm-core "$pkgdir/usr/bin/thrm-core"

  install -Dm644 "$srcdir/99-flydigi-fan.rules" "$pkgdir/usr/lib/udev/rules.d/99-flydigi-fan.rules"
  # Desktop icon can stay larger; tray uses the patched 64px PNG inside thrm-core.
  install -Dm644 appicon.png "$pkgdir/usr/share/icons/hicolor/256x256/apps/thrm.png"
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
