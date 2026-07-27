# Maintainer: Jochem Kuipers <jochem@kuipers.cc>
pkgname=thrm-bin
pkgver=3.6.2
pkgrel=3
pkgdesc='Flydigi BS-series laptop cooler controller (prebuilt)'
arch=('x86_64')
url='https://github.com/TIANLI0/THRM'
license=('MIT')
depends=('gtk3' 'webkit2gtk-4.1' 'hidapi')
optdepends=('bluez: BS1 BLE support')
provides=('thrm')
conflicts=('thrm')
options=('!strip' '!debug')
source=(
  "https://github.com/TIANLI0/THRM/releases/download/v${pkgver}/THRM-linux-amd64-portable.tar.gz"
  "LICENSE::https://raw.githubusercontent.com/TIANLI0/THRM/v${pkgver}/LICENSE"
  '99-flydigi-fan.rules'
)
sha256sums=(
  '3d146a8e42a58d076f9719d3b4af2e653e5b4ae5b3fcbda22a8fb3c33c7bbf4f'
  'bb4f94dbe3dcfdc66e27d35cae627a73c9e8f66ec792971e569d272893b08ac6'
  'd267175637ab454a65e12fe619e244d4d202ade38ecf4c12b4e254a90ecdfbc8'
)

package() {
  cd "$srcdir/THRM-linux-amd64"

  # Upstream writes logs/telemetry next to the binary (GetInstallDir = dirname(exe)).
  # Keep binaries out of /usr/bin so those dirs can be user-writable.
  install -Dm755 thrm "$pkgdir/usr/lib/thrm/thrm"
  install -Dm755 thrm-core "$pkgdir/usr/lib/thrm/thrm-core"
  install -dm1777 "$pkgdir/usr/lib/thrm/logs"
  install -dm1777 "$pkgdir/usr/lib/thrm/telemetry"

  install -dm755 "$pkgdir/usr/bin"
  ln -s ../lib/thrm/thrm "$pkgdir/usr/bin/thrm"
  ln -s ../lib/thrm/thrm-core "$pkgdir/usr/bin/thrm-core"

  # Patched rules: upstream ATTRS{idVendor} misses Bluetooth HID (uhid).
  install -Dm644 "$srcdir/99-flydigi-fan.rules" "$pkgdir/usr/lib/udev/rules.d/99-flydigi-fan.rules"
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
