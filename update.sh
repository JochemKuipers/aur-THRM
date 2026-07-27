#!/usr/bin/env bash
# Bump PKGBUILD/.SRCINFO to the latest TIANLI0/THRM release.
# Exit 0 if already up to date (or after a successful bump).
set -euo pipefail

cd "$(dirname "$0")"

api="${GITHUB_API_URL:-https://api.github.com}/repos/TIANLI0/THRM/releases/latest"
tag=$(curl -fsSL "$api" | jq -r '.tag_name')
[[ -n "$tag" && "$tag" != null ]] || { echo "failed to resolve latest tag" >&2; exit 1; }
ver="${tag#v}"
ver="${ver#V}"

cur=$(sed -n 's/^pkgver=//p' PKGBUILD | head -1)
if [[ "$ver" == "$cur" ]]; then
  echo "already at $ver"
  exit 0
fi

echo "bumping $cur -> $ver"

tar_url="https://github.com/TIANLI0/THRM/releases/download/v${ver}/THRM-linux-amd64-portable.tar.gz"
lic_url="https://raw.githubusercontent.com/TIANLI0/THRM/v${ver}/LICENSE"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "$tar_url" -o "$tmp/portable.tar.gz"
curl -fsSL "$lic_url" -o "$tmp/LICENSE"
tar -xzf "$tmp/portable.tar.gz" -C "$tmp"

tar_sum=$(sha256sum "$tmp/portable.tar.gz" | awk '{print $1}')
lic_sum=$(sha256sum "$tmp/LICENSE" | awk '{print $1}')
rules_sum=$(sha256sum 99-flydigi-fan.rules | awk '{print $1}')

# Refresh tray PNG from upstream portable appicon (committed source).
cp -f "$tmp"/THRM-linux-amd64/appicon.png tray-icon.png
tray_sum=$(sha256sum tray-icon.png | awk '{print $1}')

# Locate embedded icon.ico span in the new thrm-core (run once per bump).
read -r tray_off tray_span < <(python - "$tmp/THRM-linux-amd64/thrm-core" <<'PY'
import struct, sys
from pathlib import Path
core = Path(sys.argv[1]).read_bytes()

def ico_blob(buf, off):
    if off + 6 > len(buf):
        return None
    reserved, typ, count = struct.unpack_from("<HHH", buf, off)
    if reserved or typ != 1 or not 1 <= count <= 16:
        return None
    hdr = 6 + count * 16
    if off + hdr > len(buf):
        return None
    end, ok = off + hdr, 0
    for i in range(count):
        size, img_off = struct.unpack_from("<II", buf, off + 6 + i * 16 + 8)
        if size < 16 or img_off < hdr:
            return None
        start, stop = off + img_off, off + img_off + size
        if stop > len(buf):
            return None
        head = buf[start:start + 8]
        if head.startswith(b"\x89PNG") or head[:2] == b"BM" or head[:4] == b"\x28\x00\x00\x00":
            ok += 1
        end = max(end, stop)
    size = end - off
    if ok == 0 or size < 50_000 or off < 1_000_000:
        return None
    return size

cands = []
start = 0
while True:
    off = core.find(b"\x00\x00\x01\x00", start)
    if off < 0:
        break
    size = ico_blob(core, off)
    if size:
        cands.append((off, size))
    start = off + 1
if not cands:
    raise SystemExit("no embedded icon.ico in new thrm-core")
off, size = max(cands)
print(off, size)
PY
)

awk -v ver="$ver" -v tar_sum="$tar_sum" -v lic_sum="$lic_sum" -v rules_sum="$rules_sum" \
    -v tray_sum="$tray_sum" -v tray_off="$tray_off" -v tray_span="$tray_span" '
  /^pkgver=/ { print "pkgver=" ver; next }
  /^pkgrel=/ { print "pkgrel=1"; next }
  /^_tray_icon_offset=/ { print "_tray_icon_offset=" tray_off; next }
  /^_tray_icon_span=/ { print "_tray_icon_span=" tray_span; next }
  /^sha256sums=/,/^)/ {
    if (/^sha256sums=/) {
      print "sha256sums=("
      print "  '\''" tar_sum "'\''"
      print "  '\''" lic_sum "'\''"
      print "  '\''" rules_sum "'\''"
      print "  '\''" tray_sum "'\''"
      print ")"
      skip = 1
      next
    }
    if (skip && /^)/) { skip = 0; next }
    if (skip) next
  }
  { print }
' PKGBUILD > PKGBUILD.tmp
mv PKGBUILD.tmp PKGBUILD

cat > .SRCINFO <<EOF
pkgbase = thrm-bin
	pkgdesc = Flydigi BS-series laptop cooler controller (prebuilt)
	pkgver = ${ver}
	pkgrel = 1
	url = https://github.com/TIANLI0/THRM
	arch = x86_64
	license = MIT
	depends = gtk3
	depends = webkit2gtk-4.1
	depends = hidapi
	optdepends = bluez: BS1 BLE support
	provides = thrm
	conflicts = thrm
	options = !strip
	options = !debug
	source = https://github.com/TIANLI0/THRM/releases/download/v${ver}/THRM-linux-amd64-portable.tar.gz
	source = LICENSE::https://raw.githubusercontent.com/TIANLI0/THRM/v${ver}/LICENSE
	source = 99-flydigi-fan.rules
	source = tray-icon.png
	sha256sums = ${tar_sum}
	sha256sums = ${lic_sum}
	sha256sums = ${rules_sum}
	sha256sums = ${tray_sum}

pkgname = thrm-bin
EOF

echo "updated to $ver (tray icon @ ${tray_off}+${tray_span})"
